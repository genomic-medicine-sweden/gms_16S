process GENERATE_MASTER_HTML {
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "pyhdfd78af_1") must be EXCLUDED to support installation on different operating systems.
    conda "conda-forge::nf-core=3.0.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nf-core:3.0.2--pyhdfd78af_1':
        'quay.io/biocontainers/nf-core:3.0.2' }"

    input:
    path csv

    output:
    path 'master.html'  , emit: master_html
    path "versions.yml" , emit: versions

    script:
    """
    generate_master_html.py --csv ${csv} --html ${params.master_template} --timestamp ${params.trace_timestamp}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        generate_master_html.py: \$(echo \$(generate_master_html.py --version 2>&1) | sed 's/^.*generate_master_html.py //; s/ .*\$//' )
    END_VERSIONS
    """

    stub:
    """
    touch master.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        generate_master_html.py: \$(echo \$(generate_master_html.py --version 2>&1) | sed 's/^.*generate_master_html.py //; s/ .*\$//' )
    END_VERSIONS
    """
}
