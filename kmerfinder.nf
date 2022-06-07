#!/usr/bin/env nextflow

/*
Run KmerFinder (installed in a Conda environment) over genome assemblies (*.fasta) for species identification.

[Dependencies]
- Conda
- Python
- KhmerFinder and KMA

[Use guide]
An example command line in a screen session:
nextflow -Djava.io.tmpdir=$PWD run kmerfinder.nf --db "$HOME/databases/kmerfinder/bacteria_220606/bacteria/bacteria.ATG" --tax "$HOME/databases/kmerfinder/bacteria_220606/bacteria/bacteria.tax" --outdir "${PWD}/output" --fasta "assemblies/*_.fasta" --queueSize 15 -c kmerfinder.config

[Declarations]
Copyright (C) 2020-2022 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public License v3.0
Publication: 7 June 2022; last modification: 7 June 2022
*/

/*------------------------------------------------------------------------------
    Output settings
------------------------------------------------------------------------------*/
nextflow.enable.dsl = 2

include { mkdir } from "./module"

out_dir = mkdir(params.outdir)

fasta_in = Channel.fromPath(params.fasta, type: "file").map { tuple(it.name.split('.')[0], it) }

process kmerfinder {
    publishDir path: "$out_dir", mode: "copy", overwrite: true, pattern: "data.json"
    publishDir path: "$out_dir", mode: "copy", overwrite: true, pattern: "results.spa"
    publishDir path: "$out_dir", mode: "copy", overwrite: true, pattern: "results.txt"
    executor "pbs"
    clusterOptions "-N KmerFinder"

    input:
    tuple val(isolate), path(fasta)
}

/*------------------------------------------------------------------------------
    Workflow 
------------------------------------------------------------------------------*/
workflow {
    kmerfinder(fasta_in)
}