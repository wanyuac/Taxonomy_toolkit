#!/usr/bin/env nextflow

/*
Run Kraken2 for paired-end read sets.

[Use guide]
An example command line in a screen session:
nextflow -Djava.io.tmpdir=$PWD run kraken2.nf --db "./bacteria" --kraken2Dir "./kraken2/bin" --outdir "${PWD}/report" --fastq "./reads/*_{1,2}.fastq.gz" --queueSize 35 -c kraken2.config -profile pbs

Note to use quote signs for paths, particularly, the paths of input read files, in this command line. Nextflow only reads
the first item in the file list provided by --fastq ./reads/*_{1,2}.fastq.gz, causing an error to run the pipeline. 

[Declarations]
Copyright (C) 2020 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public License v3.0
Publication: 24 Mar 2020; last modification: 16 Apr 2020
*/

def out_dir = new File(params.outdir)

if ( !out_dir.exists() ) {
    result = out_dir.mkdir()
    println result ? "Successfully created directory ${out_dir}" : "Cannot create directory: ${out_dir}"
}

read_sets = Channel.fromFilePairs(params.fastq)

process kraken2 {
    /*
    The "publishDir" statement must be accompanied by the declaration of output in the process in order
    to copy/move output files into the right output directory. Nothing happens if the output is not
    defined even though this is a terminal process.
    */
    publishDir path: "${out_dir}", mode: "move", overwrite: true
    
    input:
    set genome, file(paired_fastq) from read_sets
    
    output:
    file("${genome}.txt") into summary_out
    file("${genome}.kraken") into taxa_out
    
    script:
    
    // --output: classification output; --report: a summary tree of assigned taxonomy
    """
    ${params.kraken2Dir}/kraken2 --db ${params.db} --paired --threads 4 --gzip-compressed --output ${genome}.kraken --report ${genome}.txt --classified-out "${genome}_known#.fastq" --unclassified-out "${genome}_unknown#.fastq" ${paired_fastq}
    """
}
