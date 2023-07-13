// Merge nanopore barcode fastq.gz files when you have have sample sheet for the barcode folders
process GENERATE_INPUT {
    debug true //print to stdout. debugging

    input:
       path(merged_files) 

    output:
//    publishDir 'fastq_pass_merged', mode: 'move'
      path '*amplesheet_merged.csv' , emit : sample_sheet_merged
    script:
    """
    generate_input.sh $merged_files
    """
}

