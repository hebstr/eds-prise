### DB CONNECT -----------------------------------------------------------------

conn <- connect_db(user = "sas_eds")

dbSendQuery(conn$db$oracle, "ALTER SESSION SET nls_date_format = 'YYYY-MM-DD'")

db <- set_names(names(conn$db)) |> map("")

### EXTRACT DB DUCKDB ----------------------------------------------------------

db$duckdb$code <-
conn$tbl$duckdb("code") |>
  select(ID_PAT, CODE, TEXTE) |>
  pivot_wider(
    names_from = CODE,
    names_prefix = "CIM_",
    values_from = TEXTE
  )

db$duckdb$sej <-
conn$tbl$duckdb("sej")# |>
  #mutate(SEJ_REF = ifelse(IEP %in% !!pull(conn$tbl$duckdb("ref"), IEP), "1", "0"))

conn$tbl$duckdb("doc") |>
  left_join(y = conn$tbl$duckdb("pat"), by = "ID_PAT") |>
  left_join(y = db$duckdb$sej, by = "ID_SEJ") |>
  mutate(AGE_PAT = trunc((DATE_ENTREE - DATENAIS) / 365.25)) |>
  filter(AGE_PAT >= inclusion$pat$age) |>
  inner_join(db$duckdb$code, by = "ID_PAT") |>
  copy_to_db(
    dest = "oracle",
    name = str_glue("ETUDE_{toupper(id)}_DOC")
  )

conn$tbl$oracle(str_glue("ETUDE_{toupper(id)}_DOC")) |>
  left_join(
    conn$tbl$oracle("EDBM_EDS.EHOP_ENTREPOT") |> select(ID_ENTREPOT, TEXTE_AFFICHAGE)
  ) |>
  rename_with(tolower) |>
  select(
    id_doc = id_entrepot,
    id_sej,
    id_pat,
    id_iep = iep,
    id_ipp = ipp,
    pat_date_nais = datenais,
    pat_age = age_pat,
    pat_sexe = sexe,
    pat_cp = cp,
    pat_ville = ville,
    sej_date_entree = date_entree,
    sej_date_sortie = date_sortie,
    # sej_ref,
    doc_date_signature = datesignature,
    doc_uf_code = uf,
    doc_uf_libelle = libelle_uf,
    doc_type = type_doc,
    doc_titre = titre,
    doc_texte = texte_affichage,
    starts_with("cim")
  ) |>
  mutate(across(starts_with("id_"), as.character)) |>
  arrange(id_pat, sej_date_entree) |>
  copy_to_duckdb("doc_texte")

db$duckdb$doc <- conn$tbl$duckdb("doc_texte")

df <-
db$duckdb$doc |>
  collect() |>
  mutate(sej_m = str_remove(sej_date_entree, "-\\d{2}$")) |>
  split(~ sej_m) |>
  map(~ select(., -sej_m))

walk(str_glue("collect/data/{names(df)}"), fs::dir_create)

iwalk(df, ~ saveRDS(.x, file = str_glue("collect/data/{.y}/{.y}_{id}_import.rds")))

### DB DISCONNECT --------------------------------------------------------------

walk(conn$db, dbDisconnect)
