### CONCEPTS -------------------------------------------------------------------

concepts <- list(
  pre = list(infiltr = "infilt"),
  post = list(
    scap = "epaul|scap|clavic|acrom",
    cortico = "corti(s|c)"
  ),
  dr = list(
    np = "amouyel.+thomas",
    pn = "(dr|docteur|thomas).+amouyel"
  )
)

### EXTRACT --------------------------------------------------------------------

edstr_config(
  edstr_dirname = "collect/data/{.split}",
  edstr_filename = "{.split}_{id}",
  edstr_text = .col$text
)

df_import <- edstr_import(load = TRUE)

df_clean <- edstr_clean(
  data = df_import,
  replace = src_config("clean"),
)

df_clean_filter <-
df_clean |>
  filter(
    if_any(starts_with("cim10"), ~ !is.na(.)),
    if_any(starts_with("ccam"), ~ !is.na(.))
  )

df_extract <- edstr_extract(
  data = df_clean_filter,
  token = 1:3,
  concepts = concepts,
  # intersect = TRUE,
  group = "id_pat"
)

# df_view <- edstr_view(
#   data = df_clean,
#   id = "id_doc",
#   pattern = "(?i)infiltration",
#   ngrams = 5
# )
