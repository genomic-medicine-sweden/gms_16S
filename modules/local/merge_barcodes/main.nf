// Merge nanopore barcode fastq.gz files
process MERGE_BARCODES {
    echo true //print to stdout

    input:
      path('fastq_pass')

    output:
//    publishDir 'fastq_pass_merged', mode: 'move'
      path('*fastq.gz')    
    script:
    """
    merge_barcodes.sh $fastq_pass ./
    """
}

