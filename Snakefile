from pathlib import Path
configfile: "config.json"

rule all:
    input:
        expand("{library_name}/nanopore_run_report.json", library_name = list(config["libraries"].keys())[0])

rule mv:
    output: expand("{library_name}/nanopore_run_report.json", library_name = list(config["libraries"].keys())[0])
    params: run_dir=config["run_dir"],
            library_dir= list(config["libraries"].keys())[0]
    shell:
        """
        mkdir {params.library_dir};
        cp {params.run_dir}/report_*.json {output};
        mv {params.run_dir}/*5_pass "{params.library_dir}"
        """
