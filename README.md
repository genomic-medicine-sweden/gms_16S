# gms-emu.
EMU is a taxonomic profiler optimized for long 16S rRNA reads.
https://gitlab.com/treangenlab/emu
This nextflow-pipeline is under construction.

## Rough plan
![emu_workflow](https://user-images.githubusercontent.com/115690981/236446422-f37d2937-1490-4a52-8b49-e668e193001f.png)


#### Quick start
1. Add you samples to a sample_sheet.csv
2. gunzip the files in the database directory (if they are gzipped).
3. Run
``` 
nextflow run main.nf --input assets/samplesheet_mod.csv \
    --outdir results_emu \
    --db /path/to/assets/databases/emu_database \
    --seqtype map-ont \
    -profile singularity,test 
```
