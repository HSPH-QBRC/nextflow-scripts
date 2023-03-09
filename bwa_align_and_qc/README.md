### Nextflow script for basic QC and BWA-based alignment

This script executes a basic QC and alignment pipeline using the following:
- FastQC 
- BWA mem for alignment
- Sambamba for sorting

We assume you have created a BWA index and archived them using `zip`. For instance, a listing of your archive should look similar to:
```
$ unzip -l human_index.zip 
Archive:  human_index.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      150  03-08-2023 16:00   grch38.amb
       85  03-08-2023 16:00   grch38.ann
 58617712  03-08-2023 16:00   grch38.bwt
 14654406  03-08-2023 16:00   grch38.pac
 29308864  03-08-2023 16:00   grch38.sa
---------                     -------
102581217                     5 files
```

Note that the "prefix" of the index files (`grch38`) will be used as a pipeline parameter. Obviously modify as required for each genome.

**To run locally:**

For running locally, inspect the resource requirements for each process (`cpus` and `memory`) to ensure they are appropriate for your local machine. Then, simply fill out the parameter file `params.json` and run:
```
nextflow run bwa_align_and_qc.nf -params-file params.json
```

Parameters in `params.json`:
- `output_dir`: a string indicating a path to an output directory where files will be placed. e.g. `"${baseDir}/foo"` to create the `foo/` directory relative to the working dir and place output files there.
- `genome_id`: a string giving the "prefix" of the BWA files, as described above.
- `fastq_files_pattern`: a glob pattern for finding the FASTQ-format files of interest. e.g. `"${baseDir}/reads/*_R{1,2}.fastq.gz"` to search for all files in the `reads/` directory.
- `is_paired`: a boolean (`true` or `false`) indicating whether you are performing a paired alignment,
- `bwa_index_path`: a string indicating a path to the BWA index zip archive.


**To run on AWS Batch:**

This largely assumes you have created an AWS Batch environment consistent with https://github.com/HSPH-QBRC/batchflow

For running on AWS Batch, we need to do the following:
- Inspect `bwa_align_and_qc.nf` to ensure the resource requirements for each process (`cpus` and `memory`) are appropriate for each step, which can be dependent on the size of sequencing files and reference genome. These also need to be appropriate for the AWS Batch compute environment you will be using. For instance, a process' CPU requirements can't exceed the maximum cpus permitted in the Batch compute environment.
- Edit `nextflow.batch.config` to add the following variables:
    - `process.queue`: the name of the AWS Batch queue to use
    - `aws.region`: the AWS region you are working in
    - `workDir`: an AWS bucket (including `s3://`) where intermediate results will be saved. The easiest option is to use the bucket created along with the Batch environment.
    - (optional) `aws.batch.cliPath`: the path where the AWS cli is located. Note that we have already set this to `/opt/aws-cli/bin/aws`, but modify as necessary to be consistent with the AMI that will be used when creating Batch worker instances. See further explanation at https://github.com/HSPH-QBRC/batchflow/blob/main/README.md#notes-about-aws-cli-path 

- Fill out the parameter file `params.json`. Note that all file paths should reference buckets (which include the `s3://` prefix)
```
nextflow run bwa_align_and_qc.nf \
    -params-file params.json \
    -c nextflow.batch.config
```