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
genome = str(snakemake.params.genome_path)
experiment = str(snakemake.wildcards.experiment)

command = f"svim alignment SV_calling_output/{experiment} alignment_output/{experiment}/alignment_sorted.bam {genome}" 

shell(command)

