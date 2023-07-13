// Merge nanopore barcode fastq.gz files when you have have sample sheet for the barcode folders
process MERGE_BARCODES_SAMPLESHEET {
    debug true //print to stdout. debugging

    input:
     path('barcodes_samplesheet') 
     path('fastq_pass')
   

    output:
    // publishDir 'fastq_pass_merged', mode: 'move'
    path('fastq_pass_merged/*fastq.gz') , emit : fastq_files_merged
    path('fastq_pass_merged') , emit : fastq_dir_merged
    
    script:
    """
    merge_barcodes_samplesheet.py $barcodes_samplesheet fastq_pass_merged $fastq_pass 
    """
}

