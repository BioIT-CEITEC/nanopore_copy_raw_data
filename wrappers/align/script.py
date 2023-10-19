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
experiment = str(snakemake.wildcards.experiment)
command = "./"+str(snakemake.params.guppy_version)+\
        "/bin/guppy_aligner"+\
        " --input_path basecalling_output/"+ experiment+\
        " --save_path alignment_output/"+ experiment+\
        " --align_ref " + str(snakemake.params.genome_path) 

shell(command)
shell("samtools view -b -S alignment_output/{experiment}/*.sam > alignment.bam")
shell("samtools sort 'alignment_output/{experiment}/alignment.bam' -o 'alignment_output/{experiment}/alignment_sorted.bam'")
shell("samtools index 'alignment_output/{experiment}/alignment_sorted.bam'")


