#!/usr/bin/env Rscript
# ------------------------------------------------------------------------------
# Generate the synthetic CI test project: tests/fixture/CI-Test/
#
# Run from the phipflow repository root:
#   Rscript tests/fixture/make_fixture.R
#
# The generated files are committed, so this only needs to be re-run when the
# fixture design changes. Peptide IDs are taken from peplib/peptide_library.rds
# so that peptide-library lookups and DELTA taxon aggregation have real strata.
#
# Design:
#   24 subjects x 2 timepoints (BL, FU) = 48 samples, named R01..R48.
#   12 subjects are Case, 12 are Control.
#   Peptides: 8 species x 60 peptides + 300 background peptides.
#   Planted signals:
#     - Bacteroides fragilis peptides are more prevalent in Case than Control.
#     - Escherichia coli peptides increase from BL to FU in Case subjects.
# ------------------------------------------------------------------------------

set.seed(20261005)

project_name <- "CI-Test"
out_dir      <- file.path("tests", "fixture", project_name)

peplib <- as.data.frame(readRDS(file.path("peplib", "peptide_library.rds")))

# ------------------------------------------------------------------------------
# Peptides
# ------------------------------------------------------------------------------
species_used <- c(
  "Bacteroides fragilis",
  "Escherichia coli",
  "Bacteroides uniformis",
  "Phocaeicola vulgatus",
  "Akkermansia muciniphila",
  "Faecalibacterium prausnitzii",
  "Alistipes shahii",
  "Blautia obeum"
)
n_per_species <- 60L
n_background  <- 300L

species_peptides <- lapply(species_used, function(sp) {
  ids <- peplib$peptide_id[!is.na(peplib$species) & peplib$species == sp]
  sort(sample(ids, n_per_species))
})
names(species_peptides) <- species_used

background_pool <- setdiff(peplib$peptide_id, unlist(species_peptides))
background      <- sample(background_pool, n_background)

peptides <- c(unlist(species_peptides, use.names = FALSE), background)
n_pep    <- length(peptides)

# ------------------------------------------------------------------------------
# Samples / metadata
# ------------------------------------------------------------------------------
n_subjects <- 24L
subjects   <- sprintf("S%02d", seq_len(n_subjects))
status     <- rep(c("Case", "Control"), each = n_subjects / 2)

metadata <- data.frame(
  SampleName = sprintf("R%02d", seq_len(2 * n_subjects)),
  subject_id = rep(subjects, times = 2),
  Status     = rep(status, times = 2),
  Timepoint  = rep(c("BL", "FU"), each = n_subjects),
  Sex        = rep(sample(c("F", "M"), n_subjects, replace = TRUE), times = 2),
  Age        = rep(sample(25:70, n_subjects, replace = TRUE), times = 2),
  stringsAsFactors = FALSE
)
metadata$Status_Timepoint <- paste(metadata$Status, metadata$Timepoint, sep = "_")

# metadata column order: sample name must be first (renamed to sample_id)
metadata <- metadata[, c(
  "SampleName", "Sex", "Age", "Status", "Timepoint",
  "Status_Timepoint", "subject_id"
)]

# ------------------------------------------------------------------------------
# Enrichment probabilities with planted signals
# ------------------------------------------------------------------------------
base_prob <- runif(n_pep, 0.05, 0.4)
prob <- matrix(base_prob, nrow = n_pep, ncol = nrow(metadata))

is_fragilis <- peptides %in% species_peptides[["Bacteroides fragilis"]]
is_coli     <- peptides %in% species_peptides[["Escherichia coli"]]
is_case     <- metadata$Status == "Case"
is_case_fu  <- is_case & metadata$Timepoint == "FU"

prob[is_fragilis, is_case]    <- 0.75
prob[is_fragilis, !is_case]   <- 0.10
prob[is_coli,     is_case_fu] <- 0.80

exist <- matrix(
  rbinom(length(prob), 1L, prob),
  nrow = n_pep,
  dimnames = list(peptides, metadata$SampleName)
)

fold <- exist * round(rlnorm(length(exist), meanlog = 2, sdlog = 0.6), 3)
# a few infinite fold changes to exercise --replace_inf
fold[sample(which(exist == 1L), 10)] <- Inf

# ------------------------------------------------------------------------------
# Write files
# ------------------------------------------------------------------------------
dir.create(file.path(out_dir, "Data"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "Metadata"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "R"), recursive = TRUE, showWarnings = FALSE)

write_matrix <- function(m, path) {
  df <- data.frame(peptide_name = rownames(m), m, check.names = FALSE)
  utils::write.csv(df, path, row.names = FALSE, quote = FALSE)
}

write_matrix(exist, file.path(out_dir, "Data", "exist.csv"))
write_matrix(fold, file.path(out_dir, "Data", "fold.csv"))

utils::write.csv(
  metadata,
  file.path(out_dir, "Metadata", paste0(project_name, "_metadata.csv")),
  row.names = FALSE,
  quote = FALSE
)

message("Fixture written to ", out_dir, ": ",
        n_pep, " peptides x ", nrow(metadata), " samples")
