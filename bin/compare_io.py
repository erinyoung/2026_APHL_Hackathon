#!/usr/bin/python3.7

import argparse
import sys

import logging

import pandas as pd

logging.basicConfig(level = logging.INFO, format = '%(levelname)s : %(message)s')

def check_parsnp_file(parsnp_log_file, input_list):

	logging.debug("Creating empty list to hold samples that were not present in parsnp file")
	not_present_list = []

	with open (parsnp_log_file, "r") as input:

		logging.debug("Reading contents of file")
		results = input.read()

		logging.debug("Going through each sample name in input list")
		for sample in input_list:

			logging.debug("Checking to see if sample is in contents of parsnp results")
			if sample in results:
				pass
			else:
				not_present_list.append(sample)

	return not_present_list

class CompileResults(argparse.ArgumentParser):

    def error(self, message):
        self.print_help()
        sys.stderr.write(f'\nERROR DETECTED: {message}\n')

        sys.exit(1)

if __name__ == "__main__":

    parser = CompileResults(prog = 'Ensures proper number of samples exit parsnp',
        description = "Compares the samples input in the pipeline to the samples that exit parsnp.",
        epilog = "Usage: python3 compare_io.py <SAMPLESHEET_NUMBER> <LOG>"
        )
    parser.add_argument(
        "-s",
        "--sample_list",
		nargs="*",
		required=True,
        help="List of samples in the input file."
    )
    parser.add_argument(
        "-l",
        "--log_file",
		required=True,
        help="Aligner log output file to compare input samples to.",
    )

    logging.debug("Run parser to call arguments downstream")
    args = parser.parse_args()

    logging.debug("Splitting sample list into a list of individual sample names")
    string = ''.join(args.sample_list)
    filtered = string.strip("[]")
    total_list = filtered.split(",")

    logging.debug("Checking parsnp log file to see which samples were not present in the parsnp output")
    not_present_list = check_parsnp_file(args.log_file, total_list)

    logging.debug("Creating dataframe to hold sample names and whether they were present in parsnp output or not")
    df = pd.DataFrame({'Sample': total_list})
    df['excluded_from_analysis'] = df['Sample'].apply(lambda x: 'Yes' if x in not_present_list else 'No')
    df.to_csv('sample_exclusion_status.csv', index=False)
