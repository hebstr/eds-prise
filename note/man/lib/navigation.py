import streamlit as st
import pandas as pd
import filelock as fl

def navigation(
    path,
    columns,
    nrow,
    vars_note,
    value_note,
    label,
    key_button_back = "button-backward",
    key_button_save = "button-save",
    key_button_forward = "button-forward"
):

### DEF ------------------------------------------------------------------------

    state = st.session_state

    def go_back():

        if state.doc_index > 0 :
            state.doc_index -= 1

    def go_forward():

        if state.doc_index < nrow - 1 :
            state.doc_index += 1

    def save():

        with fl.FileLock(f"{path}.lock"):

            fresh = pd.read_csv(path, keep_default_na = False)

            for name in vars_note :
                fresh.loc[state.doc_index, name] = state[name]

            fresh.to_csv(path, index = False)

        if state.doc_index < nrow - 1 :
            state.doc_index += 1

        state.save_count += 1

### DISPLAY --------------------------------------------------------------------

    col_backward, col_save, col_forward = st.columns(columns)

    with col_backward :
        st.button(
            label = "◀",
            use_container_width = True,
            on_click = go_back,
            key = key_button_back
        )

    with col_save :
        st.button(
            label = label,
            use_container_width = True,
            on_click = save,
            icon = ":material/save:",
            disabled = not value_note,
            key = key_button_save,
            type = "primary" if value_note else "secondary"
        )

    with col_forward :
        st.button(
            label = "▶",
            use_container_width = True,
            on_click = go_forward,
            key = key_button_forward
        )
