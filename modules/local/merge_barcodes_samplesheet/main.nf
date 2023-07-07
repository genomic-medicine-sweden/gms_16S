// Merge nanopore barcode fastq.gz files when you have have sample sheet for the barcode folders
process MERGE_BARCODES_SAMPLESHEET {
    debug true //print to stdout. debugging

    input:
     path('barcodes_samplesheet') 
     path('fastq_pass')
   

    output:
    publishDir 'fastq_pass_merged', mode: 'move'
      path('*.fastq.gz')    
    script:
    """
    merge_barcodes_samplesheet.py $barcodes_samplesheet ./ $fastq_pass 
    """
}

