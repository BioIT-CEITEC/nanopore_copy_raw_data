<<<<<<< Updated upstream
rule basecall:
=======
# Download the guppy basecaller software
# Put your fast5 files into the data/<experiment_name>/ folder
# Put your genome reference into the references folder

# TODO incorporate dorado
# https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.4.1-linux-x64.tar.gz

rule basecalling:
    input: 
        experiment_path = 'data/{experiment_name}',
        basecaller_location = config['basecaller_location'],
    output:
        'outputs/basecalling/{experiment_name}/guppy/sequencing_summary.txt'
    params:
        kit = config['kit'],
        flowcell = config['flowcell'],
        save_path='outputs/basecalling/{experiment_name}/guppy/'
    threads: workflow.cores * 0.75
    resources: gpus=1
    shell:
        """
        {input.basecaller_location} \
            --flowcell {params.flowcell} \
            --kit {params.kit} \
            --records_per_fastq 0 \
            --trim_strategy none \
            --save_path {params.save_path} \
            --recursive \
            --gpu_runners_per_device 1 \
            --num_callers {threads} \
            --chunks_per_runner 512 \
            --calib_detect \
            --input_path {input.experiment_path} \
        """

# /usr/local/share/apps/ont-guppy-cpu/bin/guppy_basecaller --flowcell "FLO-MIN106" --kit "SQK-LSK108" --save_path outputs/basecalling/reads/guppy/ --input_path data/reads
      
rule merge_fastq_files:
>>>>>>> Stashed changes
    input:
        'all_reads/{reads_folder}'
    output:
<<<<<<< Updated upstream
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
=======
        "outputs/basecalling/{experiment_name}/guppy/reads.fastq"
    conda:
        "../envs/merge_fastq.yaml"
    shell:
        """
        if [ -d outputs/basecalling/{wildcards.experiment_name}/guppy/pass ]; then cat outputs/basecalling/{wildcards.experiment_name}/guppy/pass/fastq_runid*.fastq > {output}; \
        else cat outputs/basecalling/{wildcards.experiment_name}/guppy/fastq_runid*.fastq > {output}; fi
        """

#cat outputs/basecalling/reads/guppy/fastq_runid*.fastq > "outputs/basecalling/reads/guppy/reads.fastq"

rule align_to_genome:
    input:
        #reads="outputs/basecalling/{experiment_name}/guppy/reads.fastq.gz"
        reads="outputs/basecalling/{experiment_name}/guppy/reads.fastq"
    params: 
        reference_path = {config['reference_path']}
    output:
        bam = 'outputs/alignment/{experiment_name}/minimap2/reads-align.genome.sorted.bam',
        bai = 'outputs/alignment/{experiment_name}/minimap2/reads-align.genome.sorted.bam.bai',
    conda:
        "../envs/alignment.yaml"
    threads: 32
    shell:
        """
		minimap2 \
			-x splice \
			-a \
			-t {threads} \
			-u b \
			-p 1 \
			--secondary=no \
			{params.reference_path} \
			{input.reads} \
			| samtools view -b - \
			| samtools sort --threads {threads} \
			> {output.bam}  
		samtools index {output.bam}
		"""   
>>>>>>> Stashed changes


# rule SV_calling:
#     input: 
#         "outputs/alignment/{experiment_name}/minimap2/reads-align.genome.sorted.bam" 
#     output:
#         "outputs/sv_calling/{experiment_name}/variants.vcf"
#     params: reference_path = snakemake.params.reference_path
#     conda: 
#         "../envs/svim_environment.yaml"
#     #script: "../wrappers/SV_calling/script.py"
#     shell:
#         """
#         svim alignment outputs/sv_calling//{experiment_name} outputs/alignment/{experiment_name}/minimap2/reads-align.genome.sorted.bam {input.reference_path} 
#         """
