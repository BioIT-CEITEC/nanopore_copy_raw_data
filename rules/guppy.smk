rule basecall:
    input:
        'all_reads/{reads_folder}'
    output:
        "basecalling_output/{reads_folder}/sequencing_summary.txt"
    params: quality = quality,
            bps = bps,
            data_type = data_type,
            guppy_version = guppy_version,
            flowcell = flowcell,
            basecaller = basecaller
    script: "../wrappers/basecall/script.py"

rule align:
    input:
        "basecalling_output/{experiment}/sequencing_summary.txt"
    output:
        "alignment_output/{experiment}/alignment_summary.txt"
    params: genome_path = genome_path,
            guppy_version = guppy_version
    script: "../wrappers/align/script.py"

rule SV_calling:
    input: # SAM, BAM file
        "alignment_output/{experiment}/alignment_summary.txt" # different name, change!!
    output:
        "SV_calling_output/{experiment}/variants.vcf"
    params: genome_path = genome_path
    conda: 
        "svim_env" # installed with conda create -n svim_env --channel bioconda svim
    script: "../wrappers/SV_calling/script.py"
