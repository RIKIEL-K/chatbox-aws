
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.project_name}-enc"
  type = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.project_name}-vectors"]
    }]
    AWSOwnedKey = true
  })
}

# Politique réseau autorisant l'accès public (API AWS).
# Simplifie le dev par rapport à un VPC Endpoint privé.
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-net"
  type = "network"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-vectors"]
      },
      {
        ResourceType = "dashboard"
        Resource     = ["collection/${var.project_name}-vectors"]
      }
    ]
    AllowFromPublic = true
  }])
}

# Politique d'accès aux données de l'index vectoriel.
# Autorise Terraform (création) et le rôle Bedrock (lecture/écriture).
resource "aws_opensearchserverless_access_policy" "data" {
  name = "${var.project_name}-data"
  type = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index"
        Resource     = ["index/${var.project_name}-vectors/*"]
        Permission = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ]
      },
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-vectors"]
        Permission = [
          "aoss:CreateCollectionItems",
          "aoss:DeleteCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:DescribeCollectionItems"
        ]
      }
    ]
    Principal = [
      aws_iam_role.bedrock_kb.arn,
      data.aws_caller_identity.current.arn
    ]
  }])
}

# Création de la collection vectorielle (le conteneur de la BDD).
# Mode "DISABLED" pour économiser les coûts de redondance en dev.
resource "aws_opensearchserverless_collection" "vector" {
  name             = "${var.project_name}-vectors"
  type             = "VECTORSEARCH"
  standby_replicas = "DISABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data
  ]

  tags = {
    Name        = "${var.project_name}-vectors"
    Environment = var.environment
  }
}

resource "time_sleep" "wait_for_collection" {
  depends_on       = [aws_opensearchserverless_collection.vector]
  create_duration  = "120s"
  destroy_duration = "30s"
}


resource "opensearch_index" "bedrock" {
  name                           = "bedrock-knowledge-base-default-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"

  mappings = jsonencode({
    properties = {
      "bedrock-knowledge-base-default-vector" = {
        type      = "knn_vector"
        dimension = 1024
        method = {
          name       = "hnsw"
          engine     = "faiss"
          parameters = { m = 16, ef_construction = 512 }
          space_type = "l2"
        }
      }
      "AMAZON_BEDROCK_METADATA"   = { type = "text", index = false }
      "AMAZON_BEDROCK_TEXT_CHUNK" = { type = "text", index = true }
    }
  })

  force_destroy = true

  depends_on = [
    time_sleep.wait_for_collection,
    aws_opensearchserverless_access_policy.data
  ]

  lifecycle {
    ignore_changes = [mappings]
  }
}

