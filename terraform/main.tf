terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "devops-chatbot-terraform-state-bucket"
    key            = "devops-chatbot/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-chatbot-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}

# Provider OpenSearch pour créer l'index dans la base vectorielle.
# Utilise l'authentification AWS SigV4 automatiquement.
provider "opensearch" {
  url         = aws_opensearchserverless_collection.vector.collection_endpoint
  healthcheck = false
  aws_region  = var.aws_region
}

# Récupération de l'identité et de la région AWS courantes.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Récupération du réseau VPC par défaut.
data "aws_vpc" "default" {
  default = true
}

# Récupération des sous-réseaux publics du VPC par défaut.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
