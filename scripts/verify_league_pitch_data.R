#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(DBI)
})

if (file.exists(".Renviron")) {
  readRenviron(".Renviron")
}

source("pitch_data_service.R")

args <- commandArgs(trailingOnly = TRUE)
start_date <- if (length(args) >= 1L && nzchar(args[[1]])) suppressWarnings(as.Date(args[[1]])) else as.Date(NA)
end_date <- if (length(args) >= 2L && nzchar(args[[2]])) suppressWarnings(as.Date(args[[2]])) else as.Date(NA)
school_code <- if (length(args) >= 3L && nzchar(args[[3]])) args[[3]] else Sys.getenv("TEAM_CODE", "LEAGUE")
school_code <- toupper(trimws(school_code))
if (!nzchar(school_code)) school_code <- "LEAGUE"

con <- pitch_data_db_connect()
if (is.null(con)) stop("Unable to connect to Neon using PITCH_DATA_DB_URL")
on.exit(tryCatch(DBI::dbDisconnect(con), error = function(...) NULL), add = TRUE)

schema <- gsub("[^A-Za-z0-9_]", "_", Sys.getenv("PITCH_DATA_DB_SCHEMA", "public"))
events_tbl <- as.character(DBI::dbQuoteIdentifier(con, DBI::Id(schema = schema, table = Sys.getenv("PITCH_DATA_DB_TABLE", "pitch_events"))))
files_tbl <- as.character(DBI::dbQuoteIdentifier(con, DBI::Id(schema = schema, table = "pitch_data_files")))
school_lit <- as.character(DBI::dbQuoteLiteral(con, school_code))

date_where <- character(0)
if (!is.na(start_date)) date_where <- c(date_where, sprintf("e.session_date >= %s", as.character(DBI::dbQuoteLiteral(con, as.character(start_date)))))
if (!is.na(end_date)) date_where <- c(date_where, sprintf("e.session_date <= %s", as.character(DBI::dbQuoteLiteral(con, as.character(end_date)))))
date_sql <- if (length(date_where)) paste("AND", paste(date_where, collapse = " AND ")) else ""

q <- function(sql) DBI::dbGetQuery(con, sql)

cat("Verifying school_code=", school_code, "\n", sep = "")
if (!is.na(start_date) || !is.na(end_date)) {
  cat("Window=", as.character(start_date), " to ", as.character(end_date), "\n", sep = "")
}

summary_sql <- sprintf(
  "SELECT COUNT(*) AS rows,
          COUNT(DISTINCT NULLIF(btrim(e.pitchuid), '')) AS distinct_pitchuid,
          MIN(e.session_date) AS min_date,
          MAX(e.session_date) AS max_date
   FROM %s e
   WHERE e.school_code = %s %s",
  events_tbl, school_lit, date_sql
)
print(q(summary_sql))

missing_sql <- sprintf(
  "SELECT COUNT(*) AS missing_pitchuid
   FROM %s e
   WHERE e.school_code = %s
     AND (e.pitchuid IS NULL OR btrim(e.pitchuid) = '') %s",
  events_tbl, school_lit, date_sql
)
print(q(missing_sql))

dupe_sql <- sprintf(
  "SELECT e.pitchuid, COUNT(*) AS rows
   FROM %s e
   WHERE e.school_code = %s
     AND e.pitchuid IS NOT NULL
     AND btrim(e.pitchuid) <> '' %s
   GROUP BY e.pitchuid
   HAVING COUNT(*) > 1
   ORDER BY rows DESC
   LIMIT 20",
  events_tbl, school_lit, date_sql
)
dupes <- q(dupe_sql)
cat("Duplicate PitchUID groups:", nrow(dupes), "\n")
if (nrow(dupes)) print(dupes)

bad_file_sql <- sprintf(
  "SELECT COUNT(*) AS rows_from_disallowed_files
   FROM %s e
   WHERE e.school_code = %s
     AND lower(coalesce(e.source_file, '')) ~ '(private|playerpositioning|json)' %s",
  events_tbl, school_lit, date_sql
)
print(q(bad_file_sql))

level_sql <- sprintf(
  "SELECT COALESCE(NULLIF(btrim(e.level), ''), '(blank)') AS level, COUNT(*) AS rows
   FROM %s e
   WHERE e.school_code = %s %s
   GROUP BY 1
   ORDER BY rows DESC",
  events_tbl, school_lit, date_sql
)
print(q(level_sql))

team_sql <- sprintf(
  "SELECT COALESCE(NULLIF(btrim(e.pitcherteam), ''), '(blank)') AS pitcherteam, COUNT(*) AS rows
   FROM %s e
   WHERE e.school_code = %s %s
   GROUP BY 1
   ORDER BY rows DESC
   LIMIT 25",
  events_tbl, school_lit, date_sql
)
print(q(team_sql))

file_sql <- sprintf(
  "SELECT COUNT(DISTINCT e.file_id) AS files_loaded,
          COUNT(DISTINCT f.source_file) AS manifest_files
   FROM %s e
   LEFT JOIN %s f ON f.file_id = e.file_id
   WHERE e.school_code = %s %s",
  events_tbl, files_tbl, school_lit, date_sql
)
print(q(file_sql))

cat("Verification complete.\n")
