import { useReducer, useCallback } from 'react';
import { sendChatMessage } from '../api/chatApi.js';

/**
 * Actions du reducer de chat.
 */
const ACTIONS = {
  SEND_MESSAGE: 'SEND_MESSAGE',
  RECEIVE_RESPONSE: 'RECEIVE_RESPONSE',
  SET_ERROR: 'SET_ERROR',
  NEW_CONVERSATION: 'NEW_CONVERSATION',
};

/**
 * État initial du chat.
 */
function createInitialState() {
  return {
    messages: [],
    sessionId: null,
    isLoading: false,
    error: null,
    totalQueries: 0,
  };
}

/**
 * Reducer pur pour la gestion d'état du chat.
 */
function chatReducer(state, action) {
  switch (action.type) {
    case ACTIONS.SEND_MESSAGE: {
      return {
        ...state,
        messages: [
          ...state.messages,
          {
            role: 'user',
            content: action.payload,
            timestamp: Date.now(),
          },
        ],
        isLoading: true,
        error: null,
      };
    }

    case ACTIONS.RECEIVE_RESPONSE: {
      const { response, sessionId, citations } = action.payload;
      return {
        ...state,
        messages: [
          ...state.messages,
          {
            role: 'assistant',
            content: response,
            citations: citations || [],
            timestamp: Date.now(),
          },
        ],
        sessionId: sessionId || state.sessionId,
        isLoading: false,
        totalQueries: state.totalQueries + 1,
      };
    }

    case ACTIONS.SET_ERROR: {
      return {
        ...state,
        messages: [
          ...state.messages,
          {
            role: 'assistant',
            content: action.payload,
            timestamp: Date.now(),
            isError: true,
          },
        ],
        isLoading: false,
        error: action.payload,
        totalQueries: state.totalQueries + 1,
      };
    }

    case ACTIONS.NEW_CONVERSATION: {
      return createInitialState();
    }

    default:
      return state;
  }
}

/**
 * Custom hook encapsulant toute la logique du chat.
 * Expose : messages, isLoading, error, sendMessage, newConversation.
 */
export function useChat() {
  const [state, dispatch] = useReducer(chatReducer, null, createInitialState);

  const sendMessage = useCallback(
    async (text) => {
      const trimmed = text.trim();
      if (!trimmed) return;

      dispatch({ type: ACTIONS.SEND_MESSAGE, payload: trimmed });

      try {
        const data = await sendChatMessage(trimmed, state.sessionId);
        dispatch({ type: ACTIONS.RECEIVE_RESPONSE, payload: data });
      } catch (err) {
        dispatch({
          type: ACTIONS.SET_ERROR,
          payload: `❌ Erreur : ${err.message}`,
        });
      }
    },
    [state.sessionId]
  );

  const newConversation = useCallback(() => {
    dispatch({ type: ACTIONS.NEW_CONVERSATION });
  }, []);

  return {
    messages: state.messages,
    sessionId: state.sessionId,
    isLoading: state.isLoading,
    error: state.error,
    totalQueries: state.totalQueries,
    sendMessage,
    newConversation,
  };
}

