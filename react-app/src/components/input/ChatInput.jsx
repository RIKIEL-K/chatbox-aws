import { useState, useRef, useEffect } from 'react';
import { Send, Sparkles } from 'lucide-react';
import { useChatContext } from '../../context/ChatContext.jsx';
import '../../styles/input/ChatInput.css';

export default function ChatInput() {
  const { sendMessage, isLoading } = useChatContext();
  const [inputValue, setInputValue] = useState('');
  const textareaRef = useRef(null);

  // Auto-resize du textarea
  useEffect(() => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = 'auto';
      textarea.style.height = Math.min(textarea.scrollHeight, 160) + 'px';
    }
  }, [inputValue]);

  const handleSubmit = (e) => {
    e?.preventDefault();
    if (!inputValue.trim() || isLoading) return;
    sendMessage(inputValue);
    setInputValue('');
    // Reset textarea height
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  return (
    <div className="chat-input-container" id="chat-input-container">
      <form className="chat-input-form" onSubmit={handleSubmit}>
        <div className="chat-input-wrapper">
          <Sparkles size={16} className="chat-input-icon" />
          <textarea
            ref={textareaRef}
            className="chat-input-textarea"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Posez votre question DevOps… (ex: Comment créer un module Terraform ?)"
            disabled={isLoading}
            rows={1}
            id="chat-input"
            aria-label="Message"
          />
          <button
            type="submit"
            className={`chat-input-send ${inputValue.trim() && !isLoading ? 'chat-input-send--active' : ''}`}
            disabled={!inputValue.trim() || isLoading}
            title="Envoyer"
            id="chat-send-btn"
            aria-label="Envoyer le message"
          >
            <Send size={18} />
          </button>
        </div>
      </form>
    </div>
  );
}
