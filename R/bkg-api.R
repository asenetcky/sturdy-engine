# API in R as Background Job

# Load libraries ------------------------------------------------
# library(vetiver)
# library(dplyr)
# library(pins)
# library(fs)
# library(plumber)

# Grab model from pinboard ------------------------------------------------
pin_board <- 
  pins::board_folder(fs::path_wd("data/models/"))



v_model_from_pin <- 
  vetiver::vetiver_pin_read(
    board = pin_board,
    name = "payroll-model"
  )


# Deploy API ------------------------------------------------
plumber::pr() |>
  vetiver::vetiver_api(v_model_from_pin) |>
  plumber::pr_run(port = 8080)
