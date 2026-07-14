# Rôle IAM de base autorisant le service Lambda à s'exécuter.
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
  }
}

# Permissions spécifiques de la Lambda : appeler Bedrock (RAG) 
# et écrire ses logs dans CloudWatch. Pas d'autres accès.
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockRAG"
        Effect = "Allow"
        Action = [
          "bedrock:RetrieveAndGenerate",
          "bedrock:Retrieve"
        ]
        Resource = [aws_bedrockagent_knowledge_base.devops.arn]
      },
      {
        Sid    = "BedrockInvokeModel"
        Effect = "Allow"
        Action = ["bedrock:InvokeModel", "bedrock:GetInferenceProfile"]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/*",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/*"
        ]
      },
      {
        Sid    = "BedrockMarketplace"
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe",
          "aws-marketplace:Unsubscribe"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# ─── Fonction Lambda ───

# Compresse le code Python local (handler.py) en archive ZIP 
# pour le déployer sur AWS Lambda.
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  excludes    = ["lambda.zip", "__pycache__"]
  output_path = "${path.module}/.build/lambda.zip"
}

# Déploie la fonction Lambda avec Python 3.12, 256MB de RAM, 
# et lui passe les variables d'environnement nécessaires.
resource "aws_lambda_function" "chat" {
  function_name    = "${var.project_name}-chat"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 256
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.devops.id
      MODEL_ARN         = length(regexall("^us\\.", var.bedrock_model_id)) > 0 ? "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.bedrock_model_id}" : "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}"
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name        = "${var.project_name}-chat"
    Environment = var.environment
  }
}

# Configuration du groupe de logs de la Lambda.
# Rétention fixée à 14 jours pour ne pas payer indéfiniment.
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.chat.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-lambda-logs"
    Environment = var.environment
  }
}
