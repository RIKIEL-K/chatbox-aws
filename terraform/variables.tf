variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Préfixe de nommage des ressources AWS"
  type        = string
  default     = "devops-chatbot"
}

variable "environment" {
  description = "Environnement cible (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "bedrock_model_id" {
  description = "ID du modèle Bedrock pour la génération de réponses"
  type        = string
  default     = "amazon.nova-lite-v1:0"
}

variable "embedding_model_id" {
  description = "ID du modèle d'embedding pour l'indexation vectorielle"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}
