#########################################
# wrapper for rule: SV_calling
#########################################
import os
import sys
import math
import subprocess
import re
from snakemake.shell import shell

# Installing new environment with: 
# conda create -n svim_env --channel bioconda svim

shell.executable("/bin/bash")
#TODO logging

command = "svim alignment SV_calling_output" + \ 
"alignment_output/{experiment}/fastq_runid_2fdae66b28c95c27857e236709f82e78094d4aac_0_0.sam" 

#  SVIM.py alignment [options] working_dir bam_file
# svim alignment --help
shell(command)

