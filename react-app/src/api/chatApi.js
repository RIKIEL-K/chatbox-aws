/**
 * Service HTTP pour communiquer avec le backend Lambda via API Gateway.
 */

const API_BASE = '/api';

/**
 * Envoie un message au backend RAG et retourne la réponse.
 * @param {string} message — Le message utilisateur
 * @param {string|null} sessionId — ID de session pour la continuité
 * @returns {Promise<{response: string, sessionId: string, citations: Array}>}
 */
export async function sendChatMessage(message, sessionId = null) {
  const payload = { message };
  if (sessionId) {
    payload.sessionId = sessionId;
  }

  const res = await fetch(`${API_BASE}/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const data = await res.json();

  if (!res.ok) {
    throw new Error(data.error || `Erreur HTTP ${res.status}`);
  }

  return data;
}
