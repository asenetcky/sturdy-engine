# query builder

# ct's open data portal
domain <- "https://data.ct.gov/"

# the e licensing table
resource <- "resource/9m78-yc88.json"

where_clause <- "?$where="


years <- c("2025", "2024", "2023")

calendar_clause <- "calendar_year="

full_statement <-
  glue::glue(
    "{domain}{resource}{where_clause}{calendar_clause}"
  )

datasets <-
  years |>
  purrr::map(
    \(year) {
      statement <-
        glue::glue(
          "{full_statement}{year}"
        )

      RSocrata::read.socrata(statement)
    }
  )

# data <-
#   RSocrata::read.socrata(glue::glue("{full_statement}2025"))


chonker <-
  datasets |>
  purrr::list_rbind()

nanoparquet::write_parquet(
  chonker,
  "data/payroll-2023-2025.parquet",
  compression = "gzip"
)
