# setup renv the first time
# renv::init()
# renv::activate(profile = "<PROFILE_NAME>")

# using pak because it plays better with Pop!_OS for me
options(renv.config.pak.enabled = TRUE)

# purrr first then walk the rest
renv::install("purrr")

c(
  "dplyr",
  "ggplot2",
  "tidyr",
  "vetiver",
  "plumber",
  "RSocrata",
  "duckdb",
  "nanoparquet",
  "httr2",
  "devtools",
  "styler",
  "DBI",
  "odbc",
  "dbplyr",
  "fs"
) |>
  purrr::walk(
    \(pkg) renv::install(pkg, prompt = FALSE)
  )

renv::snapshot()
