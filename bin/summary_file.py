#!/bin/python3

import os
import sys
import logging
import argparse

logging.basicConfig(level = logging.DEBUG, format = '%(levelname)s : %(message)s')

def summarize_output(report, output_file, sample_name):

    header = 'Number of BLAST hits'

    with open(report, 'r') as inp, open(output_file, 'w') as out:

        out.write('sample\tIsolate name\tNumber of BLAST hits\tNumber of clusters\tPredicted emm-type\tPosition(s)\tPossible emm-like alleles\temm-like position(s)\tEMM cluster\n')
        lines = inp.readlines()

        for each_line in lines:
            logging.debug(f"Processing line: {each_line}")
            if header in each_line:
                pass
            else:
                out.write(sample_name + '\t' + each_line)

class SummaryScript(argparse.ArgumentParser):

    def error(self, message):
        self.print_help()
        sys.stderr.write(f'\nERROR DETECTED: {message}\n')

        sys.exit(1)

if __name__ == "__main__":
    parser = SummaryScript(prog = 'Transcribes emmtype results',
        description='A script to summarize emmtype',
        epilog='Use with summary_file.py '
        )
    parser.add_argument('-t', '--txt_file',
        help='Should be txt file: ${prefix}_emmtyper.txt'
        )
    parser.add_argument('-o', '--output_file',
        help='Location to output results: emmtyper/${prefix}'
        )
    parser.add_argument('-s', '--sample_name',
        help='This is supplied by the nextflow config and can be changed via the usual methods i.e. command line.'
        )

    logging.debug("Run parser to call arguments downstream")
    args = parser.parse_args()

    logging.info("Summarizing emmtype results")
    if not os.path.exists(args.txt_file):
        logging.error(f"File {args.txt_file} does not exist. Exiting.")
        sys.exit(1)

    summarize_output(args.txt_file, args.output_file, args.sample_name)
