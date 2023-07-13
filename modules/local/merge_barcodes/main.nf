// Merge nanopore barcode fastq.gz files
process MERGE_BARCODES {
    debug true //print to stdout

    input:
      path('fastq_pass')

    output:
//    publishDir 'fastq_pass_merged', mode: 'move'
//      path('*fastq.gz') , emit : fastq_files_merged
      path('fastq_pass_merged/*fastq.gz') , emit : fastq_files_merged
      path('fastq_pass_merged') , emit : fastq_dir_merged
    
    script:
    """
    merge_barcodes.sh $fastq_pass fastq_pass_merged
    """
}

