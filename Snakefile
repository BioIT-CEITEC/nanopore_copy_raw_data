from pathlib import Path
import os
import glob
configfile: "config.json"

# BARCODED / NON BARCODED
library_name = list(config["libraries"].keys())[0]
RUN_DIR = config["run_dir"]
sample_hashes = list(config["libraries"][library_name]["samples"].keys())

sample_names = []

for sample in sample_hashes:
    sample_name = config["libraries"][library_name]["samples"][sample]["sample_name"]
    sample_names.append(sample_name)

# # Extract sample names
# sample_names = []
# libraries = config.get("libraries", {})
# for library in libraries.values():
#     samples = library.get("samples", {})
#     for sample in samples.values():
#         sample_name = sample.get("sample_name")
#         if sample_name:
#             sample_names.append(sample_name)

# barcode_flag = config["libraries"][library_name]["samples"][sample_names[0]]["i7_name"]
barcode_flag = config["libraries"][library_name]["samples"][sample_hashes[0]]["i7_name"]
print(barcode_flag)

if(barcode_flag == "NON_BARCODED"):
    is_barcoded = False
else:
    raise Exception("Not implemented yet")

rule all:
    input:
        expand("{library_name}/outputs/{sample_name}/nanopore_run_report.json", sample_name = sample_names, library_name = library_name)

# # IF NON-BARCODED 
# rule merge_samples_pass_files:
#     input: "{library_name}/{sample_name}/{flowcell}/pod5_pass/*.pod5"
#     output: "{library_name}/outputs/{sample_name}/reads_merged.pod5"
#     conda: "pod5_merge.yaml"
#     shell: "pod5 merge {input} --output {output}"

def list_pod5s_per_sample(run_dir, sample_name):
    search_pattern = os.path.join(run_dir, sample_name, "20*", "pod5_pass", "*.pod5")
    matched_files = glob.glob(search_pattern)
    return(matched_files)

rule mv_NON_BARCODED:
    input: pod5s = lambda wildcards: list_pod5s_per_sample(wildcards.RUN_DIR, wildcards.)
    output: report = expand("{library_name}/outputs/{sample_name}/nanopore_run_report.json", sample_name = sample_names, library_name = library_name),
            pod5_merged = expand("{library_name}/outputs/{sample_name}/reads_merged.pod5", sample_name = sample_names, library_name = library_name)
    params: original_folder = expand(os.path.join(RUN_DIR, "{first_sample}/{flowcell}"), first_sample = sample_names[0], flowcell = os.listdir(os.getcwd())[1])
    conda: "pod5_merge.yaml"
    shell:
        """
        mkdir {params.library_dir};
        cp original_folder/report_*.json {output.report};
        pod5 merge {input.pod5s} --output {output.pod5_merged}
        """

# rule mv_BARCODED:
#     output: expand("{library_name}/nanopore_run_report.json", library_name = list(config["libraries"].keys())[0])
#     params: run_dir=config["run_dir"],
#             library_dir= list(config["libraries"].keys())[0]
#     shell:
#         """
#         mkdir {params.library_dir};
#         cp {params.run_dir}/report_*.json {output};
#         mv {params.run_dir}/*5_pass "{params.library_dir}"
#         """
