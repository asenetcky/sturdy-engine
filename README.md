# quick and dirty model to api pipeline

## How to walk through this example


- Clone this repo from github.

- Execute the following R command `renv::activate(profile = "development")`.

- Execute the following R command `renv::restore()`.

- Source `R/grab-odp-data.R` - It is going to take a while. It will
pull the state employee payroll data down from the CT Open Data Portal.
The data will be saved in the `data/` folder.  If you're lucky, you can
ask a friend for the parquet file.  Just be sure to save it in
`data/` as `payroll-2024-2025.parquet`.

- Source `R/model-setup.R` - This will create the model and store it locally
within `data/models/payroll-model` as a pin in the pin board.

- Source/walk-through `R/model-predict.R` to start the background job
that spools up the `plumber` API based on the model. It will also
send rows up to the API to create predications. This model is nonsense
and its performance is terrible. The model itself is not meant to be
important.


