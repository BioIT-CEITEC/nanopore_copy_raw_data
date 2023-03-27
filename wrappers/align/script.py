#########################################
# wrapper for rule: align
#########################################
import os
import sys
import math
import subprocess
import re
from snakemake.shell import shell

shell.executable("/bin/bash")
#TODO logging
command = "./"+str(snakemake.params.guppy_version)+\
        "/bin/guppy_aligner"+\
        " --input_path basecalling_output/"+ str(snakemake.wildcards.experiment)+"/pass"+\
        " --save_path alignment_output/"+str(snakemake.wildcards.experiment)+\
        " --align_ref " + str(snakemake.params.genome_path) 

shell(command)


