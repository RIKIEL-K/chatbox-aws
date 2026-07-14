import { createContext, useContext } from 'react';
import { useChat } from '../hooks/useChat.js';

/**
 * Context React pour partager l'état du chat dans l'arbre de composants.
 */
const ChatContext = createContext(null);

/**
 * Provider qui enveloppe l'application et expose le hook useChat.
 */
export function ChatProvider({ children }) {
  const chat = useChat();

  return (
    <ChatContext.Provider value={chat}>
      {children}
    </ChatContext.Provider>
  );
}

/**
 * Hook consommateur pour accéder au contexte du chat.
 * @returns {ReturnType<typeof useChat>}
 */
export function useChatContext() {
  const context = useContext(ChatContext);
  if (!context) {
    throw new Error('useChatContext doit être utilisé dans un <ChatProvider>');
  }
  return context;
}
