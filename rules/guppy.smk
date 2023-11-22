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
    input:
        #basecalling_done='outputs/basecalling/{experiment_name}/guppy/sequencing_summary.txt'
        'outputs/basecalling/{experiment_name}/guppy/sequencing_summary.txt'

    output:
        "outputs/basecalling/{experiment_name}/guppy/reads.fastq"
    conda:
        "../envs/merge_fastq.yaml"
    shell:
        """
        if [ -d outputs/basecalling/{wildcards.experiment_name}/guppy/pass ]; then cat outputs/basecalling/{wildcards.experiment_name}/guppy/pass/fastq_runid*.fastq > {output}; \
        else cat outputs/basecalling/{wildcards.experiment_name}/guppy/fastq_runid*.fastq > {output}; fi
        """

""" 
if [ -d "outputs/basecalling/reads/guppy/pass" ]; then cat "outputs/basecalling/reads/guppy/pass/fastq_runid*.fastq" > "outputs/basecalling/reads/guppy/reads.fastq"; \
else cat outputs/basecalling/reads/guppy/fastq_runid*.fastq > "outputs/basecalling/reads/guppy/reads.fastq"; fi 
"""

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
			| samtools view -bh - \
			| samtools sort --threads {threads} \
			> {output.bam}  
		samtools index {output.bam}
		"""   


rule SV_calling:
    input: 
        bam = 'outputs/alignment/{experiment_name}/minimap2/reads-align.genome.sorted.bam'
    output:
        "outputs/sv_calling/{experiment_name}/variants.vcf"
    params: reference_path = config["reference_path"]
    conda: 
        "../envs/svim_environment.yaml"
    #script: "../wrappers/SV_calling/script.py"
    shell:
        """
        svim alignment outputs/sv_calling/{wildcards.experiment_name} {input.bam} {params.reference_path} 
        """

# svim alignment outputs/sv_calling/reads 'outputs/alignment/reads/minimap2/reads-align.genome.sorted.bam' "references/chr17.fas"
# sniffles --input 'outputs/alignment/reads/minimap2/reads-align.genome.sorted.bam' -v "outputs/sv_calling/reads/variants.vcf"