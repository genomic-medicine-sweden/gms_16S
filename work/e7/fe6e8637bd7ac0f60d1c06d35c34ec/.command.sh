#!/bin/bash -euo pipefail
emu \
    abundance \
    --keep-counts --type map-ont --db /aux/db/workdir_fwa010/emu_pipe_project/nf-core-gmsemu/assets/test_assets/database/ --output-dir ./  \
    --threads 2         small_test_data2.fastq.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_GMSEMU:GMSEMU:EMU_ABUNDANCE":
    emu: $(echo $(emu --version 2>&1) | sed 's/^.*emu //; s/Using.*$//' )
END_VERSIONS
