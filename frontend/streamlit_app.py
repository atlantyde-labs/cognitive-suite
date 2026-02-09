#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend/streamlit_app.py
-------------------------

Interfaz interactiva basada en Streamlit para explorar los resultados del
análisis cognitivo. Esta aplicación permite cargar el fichero
``analysis.json`` generado por el pipeline, visualizar los registros
como una tabla y filtrar por etiquetas cognitivas. También muestra
detalles individuales al seleccionar un registro.

Para ejecutar en local (en desarrollo):

```
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
```

Al ejecutar dentro del contenedor Docker de ``frontend`` se utiliza
``streamlit run`` en el ``CMD``.
"""

import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any, Optional

import pandas as pd  # type: ignore
import streamlit as st  # type: ignore
import sys

# Asegurar que los scripts del motor son importables
root_dir = Path(__file__).resolve().parent.parent
if str(root_dir) not in sys.path:
    sys.path.append(str(root_dir))

try:
    from scripts.gamification_engine import GamificationEngine
except ImportError:
    GamificationEngine = None

ROLE_PERMS = {
    "viewer": {"view_details": False, "view_entities": False, "view_file": False},
    "analyst": {"view_details": True, "view_entities": True, "view_file": False},
    "admin": {"view_details": True, "view_entities": True, "view_file": True},
}


def load_data(path: Path) -> List[Dict[str, Any]]:
    """Carga el archivo de análisis JSON y devuelve una lista de registros."""
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_env(value: str) -> str:
    env = (value or "dev").strip().lower()
    if env in {"prod", "production"}:
        return "prod"
    if env in {"dev", "development", "local"}:
        return "dev"
    return "dev"


def hash_identifier(value: str, salt: str) -> str:
    payload = f"{salt}{value}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:12]


def resolve_audit_path(base: Path) -> Path:
    override = os.getenv("COGNITIVE_UI_AUDIT_LOG", "")
    if override:
        path = Path(override)
        return path if path.is_absolute() else base / path
    return base / "audit" / "ui_access.jsonl"


def write_audit_event(event: Dict[str, Any], audit_path: Path) -> None:
    try:
        audit_path.parent.mkdir(parents=True, exist_ok=True)
        with audit_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event, ensure_ascii=False) + "\n")
    except Exception:
        pass


def load_auth_tokens() -> Dict[str, str]:
    tokens: Dict[str, str] = {}
    for role in ROLE_PERMS:
        token = os.getenv(f"COGNITIVE_UI_TOKEN_{role.upper()}")
        if token:
            tokens[role] = token
    return tokens


def role_for_token(token: str, tokens: Dict[str, str]) -> Optional[str]:
    if not token:
        return None
    for role, expected in tokens.items():
        if token == expected:
            return role
    return None


def ensure_auth(
    auth_required: bool,
    tokens: Dict[str, str],
    audit_path: Path,
    env: str
) -> str:
    if not auth_required:
        st.session_state.setdefault("auth_role", "admin")
        st.session_state.setdefault("auth_user", "local")
        return "admin"

    if not tokens:
        st.error("Auth required but no tokens configured. Set COGNITIVE_UI_TOKEN_* env vars.")
        st.stop()

    if st.session_state.get("auth_role"):
        return st.session_state["auth_role"]

    st.sidebar.header("Access")
    token = st.sidebar.text_input("Access token", type="password")
    if st.sidebar.button("Sign in"):
        role = role_for_token(token, tokens)
        if role:
            st.session_state["auth_role"] = role
            st.session_state["auth_user"] = f"token:{role}"
            write_audit_event(
                {
                    "event": "ui_login_success",
                    "timestamp": now_iso(),
                    "env": env,
                    "role": role,
                },
                audit_path,
            )
            st.experimental_rerun()
        else:
            write_audit_event(
                {
                    "event": "ui_login_failure",
                    "timestamp": now_iso(),
                    "env": env,
                    "reason": "invalid_token",
                },
                audit_path,
            )
            st.sidebar.error("Invalid token.")
    st.stop()
    return ""  # Satisfy type hint although st.stop() halts execution


def main() -> None:
    st.set_page_config(page_title="Cognitive Suite Analysis", layout="wide")
    st.title("📊 Cognitive Suite – Resultados del Análisis")
    base = Path(os.getenv("COGNITIVE_OUTPUTS", "outputs"))
    env = normalize_env(os.getenv("COGNITIVE_ENV", "dev"))
    tokens = load_auth_tokens()
    flag = os.getenv("COGNITIVE_UI_AUTH_REQUIRED", "").strip().lower() in {"1", "true", "yes"}
    auth_required = env == "prod" or flag or bool(tokens)
    audit_path = resolve_audit_path(base)
    hash_salt = os.getenv("COGNITIVE_HASH_SALT", "")
    role = ensure_auth(auth_required, tokens, audit_path, env)
    if role not in ROLE_PERMS:
        role = "viewer"
    perms = ROLE_PERMS[role]
    actor = st.session_state.get("auth_user", "unknown")

    # Inyectar CSS Dinámico (Glassmorphism)
    style_path = Path(__file__).resolve().parent / "style.css"
    if style_path.exists():
        st.markdown(f"<style>{style_path.read_text(encoding='utf-8')}</style>", unsafe_allow_html=True)

    # Motor de Gamificación
    engine = GamificationEngine() if GamificationEngine else None
    user_data = None
    if engine:
        # Por ahora cargamos octocat como demo/admin
        user_name = "octocat"
        user_data = engine.get_user_ledger(user_name)

    # --- SIDEBAR: Profile Card ---
    if user_data:
        st.sidebar.markdown(f"""
        <div class="glass-card profile-card">
            <div class="badge-label">Avatar</div>
            <div class="profile-avatar">{user_data.get('user', 'U')[0].upper()}</div>
            <div class="badge-label">Rango Actual</div>
            <div class="level-badge">{user_data.get('level', 'L0')}</div>
            <div class="badge-label">Usuario Corresponsal</div>
            <h3 style="margin:0;">{user_data.get('user', 'User')}</h3>
            <p style="color:#94a3b8; font-size:12px;">{user_data.get('xp_total', 0)} XP Acumulados</p>
        </div>
        """, unsafe_allow_html=True)

    st.sidebar.markdown(f"**Role:** {role}")
    if auth_required and st.sidebar.button("Sign out"):
        write_audit_event(
            {
                "event": "ui_logout",
                "timestamp": now_iso(),
                "env": env,
                "role": role,
                "actor": actor,
            },
            audit_path,
        )
        st.session_state.pop("auth_role", None)
        st.session_state.pop("auth_user", None)
        st.session_state.pop("access_logged", None)
        st.experimental_rerun()

    analysis_path = base / "insights" / "analysis.json"
    data = load_data(analysis_path)
    if not data:
        msg = (
            f"No se encontró el archivo de análisis en: {analysis_path}."
            "\n\nEjecuta primero el pipeline o monta outputs en Docker y define COGNITIVE_OUTPUTS."
        )
        st.warning(msg)
        return
    if not st.session_state.get("access_logged"):
        write_audit_event(
            {
                "event": "ui_access",
                "timestamp": now_iso(),
                "env": env,
                "role": role,
                "actor": actor,
                "record_count": len(data),
            },
            audit_path,
        )
        st.session_state["access_logged"] = True

    # --- TABS PRINCIPALES ---
    tab_analysis, tab_labs = st.tabs(["📝 Análisis Semántico", "🛡️ Gamification Hub"])

    with tab_analysis:
        # Convertir a DataFrame para representación tabular
        df = pd.DataFrame([
            {
                "uuid": rec.get("uuid"),
                "archivo": Path(rec.get("file", "")).name if perms["view_file"] else f"file_{hash_identifier(str(rec.get('uuid', '')), hash_salt)}",
                "tipo": rec.get("content_type"),
                "palabras": rec.get("word_count"),
                "etiquetas": ", ".join(rec.get("intent_tags", [])),
                "sentimiento": rec.get("sentiment", {}).get("label"),
                "relevancia": rec.get("relevance_score"),
            }
            for rec in data
        ])
        # Filtro por etiquetas
        all_tags = sorted({tag for rec in data for tag in rec.get("intent_tags", [])})
        selected_tags = st.multiselect("Filtra por etiquetas cognitivas", options=all_tags, default=all_tags)
        if selected_tags and len(selected_tags) < len(all_tags):
            mask = df["etiquetas"].apply(lambda x: any(tag in x for tag in selected_tags))
            df_display = df[mask]
        else:
            df_display = df
        st.dataframe(df_display, use_container_width=True)
        if not perms["view_details"]:
            st.info("Your role does not allow access to record details.")
        else:
            # Seleccionar un registro para detalles
            st.subheader("Detalles del registro")
            selected_uuid = st.selectbox(
                "Seleccione un UUID para ver detalles", options=["(Seleccione)"] + list(df_display["uuid"])
            )
            if selected_uuid and selected_uuid != "(Seleccione)":
                rec = next((r for r in data if r.get("uuid") == selected_uuid), None)
                if rec:
                    write_audit_event(
                        {
                            "event": "ui_record_view",
                            "timestamp": now_iso(),
                            "env": env,
                            "role": role,
                            "actor": actor,
                            "record_id": hash_identifier(str(rec.get("uuid", "")), hash_salt),
                            "redacted": bool(rec.get("redacted")),
                        },
                        audit_path,
                    )
                    st.write(f"### {rec.get('title')}")
                    if perms["view_file"]:
                        st.write(f"**Archivo:** {rec.get('file')}")
                    else:
                        st.write("**Archivo:** restricted")
                    st.write(f"**Tipo de contenido:** {rec.get('content_type')}")
                    st.write(f"**Etiquetas:** {', '.join(rec.get('intent_tags', []))}")
                    st.write(f"**Sentimiento:** {rec.get('sentiment', {}).get('label')} (score: {rec.get('sentiment', {}).get('score')})")
                    st.write(f"**Resumen:** {rec.get('summary')}")
                    if perms["view_entities"] and rec.get('entities'):
                        st.write("**Entidades:**")
                        ent_df = pd.DataFrame(rec['entities'], columns=["Tipo", "Texto"])
                        st.table(ent_df)
                    if perms["view_entities"] and rec.get('author_signature'):
                        st.write(f"**Firma de autor:** {rec.get('author_signature')}")
                    st.write(f"**Puntuación de relevancia:** {rec.get('relevance_score')}")

    with tab_labs:
        st.header("🎯 Misiones y Oráculos")
        st.markdown("Bienvenido al **Command Center** de Atlantyqa. Aquí puedes validar tus pruebas de trabajo.")

        if engine:
            col1, col2, col3 = st.columns(3)
            labs = [
                {"id": "lab_01", "name": "Lab 01: Deep Dive", "xp": "10 XP", "icon": "🤿"},
                {"id": "lab_02", "name": "Lab 02: GitOps", "xp": "100 XP", "icon": "🔐"},
                {"id": "lab_03", "name": "Lab 03: Dashboard", "xp": "75 XP", "icon": "🎨"},
            ]

            for i, lab in enumerate(labs):
                with [col1, col2, col3][i]:
                    st.markdown(f"""
                    <div class="glass-card mission-card">
                        <h3>{lab['icon']} {lab['id'].upper()}</h3>
                        <p>{lab['name']}</p>
                        <p class="xp-label">Reward: {lab['xp']}</p>
                    </div>
                    """, unsafe_allow_html=True)

                    if st.button(f"Verificar {lab['id'].upper()}", key=f"btn_{lab['id']}"):
                        with st.spinner(f"El Oráculo está verificando {lab['id']}..."):
                            success, msg = engine.verify_lab(lab['id'])
                            if success:
                                st.success(msg)
                                st.balloons()
                            else:
                                st.error(msg)
        else:
            st.error("Error: Gamification Engine no disponible.")

if __name__ == "__main__":
    main()
