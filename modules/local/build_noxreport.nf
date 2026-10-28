process BUILD_NOXREPORT {
    tag "${project_name}"

    label 'render_reports'

    input:
    path report_marker
    val base_dir
    val project_name
    val metadata_path
    val results_name
    val use_modules
    val delta_min_m_eff

    output:
    path "build_noxreport.${project_name}.done", emit: noxreport_marker

    script:
    def book_name = results_name == 'results' ? "${project_name}_book" : "${project_name}_${results_name}_book"
    """
    set -euo pipefail

    workdir=\$PWD
    project_dir="${base_dir}/${project_name}"
    book_dir="\${project_dir}/${book_name}"

    if [[ "${use_modules}" == "true" ]]; then
      module purge
      module load R
      module load Pandoc/3.9 || true
    fi

    # The book is created on the first run only; later runs re-render it, so
    # edits to its .Rmd files and report_config.yml are kept.
    if [[ ! -d "\${book_dir}" ]]; then
      echo "Creating noxreports book: \${book_dir}"
      Rscript --vanilla -e 'noxreports::main()' init \\
        --results "\${project_dir}/${results_name}" \\
        --metadata "${metadata_path}" \\
        --project "${project_name}" \\
        --min-m-eff "${delta_min_m_eff}" \\
        --out "\${book_dir}"
    fi

    echo "Rendering noxreports book: \${book_dir}"
    Rscript --vanilla -e 'noxreports::main()' render "\${book_dir}"

    echo "DONE: \${book_dir}" > "\${workdir}/build_noxreport.${project_name}.done"
    """
}
