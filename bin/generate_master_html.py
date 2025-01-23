#!/usr/bin/env python

"""Generate a master html template."""

import os
import re
import argparse
import pandas as pd
from jinja2 import Template
from datetime import datetime

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

args = parser.parse_args()

def get_date_id(samplesheet_csv_fpath):
    date_ids = []
    parent_dir = os.path.dirname(samplesheet_csv_fpath)
    pipeline_info_dir = os.path.join(parent_dir, 'pipeline_info')
    for filename in os.listdir(pipeline_info_dir):
        if filename.startswith("execution_report"):
            execution_report_fpath = os.path.join(pipeline_info_dir, filename)
            date_id = find_date_in_string(execution_report_fpath, r'(\d{4}-\d{2}-\d{2}[^.]+)')
            date_ids.append(date_id)
    date_list = map(find_date_in_string, date_ids, [r'\b(\d{4}-\d{2}-\d{2})']*len(date_ids))
    date_id_zipped = list(zip(date_ids, date_list))
    sorted_date_ids = [date_id[0] for date_id in sorted(date_id_zipped, key=lambda date: datetime.strptime(date[1], "%Y-%m-%d"), reverse=True)]    
    return sorted_date_ids[0]

def find_date_in_string(input_string, date_pattern):
    """Searches for a date within a given string."""
    date = ""
    match = re.search(date_pattern, input_string)
    if match:
        date_regex = match.group(1)
        if len(date_regex) == 8:
            date = datetime.strptime(date_regex, "%Y%m%d").strftime("%d-%m-%Y")
        elif len(date_regex) > 8:
            date = date_regex
        else:
            date = "(No date found)"
    return date

def get_sample_ids(samplesheet_csv):
    """Get sample id from csv."""
    df = pd.read_csv(samplesheet_csv)
    sample_ids = df['sample'].tolist()
    return sample_ids

def generate_master_html(template_html_fpath, sample_ids, seqrun_date, date_id):
    """Read the template from an HTML file."""
    with open(template_html_fpath, "r") as file:
        master_template = file.read()
    template = Template(master_template)
    rendered_html = template.render(sample_ids=sample_ids, seqrun_date=seqrun_date, date_id=date_id)
    return rendered_html

def main():
    sample_ids = get_sample_ids(args.csv)
    seqrun_date = find_date_in_string(args.csv, r'/(\d{8})_')
    date_id = get_date_id(args.csv)
    rendered_html = generate_master_html(args.html, sample_ids, seqrun_date, date_id)
    with open("master.html", "w") as fout:
        fout.write(rendered_html)

if __name__ == "__main__":
    main()
