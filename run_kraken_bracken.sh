#!/bin/bash
# Run kraken2 and bracken over a directory reads for taxonomical profiling
#
# Dependencies:
#  1. kraken2 and bracken
#  2. Python v3 and pandas package
#  3. script top3_bracken_taxa.py (in the same code directory)
#
# Copyright (C) 2024 Yu Wan <wanyuac@126.com>
# Licensed under the GNU General Public Licence version 3 (GPLv3) <https://www.gnu.org/licenses/>.
# First version: 26 Feb 2022; latest update: 26 Feb 2024

# Function definitions ###############
display_parameters() {
    echo "
    This script runs kraken2 and bracken over a directory of reads for taxonomical profiling. It assumes paired-end input reads
    with filenames following the format: [isolate name]_[1,2].fastq.gz by default. This script does not generate read-level
    Kraken reports but only sample-level reports.

    Parameters (six in total):
      --dir_in=*: directory of input reads, no back slash (mandatory)
      --dir_out=*: output directory (default: taxa)
      --kraken_db=*: directory of Kraken2's database (mandatory)
      --bracken_db=*: directory of Bracken's database (mandatory)
      --se: a flag indicating input reads are single-end with filenames following the format [isolate name].fastq.gz (optional)
      --min_read_len=*: a uniform minimum length of all input reads (default: 50, a parameter for bracken)
      --report=*: filename of the final report of top-3 taxa per sample in the tab-delimited format (default: top3_taxa.tsv)
      --threads=*: number of threads (default: 2)
    "
}

check_dir() {
    if [ ! -d "$1" ]
    then
        mkdir -p "$1"
    fi
}

# Print parameter information ###############
if [ -z "$1" ]
then
    display_parameters
    exit
else
    # https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
    # "cd --" is interpreted as "no more options following", so the command is equivalent to cd, which switches to the current user's home directory.
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    if [ ! -f "$SCRIPT_DIR/top3_bracken_taxa.py" ]
    then
        echo "Error: script top3_bracken_taxa.py was not found in $SCRIPT_DIR" >&2
        exit
    fi
fi

# Default parameters ###############
treads=2
pe=true
dir_out='taxa'
min_read_len=50
LOG_file="$dir_out"/run_kraken_bracken.log
report="top3_taxa.tsv"

# Read customised parameters
for arg in "$@"
do
    case $arg in
        --dir_in=*)
        dir_in="${arg#*=}"
        ;;
        --dir_out=*)
        dir_out="${arg#*=}"
        ;;
        --kraken_db=*)
        kraken_db="${arg#*=}"
        ;;
        --bracken_db=*)
        bracken_db="${arg#*=}"
        ;;
        --se)
        pe=false
        ;;
        --min_read_len=*)
        min_read_len="${arg#*=}"
        ;;
        --report=*)
        report="${arg#*=}"
        ;;
        --threads=*)
        threads="${arg#*=}"
        ;;
        *)
        ;;
    esac
done

if [ ! -d "$kraken_db" ] || [ ! -d "$bracken_db" ]
then
    echo "Error: databases $kraken_db and/or $bracken_db do not exist." >&2
    exit
else
    kraken_output_root="$dir_out/1_kraken"
    bracken_output_root="$dir_out/2_bracken"
    check_dir "$dir_out"
    check_dir $kraken_output_root
    check_dir $bracken_output_root
    echo "$(date) Pipeline parameters
    Input directory: $dir_in
    Output directory: $dir_out
    Kraken2 database: $kraken_db
    Bracken database: $bracken_db
    Paired-end reads: $pe
    Min. read length: $min_read_len
    Top-3 taxa report: $report
    No. of threads: $threads
    " > $LOG_file
fi

# Run Kraken2 and bracken ###############
if [ -d "$dir_in" ]
then
    isolates=()
    if [ "$pe" = true ]
    then  # Run kraken2 for paired-end reads
        for r1 in "$dir_in"/*_1.fastq.gz
        do
            s=$( basename "$r1" '_1.fastq.gz' )
            isolates+=( "$s" )  # Add the isolate name into the array
            r2="$dir_in/${s}_2.fastq.gz"
            kraken_sample_report="$kraken_output_root/${s}_kraken_sample_report.txt"
            if [ -f "$kraken_sample_report" ]
            then
                echo "$(date): skip the kraken analysis for sample $s as its report $kraken_sample_report exists." >> $LOG_file
            else
                echo "$(date): analysing paired-end reads of sample $s with Kraken2" >> $LOG_file
                kraken2 --threads $threads --paired --gzip-compressed --db $kraken_db --report "$kraken_sample_report" --output - $r1 $r2
            fi
        done
    else  # Run kraken2 for single-end reads
        for r1 in "$dir_in"/*.fastq.gz
        do
            s=$( basename "$r1" '.fastq.gz' )
            isolates+=( "$s" )
            kraken_sample_report="$kraken_output_root/${s}_kraken_sample_report.txt"
            if [ -f "$kraken_sample_report" ]
            then
                echo "$(date): skip the kraken analysis for sample $s as its report $kraken_sample_report exists." >> $LOG_file
            else
                echo "$(date): analysing single-end reads of sample $s with Kraken2" >> $LOG_file
                kraken2 --threads $threads --gzip-compressed --db $kraken_db --report "$kraken_sample_report" --output - $r1
            fi
        done
    fi
    echo "$(date): Kraken2 analysis completed." >> $LOG_file
    echo "$(date): Start bracken analysis" >> $LOG_file
    for s in "${isolates[@]}"
    do
        kraken_report="$kraken_output_root/${s}_kraken_sample_report.txt"
        if [ -f "$kraken_report" ]
        then
            echo "$(date): summarising species-level abundance of sample $s with bracken" >> $LOG_file
            bracken -r $min_read_len -t $threads -d $bracken_db -l S -i $kraken_report -o "$bracken_output_root/${s}_bracken.tsv" -w "$bracken_output_root/${s}_bracken.txt"
            ( head -n 1 "$bracken_output_root/${s}_bracken.tsv" && tail -n +2 "$bracken_output_root/${s}_bracken.tsv" | sort -t$'\t' -k7 -n -r ) > "$bracken_output_root/${s}_bracken_sorted.tsv"
        else
            echo "$(date): warning from backen: skipped sample $s for the unavailability of $kraken_report" >> $LOG_file
        fi
    done
    echo "$(date): bracken analysis completed." >> $LOG_file
else
    echo "Error: input read directory $dir_in does not exist." >&2
    exit
fi

# compile bracken results ###############
echo "$(date): Compile bracken reports for top-3 taxa of each sample" >> $LOG_file
isolate_list="$dir_out/isolates.txt"
for i in "${isolates[@]}"
do
    echo "$i" >> $isolate_list
done

python "$SCRIPT_DIR"/top3_bracken_taxa.py --list "$isolate_list" --dir "$bracken_output_root" --suffix '_bracken_sorted.tsv' --out "$dir_out/$report" && \
echo "$(date): The pipeline completed successfully." >> $LOG_file
