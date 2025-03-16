// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id                 = row.sample
    meta.sequencing_run     = row.sequencing_run
    meta.single_end         = row.single_end.toBoolean()
    meta.fw_primer          = row.FW_primer
    meta.rv_primer          = row.RV_primer

    // Add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (meta.single_end) {
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
        }
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return fastq_meta
}

//
// Check input samplesheet and get read channels
//

include { GENERATE_INPUT             } from '../../../modules/local/generate_input/main.nf'
include { MERGE_BARCODES             } from '../../../modules/local/merge_barcodes/main.nf'
include { MERGE_BARCODES_SAMPLESHEET } from '../../../modules/local/merge_barcodes_samplesheet/main.nf'
include { SAMPLESHEET_CHECK          } from '../../../modules/local/samplesheet_check/main.nf'

workflow PIPELINE_INITIALISATION {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    ch_versions = Channel.empty()

    // Check input path parameters to see if they exist
    def checkPathParamList = !params.merge_fastq_pass ? [params.input] : []
    checkPathParamList += [params.multiqc_config, params.fasta]
    checkPathParamList.findAll { it }.each { path ->
        if (!file(path).exists()) {
            exit 1, "ERROR: File path does not exist: ${path}"
        }
    }

    //
    // MODULE: Concatenate input read files
    //
    if ( params.merge_fastq_pass && !params.barcodes_samplesheet ) {
        MERGE_BARCODES(params.merge_fastq_pass)
        GENERATE_INPUT(MERGE_BARCODES.out.fastq_dir_merged).sample_sheet_merged.set{ ch_samplesheet }
    } else if ( params.merge_fastq_pass && params.barcodes_samplesheet ) {
        MERGE_BARCODES_SAMPLESHEET(params.barcodes_samplesheet, params.merge_fastq_pass)
        GENERATE_INPUT(MERGE_BARCODES_SAMPLESHEET.out.fastq_dir_merged).sample_sheet_merged.set{ ch_samplesheet }
        ch_versions = ch_versions.mix(MERGE_BARCODES_SAMPLESHEET.out.versions.first())
    } else if ( !params.merge_fastq_pass && !params.barcodes_samplesheet && samplesheet ) {
        ch_samplesheet = Channel.value(samplesheet)
    } else {
        error "Invalid input. Please specify either '--input' or '--merge_fastq_pass' (and '--barcodes_samplesheet' if available)."
    }

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    SAMPLESHEET_CHECK ( ch_samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { ch_reads }
    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions.first())

    emit:
    reads       = ch_reads          // channel: [ val(meta), [ reads ] ]
    samplesheet = ch_samplesheet    // channel: [ val(meta), [ samplesheet ] ]
    versions    = ch_versions       // channel: [ versions.yml ]
}
