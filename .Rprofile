### SETUP INIT -----------------------------------------------------------------

source("rv/scripts/rvr.R")
source("rv/scripts/activate.R")
source("~/.Rprofile")
readRenviron(".env")

library(tidyverse)
library(edstr)
library(DBI)
library(openxlsx2)
library(nanoparquet)

# conflicted::conflicts_prefer(dplyr::filter(), .quiet = TRUE)

id <- Sys.getenv("ID")

.split <- str_to_kebab(Sys.getenv("SPLIT"))

.cim10 <- "M1901|M25(3|5)1|M75|S46"

.ccam_list <- list(
  infiltr_ms = "MZLB001|MZLH002|MZLH001|ZZLJ002",
  chir_epaule = list(
    coiffe_rot = "MJEC001|MJEC002|MJEA010|MJEA006|MJMA003",
    acromioplastie = "MEMC003|MEMA006|MEMC005",
    arthroplasties_scapulohum = "MEKA0(0[5-9]|10)",
    reprise_chir = "MEKA002|MEMA015",
    explo_artho = "MEQC002"
  ),
  ponction = "MZJB001"
)

.ccam <-
  .ccam_list |>
  list_flatten() |>
  list_c() |>
  paste(collapse = "|")

.col <- lst(
  id = Sys.getenv("COL_ID"),
  group = Sys.getenv("COL_GROUP"),
  text = Sys.getenv("COL_TEXT"),
  estimate_id = Sys.getenv("COL_ESTIMATE_ID"),
  estimate_group = Sys.getenv("COL_ESTIMATE_GROUP"),
  truth = Sys.getenv("COL_TRUTH")
)

.estimate <- lst(
  "{Sys.getenv('ESTIMATE_LABEL')}" := c(
    true = Sys.getenv("ESTIMATE_TRUE"),
    false = Sys.getenv("ESTIMATE_FALSE")
  )
)

src_config <- \(x) source(str_glue("config/{x}.R"))$value

### QUERY ----------------------------------------------------------------------

connect_db <- \(
  user = "edbm",
  name_duckdb = str_glue("collect/data/{id}_query.duckdb")
) {
  lst(
    db = lst(
      oracle = edsConnect(user = user),
      duckdb = dbConnect(drv = duckdb::duckdb(), dbdir = name_duckdb),
    ),
    tbl = map(db, ~ \(x) tbl(., I(x)))
  )
}

copy_to_db <- \(df, dest, name, ...) {
  copy_to(
    df = df,
    dest = conn$db[[dest]],
    name = name,
    overwrite = TRUE,
    temporary = FALSE,
    analyze = FALSE,
    ...
  )
}

copy_to_duckdb <- \(.x, .y) {
  cli::cli_progress_step(.y)

  copy_to_db(df = .x, name = .y, dest = "duckdb")

  cli::cli_progress_done()
}

name_duckdb <- str_glue("collect/data/{id}_query.duckdb")

name_tbl <- \(x) toupper(str_glue("etude_{str_to_snake(id)}_{x}"))

check_all_ref <- \(df1, df2) {
  sum_ref <- \(x) {
    data <- distinct(x, id_sej, sej_ref)

    sum(data$sej_ref == 1)
  }

  identical(sum_ref(df1), sum_ref(df2))
}

### NOTE AUTO ------------------------------------------------------------------

auto_output_ls <- \(
  dir = str_glue("note/auto/data/{.split}"),
  format = "csv",
  subset = "",
  negate = FALSE
) {
  output_glob <- str_glue("*output*.{format}")
  output_extract <- str_glue("(?<=output_).+(?=\\.{format})")

  output_ls <-
    fs::dir_ls(path = dir, glob = output_glob) |>
    as.character() |>
    set_names(str_extract, output_extract)

  if (nzchar(subset)) str_subset(output_ls, subset, negate) else output_ls
}

auto_output_read <- \(data, text = "doc_texte", fmt_json = TRUE) {
  .fun <- \(x) {
    data_read <-
      easy_read_csv(x) |>
      select(-all_of(text)) |>
      mutate(ntoken_out = round((nchar(llm) / 3.5), 1))

    if (fmt_json) {
      data_read$llm <-
        str_replace_all(data_read$llm, c("^\\{" = "[{", "\\}$" = "}]")) |>
        map(fromJSON)
    }

    return(data_read)
  }

  map(data, .fun)
}

auto_output_data <- \(
  data_extract,
  data_auto_output,
  text = "doc_texte",
  id,
  group,
  truth,
  estimate = .estimate,
  estimate_id,
  estimate_group
) {
  estimate_name <- names(estimate)
  false <- list_c(estimate)[["false"]]

  str_sep <- \(x) str_flatten(unlist(x), "<br>")
  str_factor <- \(x) factor(x, levels = c(1, 0))

  data_extract |>
    select(-all_of(text)) |>
    right_join(data_auto_output, by = id) |>
    unnest(cols = llm) |>
    mutate(
      "{estimate_id}" := ifelse(.data[[estimate_name]] == false, 0, 1),
      "{estimate_group}" := ifelse(sum(.data[[estimate_id]]) == 0, 0, 1),
      across(where(is.list), ~ map_chr(., str_sep)),
      across(c(truth, estimate_id, estimate_group), str_factor),
      .by = {{ group }},
    ) |>
    relocate(-all_of(truth))
}

auto_config_ntoken <- \(data, max = 8000) {
  .outliers <-
    data |>
    select(
      n,
      .col$id,
      .col$estimate_id,
      .col$estimate_group,
      .col$truth,
      ntoken,
      ntoken_out
    ) |>
    filter(ntoken > max)

  lst(
    max = max,
    summary = lst(
      input = summary(data$ntoken),
      output = summary(data$ntoken_out)
    ),
    outliers = if (nrow(.outliers) == 0) NULL else .outliers
  )
}

auto_config_confmat <- \(
  data,
  id,
  group,
  truth,
  estimate = names(.estimate),
  estimate_id,
  estimate_group,
  metrics = "^(k|sp|pr|r|f|acc)"
) {
  z <- enexprs(
    id = id,
    group = group,
    truth = truth,
    estimate_id = estimate_id,
    estimate_group = estimate_group
  )

  distinct_by <- \(id_col, ...) distinct(data, {{ id_col }}, ..., !!z$truth)

  data_id <- distinct_by(
    !!z$id,
    .data[[estimate]],
    !!z$estimate_id,
    !!z$estimate_group
  )
  data_group <- distinct_by(!!z$group, !!z$estimate_group)

  .table <- yardstick::conf_mat(
    data = data_group,
    truth = !!z$truth,
    estimate = !!z$estimate_group
  )

  .metrics <- filter(summary(.table), str_detect(.metric, metrics))

  data_mismatch <- \(x) {
    lst(
      fn = filter(x, !!z$truth == 1 & !!z$estimate_group == 0),
      fp = filter(x, !!z$truth == 0 & !!z$estimate_group == 1)
    )
  }

  .mismatch <- lst(
    id = data_mismatch(data_id),
    group = data_mismatch(data_group)
  )

  lst(
    table = .table$table,
    metrics = .metrics,
    mismatch = .mismatch
  )
}

sep_prompt_model <- \(data, col, names = c("prompt", "model")) {
  separate_wider_delim(
    data = data,
    cols = {{ col }},
    delim = "_",
    names = names
  )
}

auto_summary_pred <- \(data, estimate = .estimate) {
  var <- names(.estimate)

  values <- str_glue("\\b{unlist(.estimate)}\\b")

  df <-
    data |>
    imap(~ pluck(.x, "pred") |> mutate(config = .y)) |>
    bind_rows()

  values_data <- str_subset(unique(df[[var]]), paste(values, collapse = "|"))

  df |>
    pivot_wider(names_from = all_of(var), values_from = n) |>
    mutate(
      total_correct = rowSums(across(all_of(values_data)), na.rm = TRUE),
      total_doc = rowSums(across(where(is.integer)), na.rm = TRUE),
    ) |>
    sep_prompt_model(col = config)
}

auto_summary_table <- \(data, names_prefix = "confmat") {
  .names <- paste0(names_prefix, "_", c("vp", "fn", "fp", "vn"))

  data |>
    imap(
      ~ pluck(.x, "table") |>
        as_tibble() |>
        mutate(confmat = .names, config = .y)
    ) |>
    bind_rows() |>
    select(config, confmat, n) |>
    pivot_wider(names_from = "confmat", values_from = "n") |>
    mutate("{names_prefix}_total" := rowSums(across(where(is.numeric))))
}

auto_summary_metrics <- \(data, names = "metric_{.metric}") {
  data |>
    imap(
      ~ pluck(.x, "metrics") |>
        mutate(.metric = str_glue(names), config = .y)
    ) |>
    bind_rows() |>
    select(-.estimator) |>
    pivot_wider(names_from = .metric, values_from = .estimate)
}

auto_summary <- \(data, name = "confmat") {
  data <- map(data, pluck, name)
  table <- auto_summary_table(data)
  metrics <- auto_summary_metrics(data)

  lst(table, metrics) |>
    reduce(inner_join, by = "config") |>
    sep_prompt_model(col = config)
}

### XLSX -----------------------------------------------------------------------

.xlsx_fun <- \(
  x,
  sheet,
  data,
  max_width = 60,
  halign = "center",
  font_size = 8,
  header_color = "#E5E5E5",
  border_color = "#999999",
  border_type = "thin",
  color = NULL
) {
  options(openxlsx2.maxWidth = max_width)

  params <- list(
    dims = list(
      full = wb_dims(x = data),
      data = wb_dims(x = data, select = "data"),
      cols = wb_dims(x = data, select = "col_names")
    ),
    colors = list(
      border = wb_color(border_color),
      header = wb_color(header_color)
    )
  )

  add_color <- \(wb, vars, color) {
    wb_add_font(
      wb = wb,
      dims = wb_dims(x = data, cols = vars, select = "data"),
      color = wb_color(color),
      size = font_size,
      bold = TRUE
    )
  }

  output <- wb_add_worksheet(
    wb = x,
    sheet = sheet,
    zoom = 105
  ) |>
    wb_add_data_table(
      x = data,
      na.strings = NULL
    ) |>
    wb_add_font(
      dims = params$dims$cols,
      size = font_size + 1,
      bold = TRUE
    ) |>
    wb_add_font(
      dims = params$dims$data,
      size = font_size
    ) |>
    wb_add_fill(
      dims = params$dims$cols,
      color = params$colors$header
    ) |>
    wb_set_col_widths(
      cols = seq_len(ncol(data)),
      widths = "auto"
    ) |>
    wb_add_cell_style(
      dims = params$dims$full,
      horizontal = halign,
      vertical = "center",
      wrap_text = TRUE
    ) |>
    wb_add_border(
      dims = params$dims$full,
      top_color = params$colors$border,
      top_border = border_type,
      bottom_color = params$colors$border,
      bottom_border = border_type,
      left_color = params$colors$border,
      left_border = border_type,
      right_color = params$colors$border,
      right_border = border_type,
      inner_hcolor = params$colors$border,
      inner_hgrid = border_type,
      inner_vcolor = params$colors$border,
      inner_vgrid = border_type
    ) |>
    reduce2(
      .x = color,
      .y = names(color),
      .f = add_color,
      .init = _
    )

  return(output)
}

get_xlsx <- \(x, ...) {
  reduce2(
    .x = x,
    .y = names(x),
    .f = \(wb, data, name) {
      .xlsx_fun(
        x = wb,
        sheet = name,
        data = data,
        ...
      )
    },
    .init = wb_workbook()
  )
}

### SAFE PATH ------------------------------------------------------------------

check_safe_path <- \(file) {
  cli::cli_text("\n\n")
  cli::cli_alert_warning("Le fichier {.strong {file}} existe déja. Continuer ?")

  check <- menu(c("Oui", "Non"))

  if (check == 1) file else invisible(NULL)
}

safe_path <- \(
  root,
  dir,
  split = .split,
  subdir = "",
  suffix = "",
  ext,
  read = FALSE
) {
  dirname <- fs::path(root, dir, split)

  filename <- if (nzchar(subdir)) {
    fs::path(subdir, str_glue("{split}_{id}_{str_to_snake(subdir)}"))
  } else {
    str_glue("{split}_{id}_{root}_{str_to_snake(dir)}")
  }

  if (nzchar(suffix)) {
    filename <- str_glue("{filename}_{suffix}")
  }

  path <- fs::path(dirname, filename, ext = ext)

  if (!read && fs::file_exists(path)) check_safe_path(path) else path
}

collect_data_extract <- \(subdir = "extract") {
  path <- safe_path(
    root = "collect",
    dir = "data",
    subdir = subdir,
    ext = "rds",
    read = TRUE
  )

  if (!fs::file_exists(path)) {
    cli::cli_abort("Le chemin {.path {path}} n'existe pas")
  }

  data <- readRDS(path)$data

  lst(
    auto = data$extract,
    man = select(data$csv, .col$id, "extract", .col$text)
  )
}

note_data_path <- \(...) safe_path(root = "note", dir = "data", ...)

note_input_path <- \(dir, suffix = "input", ext = "parquet", ...) {
  safe_path(
    root = "note",
    dir = str_glue("{dir}/data"),
    suffix = suffix,
    ext = ext,
    ...
  )
}

### MKDIR ----------------------------------------------------------------------

c(
  fs::path("collect", "data", .split),
  fs::path("note", c("data", "auto/data", "man/data"), .split)
) |>
  walk(fs::dir_create)

### SOURCE ---------------------------------------------------------------------

auto_exec <- \(dir = "config", prefix = "_") {
  fs::dir_ls(path = dir) |>
    str_subset(str_glue("^[^{prefix}]")) |>
    walk(source)
}

auto_exec()
