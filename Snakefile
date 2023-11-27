from pathlib import Path

include: "rules/guppy.smk"

def get_libraries():
    return [path.stem for path in Path('data').iterdir()]

rule all:
    input:
        #expand('outputs/alignment/{folder}/minimap2/reads-align.genome.sorted.bam.bai', folder = config["experiment_folders"])
        # expand( "outputs/sv_calling/{folder}/variants.vcf", folder = config["experiment_folders"])
        #TODO folder is not the right expand!! We want experiment name, not library name
        expand("outputs/basecalling/{library_name}/guppy/sequencing_summary.txt", library_name = get_libraries())

