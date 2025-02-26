con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "data/duckdb/mtcar.duckdb")
DBI::dbWriteTable(con, "mtcars", mtcars)
DBI::dbDisconnect(con)
