import json
import glob
import os

# TODO incorporate dorado
# https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.4.1-linux-x64.tar.gz
#TODO add option to copy fastq files from online basecalling,
#TODO add option to download cpu vs gpu version of guppy,

def get_exp_info(library_name):
    pattern = os.path.join(library_name, 'report_*.json')
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

# TODO extrahovat do params 
rule download_basecaller_tar:
    output: '/tmp/ont-guppy-cpu_6.4.6_linux64.tar.gz'
    shell:
        f"""
        wget -P {GLOBAL_TMPD_PATH} https://cdn.oxfordnanoportal.com/software/analysis/ont-guppy-cpu_6.4.6_linux64.tar.gz
        """

# wget -P /tmp https://cdn.oxfordnanoportal.com/software/analysis/ont-guppy-cpu_6.4.6_linux64.tar.gz
# tar -xf /tmp/ont-guppy-cpu_6.4.6_linux64.tar.gz /tmp/ont-guppy/
        
rule extract_basecaller:
    input:'/tmp/ont-guppy-cpu_6.4.6_linux64.tar.gz'
    output: basecaller_location
    # params: extract_path = f"{GLOBAL_TMPD_PATH}/ont-guppy/"
    shell:
        """
        cd /tmp ;
        tar -xf {input}
        """


rule basecalling:
    input: 
        #TODO take only pass?
        library_path = config["run_dir"] + "/fast5_pass",
        #TODO generalize to cpu or gpu
        basecaller_location = basecaller_location,
    output:
        'outputs/basecalling/{library_name}/guppy/sequencing_summary.txt'
    params:
        #exp_info = get_exp_info(wildcards.library_name)
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
            --num_callers {threads} \
            --chunks_per_runner 512 \
            --calib_detect \
            --input_path {input.library_path} \
            -q 0 \
            2>&1; \
        """

        # """
        # {input.basecaller_location} \
        #     --flowcell {params.flowcell} \
        #     --kit {params.kit} \
        #     --records_per_fastq 0 \
        #     --trim_strategy none \
        #     --save_path {params.save_path} \
        #     --recursive \
        #     --gpu_runners_per_device 1 \
        #     --num_callers {threads} \
        #     --chunks_per_runner 512 \
        #     --calib_detect \
        #     --input_path {input.library_path} \
        #     2>&1; \
        # """

rule merge_fastq_files:
    input:
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

# def get_reference():
#     files = glob.glob('references/*.fa*')
#     assert len(files) == 1, 'Number of found references !=1'
#     return files[0]

from pathlib import Path
assert Path(reference_path).exists()

rule align_to_genome:
    input:
        reads="outputs/basecalling/{library_name}/guppy/reads.fastq"
    params: 
        reference_path = reference_path
    output:
        bam = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.bam',
        bai = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.bam.bai',
        #sam = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.sam',
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
			| samtools view -bh -\
			| samtools sort --threads {threads} \
			> {output.bam}  
		samtools index {output.bam}
		"""
  

        #samtools view -h -o {output.sam} {output.bam}
        # samtools view -h -o 'outputs/alignment/20220609_1405_MN16014_ais607_4d08b843/minimap2a/reads-align.genome.sorted.sam' 'outputs/alignment/20220609_1405_MN16014_ais607_4d08b843/minimap2a/reads-align.genome.sorted.bam'


# minimap2 -x splice -a -t 30 -u b -p 1 --secondary=no /mnt/share/share/710000-CEITEC/713000-cmm/713016-bioit/base/references_backup/homo_sapiens/GRCh38-p10/seq/GRCh38-p10.fa outputs/basecalling/20220609_1405_MN16014_ais607_4d08b843/guppy/reads.fastq | samtools view -bh - | samtools sort --threads 30 > outputs/alignment/20220609_1405_MN16014_ais607_4d08b843/minimap2/reads-align.genome.sorted.bam  
# samtools index outputs/alignment/20220609_1405_MN16014_ais607_4d08b843/minimap2/reads-align.genome.sorted.bam
# works in command line 

rule SV_calling:
    input: 
        bam = 'outputs/alignment/{library_name}/minimap2/reads-align.genome.sorted.bam'
    output:
        vcf = 'outputs/sv_calling/{library_name}/variants.vcf'
    params: reference_path = reference_path,
    conda: 
        "../envs/svim_environment.yaml"
    shell:
        """
        svim alignment outputs/sv_calling/{wildcards.library_name} {input.bam} {params.reference_path} 
        """

# svim alignment outputs/sv_calling/reads 'outputs/alignment/reads/minimap2/reads-align.genome.sorted.bam' "references/chr17.fas"
# sniffles --input 'outputs/alignment/reads/minimap2/reads-align.genome.sorted.bam' -v "outputs/sv_calling/reads/variants.vcf"