import streamlit as st
import hmac
import toml
import os

state = st.session_state

def load_secrets(path_toml):

    secrets_path = path_toml

    if os.path.exists(secrets_path):

        with open(secrets_path) as f:
            secrets = toml.load(f)

        return secrets

    else:
        raise FileNotFoundError(f"Secrets file not found at {secrets_path}")

def verify_credentials(path_toml, username, password):

    secrets = load_secrets(path_toml)

    if username in secrets["users"]:
        return hmac.compare_digest(password, secrets["users"][username])

    return False

def check_password(path_toml):

    secrets = load_secrets(path_toml)

    def password_entered():

        username = state["username"]

        if username in secrets["users"]:

            correct_password = secrets["users"][username]

            if hmac.compare_digest(state["password"], correct_password):

                state["password_correct"] = True

                state["user"] = username

                del state["password"]

            else:
                state["password_correct"] = False
        else:
            state["password_correct"] = False

    if state.get("password_correct"):
        return True

    _, col, _ = st.columns([1, 3, 1])

    with col :

        st.markdown("### Connexion")

        st.text_input(
            label = "Identifiant",
            key = "username"
        )

        st.text_input(
            label = "Mot de passe",
            type = "password",
            on_change = password_entered,
            key = "password"
    )

    if "password_correct" in state and not state["password_correct"]:
        st.error("😕 Nom d'utilisateur ou mot de passe incorrect")

    return False
