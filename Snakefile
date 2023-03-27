configfile: "config.json"
genome_path = config['reference_genome_path']
guppy_version = config['guppy_version']
experiment_folders = config['experiment_folders']
data_type = config['data_type']
bps = config['bps']
quality = config['quality']
flowcell = config['flowcell']

rule all:
    input: expand("alignment_output/{folder}/alignment_summary.txt", folder=experiment_folders)


include: "rules/guppy.smk"


