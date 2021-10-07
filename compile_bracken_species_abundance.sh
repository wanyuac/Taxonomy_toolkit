#!/bin/sh
# Extract the line corresponding to a particular taxon from the tsv-formatted bracken reports.
# Example command:
#    sh compile_bracken_species_abundance.sh [taxon name] [report directory (no backslash)] [genome_list.txt] > output.tsv
# Copyright (C) 2021 Yu Wan <wanyuac@126.com>
# Licensed under the GNU General Public Licence version 3 (GPLv3) <https://www.gnu.org/licenses/>.
# Creation: 17 May 2021; the latest update: 17 May 2021

echo -e 'isolate\tspecies\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads'
species=$1
rdir=$2  # Directory of Kraken reports
genomes=$3

while read -r g
do
    line=$(grep "${species}" "${rdir}/${g}_bracken.tsv")
    echo -e "${g}\t${line}"
done < "${genomes}"
