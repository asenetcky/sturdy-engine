# Model
set.seed(20250226)

## Grab data
data <-
  nanoparquet::read_parquet(
    fs::path_wd("data/payroll-2024-2025.parquet")
  ) |>
  dplyr::mutate(id = dplyr::row_number()) |>
  dplyr::select(
    id,
    year = calendar_year,
    dept = deptid,
    job = job_cd_descr,
    salary = annual_rate
  ) |>
  dplyr::filter(
    dplyr::if_all(
      dplyr::everything(),
      \(x) !is.na(x)
    )
  )

top_departments <- 
  data |> 
  dplyr::count(dept, sort = TRUE) |> 
  dplyr::slice_head(n = 10)

top_jobs <-
  data |> 
  dplyr::count(job, sort = TRUE) |> 
  dplyr::slice_head(n = 10)

data <- 
  data |> 
  dplyr::filter(
    job %in% top_jobs$job & 
      dept %in% top_departments$dept
  ) |> 
  dplyr::slice_sample(n = 30000) |> 
  dplyr::mutate(
    salary = as.double(salary),
    dept  = as.factor(dept),
    job = as.factor(job)
  )

training <-
  data |>
  dplyr::slice_sample(prop = 0.8)

predictions <-
  data |>
  dplyr::anti_join(training, by = "id")


# This model is nonsense and this isn't not even the best way
# to go about it nowawdays, but it's a simple example
model <- lm(salary ~ year + dept + job, training)
summary(model)

## Prep Vetiver
example_for_api_doco <-
  data |>
  head(1) |>
  dplyr::select(year, dept, job)

v_model <-
  vetiver::vetiver_model(
    model,
    model_name = "payroll-model",
    save_prototype = example_for_api_doco,
    versioned =  TRUE
  )

## Save model into `pins` board

### create board
board_path <- fs::path_wd("data/models/")
model_board <-
  pins::board_folder(
    path = board_path,
    versioned = TRUE
  )

### save model locally
vetiver::vetiver_pin_write(
  vetiver_model = v_model,
  board = model_board,
  check_renv = TRUE
)

## create dockerfile 

vetiver::vetiver_prepare_docker(
  board = model_board,
  name = "payroll-model",
  path = fs::path_wd("docker/"),
  docker_args = list(port = 8080)
)
