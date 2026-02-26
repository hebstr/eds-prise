import streamlit as st
from lib.password import verify_credentials
from lib.export import wb_export

def download(
    secrets,
    export_data,
    export_filename,
    dialog_title,
    button_label,
    button_icon,
    button_type
):

    @st.dialog(title = dialog_title, width = "medium")

    def download_dialog():

        username = st.text_input("Identifiant")

        password = st.text_input("Mot de passe", type = "password")

        data = wb_export(df = export_data, sheet_name = export_filename)

        mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

        if password and verify_credentials(secrets, username, password):

            st.markdown("""
            ## IMPORTANT
            texte à ajouter
            """)

            st.space("stretch")

            st.download_button(
                label = button_label,
                type = "primary",
                use_container_width = True,
                data = data,
                file_name = f"{export_filename}.xlsx",
                mime = mime,
                icon = button_icon,
            )

        elif password:
            st.error("Identifiant ou mot de passe incorrect")

    click_download = st.button(
        label = button_label,
        type = button_type,
        use_container_width = True,
        icon = button_icon
    )

    if click_download:
        download_dialog()
