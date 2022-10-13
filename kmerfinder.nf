#!/usr/bin/env nextflow

/*
Run KmerFinder (installed in a Conda environment) over genome assemblies (*.fasta) for species identification.

[Dependencies]
- Conda
- Python
- KhmerFinder and KMA

[Use guide]
An example command line in a screen session:
nextflow -Djava.io.tmpdir=$PWD run kmerfinder.nf --db "$HOME/databases/kmerfinder/bacteria_220606/bacteria/bacteria.ATG" --tax "$HOME/databases/kmerfinder/bacteria_220606/bacteria/bacteria.tax" --outdir "${PWD}/output" --fasta "assemblies/*.fasta" --queueSize 15 -c kmerfinder.config

[Declarations]
Copyright (C) 2020-2022 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public License v3.0
Publication: 7 June 2022; last modification: 9 June 2022
*/

/*------------------------------------------------------------------------------
    Output settings
------------------------------------------------------------------------------*/
nextflow.enable.dsl = 2

include { mkdir } from "./module"

out_dir = mkdir(params.outdir)

fasta_in = Channel.fromPath(params.fasta, type: "file").map { file -> tuple(file.baseName, file) }  // Imports the path and removes the filename extension (.fasta); www.nextflow.io/docs/latest/faq.html#how-do-i-get-a-unique-id-based-on-the-file-name

process kmerfinder {
    publishDir path: "$out_dir", mode: "copy", overwrite: true, pattern: "data.json", saveAs: { filename -> "${isolate}.json" }
    publishDir path: "$out_dir", mode: "copy", overwrite: true, pattern: "results.spa", saveAs: { filename -> "${isolate}.spa" }
    publishDir path: "$out_dir", mode: "copy", overwrite: true, pattern: "results.txt", saveAs: { filename -> "${isolate}.txt" }
    executor "pbs"  // Do not put clusterOptions here as it overrides the one in the config file. Further, Nextflow generates a name for each job automatically, so do not need to add 'clusterOptions -N kmerfinder' here.

    input:
    tuple val(isolate), path(assembly)

    output:
    path "data.json"
    path "results.spa"
    path "results.txt"

    script:
    """
    module load anaconda3/personal
    source activate ${params.conda_env}
    python ${params.kmerfinder_dir}/kmerfinder.py -i ${assembly} --output_folder . -db ${params.db} --tax ${params.tax} --kma_path ${params.kma_dir}
    """
}

/*------------------------------------------------------------------------------
    Workflow 
------------------------------------------------------------------------------*/
workflow {
    kmerfinder(fasta_in)
}