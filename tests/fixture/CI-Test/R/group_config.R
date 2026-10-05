# ------------------------------------------------------------------------------
# Group definitions for the synthetic CI test project.
# See tests/fixture/make_fixture.R for how the data was generated.
# ------------------------------------------------------------------------------

group_definitions <- list(
  # cross-sectional: Case vs Control at baseline
  Status_BL = list(
    group_col = "Status_Timepoint",
    groups = c("Case_BL", "Control_BL"),
    comparisons = list(
      c("Case_BL", "Control_BL")
    ),
    longitudinal = c(FALSE)
  ),
  # longitudinal: paired BL vs FU within Case subjects
  Status_Timepoint = list(
    group_col = "Status_Timepoint",
    groups = c("Case_BL", "Case_FU"),
    comparisons = list(
      c("Case_BL", "Case_FU")
    ),
    longitudinal = c(TRUE)
  )
)
