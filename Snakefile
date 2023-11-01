configfile: "config.json"
<<<<<<< Updated upstream
genome_path = config['genome_path']
guppy_version = config['guppy_version']
experiment_folders = config['experiment_folders']
data_type = config['data_type']
bps = config['bps']
quality = config['quality']
flowcell = config['flowcell']
basecaller = config['basecaller']
=======
>>>>>>> Stashed changes

""" rule all:
    input: expand("alignment_output/{folder}/alignment_summary.txt", folder=experiment_folders) """

rule all:
<<<<<<< Updated upstream
    #input: expand("SV_calling_output/{folder}/variants.vcf", folder=experiment_folders) # with SV
    input: expand("alignment_output/{folder}/alignment_summary.txt", folder=experiment_folders)
include: "rules/guppy.smk"
=======
    input:
        expand('outputs/alignment/{folder}/minimap2/reads-align.genome.sorted.bam.bai', folder = config["experiment_folders"])
        #expand('outputs/basecalling/{folder}/guppy/sequencing_summary.txt', folder = experiment_folders)

>>>>>>> Stashed changes
