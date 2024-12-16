#!/usr/bin/env python

"""Generate a master html template."""

import argparse
import pandas as pd
from jinja2 import Template

description = '''
------------------------
Title: generate_master_html.py
Date: 2024-12-16
Author(s): Ryan Kennedy
------------------------
Description:
    This script creates master html file that points to all html files that were outputted from EMU.

List of functions:
    get_sample_ids, generate_master_html.

List of standard modules:
    csv, os, argparse.

List of "non standard" modules:
    pandas, jinja2.

Procedure:
    1. Get sample IDs by parsing samplesheet csv.
    2. Render html using template.
    3. Write out master.html file.

-----------------------------------------------------------------------------------------------------------
'''

usage = '''
-----------------------------------------------------------------------------------------------------------
Generates master html file that points to all html files.
Executed using: python3 ./generate_master_html.py -i <Input_Directory> -o <Output_Filepath>
-----------------------------------------------------------------------------------------------------------
'''

parser = argparse.ArgumentParser(
                description=description,
                formatter_class=argparse.RawDescriptionHelpFormatter,
                epilog=usage
                )
parser.add_argument(
    '-v', '--version',
    action='version',
    version='%(prog)s 0.0.1'
    )
parser.add_argument(
    '-c', '--csv',
    help='input samplesheet csv filepath',
    metavar='SAMPLESHEET_CSV_FILEPATH',
    dest='csv',
    required=True
    )
parser.add_argument(
    '-m', '--html',
    help='input master html template filepath',
    metavar='MASTER_HTML_TEMPLATE_FILEPATH',
    dest='html',
    required=True
    )
parser.add_argument(
    '-i',
    help='input directory',
    metavar='INPUT_DIRECTORY',
    dest='input',
    required=True
    )

args = parser.parse_args()

def get_sample_ids(samplesheet_csv):
    df = pd.read_csv(samplesheet_csv)
    sample_ids = df['sample'].tolist()
    return sample_ids

def generate_master_html(template_html_fpath, sample_ids):
    # Read the template from an HTML file
    with open(template_html_fpath, "r") as file:
        master_template = file.read()
    template = Template(master_template)
    rendered_html = template.render(sample_ids=sample_ids)
    return rendered_html

def main():
    sample_ids = get_sample_ids(args.csv)
    rendered_html = generate_master_html(args.html, sample_ids)
    with open("master.html", "w") as fout:
        fout.write(rendered_html)

if __name__ == "__main__":
    main()
