nextflow run main.nf \
  --input assets/examples/samplesheet_medium_adapted.csv \
  --outdir results \
  --db /Users/kadg/Forschung/GMS/16S-Pipeline/gms_16S/assets/databases/emu_database \
  --seqtype map-ont \
   -profile test,docker \
  --quality_filtering \
  --longread_qc_qualityfilter_minlength 1200 \
  --longread_qc_qualityfilter_maxlength 1800
