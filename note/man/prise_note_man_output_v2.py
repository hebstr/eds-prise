import os
import pandas as pd
import streamlit as st
from streamlit.components.v1 import html
from dotenv import load_dotenv
from caseutil import to_kebab
from lib.password import check_password
from lib.navigation import navigation
from lib.download import download
from rich import pretty

pretty.install()
load_dotenv()

ID = os.getenv("ID")
SPLIT = to_kebab("2023-01")
TEXT = os.getenv("COL_TEXT")
WK_DIR = "note/man"
CONFIG_DIR = f"{WK_DIR}/.streamlit"
SECRETS = f"{CONFIG_DIR}/secrets.toml"
TUTO_TEXT = f"{CONFIG_DIR}/tuto.md"
TUTO_EMBED = f"{CONFIG_DIR}/tuto.webm"
INPUT = "input"
OUTPUT = "output"
EMPTY = ""

AUTH = False
DOWNLOAD = "hidden"
DATA_SUFFIX = ""

### DATA -----------------------------------------------------------------------

if AUTH:
    if not check_password(SECRETS):
        st.stop()
    USER = st.session_state["user"]
    USER_SUFFIX = f"_{USER}"
else:
    USER_SUFFIX = "_admin"

TITLE = f"{SPLIT}_{ID}{USER_SUFFIX}"

VAR_ESTIMATE_PREFIX = "note_estimate"
VAR_ESTIMATE = VAR_ESTIMATE_PREFIX + USER_SUFFIX
ESTIMATE_TRUE = ["actuel", "possible", "antécédent"]
ESTIMATE_FALSE = os.getenv("ESTIMATE_FALSE")

VAR_COMMENT = "note_comment" + USER_SUFFIX

VARS_NOTE = {
    VAR_ESTIMATE: dict(label="AVC", value=ESTIMATE_TRUE + [ESTIMATE_FALSE]),
    VAR_COMMENT: dict(label="COMMENTAIRE", value=EMPTY),
}

VARS_META = {
    "pat_sexe": "SEXE",
    "pat_age": "ÂGE",
    "pat_cp": "CP",
    "pat_ville": "VILLE",
    "sej_date_entree": "DATE ENTRÉE",
    "sej_date_sortie": "DATE SORTIE",
    "doc_uf_code": "UF CODE",
    "doc_uf_libelle": "UF LIBELLÉ",
    "doc_titre": "TITRE DOC",
}


def load_css(file):
    with open(f"{CONFIG_DIR}/{file}.css") as f:
        return f"<style>{f.read()}</style>"


def data_path(mode, ext="parquet"):
    return f"{WK_DIR}/data/{SPLIT}/{SPLIT}_{ID}_note_man_data_{mode}{DATA_SUFFIX}.{ext}"


data_man_input = data_path(INPUT)
data_man_output = data_path(OUTPUT)


@st.cache_data
def read_data():
    return pd.read_parquet(data_man_input)


df_input = read_data()


def create_output():
    return df_input.drop([TEXT], axis=1)


def check_note_values(data, var, value):
    cols = [col for col in data.columns if col.startswith(var)]
    return data[cols].isin(value).any(axis=None)


if os.path.exists(data_man_output):
    df_output = pd.read_parquet(data_man_output)

    any_estimate_value = check_note_values(
        data=df_output, var=VAR_ESTIMATE_PREFIX, value=VARS_NOTE[VAR_ESTIMATE]["value"]
    )

    if not any_estimate_value:
        df_output = create_output()

else:
    df_output = create_output()

for name in VARS_NOTE:
    if name not in df_output.columns:
        df_output.loc[:, name] = EMPTY

df_output.to_parquet(data_man_output)

### SESSION --------------------------------------------------------------------

st.set_page_config(
    page_title=TITLE, layout="wide", initial_sidebar_state="expanded", menu_items={}
)

st.markdown(body=load_css("style_app"), unsafe_allow_html=True)

state = st.session_state

max_index = df_output[df_output[VAR_ESTIMATE] != EMPTY].index.max()

if "doc_index" not in state:
    state.doc_index = 0 if pd.isna(max_index) else max_index

n_docs = len(df_output)

text_input = df_input[TEXT].iloc[state.doc_index]


def get_val(var):
    return df_output[var].iloc[state.doc_index]


for name in VARS_NOTE:
    state[name] = get_val(name)


def set_id_index(var):
    option = VARS_NOTE[var]["value"]
    return None if state[var] not in option else option.index(state[var])


def set_id_key(var):
    return f"key_{var}_{state.doc_index}"


def set_radio(var, **kwargs):
    state[var] = st.radio(
        label=VARS_NOTE[var]["label"],
        options=VARS_NOTE[var]["value"],
        index=set_id_index(var),
        key=set_id_key(var),
        **kwargs,
    )


def set_comment(var, **kwargs):
    state[var] = st.text_input(
        label=VARS_NOTE[var]["label"], value=state[var], key=set_id_key(var), **kwargs
    )


def st_col(**kwargs):
    return st.column_config.Column(**kwargs)


if "save_count" not in state:
    state.save_count = 0

### BODY -----------------------------------------------------------------------

st.dataframe(
    data=(
        df_output.loc[:, list(VARS_META)]
        .iloc[[state.doc_index]]
        .rename(columns=VARS_META)
    ),
    hide_index=True,
    column_config={
        VARS_META["doc_uf_libelle"]: st_col(width=300),
        VARS_META["doc_titre"]: st_col(width=200),
    },
)

col_text, col_df = st.columns([3, 1])

with col_text:
    html(html=load_css("style_text") + text_input, scrolling=True)


def set_type(var):
    all_values = df_output[var].isin(VARS_NOTE[var]["value"]).all()
    return "primary" if all_values else "secondary"


with col_df:
    df_note = df_output[["n"] + list(VARS_NOTE)]

    event = st.dataframe(
        data=df_note,
        on_select="rerun",
        selection_mode="single-row",
        column_config={
            "n": st_col(width=40),
            **{name: st_col(label=VARS_NOTE[name]["label"]) for name in VARS_NOTE},
        },
        key=f"df_{state.save_count}_{state.doc_index}",
    )

    if event.selection.rows:
        selected_row = event.selection.rows[0]
        new_doc_index = df_note.iloc[selected_row]["n"] - 1

        if state.doc_index != new_doc_index:
            state.doc_index = new_doc_index
            st.rerun()

### SIDEBAR > HEADER -----------------------------------------------------------

st.sidebar.space()

# with st.sidebar.container(key="button-tuto"):
#     click_on_tuto = st.button(
#         label="**COMMENT UTILISER L'APPLICATION**",
#         icon=":material/videocam:",
#         use_container_width=True,
#         disabled=not os.path.exists(TUTO_TEXT) and os.path.exists(TUTO_EMBED),
#     )

#     @st.dialog(title=" ", width="large")
#     def display_tuto():
#         with open(TUTO_TEXT) as f:
#             st.markdown(f.read())
#         with open(TUTO_EMBED, "rb") as f:
#             st.video(f)

#     if click_on_tuto:
#         display_tuto()

st.sidebar.space("stretch")

with st.sidebar.container(key="slider-doc"):
    n_value = get_val("n")

    slider_doc = st.slider(
        label=" ",
        label_visibility="collapsed",
        value=n_value,
        min_value=1,
        max_value=n_docs,
        key=f"slider_doc_{state.doc_index}",
    )

    if slider_doc != n_value:
        state.doc_index = slider_doc - 1
        st.rerun()

### SIDEBAR > BODY -------------------------------------------------------------

col_estimate, col_comment = st.sidebar.columns([1.1, 2.4])

with col_estimate:
    set_radio(VAR_ESTIMATE)

with col_comment:
    set_comment(VAR_COMMENT)

st.sidebar.space("stretch")

with st.sidebar.container(key="navigation"):
    navigation(
        columns=[0.5, 3.5, 0.5],
        path=data_man_output,
        nrow=n_docs,
        label="**ENREGISTRER ET PASSER AU SUIVANT**",
        vars_note=VARS_NOTE,
        value_note=state[VAR_ESTIMATE] not in [EMPTY, None],
    )

with st.sidebar.container(key="slider-note"):
    st.slider(
        label=" ",
        label_visibility="collapsed",
        value=df_output[VAR_ESTIMATE].ne(EMPTY).sum(),
        max_value=n_docs,
        key=f"slider_note_{state.save_count}",
    )

with st.sidebar.container(key=f"button-download-{DOWNLOAD}"):
    download(
        secrets=SECRETS,
        export_data=(
            df_output[["n"] + list(VARS_META) + list(VARS_NOTE)].query(
                f"{VAR_ESTIMATE} not in ['{ESTIMATE_FALSE}', '{EMPTY}']"
            )
        ),
        export_filename=TITLE,
        dialog_title=" ",
        button_label="**TÉLÉCHARGER LES DONNÉES ANNOTÉES**",
        button_icon=":material/download:",
        button_type=set_type(VAR_ESTIMATE),
    )

st.sidebar.space("stretch")

### SIDEBAR > FOOTER -----------------------------------------------------------

with st.sidebar.container(key="sidebar-footer"):
    hl_vars = dict(
        EXTRACTION="extract",
        # TRUTH = "sej_ref",
        # LLM_ESTIMATE = "avc",
        # LLM_CITATIONS = "citations",
        # LLM_RAISONNEMENT = "raisonnement"
    )

    for item, value in hl_vars.items():
        st.sidebar.html(
            load_css("style_text")
            + f"""
            <p class='sidebar-footer-title'>{item}</p>
            <p class='sidebar-footer-{value}'>{get_val(value)}</p>
            """
        )
