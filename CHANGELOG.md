# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added a `generate_master_html` python script that creates `master.html` file containing a table of samples with corresponding pointers to each html output file
- Added repective `GENERATE_MASTER_HTML` process
- Added `cmd.config`
- Added `params.trace_timestamp` to `nextflow.config`
- Added `changelog_update_reminder` GA workflow

### Fixed

### Changed

## [v0.1.0]

### Added

- Support for Nanopore reads. Reads can be in barcode directories or premerged into samplespecific fastq-files.
- Krona
- emu
- FiltLong
- Porchop_abi
- NanoPlot
- Multiqc
- fastqc
- Adaptation to nextflow
- All tools are containerised with singularity



