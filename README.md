This is the first step of nanopore pipeline. It will only copy files 

Workflow Logic
The pipeline follows these steps to resolve file paths:
    Input Detection: * For Barcoded runs: It searches RUN_DIR/*/pod5_pass/{barcode}/*.pod5.
    For Non-Barcoded runs: It searches RUN_DIR/{sample_name}/*/pod5_pass/*.pod5.
Merging (pod5merge):
    If 0 files are found: Touches an empty file.
    If 1 file is found: Performs a simple cp (copy).
    If multiple files are found: Uses pod5 merge to combine them.

Reporting: Runs a custom script to count reads and output metadata.
