### DB CONNECT -----------------------------------------------------------------

conn <- connect_db(user = "sas_eds")

dbSendQuery(conn$db$oracle, "ALTER SESSION SET nls_date_format = 'YYYY-MM-DD'")

db <- set_names(names(conn$db)) |> map("")

### TBL REF --------------------------------------------------------------------

# db$oracle$ref <-
# readxl::read_excel(str_glue("note/man/data/{id}_man_truth.xlsx")) |>
#   transmute(IEP = as.character(IEP)) |>
#   distinct() |>
#   drop_na()

### TBL PAT --------------------------------------------------------------------

db$oracle$pat <-
conn$tbl$oracle("EDBM_ZPAT.EHOP_PATIENT_MAPPING") |>
  left_join(y = conn$tbl$oracle("EDBM_ZPAT.EHOP_PATIENT"), by = "ID_PAT") |>
  left_join(y = conn$tbl$oracle("NOYAU_EDS.PATIENTS_OPPOSITION"), by = "IPP") |>
  filter(
    RETRAIT == 0,
    is.na(DATE_OPPOSITION)
  ) |>
  select(
    ID_PAT,
    IPP,
    NOM,
    PRENOM,
    DATENAIS,
    SEXE,
    CP,
    VILLE
  )

### TBL SEJ --------------------------------------------------------------------

db$oracle$sej <-
conn$tbl$oracle("EDBM_EDS.EHOP_SEJOUR") |>
  left_join(y = conn$tbl$oracle("EDBM_ZPAT.EHOP_SEJOUR_MAPPING"), by = "ID_SEJ") |>
  filter(DATE_ENTREE |> between(!!!inclusion$sej$date)) |>
  select(
    ID_SEJ,
    IEP,
    DATE_ENTREE,
    DATE_SORTIE
  )

### TBL DOC --------------------------------------------------------------------

db$oracle$doc <-
conn$tbl$oracle("EDBM_EDS.EHOP_ENTREPOT") |>
  filter(DATESIGNATURE |> between(!!!inclusion$doc$date)) |>
  mutate(EXERCICE = year(DATESIGNATURE)) |>
  left_join(
    y = conn$tbl$oracle("SAS_EDS.STRUCTURE_CHU_HISTORIQUE_2025"),
    by = join_by(EXERCICE, UF == CODE_UF)
  ) |>
  filter(!(TYPE_DOC %in% exclusion$doc$type | TITRE %in% exclusion$doc$titre)) |>
  select(
    ID_ENTREPOT,
    ID_SEJ,
    ID_PAT,
    AGE_PAT,
    DATESIGNATURE,
    UF,
    LIBELLE_UF,
    TYPE_DOC,
    TITRE
  )

### TBL CIM10 ------------------------------------------------------------------

db$oracle$code <-
conn$tbl$oracle("EDBM_EDS.EHOP_ENTREPOT_STRUCTURE") |>
  select(ID_ENTREPOT, ID_PAT, ID_SEJ, CODE_THESAURUS, CODE, DATE_DATA, TEXTE) |>
  mutate(CODE = replace(CODE, "\\s+.+", "")) |>
  filter(
    CODE_THESAURUS == "cim10",
    sql(str_glue("REGEXP_LIKE(CODE, '{.cim10}')"))
  )

### COPY DB DUCKDB -------------------------------------------------------------

# iwalk(db$oracle, copy_to_duckdb)

### DB DISCONNECT --------------------------------------------------------------

walk(conn$db, dbDisconnect)
