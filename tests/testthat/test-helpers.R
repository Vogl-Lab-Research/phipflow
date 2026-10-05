# Unit tests for src/R/helper_functions.R
#
# Run from the phipflow repository root:
#   Rscript -e 'testthat::test_dir("tests/testthat")'

source(testthat::test_path("..", "..", "src", "R", "helper_functions.R"))

palette <- sprintf("#%06X", seq_len(60) * 1000)

defs <- list(
  cross = list(
    group_col = "Status",
    groups = c("Case", "Control", "Other")
  ),
  paired = list(
    group_col = "Status_Timepoint",
    groups = c("Case_BL", "Case_FU"),
    comparisons = list(c("Case_BL", "Case_FU")),
    longitudinal = c(TRUE)
  )
)

# ------------------------------------------------------------------------------
# build_group_config
# ------------------------------------------------------------------------------
test_that("missing comparisons generate all pairwise comparisons", {
  cfg <- build_group_config("cross", group_definitions = defs, fallback_palette = palette)

  expect_equal(cfg$group_col, "Status")
  expect_equal(
    cfg$comparisons,
    list(c("Case", "Control"), c("Case", "Other"), c("Control", "Other"))
  )
  expect_equal(cfg$longitudinal, c(FALSE, FALSE, FALSE))
})

test_that("default_longitudinal fills longitudinal when not given", {
  cfg <- build_group_config(
    "cross",
    default_longitudinal = TRUE,
    group_definitions = defs,
    fallback_palette = palette
  )

  expect_equal(cfg$longitudinal, c(TRUE, TRUE, TRUE))
})

test_that("comparisons and longitudinal from group_definitions are used", {
  cfg <- build_group_config("paired", group_definitions = defs, fallback_palette = palette)

  expect_equal(cfg$comparisons, list(c("Case_BL", "Case_FU")))
  expect_equal(cfg$longitudinal, TRUE)
  expect_named(cfg$group_palette, c("Case_BL", "Case_FU"))
})

test_that("manual comparisons override group_definitions", {
  cfg <- build_group_config(
    "cross",
    group_definitions = defs,
    fallback_palette = palette,
    manual_comparisons = list(c("Case", "Other")),
    manual_longitudinal = TRUE
  )

  expect_equal(cfg$comparisons, list(c("Case", "Other")))
  expect_equal(cfg$longitudinal, TRUE)
})

test_that("invalid group configurations are rejected", {
  expect_error(
    build_group_config("nope", group_definitions = defs, fallback_palette = palette),
    "Unknown active_group_name"
  )

  bad_label <- defs
  bad_label$paired$comparisons <- list(c("Case_BL", "Case_XX"))
  expect_error(
    build_group_config("paired", group_definitions = bad_label, fallback_palette = palette),
    "not present in active group"
  )

  bad_length <- defs
  bad_length$paired$longitudinal <- c(TRUE, FALSE)
  expect_error(
    build_group_config("paired", group_definitions = bad_length, fallback_palette = palette),
    "same length as comparisons"
  )
})

# ------------------------------------------------------------------------------
# make_group_palette_full
# ------------------------------------------------------------------------------
test_that("palette has one unique colour per label across all definitions", {
  pal <- make_group_palette_full(defs, fallback_palette = palette)

  expect_named(pal, c("Case", "Control", "Other", "Case_BL", "Case_FU"))
  expect_false(anyDuplicated(unname(pal)) > 0)
})

test_that("palette skips the 12th colour once there are 12 or more labels", {
  many <- list(g = list(group_col = "g", groups = paste0("L", 1:12)))
  pal <- make_group_palette_full(many, fallback_palette = palette)

  expect_false(palette[12] %in% pal)
  expect_equal(unname(pal[12]), palette[13])
})

# ------------------------------------------------------------------------------
# load_manual_comparison_config
# ------------------------------------------------------------------------------
test_that("no manual comparison file returns NULLs", {
  cfg <- load_manual_comparison_config(NULL)

  expect_null(cfg$manual_comparisons)
  expect_null(cfg$manual_longitudinal)
})

test_that("manual comparison file is read and validated", {
  ok <- withr::local_tempfile(fileext = ".R")
  writeLines(c(
    "manual_comparisons <- list(c('A', 'B'))",
    "manual_longitudinal <- c(TRUE)"
  ), ok)

  cfg <- load_manual_comparison_config(ok)
  expect_equal(cfg$manual_comparisons, list(c("A", "B")))
  expect_equal(cfg$manual_longitudinal, TRUE)

  bad <- withr::local_tempfile(fileext = ".R")
  writeLines("manual_comparisons <- list(c('A', 'B', 'C'))", bad)
  expect_error(load_manual_comparison_config(bad), "character vector of length 2")
})

# ------------------------------------------------------------------------------
# parse_longitudinal_group_col
# ------------------------------------------------------------------------------
test_that("longitudinal group column is split at the last underscore", {
  expect_equal(
    parse_longitudinal_group_col("Smoker_status_Timepoint", paired_col = "subject_id"),
    list(group_col = "Smoker_status", time_col = "Timepoint")
  )
  expect_equal(
    parse_longitudinal_group_col("Smoker_Timepoint")$group_col,
    "group_char"
  )
})
