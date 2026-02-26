df_note_man_input <-
collect_data_extract()$auto |>
  select(-extract, -.col$text) |>
  left_join(
    y = collect_data_extract()$man[c(.col$id, "extract", .col$text)],
    by = .col$id
  ) |>
  rename(n_init = n) |>
  rownames_to_column(var = "n")

write_delim(
  x = df_note_man_input,
  delim = "|",
  file = note_input_path(dir = "man", "input_dr")
)
