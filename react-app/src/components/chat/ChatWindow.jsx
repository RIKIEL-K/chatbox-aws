import { useRef, useEffect } from 'react';
import { useChatContext } from '../../context/ChatContext.jsx';
import MessageBubble from './MessageBubble.jsx';
import TypingIndicator from './TypingIndicator.jsx';
import { Bot } from 'lucide-react';
import '../../styles/chat/ChatWindow.css';

export default function ChatWindow() {
  const { messages, isLoading } = useChatContext();
  const scrollRef = useRef(null);
  const bottomRef = useRef(null);

  // Auto-scroll vers le bas à chaque nouveau message
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  return (
    <div className="chat-window" id="chat-window" ref={scrollRef}>
      {messages.length === 0 ? (
        <div className="chat-welcome">
          <div className="chat-welcome-icon">
            <Bot size={40} />
          </div>
          <h2 className="chat-welcome-title">DevOps AI Assistant</h2>
          <p className="chat-welcome-subtitle">
            Bonjour ! Je suis votre assistant DevOps. Posez votre question !
          </p>
        </div>
      ) : (
        <div className="chat-messages">
          {messages.map((msg, idx) => (
            <MessageBubble key={idx} message={msg} index={idx} />
          ))}
          {isLoading && <TypingIndicator />}
        </div>
      )}
      <div ref={bottomRef} />
    </div>
  );
}
