//  A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
//  Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
//  Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.
process COMBINE_REPORTS {
    debug true
    // tag "${meta.id}"
    label 'process_single'

    input:
    //  Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/modules/nf-core/bwa/index/main.nf
    //  Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    //tuple val(meta), path(report)
    path report
    // collect all reports

    output:
    //tuple val(meta), path("${report.baseName}samplename.tsv"), emit: report
    //path "$report.baseName-samplename.tsv", emit: reportsamplename
    path "combined-rel-abundance.tsv", emit: combinedreport



// add_samlpename is not needed, but the reports must be collected!
// bash add_sample_column.sh  "$report" "${report.baseName}-samplename.tsv"  

// although i pass the collected reports I still get one single report at a time
    script:
    """
    echo $report
    bash combine_tsv.sh "${report}" > "combined-rel-abundance.tsv"
    """

    //"""
    //#!/usr/bin/env nextflow
    // def lines = report.splitCsv()
    // for (List row : lines) {
    //    println "$row\t${meta.id}"
    // }

    // def f = file(report)
    // def lines = f.splitCsv()
    // for (List row : lines) {
    //     log.info "${row[0]} -- ${row[2]}"
    // }
    //"""
}




process PHYLOSEQ_OBJECT {
    //errorStrategy 'ignore'
    debug true
    label 'process_single'

    // //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    // //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // conda "bioconda::emu=3.4.4"
    //  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //      'https://depot.galaxyproject.org/singularity/bioconductor-phyloseq:1.50.0':
    //      'quay.io/biocontainers/bioconductor-phyloseq:1.50.0--r44hdfd78af_0' }"

    conda 'modules/local/phyloseq/env.yaml'

    input:
    //  Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/modules/nf-core/bwa/index/main.nf
    //  Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    path combined_report
    path taxonomy_file

    output:
    path "phyloseq_output.RDS"      , emit: phyloseq_output

    // when:
    // task.ext.when == null || task.ext.when

    script:
    """
    phyloseq_object.R  $combined_report $taxonomy_file
    """
    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     R: \$(R --version 2>&1 | sed -n 1p | sed 's/R version //' | sed 's/ (.*//')
    // END_VERSIONS
}

