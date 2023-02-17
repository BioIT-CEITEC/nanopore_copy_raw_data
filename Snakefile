configfile: "config.json"
genome_path = config['reference_genome_path']
guppy_version = 'ont-guppy-cpu'
file_name = config['file_name']


rule all:
    input: expand("alignment_output/{rf}/alignment_summary.txt", rf=[file_name])


include: "rules/guppy.smk"


