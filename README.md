# InfraGPT

> Chatbot IA spécialisé en infrastructure et DevOps, propulsé par **Amazon Bedrock** avec un système RAG (Retrieval-Augmented Generation) basé sur une documentation technique.

🔗 **Application** : `http://<ALB_DNS_NAME>`

---

## Architecture

<!-- Insérez ici une capture d'écran de votre architecture AWS -->

---

## Prérequis

Avant de commencer, assurez-vous que les éléments suivants sont installés et configurés sur votre machine :

| Outil | Version minimale |
|---|---|
| [AWS CLI](https://aws.amazon.com/cli/) | v2 configurée avec un profil valide |
| [Terraform](https://www.terraform.io/downloads) | >= 1.5.0 |
| [Docker](https://www.docker.com/get-started/) | Toute version récente |

---

## Déploiement (1ère mise en place)

### 1. Cloner le dépôt

```bash
git clone <url-du-repo>
cd chatbox-aws
```

### 2. Initialiser le backend Terraform distant

L'état Terraform est stocké dans un bucket S3 avec verrouillage DynamoDB pour la cohérence lors des déploiements CI/CD.

```bash
aws s3api create-bucket \
  --bucket devops-chatbot-terraform-state-bucket \
  --region us-east-1

aws dynamodb create-table \
  --table-name devops-chatbot-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 3. Déployer l'infrastructure

```bash
terraform apply
```

### 6. Accéder à l'application

```bash
cd ../terraform
terraform output react_url
# → http://<ALB_DNS_NAME>
```

---

## Déploiement continu (CI/CD)

Ce dépôt embarque un pipeline GitHub Actions (`./github/workflows/deploy.yml`) qui automatise l'intégralité du cycle de déploiement à chaque push sur `main` :

- Bootstrap automatique du backend Terraform (S3 + DynamoDB) si les ressources n'existent pas encore
- `terraform apply` pour mettre à jour l'infrastructure
- Build et push de l'image Docker sur ECR
- Redéploiement du service ECS
- Synchronisation de la Knowledge Base Bedrock

---

## Détruire l'infrastructure

```bash
cd terraform
terraform destroy
```

> **Attention** : Les ressources de backend Terraform (bucket S3 et table DynamoDB) ne sont **pas** gérées par Terraform. Supprimez-les manuellement depuis la console AWS si vous souhaitez un nettoyage complet.