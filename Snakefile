from pathlib import Path
import os
import glob
configfile: "config.json"

##### BioRoot utilities #####
module BR:
    snakefile: gitlab("bioroots/bioroots_utilities", path="bioroots_utilities.smk",branch="master")
    config: config

use rule * from BR as other_*

##### Config processing #####

sample_tab = BR.load_sample()

wildcard_constraints:
    sample_name = "|".join(sample_tab.sample_name)

# BARCODED / NON BARCODED
# TODO can be more libraries? 
library_name = list(config["libraries"].keys())[0]
RUN_DIR = config["run_dir"]
sample_hashes = list(config["libraries"][library_name]["samples"].keys())

barcode_flag = config["libraries"][library_name]["samples"][sample_hashes[0]]["i7_name"]
#sample_names = []
sample_to_i7 = {}

# Creation of sample_names list for which we have the data
#TODO can we have more libraries
for sample in sample_tab.sample_name:
    sample_to_i7[sample] = config["libraries"][library_name]["samples"][sample]["i7_name"]

for sample_hash in sample_hashes:
    sample_name = config["samples"][sample_hash]["sample_name"]
    hash_to_path[sample_hash]=os.path.join(library_name, "raw_reads", sample_name, sample_name + ".pod5") #TODO add {library_name} when copy to copy_raw_data

if barcode_flag == "NON_BARCODED":
    is_barcoded = False
else:
    is_barcoded = True
    # takes the library name without the ID prefix
    RUN_DIR += "/" + library_name.split('_', 1)[1]

def list_pod5s_per_sample(run_dir, sample_name):
    if is_barcoded:
        search_pattern = os.path.join(run_dir, "*", "pod5_pass", sample_to_i7[sample_name], "*.pod5")
    else:
        search_pattern = os.path.join(run_dir, sample_name, "*", "pod5_pass", "*.pod5")
    matched_files = glob.glob(search_pattern)
    return matched_files

rule all:
    input:
        expand("{library_name}/raw_reads/{sample_name}/{sample_name}.pod5", library_name=library_name, sample_name=sample_tab.sample_name),
        expand("{library_name}/run_report/{sample_name}/{sample_name}_report.json", library_name=library_name, sample_name=sample_tab.sample_name),
        "sequencing_run_info/samplesNumberReads.json"

# merge pod5s from one sample and all flowcells in the sample folder 
rule pod5merge:
    input: pod5s = lambda wildcards: list_pod5s_per_sample(RUN_DIR, wildcards.sample_name)
    output: pod5_merged = "{library_name}/raw_reads/{sample_name}/{sample_name}.pod5"
    params:
        empty_input=lambda wildcards, input: len(input.pod5s),
        new_dir="{library_name}/raw_reads/{sample_name}"
    conda: "envs/pod5_merge.yaml"
    shell:
        """
        if [ {params.empty_input} -eq 0 ]; then
            mkdir -p {params.new_dir}
            touch {output.pod5_merged}
        else
            pod5 merge {input.pod5s} --output {output.pod5_merged}
        fi
        """

rule createSamplesNumberReads:
    input: pod5_merged = expand("raw_reads/{sample_name}/{sample_name}.pod5", sample_name = "test1")
    output: "sequencing_run_info/samplesNumberReads.json"
    params: hash_to_path = hash_to_path
    conda: "../envs/pod5_merge.yaml"
    script: "wrappers/createSamplesNumberReads.py"

def get_sample_report_path(run_dir, sample_name):
    if(is_barcoded):
        search_pattern = os.path.join(run_dir, "*", "report*.json")
    else:
        search_pattern = os.path.join(run_dir, sample_name, "*", "report*.json")

    matched_files = glob.glob(search_pattern)
    return matched_files[0] #Takes the first flowcell only, assuming the flowcell type and kit is the same between all of them

rule copy_report:
    input: lambda wildcards: get_sample_report_path(RUN_DIR, wildcards.sample_name)
    output: "{library_name}/run_report/{sample_name}/{sample_name}_report.json"
    shell:
        "cp {input} {output}"