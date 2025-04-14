from pod5 import Reader
import pandas as pd
import json
import os
import glob

directory = os.path.dirname(snakemake.output[0])
os.makedirs(directory, exist_ok=True)
hash_to_count = {}
for hash, sample_name in zip(snakemake.params.sample_tab.sample_ID, snakemake.params.sample_tab.sample_name):
    sample_dir = os.path.join(snakemake.params.library_path_name, "raw_reads", sample_name)
    pod5_files = glob.glob(os.path.join(sample_dir, "*.pod5"))
    
    total_reads = 0
    for pod5_file in pod5_files:
        if os.path.exists(pod5_file) and os.stat(pod5_file).st_size > 0:
            num_reads = Reader(pod5_file).num_reads
            if num_reads >= 50:
                total_reads += num_reads
    
    hash_to_count[sample_hash] = total_reads
    
with open(snakemake.output[0], 'w') as file:
    json.dump(hash_to_count, file)