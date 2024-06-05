from pathlib import Path
import os
import glob
configfile: "config.json"

# BARCODED / NON BARCODED
library_name = list(config["libraries"].keys())[0]
RUN_DIR = config["run_dir"]
sample_hashes = list(config["libraries"][library_name]["samples"].keys())

# Same for Barcoded and non barcoded 
#TO DO can we have more libraries
sample_names = []
for sample in sample_hashes:
    sample_name = config["libraries"][library_name]["samples"][sample]["sample_name"]
    sample_names.append(sample_name)

barcode_flag = config["libraries"][library_name]["samples"][sample_hashes[0]]["i7_name"]
print(barcode_flag)

if(barcode_flag == "NON_BARCODED"):
    is_barcoded = False
else:
    raise Exception("Not implemented yet")

rule all:
    input:
        expand("{run_dir}/outputs/{sample_name}/reads_merged.pod5", run_dir=RUN_DIR, sample_name='L0728'),
        expand("{run_dir}/outputs/{sample_name}/nanopore_run_report.json", run_dir=RUN_DIR, sample_name='L0728')

def list_pod5s_per_sample(run_dir, sample_name):
    search_pattern = os.path.join(run_dir, sample_name, "*", "pod5_pass", "*.pod5")
    matched_files = glob.glob(search_pattern)
    print('MATCHED', matched_files)
    return(matched_files)

# merge pod5s from one sample and all flowcells in the sample folder 
rule pod5merge:
    input: pod5s = lambda wildcards: list_pod5s_per_sample(wildcards.run_dir, wildcards.sample_name)
    output: pod5_merged = "{run_dir}/outputs/{sample_name}/reads_merged.pod5"
    # params: report_path = expand(os.path.join(RUN_DIR, "{first_sample}/{flowcell}"), first_sample = sample_names[0], flowcell = os.listdir(os.path.join(library_name, sample_names[0]))[1])
    #         library_name = library_name
    conda: "envs/pod5_merge.yaml"
    shell:
        """
        pod5 merge {input.pod5s} --output {output.pod5_merged}
        """

def get_sample_report_path(run_dir, sample_name):
    search_pattern = os.path.join(run_dir, sample_name, "*", "report*.json")
    matched_files = glob.glob(search_pattern)
    print(matched_files)
    return matched_files[0] #Takes the first flowcell only, assuming the flowcell type and kit is the same between all of them

rule copy_report:
    input: lambda wildcards: get_sample_report_path(wildcards.run_dir, wildcards.sample_name)
    output: "{run_dir}/outputs/{sample_name}/nanopore_run_report.json"
    shell:
        "cp {input} {output}"
        


# merge same barcodes between flowcells, name as sample_names, not barcode1
# rule mv_BARCODED:
#     output: report = expand("{library_name}/outputs/{sample_name}/nanopore_run_report.json", sample_name = sample_names, library_name = library_name),
#     params: library_name = library_name,
#             report_path = expand(os.path.join(RUN_DIR, "{flowcell}/{first_sample}"), first_sample = sample_names[0], flowcell = os.listdir(library_name))[1])
#     shell:
#         """
#         mkdir {params.library_name};
#         cp {params.report_path}/report_*.json {output.report};
#         mv {params.run_dir}/*5_pass "{params.library_dir}"
#         """
