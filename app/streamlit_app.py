import streamlit as st
import requests
import uuid
import os
import time
from pathlib import Path

# URL de l'API Gateway injectée par ECS comme variable d'environnement
API_URL = os.environ.get("API_GATEWAY_URL", "http://localhost:8000/chat")

# ─── Configuration de la page ───
st.set_page_config(
    page_title="DevOps AI Assistant",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ─── Chargement du CSS externe ───
css_path = Path(__file__).parent / "static" / "style.css"
st.markdown(f"<style>{css_path.read_text(encoding='utf-8')}</style>", unsafe_allow_html=True)


# ─── Initialisation du state ───
if "session_id" not in st.session_state:
    st.session_state.session_id = None
if "messages" not in st.session_state:
    st.session_state.messages = []
if "total_queries" not in st.session_state:
    st.session_state.total_queries = 0


# ─── Sidebar ───
with st.sidebar:
    st.markdown("### DevOps AI")
    st.markdown('<div class="custom-divider"></div>', unsafe_allow_html=True)

    # Statut en ligne
    st.markdown(
        '<div class="status-badge status-online">'
        '<span class="pulse-dot"></span> En ligne'
        '</div>',
        unsafe_allow_html=True,
    )

    st.markdown("")

    # Carte Session ID
    short_id = st.session_state.session_id[:8] if st.session_state.session_id else "Nouvelle"
    st.markdown(
        f'<div class="sidebar-card">'
        f'<div class="sidebar-card-title">Session ID</div>'
        f'<div class="sidebar-card-value">{short_id}...</div>'
        f'</div>',
        unsafe_allow_html=True,
    )

    # Carte Métriques
    st.markdown(
        f'<div class="sidebar-card">'
        f'<div class="sidebar-card-title">Métriques</div>'
        f'<div class="metric-row">'
        f'<span class="metric-label">Messages</span>'
        f'<span class="metric-value">{len(st.session_state.messages)}</span>'
        f'</div>'
        f'<div class="metric-row">'
        f'<span class="metric-label">Requêtes</span>'
        f'<span class="metric-value">{st.session_state.total_queries}</span>'
        f'</div>'
        f'</div>',
        unsafe_allow_html=True,
    )

    st.markdown("")

    if st.button("🔄 Nouvelle conversation", use_container_width=True):
        st.session_state.session_id = None
        st.session_state.messages = []
        st.session_state.total_queries = 0
        st.rerun()

    st.markdown('<div class="custom-divider"></div>', unsafe_allow_html=True)



# ─── Zone de chat principale ───
st.markdown('<div class="hero-title">DevOps AI Assistant</div>', unsafe_allow_html=True)
st.markdown(
    '<div class="hero-subtitle">'
    "Propulsé par Amazon Bedrock · Nova Lite · RAG sur vos documentations"
    "</div>",
    unsafe_allow_html=True,
)

# Message d'accueil si la conversation est vide
if not st.session_state.messages:
    with st.chat_message("assistant", avatar="🤖"):
        st.markdown(
            "Bonjour ! 👋 Je suis votre assistant DevOps.\n\n"
            "Je peux vous aider avec :\n"
            "- 🏗️ **Terraform** — modules, state, providers\n"
            "- ☸️ **Kubernetes** — deployments, services, debugging\n"
            "- 🔄 **CI/CD** — GitHub Actions, Jenkins, ArgoCD\n"
            "- ☁️ **AWS** — architecture, sécurité, coûts\n\n"
            "Posez votre question ! 🚀"
        )

# Afficher l'historique des messages
for msg in st.session_state.messages:
    avatar = "👤" if msg["role"] == "user" else "🤖"
    with st.chat_message(msg["role"], avatar=avatar):
        st.markdown(msg["content"])
        # Afficher les citations si présentes
        if msg.get("citations"):
            _render_citations(msg["citations"])


def _render_citations(citations):
    """Affiche les sources documentaires utilisées par le RAG."""
    if not citations:
        return
    with st.expander("📄 Sources consultées", expanded=False):
        for i, cite in enumerate(citations, 1):
            source_name = cite.get("source", "").split("/")[-1]
            excerpt = cite.get("excerpt", "")
            st.markdown(
                f"**{i}.** `{source_name}`\n"
                f"> {excerpt}..."
            )


def _send_message(user_input):
    """Envoie le message à l'API Gateway et traite la réponse."""
    try:
        payload = {"message": user_input}
        if st.session_state.session_id:
            payload["sessionId"] = st.session_state.session_id

        response = requests.post(
            API_URL,
            json=payload,
            timeout=60,
        )
        response.raise_for_status()
        return response.json()

    except requests.exceptions.Timeout:
        return {"error": "⏱️ Timeout — le serveur met trop de temps."}
    except requests.exceptions.ConnectionError:
        return {"error": "🔌 Impossible de joindre l'API. Vérifiez l'URL."}
    except Exception as e:
        return {"error": f"❌ Erreur : {str(e)}"}


# ─── Gestion de l'input utilisateur ───
if prompt := st.chat_input("Posez votre question DevOps... (ex: Comment créer un module Terraform ?)"):
    # Afficher et stocker le message utilisateur
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user", avatar="👤"):
        st.markdown(prompt)

    # Appeler l'API et afficher la réponse
    with st.chat_message("assistant", avatar="🤖"):
        with st.spinner("🔍 Recherche dans la base de connaissances..."):
            start = time.time()
            data = _send_message(prompt)
            elapsed = time.time() - start

        if "error" in data:
            st.error(data["error"])
            st.session_state.messages.append(
                {"role": "assistant", "content": data["error"]}
            )
        else:
            answer = data.get("response", "Pas de réponse du modèle.")
            citations = data.get("citations", [])

            # Mettre à jour le sessionId retourné par Bedrock
            if data.get("sessionId"):
                st.session_state.session_id = data["sessionId"]

            # Rendu Markdown avec coloration syntaxique automatique
            st.markdown(answer)

            # Afficher les citations et le temps de réponse
            _render_citations(citations)
            st.caption(f"⚡ Réponse en {elapsed:.1f}s")

            st.session_state.messages.append({
                "role": "assistant",
                "content": answer,
                "citations": citations,
            })

        st.session_state.total_queries += 1
