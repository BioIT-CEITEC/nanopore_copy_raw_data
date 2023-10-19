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

command = f"svim alignment SV_calling_output alignment_output/{experiment}/alignment_sorted.bam {genome}" 

# svim alignment SV_calling_output alignment_output/reads/alignment_sorted.bam "/home/lucka/nanopore_workflows/all_reads/chr17.fas"
# command vys funguje 

shell(command)

