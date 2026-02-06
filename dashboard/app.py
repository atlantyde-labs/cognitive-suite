import glob
import json

import streamlit as st

st.set_page_config(page_title="ATLANTYDE Talent Dashboard", layout="wide")

users = []
for filepath in glob.glob("metrics/users/*.json"):
    with open(filepath, encoding="utf-8") as fh:
        try:
            users.append(json.load(fh))
        except json.JSONDecodeError:
            st.error(f"No se pudo parsear {filepath}")

if not users:
    st.warning("No se detectaron ledgers en metrics/users/." )
    st.stop()

users = sorted(users, key=lambda item: item.get("xp_total", 0), reverse=True)
user_names = [user.get("user") for user in users]
selected = st.selectbox("Selecciona usuario", user_names)

data = next(user for user in users if user.get("user") == selected)

st.header(f"Perfil de talento: {selected}")

c1, c2, c3 = st.columns(3)
c1.metric("XP Total", data.get("xp_total", 0))
c2.metric("XP Efectivo", data.get("xp_effective", data.get("xp_total", 0)))
c3.metric("XP Regulatorio", data.get("xp_regulatory", 0))

st.subheader("🎓 Labs")
st.write("Desbloqueados:", data.get("labs_unlocked", []))
st.write("Bloqueados:", data.get("labs_locked", []))

st.subheader("🏛️ Roles")
st.write(data.get("roles", []))

st.subheader("🏅 Badges")
st.json(data.get("badges", {}))
