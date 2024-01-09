from pathlib import Path
configfile: "config.json"
#GLOBAL_REF_PATH = config["globalResources"] #TODO repair this
GLOBAL_REF_PATH = "/mnt/share/share/710000-CEITEC/713000-cmm/713016-bioit/base/references_backup/"
#Reference processing

# if config["libraries"][0]["lib_ROI"] != "wgs":
#     # setting reference from lib_ROI
#     f = open(os.path.join(GLOBAL_REF_PATH,"reference_info","lib_ROI.json"))
#     lib_ROI_dict = json.load(f)
#     f.close()
#     config["reference"] = [ref_name for ref_name in lib_ROI_dict.keys() if isinstance(lib_ROI_dict[ref_name],dict) and config["lib_ROI"] in lib_ROI_dict[ref_name].keys()][0]

# # setting organism from reference
# f = open(os.path.join(GLOBAL_REF_PATH,"reference_info","reference2.json"),)
# reference_dict = json.load(f)
# f.close()
# config["species_name"] = [organism_name for organism_name in reference_dict.keys() if isinstance(reference_dict[organism_name],dict) and config["reference"] in reference_dict[organism_name].keys()][0]
# config["organism"] = config["species_name"].split(" (")[0].lower().replace(" ","_")
# if len(config["species_name"].split(" (")) > 1:
#     config["species"] = config["species_name"].split(" (")[1].replace(")","")


##### Config processing #####
# Folders

#reference_directory = os.path.join(GLOBAL_REF_PATH,config["organism"],config["reference"])
ref_type = list(config["libraries"].values())[0]["reference"]
reference_path = os.path.join(GLOBAL_REF_PATH, "homo_sapiens", ref_type, "seq", ref_type, ".fa")

include: "rules/guppy.smk"

rule all:
    input:
        #expand('outputs/alignment/{folder}/minimap2/reads-align.genome.sorted.bam.bai', folder = config["experiment_folders"])
        # expand( "outputs/sv_calling/{folder}/variants.vcf", folder = config["experiment_folders"])
        #TODO folder is not the right expand!! We want experiment name, not library name
        expand("outputs/basecalling/{library_name}/guppy/sequencing_summary.txt", library_name = config["run_dir"])

