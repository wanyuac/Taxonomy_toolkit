#!/usr/bin/env nextflow

/*
Run Kraken2 (installed in a Conda environment) and Bracken over gzip-compressed paired-end read sets for species identification.

[Dependencies]
- Conda
- Python and the pandas package
- Bracken v2.6+
- top3_bracken_taxa.py in github.com/wanyuac/Kraken_toolkit

[Use guide]
An example command line in a screen session:
nextflow -Djava.io.tmpdir=$PWD run kraken2.nf --db "./bacteria" --kraken2Dir "./kraken2/bin" --outdir "${PWD}/report" --fastq "./reads/*_{1,2}.fastq.gz" --queueSize 35 -c kraken2.config -profile pbs

Note to use quote signs for paths, particularly, the paths of input read files, in this command line. Nextflow only reads
the first item in the file list provided by --fastq ./reads/*_{1,2}.fastq.gz, causing an error to run the pipeline. 

[Declarations]
Copyright (C) 2020-2022 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public License v3.0
Publication: 24 Mar 2020; last modification: 2 June 2022
*/

/*------------------------------------------------------------------------------
    Output settings
------------------------------------------------------------------------------*/
nextflow.enable.dsl = 2

def mkdir(dir_path) {  // Creates a directory and returns a File object
    def dir_obj = new File(dir_path)
    if ( ! dir_obj.exists() ) {
        result = dir_obj.mkdir()
        println result ? "Successfully created directory ${dir_path}" : "Cannot create directory ${dir_path}"
    } else {
        println "Directory ${dir_path} exists."
    }
    return dir_obj
}

def subdirs = ["kraken", "bracken"]  // A list object of subdirectory names

out_dir = mkdir(params.outdir)  // Create the parental output directory
subdirs.each { mkdir("${out_dir}/${it}") }  // Iterate through the list

/*------------------------------------------------------------------------------
    Processes
------------------------------------------------------------------------------*/
process kraken2 {
    /*
    The "publishDir" statement must be accompanied by the declaration of output in the process in order
    to copy/move output files into the right output directory. Nothing happens if the output is not
    defined even though this is a terminal process.
    */
    publishDir path: "${out_dir}/kraken", mode: "copy", overwrite: true, pattern: "${genome}_kraken.txt"
    label "PBS"
    executor "pbs"
    clusterOptions "-N Kraken2"

    input:
    tuple val(genome), file(fastqs)
    
    output:
    tuple val(genome), path("${genome}_kraken.txt") into kraken_reports
    
    script:
    """
    module load anaconda3/personal
    source activate ${params.conda_kraken_env}
    kraken2 --threads ${params.cpus} --db ${params.db} --paired --gzip-compressed --output - --report ${genome}_kraken.txt ${fastqs}
    """
}

process bracken {
    publishDir path: "${out_dir}/bracken", mode: "copy", overwrite: true, pattern: "${genome}_bracken.*" // *_bracken.tsv and *_bracken.txt
    label "PBS"
    executor "pbs"
    clusterOptions "-N Bracken"

    input:
    tuple val(genome), path("${genome}_kraken.txt") from kraken_reports

    output:
    val genome into processed_genomes

    script:
    """
    ${params.bracken_dir}/bracken -d ${params.db} -i ${genome}_kraken.txt -o ${genome}_bracken.tsv -w ${genome}_bracken.txt -l S -r ${params.read_len} -t ${params.cpus}
    """
}

process compile_reports {  // This process requires Python
    publishDir path: ${outd_ir}, mode: "copy", overwrite: true, pattern: "top3_taxa.tsv"
    executor "local"

    input:
    val genomes from processed_genomes.collect()  // Triggers this process when all genome names are gathered

    script:
    genome_list = file("genome_list.txt")  // A file object
    for (g : genomes) {
        genome_list.append("${g}\n")
    }
    /* """
    ls -1 ${out_dir}/bracken/*_bracken.tsv | xargs -I {} basename {} '_bracken.tsv' > genome_list.txt */
    """
    python ${script_dir}/top3_bracken_taxa.py -l ${genome_list} -d ${out_dir}/bracken -s '_bracken.tsv' -o top3_taxa.tsv
    """
}

/*------------------------------------------------------------------------------
    Workflow 
------------------------------------------------------------------------------*/
workflow {
    kraken2(Channel.fromFilePairs(params.fastq))
    bracken()
    compile_reports()
}