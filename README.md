# gms-emu.
A taxonomic profiler optimized for long 16S rRNA reads.
https://gitlab.com/treangenlab/emu
Under construction.

--
Quick start
gunzip the files in the database directory if they are gzipped first.

`nextflow run main.nf --input assets/samplesheet_mod.csv \
    --outdir results_emu \
    --db /path/to/assets/databases/emu_database \
    --seqtype map-ont \
    -profile singularity,test `
