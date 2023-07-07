#!/usr/bin/env python

"""
Author: Frans Wallin
Date: 20230707

Description: merge fastq.gz files present in barcode folders. Typically for nanopore. 

A samplesheet is needed.

"""

# Rest of your code goes here


if __name__ == "__main__":
    # Import regex package
    import re
    # Import package that allows you to make bash commands
    import subprocess
    # Import sys to allow CLI arguments
    import sys
    from os import path

    if len(sys.argv) == 4:
        # Flags to variables
        # samplesheet containing tqo tab separated columns. barcode sample_id
        sample_sheet = sys.argv[1]
        # outputfolder
        mapp = sys.argv[2]
        #your_path = sys.argv[3]
        # path to fastq_pass
        fastq_pass = sys.argv[3]
       # if mapp[-1] == "/":
       #     mapp = mapp[:-1]
       # if mapp[1] == "/":
       #     print("your output folder cannot start with /")
       #     sys.exit()
        # check if folder already exist
       # my_mapp = path.exists(f"{mapp}")
        # exit if folder exist
        #if my_mapp:
        #    print(f"dir {mapp} already exists. Exiting script")
        #    sys.exit()
        #if fastq_pass[-1] == "/":
         #   fastq_pass = fastq_pass[:-1]
       # if your_path[-1] == "/":
        #    your_path = your_path[:-1]
        # Open  sample sheet
        file = open(f"{sample_sheet}")
        file_1 = file.read()
        # Close sample sheet file. The file is now in a variable
        file.close()
        # Print the sample sheet
        print("Sample sheet: ", "\n", file_1)

        # Define the pattern to look for in the sample sheet file.
        #pattern = re.compile(r"(barcode\d+)\t([\w\-]+)\t(\w+)")
        pattern = re.compile(r"(barcode\d+)\t([\w\-]+)")
        # Extract the capture groups i.e. barcode, sample_id.
        captures = pattern.finditer(str(file_1))

        # # create the folder for appended files
        #command1 = 'mkdir -p ./%s || exit $?' % (mapp,)
        #out = subprocess.run(command1, shell=True).returncode
        #if out != 0:
        #    print("command did not work ", command1)
        #    sys.exit()

        # counter for number of samples
        counter = 0
        # execute the bash command such that each sample´s fastq.gz-files are appended to one file.
        for i in captures:
            barcode = i[1]
            sample_id = i[2]
            print(barcode, sample_id)
            command = 'cat %s/%s/*.fastq.gz > ./%s/%s.fastq.gz || exit $?' % (fastq_pass, barcode, mapp, sample_id,)
            out = subprocess.run(command, shell=True).returncode
            if out != 0:
                print("command did not work", command)
                sys.exit()
            print("Command used: ", command)
            counter = counter + 1
        #command = 'rsync -r -v ./%s/  %s  || exit $?; rm -r ./temporary_dir_sammanf  || exit $?' % (mapp, your_path,)
        #out = subprocess.run(command, shell=True).returncode
        #if out != 0:
        #    print("command did not work ", command)
        #    sys.exit()

        print("Number of samples found by script: ", counter)
    else:
        print("\n Usage:\n python <path to bin/merge_barcodes_samplesheet.py> <path to sample_sheet-file. Two columns. Barcode and sample id> <NAME of output directory > "
              "<PATH to fastq_pass directory> \n")
else:
    print("Error. Script is not main.")
    exit
print("end")


