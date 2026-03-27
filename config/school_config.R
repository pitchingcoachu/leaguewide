# School-specific overrides for the shared app.
# Copy this file to another repo and keep the same structure when you need to customize colors, logos, APIs, etc.
school_config <- list(
  team_code = "LEAGUE",
  # Additional school-code markers used in TrackMan team columns (optional).
  # These are checked alongside team_code during allowed-player verification.
  team_code_markers = character(0),
  allowed_pitchers = character(0),
  allowed_hitters = character(0),
  allowed_campers = character(0),
  league_mode = TRUE,
  sync_v3_only = TRUE,
  sync_start_date = "2026-02-13",
  exclude_filename_tokens = c("unverified", "fhc", "playerpositioning", "json", "private"),
  colors = list(
    primary             = "#461d7c",   # purple from the LSU logo
    accent              = "#461d7c",   # deep purple gradient start
    accent_secondary    = "#fdd023",   # LSU gold for highlights
    background          = "#ffffff",   # clean white page base
    background_secondary= "#f6f3ff"    # very light purple tint
    
  ),
  logo = "PCUlogo.png",
  coaches_emails = c(),
  notes_api = list(
    base_url = "https://script.google.com/macros/s/AKfycbxkjUyCb1MI8xc7kuLOi3qutPaoKVMzx85hGBzJRTuCOfMWnYwTS-5LWopZDTpwnaa_/exec",
    token = "pcu_notes_TZ3qj9mY0Nf4WvK1aB7rC6xD2uH8sP5L"
  ),
  extra = list(
    school_name = "League",
    ftp_folder = "trackman",
    cloudinary_folder = "trackman"
  )
)

colorize_css <- function(css, accent, accent_secondary, background, background_secondary) {
  accent_rgb <- paste(grDevices::col2rgb(accent), collapse = ",")
  accent_secondary_rgb <- paste(grDevices::col2rgb(accent_secondary), collapse = ",")
  css <- gsub("#e35205", accent, css, fixed = TRUE)
  css <- gsub("#ff8c1a", accent_secondary, css, fixed = TRUE)
  css <- gsub("rgba(227,82,5", paste0("rgba(", accent_rgb), css, fixed = TRUE)
  css <- gsub("rgba(227, 82, 5", paste0("rgba(", accent_rgb), css, fixed = TRUE)
  css <- gsub("rgba(255,140,26", paste0("rgba(", accent_secondary_rgb), css, fixed = TRUE)
  css <- gsub("rgba(255, 140, 26", paste0("rgba(", accent_secondary_rgb), css, fixed = TRUE)
  css <- gsub("#f5f7fa", background, css, fixed = TRUE)
  css <- gsub("#e8ecf1", background_secondary, css, fixed = TRUE)
  css
}
