import json
import glob
import os
# Download the guppy basecaller software
# Put your fast5 files into the data/<experiment_name>/ folder
# Put your genome reference into the references folder

# TODO incorporate dorado
# https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.4.1-linux-x64.tar.gz
#TODO add option to copy fastq files from online basecalling,
#TODO add script to download cpu vs gpu version of guppy,

def get_exp_info(library_name):
    pattern = os.path.join('data', library_name, 'report_*.json')
    files = glob.glob(pattern)
    assert len(files) == 1, 'Number of configs found != 1'

    f = open(files[0])
    run_config = json.load(f)
    #TODO which one is right?
    # flowcell = run_config['protocol_run_info']['user_info']['user_specified_flow_cell_id']
    flowcell = run_config['protocol_run_info']['meta_info']['tags']['flow cell']['string_value']

    protocol_group_id = run_config['protocol_run_info']['user_info']['protocol_group_id']
    sample_id = run_config['protocol_run_info']['user_info']['sample_id']
    experiment_name = protocol_group_id+'_'+sample_id
    kit = run_config['protocol_run_info']['meta_info']['tags']['kit']['string_value']

    return {
        'flowcell':flowcell,
        'experiment_name':experiment_name,
        'library_name':library_name,
        'kit':kit,
        'save_path':'outputs/basecalling/'+library_name+'/guppy/',
    }

rule basecalling:
    input: 
        #TODO take only pass?
        library_path = 'data/{library_name}/fast5_pass',
        #TODO generalize to cpu or gpu
        basecaller_location = "basecallers/ont-guppy-cpu/bin/guppy_basecaller",
    output:
        'outputs/basecalling/{library_name}/guppy/sequencing_summary.txt'
    params:
        kit = lambda wildcards: get_exp_info(wildcards.library_name)['kit'],
        flowcell = lambda wildcards: get_exp_info(wildcards.library_name)['flowcell'],
        save_path = lambda wildcards: get_exp_info(wildcards.library_name)['save_path'],
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
            --input_path {input.library_path} \
        """

rule merge_fastq_files:
    input:
        #basecalling_done='outputs/basecalling/{library_name}/guppy/sequencing_summary.txt'
        'outputs/basecalling/{library_name}/guppy/sequencing_summary.txt'

    output:
        "outputs/basecalling/{library_name}/guppy/reads.fastq"
    conda:
        "../envs/merge_fastq.yaml"
    shell:
        """
        if [ -d outputs/basecalling/{wildcards.library_name}/guppy/pass ]; then cat outputs/basecalling/{wildcards.library_name}/guppy/pass/fastq_runid*.fastq > {output}; \
        else cat outputs/basecalling/{wildcards.library_name}/guppy/fastq_runid*.fastq > {output}; fi
        """

""" 
if [ -d "outputs/basecalling/reads/guppy/pass" ]; then cat "outputs/basecalling/reads/guppy/pass/fastq_runid*.fastq" > "outputs/basecalling/reads/guppy/reads.fastq"; \
else cat outputs/basecalling/reads/guppy/fastq_runid*.fastq > "outputs/basecalling/reads/guppy/reads.fastq"; fi 
"""

def get_reference():
    files = glob.glob('references/*.fa*')
    assert len(files) == 1, 'Number of found references !=1'
    return files[0]

rule align_to_genome:
    input:
        #reads="outputs/basecalling/{library_name}/guppy/reads.fastq.gz"
        reads="outputs/basecalling/{library_name}/guppy/reads.fastq"
    params: 
        reference_path = get_reference()
    output:
        bam = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.bam',
        bai = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.bam.bai',
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
        bam = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.bam'
    output:
        "outputs/sv_calling/{library_name}/variants.vcf"
    params: reference_path = get_reference(),
    conda: 
        "../envs/svim_environment.yaml"
    #script: "../wrappers/SV_calling/script.py"
    shell:
        """
        svim alignment outputs/sv_calling/{wildcards.library_name} {input.bam} {params.reference_path} 
        """

# svim alignment outputs/sv_calling/reads 'outputs/alignment/reads/minimap2/reads-align.genome.sorted.bam' "references/chr17.fas"
# sniffles --input 'outputs/alignment/reads/minimap2/reads-align.genome.sorted.bam' -v "outputs/sv_calling/reads/variants.vcf"