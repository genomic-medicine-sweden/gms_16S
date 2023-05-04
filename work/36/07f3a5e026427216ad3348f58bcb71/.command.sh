#!/bin/bash -euo pipefail
printf "%s %s\n" small_test_data3.fastq.gz SAMPLE_2_T1.gz | while read old_name new_name; do
    [ -f "${new_name}" ] || ln -s $old_name $new_name
done
fastqc --quiet --threads 2 SAMPLE_2_T1.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_GMSEMU:GMSEMU:FASTQC":
    fastqc: $( fastqc --version | sed -e "s/FastQC v//g" )
END_VERSIONS
