output "api_gateway_url" {
  description = "URL publique de l'endpoint /chat"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/chat"
}

output "react_url" {
  description = "URL de l'application React (ALB)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "react_ecr_repository_url" {
  description = "URL du dépôt ECR pour push l'image Docker React"
  value       = aws_ecr_repository.react.repository_url
}

output "knowledge_base_id" {
  description = "ID de la Knowledge Base Bedrock"
  value       = aws_bedrockagent_knowledge_base.devops.id
}

output "s3_bucket_name" {
  description = "Nom du bucket S3 pour vos documents DevOps"
  value       = aws_s3_bucket.docs.id
}

output "data_source_id" {
  description = "ID de la data source Bedrock (pour lancer le sync)"
  value       = aws_bedrockagent_data_source.s3.data_source_id
}
