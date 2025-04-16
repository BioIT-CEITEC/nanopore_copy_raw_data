from pod5 import Reader
import pandas as pd
import json
import os
directory = os.path.dirname(snakemake.output[0])
os.makedirs(directory, exist_ok=True)
hash_to_count = {}
for hash, sample_name in zip(snakemake.params.sample_tab.sample_ID, snakemake.params.sample_tab.sample_name):
    path = os.path.join(snakemake.params.library_path_name, "raw_reads", sample_name, sample_name + ".pod5")
    print("Check for pod5 file")
    print(os.path.exists(path))
    if(os.stat(path).st_size == 0):
        hash_to_count[hash] = 0
    else:
        hash_to_count[hash] = Reader(path).num_reads
        # number of reads is not 0, but is small - change to 0
        if(hash_to_count[hash] < 50):
           hash_to_count[hash] = 0 
    
with open(snakemake.output[0], 'w') as file:
    json.dump(hash_to_count, file)