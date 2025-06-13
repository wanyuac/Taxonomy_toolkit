#!/usr/bin/env python
"""
Extract the top-three taxa and their read percentages from bracken's tsv-formatted output for each sample. The bracken reports must
be generated at the same level (such as 'S'), and each report must have at least three taxa.

Command structure: python top3_bracken_taxa.py -s [suffix of Bracken reports] -o [output file name] -i [input directory]/*[filename suffix]
Example command: python top3_bracken_taxa.py -s __bracken_sorted.tsv -o . -i *__bracken_sorted.tsv

Dependencies: Python 3, pandas (<1.4.0 - recommend to use v1.3), bracken v2.6+

Copyright (C) 2021 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public Licence version 3 (GPLv3) <https://www.gnu.org/licenses/>.
Creation: 7 Oct 2021; the latest update: 13 June 2025
"""

import os
import sys
import pandas
from argparse import ArgumentParser

def parse_argument():
    parser = ArgumentParser(description = "Extract top-three taxa and their read fractions for each sample from its TSV-formatted bracken report")
    parser.add_argument('-i', '--input', dest = 'input', type = str, nargs = '+', required = True, help = "Input TSV files from bracken.")
    parser.add_argument('-s', '--suffix', dest = 'suffix', type = str, required = False, default = '__bracken_sorted.tsv', help = "Part of each input filename to be removed to extract the sample name")
    parser.add_argument('-o', '--out', dest = 'out', type = str, required = False, default = 'top3taxa.tsv', help = "Output filename and path")
    parser.add_argument('-n', '--no-sort', dest = 'no_sort', action = "store_true", help = "Do not sort the result table by the abundance of top taxa across samples")
    return parser.parse_args()

def main():
    args = parse_argument()
    bracken_reports = parse_sample_names(args.input, args.suffix)
    report = pandas.DataFrame(columns = ['Sample', 'Taxon_1', 'Taxon_2', 'Taxon_3', 'Percent_1', 'Percent_2', 'Percent_3'])  # Initiate the output data frame
    for i, tsv in bracken_reports.items():
        bracken = read_bracken_report(tsv)  # Read the TSV file and sort rows by the fraction column
        r1 = bracken.loc[0]  # Not use bracken.loc[0]['taxon'] or bracken.loc[0]['fraction'] to reduce the number of searching for indices.
        r2 = bracken.loc[1]
        r3 = bracken.loc[2]
        new_line = pandas.DataFrame({'Sample' : [i], 'Taxon_1' : [r1['taxon']], 'Taxon_2' : [r2['taxon']], 'Taxon_3' : [r3['taxon']],\
                                     'Percent_1' : [float(r1['fraction'] * 100)], 'Percent_2' : [float(r2['fraction'] * 100)], 'Percent_3' : [float(r3['fraction'] * 100)]})
        report = pandas.concat([report, new_line], ignore_index = True)  # Replaces the depreciated method report.append(new_line)
    if not args.no_sort:
        report = report.sort_values(by = ['Percent_1', 'Taxon_1'], ascending = [False, False])
    report.to_csv(args.out, float_format = '%.3f', sep = '\t', header = True, index = False)  # float_format does not work on pandas v1.4.0+.
    return

def parse_sample_names(inputs, suffix):
    bracken_reports = {}
    for tsv in inputs:
        if (os.path.exists(tsv)):
            isolate = os.path.basename(tsv)[ : -len(suffix)]
            bracken_reports[isolate] = tsv
        else:
            print("Error: input TSV file " + tsv + " is not found.", file = sys.stderr)
            sys.exit(1)
    return bracken_reports

def read_bracken_report(f):
    """ Return the top-three taxa and their read fractions of the current sample """
    bracken = pandas.read_csv(f, sep = '\t')
    bracken = bracken[['name', 'fraction_total_reads']]  # Predefined columns in the bracken report
    bracken.columns = ['taxon', 'fraction']
    bracken = bracken.sort_values(by = 'fraction', ascending = False).reset_index(drop = True)
    bracken = bracken.loc[0 : 2]
    return bracken

if __name__ == '__main__':
    main()