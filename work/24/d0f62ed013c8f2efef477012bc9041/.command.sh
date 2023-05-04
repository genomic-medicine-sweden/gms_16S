#!/bin/bash -euo pipefail
check_samplesheet.py \
    samplesheet_mod.csv \
    samplesheet.valid.csv

cat <<-END_VERSIONS > versions.yml
"NFCORE_GMSEMU:GMSEMU:INPUT_CHECK:SAMPLESHEET_CHECK":
    python: $(python --version | sed 's/Python //g')
END_VERSIONS
