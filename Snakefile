from pathlib import Path
import os
import glob
configfile: "config.json"

# BARCODED / NON BARCODED
# TODO can be more libraries? 
library_name = list(config["libraries"].keys())[0]
RUN_DIR = config["run_dir"]
sample_hashes = list(config["libraries"][library_name]["samples"].keys())

# Same for Barcoded and non barcoded 
#TO DO can we have more libraries
sample_names = []
sample_to_i7 = {}
for sample in sample_hashes:
    sample_name = config["libraries"][library_name]["samples"][sample]["sample_name"]
    sample_names.append(sample_name)
    sample_to_i7[sample_name] = config["libraries"][library_name]["samples"][sample]["i7_name"]

barcode_flag = config["libraries"][library_name]["samples"][sample_hashes[0]]["i7_name"]

if(barcode_flag == "NON_BARCODED"):
    is_barcoded = False
else:
    is_barcoded = True
    # takes the library name without the ID prefix
    RUN_DIR += "/" + library_name.split('_', 1)[1]

rule all:
    input:
        expand("{library_name}/outputs/{sample_name}/reads_merged.pod5", library_name=library_name, sample_name=sample_names),
        expand("{library_name}/outputs/{sample_name}/nanopore_run_report.json", library_name=library_name, sample_name=sample_names)

def list_pod5s_per_sample(run_dir, sample_name):
    if(is_barcoded):
        search_pattern = os.path.join(run_dir, "*", "pod5_pass", sample_to_i7[sample_name], "*.pod5")
    else:
        search_pattern = os.path.join(run_dir, sample_name, "*", "pod5_pass", "*.pod5")

    matched_files = glob.glob(search_pattern)
    return(matched_files)

# merge pod5s from one sample and all flowcells in the sample folder 
rule pod5merge:
    input: pod5s = lambda wildcards: list_pod5s_per_sample(RUN_DIR, wildcards.sample_name)
    output: pod5_merged = "{library_name}/outputs/{sample_name}/reads_merged.pod5"
    conda: "envs/pod5_merge.yaml"
    shell:
        """
        pod5 merge {input.pod5s} --output {output.pod5_merged}
        """

def get_sample_report_path(run_dir, sample_name):
    if(is_barcoded):
        search_pattern = os.path.join(run_dir, "*", "report*.json")
    else:
        search_pattern = os.path.join(run_dir, sample_name, "*", "report*.json")

    matched_files = glob.glob(search_pattern)
    return matched_files[0] #Takes the first flowcell only, assuming the flowcell type and kit is the same between all of them

rule copy_report:
    input: lambda wildcards: get_sample_report_path(RUN_DIR, wildcards.sample_name)
    output: "{library_name}/outputs/{sample_name}/nanopore_run_report.json"
    shell:
        "cp {input} {output}"
        