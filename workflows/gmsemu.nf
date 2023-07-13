/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowGmsemu.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist

// def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
// for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

def checkPathParamList = []
if (!params.merge_fastq_pass) {
    checkPathParamList += params.input
}
checkPathParamList += [params.multiqc_config, params.fasta]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
// if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
if (params.input) {
  ch_input = file(params.input)  
  } else if (params.merge_fastq_pass) {
      // do nothing.    
  } else { 
  exit 1, 'Input samplesheet not specified. Unless '--merge_fastq_pass' is used, a sample_sheet.csv must be defined!' 
 }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MERGE_BARCODES              } from '../modules/local/merge_barcodes/main.nf'
include { MERGE_BARCODES_SAMPLESHEET  } from '../modules/local/merge_barcodes_samplesheet/main.nf'
include { GENERATE_INPUT              } from '../modules/local/generate_input/main.nf'
//include { FALCO                     } from '../modules/nf-core/falco/main.nf'
include { NANOPLOT as NANOPLOT1       } from '../modules/nf-core/nanoplot/main.nf'
include { NANOPLOT  as NANOPLOT2      } from '../modules/nf-core/nanoplot/main.nf'
include { PORECHOP_ABI                } from '../modules/nf-core/porechop/abi/main.nf'
include { FILTLONG                    } from '../modules/nf-core/filtlong/main.nf'
include { EMU_ABUNDANCE               } from '../modules/local/emu/abundance/main.nf'
include { KRONA_KTIMPORTTAXONOMY      } from '../modules/nf-core/krona/ktimporttaxonomy/main.nf'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow GMSEMU {
    

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

   
    if ( params.merge_fastq_pass && !params.barcodes_samplesheet) { 
        MERGE_BARCODES (params.merge_fastq_pass)
        //GENERATE_INPUT(file("${params.outdir}/fastq_pass_merged"))
        GENERATE_INPUT(MERGE_BARCODES.out.fastq_dir_merged)
        //  ch_input = file(params.outdir + 'samplesheet_merged.csv')
        ch_input = GENERATE_INPUT.out.sample_sheet_merged
    } else if ( params.merge_fastq_pass && params.barcodes_samplesheet) { 
        MERGE_BARCODES_SAMPLESHEET (params.barcodes_samplesheet, params.merge_fastq_pass)
//        merged_files = (params.outdir + '/fastq_pass_merged')
        GENERATE_INPUT (MERGE_BARCODES_SAMPLESHEET.out.fastq_dir_merged)
        ch_input = GENERATE_INPUT.out.sample_sheet_merged
    }    

    
    

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)



    //
    // MODULE: Run Falco
  //  FALCO (
  //      INPUT_CHECK.out.reads
  //  )



    //
    // MODULE: Run Nanoplot1
    NANOPLOT1 (
        INPUT_CHECK.out.reads
    )

  //  NANOPLOT2 (
  //      INPUT_CHECK.out.reads
  //  )



    //
    // MODULE: Run FastQC
    //
    FASTQC (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )



    // MODULE: Run PORECHOP_ABI and filtering
    //
    if ( params.adapter_trimming && !params.quality_filtering) {
        PORECHOP_ABI ( INPUT_CHECK.out.reads )

        ch_processed_reads = PORECHOP_ABI.out.reads
            .map { meta, reads -> [ meta + [single_end: 1], reads ] }

        ch_versions = ch_versions.mix(PORECHOP_ABI.out.versions.first())
        ch_multiqc_files = ch_multiqc_files.mix( PORECHOP_ABI.out.log )

    } else if ( !params.adapter_trimming && params.quality_filtering) {

        ch_processed_reads = FILTLONG ( INPUT_CHECK.out.reads.map { meta, reads -> [meta, [], reads ] } ).reads
        ch_versions = ch_versions.mix(FILTLONG.out.versions.first())
        ch_multiqc_files = ch_multiqc_files.mix( FILTLONG.out.log )

    } else if ( !params.adapter_trimming && !params.quality_filtering) {

        ch_processed_reads = INPUT_CHECK.out.reads

    } else {
        PORECHOP_ABI ( INPUT_CHECK.out.reads )
        ch_clipped_reads = PORECHOP_ABI.out.reads
            .map { meta, reads -> [ meta + [single_end: 1], reads ] }

        ch_processed_reads = FILTLONG ( ch_clipped_reads.map { meta, reads -> [ meta, [], reads ] } ).reads

        ch_versions = ch_versions.mix(PORECHOP_ABI.out.versions.first())
        ch_versions = ch_versions.mix(FILTLONG.out.versions.first())
        ch_multiqc_files = ch_multiqc_files.mix( PORECHOP_ABI.out.log )
        ch_multiqc_files = ch_multiqc_files.mix( FILTLONG.out.log )
    }


//    PORECHOP_ABI (INPUT_CHECK.out.reads)
//        ch_processed_reads = PORECHOP_ABI.out.reads
//            .map { meta, reads -> [ meta + [single_end: 1], reads ]}

//    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

//    CUSTOM_DUMPSOFTWAREVERSIONS (
//        ch_versions.unique().collectFile(name: 'collated_versions.yml')
//    )



       NANOPLOT2 (
        ch_processed_reads 
      )

    
    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowGmsemu.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowGmsemu.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()



    // MODULE: Run EMU_ABUNDANCE
    EMU_ABUNDANCE (
        ch_processed_reads
    )



    if ( params.run_krona ) {
        // MODULE: Run KRONA_KTIMPORTTAXONOMY
        KRONA_KTIMPORTTAXONOMY (EMU_ABUNDANCE.out.report , file(params.krona_taxonomy_tab, checkExists: true) )
          ch_versions = ch_versions.mix( KRONA_KTIMPORTTAXONOMY.out.versions.first() )
    }


}



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
