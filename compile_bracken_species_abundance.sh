#!/bin/sh
# Yu Wan (17/5/2021)
# Example command:
#    sh compile_bracken_species_abundance.sh [species name] [report directory (no backslash)] [genome_list.txt] > output.tsv

echo -e 'isolate\tspecies\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads'
species=$1
rdir=$2  # Directory of Kraken reports
genomes=$3

while read -r g
do
    line=$(grep "${species}" "${rdir}/${g}_bracken.tsv")
    echo -e "${g}\t${line}"
done < "${genomes}"
