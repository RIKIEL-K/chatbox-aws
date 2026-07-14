import { useState } from 'react';
import { Copy, Check } from 'lucide-react';
import '../../styles/chat/MessageActions.css';

export default function MessageActions({ content }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(content);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback silencieux
    }
  };

  return (
    <div className="message-actions" id="message-actions">
      <button
        className={`action-btn ${copied ? 'action-btn--active' : ''}`}
        onClick={handleCopy}
        title="Copier"
        aria-label="Copier le message"
      >
        {copied ? <Check size={14} /> : <Copy size={14} />}
      </button>
    </div>
  );
}


