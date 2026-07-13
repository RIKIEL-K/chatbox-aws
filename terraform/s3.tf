# ─── Bucket S3 pour les documents DevOps (source RAG) ───

# Création du bucket S3 qui stockera vos documentations (PDF, Markdown, etc.).
# Le nom inclut l'ID du compte pour garantir son unicité globale.
resource "aws_s3_bucket" "docs" {
  bucket        = "${var.project_name}-docs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-docs"
    Environment = var.environment
  }
}

# Activation du versioning des fichiers.
# Permet de récupérer une ancienne version d'un document en cas d'erreur.
resource "aws_s3_bucket_versioning" "docs" {
  bucket = aws_s3_bucket.docs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Chiffrement côté serveur (SSE) automatique.
# Garantit que les documents sont chiffrés au repos (AES256).
resource "aws_s3_bucket_server_side_encryption_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Verrouillage de l'accès public S3 (Best practice sécurité).
# Empêche toute exposition accidentelle des documents sur internet.
resource "aws_s3_bucket_public_access_block" "docs" {
  bucket = aws_s3_bucket.docs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
