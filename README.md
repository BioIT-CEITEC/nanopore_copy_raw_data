This is the first step of nanopore pipeline. 

## Workflow Logic
The pipeline follows these steps to resolve file paths:
Input Detection: 
- For Barcoded runs: It searches `RUN_DIR/*/pod5_pass/{barcode}/*.pod5` or `RUN_DIR/*/pod5/{barcode}/*.pod5`
- For Non-Barcoded runs: It searches `RUN_DIR/{sample_name}/*/pod5_pass/*.pod5` or `RUN_DIR/{sample_name}/*/pod5/*.pod5`
pod5 or pod5_pass is based on how new is the instrument

Merging (pod5merge):
- If 0 files are found: Touches an empty file.
- If 1 file is found: Performs a simple cp (copy).
- If multiple files are found: Uses **pod5 merge** to combine them.

Reporting: Runs a custom script to count reads and output metadata.

Output Structure
The results are organized into a structured directory named after the library_path_name defined in the config:
```plaintext
results/
└── {library_path_name}/
    ├── raw_reads/
    │   └── {sample_name}/
    │       └── {sample_name}.pod5      # The consolidated raw read file
    └── sequencing_run_info/
        └── samplesNumberReads.json     # Summary report containing read counts
```