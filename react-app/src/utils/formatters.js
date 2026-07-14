/**
 * Helpers de formatage pour l'interface chat.
 */

/**
 * Extrait le nom de fichier d'une URI S3.
 * Ex: "s3://bucket/docs/terraform.pdf" → "terraform.pdf"
 */
export function extractSourceName(uri) {
  if (!uri) return 'Source inconnue';
  const parts = uri.split('/');
  return parts[parts.length - 1] || uri;
}

/**
 * Formate un timestamp en heure locale (HH:MM).
 */
export function formatTime(timestamp) {
  if (!timestamp) return '';
  const date = new Date(timestamp);
  return date.toLocaleTimeString('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Tronque un texte à une longueur maximale.
 */
export function truncate(text, maxLength = 200) {
  if (!text || text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '…';
}

