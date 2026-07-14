import { SquarePen, Sparkles } from 'lucide-react';
import { useChatContext } from '../../context/ChatContext.jsx';
import '../../styles/layout/Header.css';

export default function Header() {
  const { sessionId, newConversation } = useChatContext();

  return (
    <header className="header" id="header">
      <div className="header-left">
        <div className="header-logo-badge">
          <Sparkles size={18} className="header-logo-icon" />
        </div>
        <div className="header-session">
          <span className="header-session-label">Session</span>
          <span className="header-session-id">
            {sessionId ? sessionId.slice(0, 12) + '…' : 'Nouvelle session'}
          </span>
        </div>
      </div>
      <div className="header-right">
        <button
          className="header-new-chat-btn"
          onClick={newConversation}
          title="Nouvelle conversation"
          id="new-chat-btn"
        >
          <SquarePen size={18} />
        </button>
      </div>
    </header>
  );
}
