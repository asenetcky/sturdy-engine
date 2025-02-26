## Serve model from pin

# create a pin board
pin_board <- pins::board_folder(fs::path_wd("data/models/"))

# this board is in the repo BUT it can be anywhere locally, onedrive
# an amazon s3 bucket or whatever

# Yes, I know the model is still in memory, but if it wasn't
# and we were picking up from where we left off
# you can just pull in the local model
# you can also version it, and write little "cards" on how to
# use and assess the model and how to look out for drift, it's
# strengths and weaknessess etc..

v_model_from_pin <-
  vetiver::vetiver_pin_read(
    board = pin_board,
    name = "payroll-model"
  )

## deploy the model manually
# plumber::pr() |>
#   vetiver::vetiver_api(v_model_from_pin) |>
#   plumber::pr_run(port = 8080)

# source the bkg-api as a background job
# you can do it programmatically or manually

rstudioapi::jobRunScript(
  path = fs::path_wd("R/bkg-api.R"),
  name = "payroll-api",
  workingDir = fs::path_wd(),
  importEnv = FALSE
)

## model endpoint
endpoint <- vetiver::vetiver_endpoint("http://127.0.0.1:8080/predict")
endpoint

## predictions

new_payroll_master <-
  predictions |>
  dplyr::slice_sample(n = 20)

new_payroll <-
  new_payroll_master |>
  dplyr::select(year, dept, job)

pred <- predict(endpoint, new_payroll)
pred


looksy <-
  dplyr::bind_cols(
    new_payroll_master,
    pred
  ) |>
  dplyr::mutate(
    pred_errors = .pred - salary
  )

View(looksy)
