### CONCEPTS -------------------------------------------------------------------

concepts <- list(
  clin = list(
    patho = "ruptur|tendinopat|bursite|capsulite",
    sympt = "douleur|scapulalg"
  ),
  acte = list(
    inflt = "infiltrati|echo.*guid|sous.+echo|deriv.+corti[cs]",
    chir = "reparation|tenotom|resect"
  ),
  loc = list(
    scap = "epaul|scapulair|sub.*scapul|supra.*scapul",
    coiffe = "coif|rotateur",
    acro = "acrom(.+(clav|delt))?|sous.*acrom(.+(clav|delt))?",
    epin = "supra.*epin|infra.*epin"
  )
)

### EXTRACT --------------------------------------------------------------------

edstr_config(
  edstr_dirname = "collect/data/{.split}",
  edstr_filename = "{.split}_{id}",
  edstr_text = .col$text
)

df_import <- edstr_import()

df_clean <- edstr_clean(
  data = df_import,
  replace = src_config("clean"),
)

# df_clean_filter <-
#   df_clean |>
#   filter(
#     if_any(starts_with("cim10"), ~ !is.na(.)),
#     if_any(starts_with("ccam"), ~ !is.na(.))
#   )

df_extract <- edstr_extract(
  data = df_clean,
  token = 1:3,
  concepts = concepts,
  intersect = TRUE,
  group = "id_pat"
)

df_extract$data$extract |>
  count(doc_uf_code, doc_uf_libelle, doc_titre, sort = TRUE)

# df_view <- edstr_view(
#   data = df_clean,
#   id = "id_doc",
#   pattern = "(?i)infiltration",
#   ngrams = 5
# )
