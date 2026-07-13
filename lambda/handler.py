import json
import os
import boto3
import logging
import time

# ─── Structured JSON Logging ───
# Format JSON pour CloudWatch Logs Insights : facilite les requêtes
# par session_id, latency, error_type, etc.

class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "function": record.funcName,
        }
        # Ajoute les champs extra (session_id, latency, etc.)
        if hasattr(record, "extra_data"):
            log_entry.update(record.extra_data)
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_entry, ensure_ascii=False)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Remplace le formatter par défaut de Lambda par le JSON formatter
if logger.handlers:
    for handler in logger.handlers:
        handler.setFormatter(JsonFormatter())

bedrock_agent = boto3.client("bedrock-agent-runtime")

KNOWLEDGE_BASE_ID = os.environ["KNOWLEDGE_BASE_ID"]
MODEL_ARN = os.environ["MODEL_ARN"]

# En-têtes CORS obligatoires car API Gateway est en proxy integration.
# Autorise Streamlit à communiquer avec cette API.
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Content-Type": "application/json",
}

def lambda_handler(event, context):
    # Point d'entrée de la Lambda.
    # Répond d'abord aux requêtes preflight (OPTIONS) du navigateur.
    if event.get("httpMethod") == "OPTIONS":
        return _response(200, {"message": "CORS preflight OK"})

    try:
        # Extraction du message utilisateur et de la session depuis la requête HTTP.
        # Le sessionId permet de garder l'historique de la discussion.
        body = json.loads(event.get("body", "{}"))
        message = body.get("message", "").strip()
        session_id = body.get("sessionId")

        if not message:
            return _response(400, {"error": "Le champ 'message' est requis."})

        # Préparation des paramètres pour le RAG (Retrieve and Generate).
        # Lie la question à la base de connaissances (S3 + OpenSearch).
        params = {
            "input": {"text": message},
            "retrieveAndGenerateConfiguration": {
                "type": "KNOWLEDGE_BASE",
                "knowledgeBaseConfiguration": {
                    "knowledgeBaseId": KNOWLEDGE_BASE_ID,
                    "modelArn": MODEL_ARN,
                },
            },
        }

        # Ajout du sessionId s'il existe pour la continuité sémantique.
        if session_id:
            params["sessionId"] = session_id

        # Invocation de Bedrock pour chercher les docs et générer la réponse.
        logger.info("Appel Bedrock KB", extra={"extra_data": {
            "action": "bedrock_invoke",
            "session_id": session_id,
            "input_preview": message[:100],
            "model_arn": MODEL_ARN,
            "knowledge_base_id": KNOWLEDGE_BASE_ID,
        }})

        start_time = time.time()
        response = bedrock_agent.retrieve_and_generate(**params)
        latency = round((time.time() - start_time) * 1000)

        # Extraction des citations (sources S3) et renvoi à Streamlit.
        citations = _extract_citations(response)

        logger.info("Réponse Bedrock OK", extra={"extra_data": {
            "action": "bedrock_response",
            "session_id": response.get("sessionId", session_id),
            "latency_ms": latency,
            "citations_count": len(citations),
            "response_length": len(response["output"]["text"]),
        }})

        return _response(200, {
            "response": response["output"]["text"],
            "sessionId": response.get("sessionId", session_id),
            "citations": citations,
        })

    # Gestion des erreurs : trop de requêtes (throttling) ou erreur interne.
    except bedrock_agent.exceptions.ThrottlingException:
        logger.warning("Throttling Bedrock", extra={"extra_data": {
            "action": "error",
            "error_type": "throttling",
            "session_id": session_id if 'session_id' in dir() else None,
        }})
        return _response(429, {"error": "Trop de requêtes. Réessayez."})
    except Exception as e:
        logger.error(f"Erreur inattendue: {str(e)}", exc_info=True, extra={"extra_data": {
            "action": "error",
            "error_type": type(e).__name__,
            "error_message": str(e),
            "model_arn": MODEL_ARN,
            "session_id": session_id if 'session_id' in dir() else None,
        }})
        return _response(500, {"error": f"Erreur interne : {str(e)}"})

def _extract_citations(response):
    # Parcourt la réponse Bedrock pour extraire l'URI S3 
    # et l'extrait de texte utilisé par le modèle Claude.
    citations = []
    for citation in response.get("citations", []):
        for ref in citation.get("retrievedReferences", []):
            location = ref.get("location", {}).get("s3Location", {})
            if location.get("uri"):
                citations.append({
                    "source": location["uri"],
                    "excerpt": ref.get("content", {}).get("text", "")[:200],
                })
    return citations

def _response(status_code, body):
    # Formate la réponse HTTP finale avec le code de statut,
    # le corps en JSON et les en-têtes CORS.
    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": json.dumps(body, ensure_ascii=False),
    }
