from pathlib import Path
import os
import glob
configfile: "config.json"
import pandas as pd

##### Config processing #####

# BARCODED / NON BARCODED
# TODO can be more libraries? 
library_tag = list(config["libraries"].keys())[0] # the original one
library_name_wrong = config["libraries"][library_tag]["library_name_wrong"]

##### Sample table creation #####
def get_panda_sample_tab_from_config_one_lib(lib_name):
    lib_config = config["libraries"][lib_name]
    sample_tab = pd.DataFrame.from_dict(lib_config["samples"], orient="index")
    sample_tab["library"] = lib_name

    sample_tab['sample_ID'] = sample_tab.index.astype(str)
    sample_tab['sample_name_full'] = sample_tab['sample_name'] + '___' + sample_tab['sample_ID']
    return sample_tab

sample_tab = get_panda_sample_tab_from_config_one_lib(library_tag)

# change library name
if library_name_wrong:
    library_path_name = config["libraries"][library_tag]["library_name"]
else: 
    library_path_name = library_tag

RUN_DIR = config["run_dir"]

wildcard_constraints:
    sample_name = "|".join(sample_tab.sample_name)

sample_to_i7 = dict(zip(sample_tab.sample_name, sample_tab.i7_name))

#TODO easier create the 
# for sample_hash in sample_tab.sample_ID:
#     sample_name = config["libraries"][library_name]["samples"][sample_hash]["sample_name"]
#     hash_to_path[sample_hash]=os.path.join(library_name, "raw_reads", sample_name, sample_name + ".pod5") #TODO add {library_name} when copy to copy_raw_data

barcode_flag = sample_tab.i7_name[0]

if barcode_flag == "NON_BARCODED":
    is_barcoded = False
else:
    is_barcoded = True
    # takes the library name without the ID prefix
    RUN_DIR += "/" + library_path_name.split('_', 1)[1]

print(RUN_DIR)

def list_pod5s_per_sample(run_dir, sample_name):
    if is_barcoded:
        search_pattern_old = os.path.join(run_dir, "*", "pod5_pass", sample_to_i7[sample_name], "*.pod5")
        search_pattern_new = os.path.join(run_dir, "*", "pod5", sample_to_i7[sample_name], "*.pod5")
    else:
        search_pattern_old = os.path.join(run_dir, sample_name, "*", "pod5_pass", "*.pod5")
        search_pattern_new = os.path.join(run_dir, sample_name, "*", "pod5", "*.pod5")
    matched_files = glob.glob(search_pattern_old) + glob.glob(search_pattern_new)
    print(matched_files)
    return matched_files 

rule all:
    input:
        expand("{library_path_name}/raw_reads/{sample_name}/{sample_name}.pod5", library_path_name=library_path_name, sample_name=sample_tab.sample_name),
        #expand("{library_path_name}/run_report/{sample_name}/{sample_name}_report.json", library_path_name=library_path_name, sample_name=sample_tab.sample_name),
        expand("{library_path_name}/sequencing_run_info/samplesNumberReads.json", library_path_name=library_path_name)

# merge pod5s from one sample and all flowcells in the sample folder 
rule pod5merge:
    input: pod5s = lambda wildcards: list_pod5s_per_sample(RUN_DIR, wildcards.sample_name)
    output: pod5_merged = "{library_path_name}/raw_reads/{sample_name}/{sample_name}.pod5"
    params:
        empty_input=lambda wildcards, input: len(input.pod5s),
        new_dir="{library_path_name}/raw_reads/{sample_name}"
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
    input: pod5_merged = expand("{library_path_name}/raw_reads/{sample_name}/{sample_name}.pod5", library_path_name = library_path_name, sample_name = sample_tab.sample_name)
    output: "{library_path_name}/sequencing_run_info/samplesNumberReads.json"
    params: sample_tab = sample_tab,
        library_path_name = library_path_name
    conda: "envs/pod5_merge.yaml"
    script: "wrappers/createSamplesNumberReads.py"

# def get_sample_report_path(run_dir, sample_name):
#     if(is_barcoded):
#         search_pattern = os.path.join(run_dir, "*", "report*.json")
#     else:
#         search_pattern = os.path.join(run_dir, sample_name, "*", "report*.json")

#     matched_files = glob.glob(search_pattern)
#     return matched_files[0] #Takes the first flowcell only, assuming the flowcell type and kit is the same between all of them

# rule copy_report:
#     input: lambda wildcards: get_sample_report_path(RUN_DIR, wildcards.sample_name)
#     output: "{library_path_name}/run_report/{sample_name}/{sample_name}_report.json"
#     shell:
#         "cp {input} {output}"