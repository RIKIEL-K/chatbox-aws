# 🚀 DevOps AI Chatbot

Chatbot IA spécialisé DevOps propulsé par **Amazon Bedrock (Claude 3.5 Haiku)** avec RAG sur vos documentations via **Bedrock Knowledge Bases + OpenSearch Serverless**.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────────┐
│   Streamlit UI  │────▶│  API Gateway     │────▶│  Lambda (Python 3.12)   │
│   (ECS Fargate) │     │  REST /chat      │     │  retrieve_and_generate  │
└─────────────────┘     └──────────────────┘     └───────────┬─────────────┘
                                                             │
                                                             ▼
                                                  ┌─────────────────────┐
                                                  │  Bedrock KB (RAG)   │
                                                  │  Claude 3.5 Haiku   │
                                                  └────┬───────────┬────┘
                                                       │           │
                                            ┌──────────▼──┐  ┌────▼──────────┐
                                            │ OpenSearch   │  │  S3 Bucket    │
                                            │ Serverless   │  │  (vos docs)   │
                                            └─────────────┘  └───────────────┘
```

## Prérequis

- **AWS CLI** configuré avec un profil valide
- **Terraform** >= 1.5.0
- **Docker** (pour builder l'image Streamlit)
- **Accès Bedrock** activé dans la console AWS pour :
  - `anthropic.claude-3-5-haiku-20241022-v1:0`
  - `amazon.titan-embed-text-v2:0`

## Déploiement

### 1. Infrastructure Terraform

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

> ⚠️ **Premier déploiement** : Si le provider OpenSearch échoue (la collection n'existe
> pas encore), lancez d'abord :
> ```bash
> terraform apply -target=aws_opensearchserverless_collection.vector
> ```
> Puis relancez `terraform apply`.

### 2. Upload de vos documents DevOps

```bash
# Récupérer le nom du bucket depuis les outputs Terraform
BUCKET=$(terraform output -raw s3_bucket_name)

# Uploader vos fichiers PDF/Markdown
aws s3 cp ./vos-docs/ s3://$BUCKET/ --recursive
```

### 3. Synchroniser la Knowledge Base

```bash
KB_ID=$(terraform output -raw knowledge_base_id)
DS_ID=$(terraform output -raw data_source_id)

aws bedrock-agent start-ingestion-job \
    --knowledge-base-id $KB_ID \
    --data-source-id $DS_ID
```

### 4. Builder et pousser l'image Docker

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

# Login ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# Build & Push
cd ../app
docker build -t devops-chatbot-streamlit .
docker tag devops-chatbot-streamlit:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Forcer le redéploiement ECS pour prendre la nouvelle image
aws ecs update-service \
    --cluster devops-chatbot-cluster \
    --service devops-chatbot-streamlit \
    --force-new-deployment
```

### 5. Accéder à l'application

```bash
terraform output streamlit_url
# → http://devops-chatbot-alb-XXXXXX.us-east-1.elb.amazonaws.com
```