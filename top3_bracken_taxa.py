#!/usr/bin/env python
"""
Extract the top-three taxa and their read percentages from bracken's tsv-formatted output for each sample. The bracken reports must
be generated at the same level (such as 'S'), and each report must have at least three taxa.

Command:
    python top3_bracken_taxa.py -l [list of sample names] -d [directory of input bracken reports] -s [suffix of Bracken reports] -o [output file name]

Dependencies: Python 3, pandas, bracken v2.6+

Copyright (C) 2021 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public Licence version 3 (GPLv3) <https://www.gnu.org/licenses/>.
Creation: 7 Oct 2021; the latest update: 3 June 2022
"""

import os
import sys
import pandas
from argparse import ArgumentParser

def parse_argument():
    parser = ArgumentParser(description = "Extract top-three taxa and their read fractions for each sample from its TSV-format Bracken report")
    parser.add_argument('-l', '--list', dest = 'list', type = str, required = True, help = "A list of sample names; one name per line.")
    parser.add_argument('-d', '--dir', dest = 'dir', type = str, required = True, help = "Directory of input TSV-format Bracken reports")
    parser.add_argument('-s', '--suffix', dest = 'suffix', type = str, required = False, default = '_bracken.tsv', help = "Name of the reference sequence in the alignment")
    parser.add_argument('-o', '--out', dest = 'out', type = str, required = False, default = 'top3taxa.tsv', help = "Output filename and path")
    return parser.parse_args()

def main():
    args = parse_argument()
    samples = read_sample_names(args.list)
    report = pandas.DataFrame(columns = ['Sample', 'Taxon_1', 'Taxon_2', 'Taxon_3', 'Percent_1', 'Percent_2', 'Percent_3'])  # Initiate the output data frame
    for s in samples:
        bracken = read_bracken_report(os.path.join(args.dir, s + args.suffix))
        r1 = bracken.loc[0]  # Not use bracken.loc[0]['taxon'] or bracken.loc[0]['fraction'] to reduce the number of searching for indices.
        r2 = bracken.loc[1]
        r3 = bracken.loc[2]
        new_line = pandas.DataFrame({'Sample' : [s], 'Taxon_1' : [r1['taxon']], 'Taxon_2' : [r2['taxon']], 'Taxon_3' : [r3['taxon']],\
                                     'Percent_1' : [float(r1['fraction']) * 100], 'Percent_2' : [float(r2['fraction']) * 100],\
                                     'Percent_3' : [float(r3['fraction']) * 100]})
        report = pandas.concat([report, new_line])  # Replaces the depreciated method report.append(new_line)
    report.to_csv(args.out, header = True, index = False, sep = '\t', float_format = '%.2f')
    return

def read_sample_names(f):
    if (os.path.exists(f)):
        with open(f, 'r') as input_list:
            samples = input_list.read().splitlines()
    else:
        print("Error: input sample-name list " + f + " is not found.", file = sys.stderr)
        sys.exit(1)
    return samples

def read_bracken_report(f):
    """ Return the top-three taxa and their read fractions of the current sample """
    if (os.path.exists(f)):
        bracken = pandas.read_csv(f, sep = '\t')
        bracken = bracken[['name', 'fraction_total_reads']]  # Predefined columns in the bracken report
        bracken.columns = ['taxon', 'fraction']
        bracken = bracken.sort_values(by = 'fraction', ascending = False).reset_index(drop = True)
        bracken = bracken.loc[0 : 2]
    else:
        print("Error: Bracken report " + f + " is not found.", file = sys.stderr)
        sys.exit(1)
    return bracken

if __name__ == '__main__':
    main()