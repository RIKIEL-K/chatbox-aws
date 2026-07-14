import { ChatProvider } from './context/ChatContext.jsx';
import Header from './components/layout/Header.jsx';
import ChatWindow from './components/chat/ChatWindow.jsx';
import ChatInput from './components/input/ChatInput.jsx';

export default function App() {
  return (
    <ChatProvider>
      <div className="app-layout">
        <main className="app-main">
          <Header />
          <ChatWindow />
          <ChatInput />
        </main>
      </div>
    </ChatProvider>
  );
}

