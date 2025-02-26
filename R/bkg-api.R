# API in R as Background Job

# Load libraries ------------------------------------------------
library(vetiver)
library(dplyr)
library(pins)
library(fs)
library(plumber)

# Grab model from pinboard ------------------------------------------------
pin_board <- board_folder(fs::path_wd("data/models/"))



v_model_from_pin <- vetiver_pin_read(
  board = pin_board,
  name = "payroll_model"
)


# Deploy API ------------------------------------------------
pr() |>
  vetiver_api(v_model_from_pin) |>
  pr_run(port = 8080)
