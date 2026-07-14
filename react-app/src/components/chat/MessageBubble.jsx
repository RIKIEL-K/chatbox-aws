import { Bot, User } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark } from 'react-syntax-highlighter/dist/esm/styles/prism';
import MessageActions from './MessageActions.jsx';
import CitationList from './CitationList.jsx';
import { formatTime } from '../../utils/formatters.js';
import '../../styles/chat/MessageBubble.css';

export default function MessageBubble({ message, index }) {
  const { role, content, citations, timestamp, isError } = message;
  const isUser = role === 'user';

  return (
    <div
      className={`message-bubble ${isUser ? 'message-bubble--user' : 'message-bubble--assistant'} ${isError ? 'message-bubble--error' : ''}`}
      style={{ animationDelay: `${index * 50}ms` }}
      id={`message-${index}`}
    >
      {/* Avatar */}
      <div className={`message-avatar ${isUser ? 'message-avatar--user' : 'message-avatar--bot'}`}>
        {isUser ? <User size={18} /> : <Bot size={18} />}
      </div>

      {/* Content */}
      <div className="message-content-wrapper">
        <div className="message-role-label">
          {isUser ? 'Vous' : 'DevOps AI'}
          {timestamp && (
            <span className="message-time">{formatTime(timestamp)}</span>
          )}
        </div>

        <div className={`message-content ${isError ? 'message-content--error' : ''}`}>
          {isUser ? (
            <p>{content}</p>
          ) : (
            <ReactMarkdown
              components={{
                code({ className, children, ...props }) {
                  const match = /language-(\w+)/.exec(className || '');
                  const codeString = String(children).replace(/\n$/, '');
                  return match ? (
                    <SyntaxHighlighter
                      style={oneDark}
                      language={match[1]}
                      PreTag="div"
                      customStyle={{
                        borderRadius: '10px',
                        border: '1px solid rgba(0,255,136,0.12)',
                        fontSize: '0.85rem',
                        margin: '12px 0',
                      }}
                      {...props}
                    >
                      {codeString}
                    </SyntaxHighlighter>
                  ) : (
                    <code className="inline-code" {...props}>
                      {children}
                    </code>
                  );
                },
              }}
            >
              {content}
            </ReactMarkdown>
          )}
        </div>

        {/* Actions — only for assistant messages */}
        {!isUser && !isError && <MessageActions content={content} />}

        {/* Citations */}
        {citations && citations.length > 0 && <CitationList citations={citations} />}
      </div>
    </div>
  );
}
