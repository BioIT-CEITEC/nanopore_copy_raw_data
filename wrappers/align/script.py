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

shell("ls alignment_output/{experiment}/*.sam | parallel 'samtools view -b {} > {.}.bam'") # to bam file
shell("ls alignment_output/{experiment}/*.bam | parallel 'samtools sort {} > {.}_sorted.bam'")
shell("ls alignment_output/{experiment}/*_sorted.bam | parallel 'samtools index {}'")

# Commands in my commandline
""" ls alignment_output/reads/*.sam | parallel 'samtools view -b {} > {.}.bam'
ls alignment_output/reads/*.bam | parallel 'samtools sort {} > {.}_sorted.bam'
ls alignment_output/reads/*_sorted.bam | parallel 'samtools index {}' """
