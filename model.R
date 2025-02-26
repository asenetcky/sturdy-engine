# Model

## Grab data

data <-
  nanoparquet::read_parquet("data/payroll-2023-2025-gzip.parquet") |>
  dplyr::mutate(id = dplyr::row_number()) |>
  dplyr::select(
    id,
    calendar_year,
    deptid,
    job_title = job_cd_descr,
    annual_rate
  ) |>
  dplyr::filter(
    dplyr::if_all(
      dplyr::everything(),
      \(x) !is.na(x)
    )
  )

# highly recommend duckdb for big datasets

# con <- DBI::dbConnect(
#   duckdb::duckdb(),
#   dbdir = "my-db.duckdb"
# )
#
#
# DBI::dbWriteTable(con, "payroll", data)
#
# df <-
#   dplyr::tbl(con, "payroll")
#

# prop not supported - so grab a number


## Define Model and Fit
set.seed(20250226)

data <-
  data |>
  dplyr::mutate(
    annual_rate = as.numeric(annual_rate),
    calendar_year = as.factor(calendar_year),
    deptid = as.factor(deptid),
    job_title = as.factor(job_title)
  )

small_data <-
  data |>
  dplyr::slice_sample(prop = 0.005)


training <-
  small_data |>
  dplyr::slice_sample(prop = 0.8)

predictions <-
  small_data |>
  dplyr::anti_join(training, by = "id")


model <- lm(annual_rate ~ calendar_year + deptid + job_title, training)
summary(model)


## Prep Vetiver
prototype <-
  data |>
  head(1) |>
  dplyr::select(calendar_year, deptid, job_title)

v_model <-
  vetiver::vetiver_model(
    model,
    model_name = "payroll_model",
    save_prototype = prototype
  )

## Save model into `pins` board

### create board
model_board <-
  pins::board_folder(
    path = fs::path_wd("data/models/"),
    versioned = TRUE
  )

### save model locally
vetiver::vetiver_pin_write(
  vetiver_model = v_model,
  board = model_board,
  check_renv = TRUE
)

## Serve model from pin

pin_board <- board_folder(fs::path_wd("data/models/"))

v_model_from_pin <- vetiver_pin_read(
  board = pin_board,
  name = "penguin_model"
)



## db setup

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "my-db.duckdb")
DBI::dbWriteTable(con, "penguins", palmerpenguins::penguins)
DBI::dbDisconnect(con)




## deploy the model

pr() |>
  vetiver_api(v_model_from_pin) |>
  pr_run(port = 8080)
## model endpoint

endpoint <- vetiver_endpoint("http://127.0.0.1:8080/predict")
endpoint

## predictions

new_penguins <-
  df |>
  slice_sample(n = 20) |>
  select(bill_length_mm, species, sex)

predict(endpoint, new_penguins)
