rule basecall:
    input:
        'all_reads/{reads_folder}'
    output:
        "basecalling_output/{reads_folder}/sequencing_summary.txt"

    shell:
        "./{guppy_version}/bin/guppy_basecaller --input_path all_reads/{wildcards.reads_folder} --save_path basecalling_output/{wildcards.reads_folder} --config ont-guppy-cpu/data/rna_r9.4.1_70bps_fast.cfg"


rule align:
    input:
        "basecalling_output/{experiment}/sequencing_summary.txt"
    output:
        "alignment_output/{experiment}/alignment_summary.txt"
    
    shell:
        "./{guppy_version}/bin/guppy_aligner --input_path basecalling_output/{wildcards.experiment}/ --save_path alignment_output/{wildcards.experiment}/ --align_ref {genome_path}"

