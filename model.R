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


# This model is nonsense and this isn't not even the best way
# to go about it nowawdays, but it's a simple example
model <- lm( annual_rate ~ calendar_year + deptid + job_title, training)
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

# create a pin board
pin_board <- pins::board_folder(fs::path_wd("data/models/"))

# this board is in the repo BUT it can be anywhere locally, onedrive
# an amazon s3 bucket or whatever




## Yes, I know the model is still in memory, but if it wasn't
## and we were picking up from where we left off
## you can just pull in the local model
## you can also version it, and write little "cards" on how to
## use and assess the model and how to look out for drift, it's
## strengths and weaknessess etc..

v_model_from_pin <-
  vetiver::vetiver_pin_read(
    board = pin_board,
    name = "payroll_model"
  )

## deploy the model
plumber::pr() |>
  vetiver::vetiver_api(v_model_from_pin) |>
  plumber::pr_run(port = 8080)

## model endpoint
endpoint <- vetiver::vetiver_endpoint("http://127.0.0.1:8080/predict")
endpoint

# source the bkg-api as a abckground job
# you can do it programmatically or manually

## predictions

new_payroll_master <-
  predictions |>
  dplyr::slice_sample(n = 20)

new_payroll <-
  new_payroll_master |>
  dplyr::select(calendar_year, deptid, job_title)

pred <- predict(endpoint, new_payroll)
pred

looksy <-
  dplyr::bind_cols(
    new_payroll_master,
    pred
  ) |>
  dplyr::mutate(
    pred_errors = .pred - annual_rate
  )

View(looksy)

