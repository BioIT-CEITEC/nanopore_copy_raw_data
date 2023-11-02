configfile: "config.json"

include: "rules/guppy.smk"

rule all:
    input:
        #expand('outputs/alignment/{folder}/minimap2/reads-align.genome.sorted.bam.bai', folder = config["experiment_folders"])
        expand( "outputs/sv_calling/{folder}/variants.vcf", folder = config["experiment_folders"])


