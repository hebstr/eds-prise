df_note_man_input <- collect_data_extract()$auto |>
  select(-extract, -.col$text) |>
  left_join(
    y = collect_data_extract()$man[c(.col$id, "extract", .col$text)],
    by = .col$id
  ) |>
  mutate(n = row_number())

write_parquet(
  x = df_note_man_input,
  file = note_input_path(dir = "man", "input_dr")
)
