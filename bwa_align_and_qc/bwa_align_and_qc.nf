/*
*    This script is used to run alignment (using BWA) and QC (FASTQC)
*    on a set of FASTQ-format files.
*
*    FASTQ files are assumed to be "ready to go", i.e. there is no 
*    trimming or lane-specific file concatenation
*/


process FASTQC {

    tag "FastQC on $sample_id"
    publishDir "${params.output_dir}/fastqc", mode:"copy"
    container "docker.io/biocontainers/fastqc:v0.11.9_cv8"
    cpus 4
    memory '8 GB'

    input:
        tuple val(sample_id), path(fq)

    output:
        path "${sample_id}_fastqc_logs"

    script:

        // This sets r1 and r2 to the fastq files
        // if paired. If single-end, r2 is the empty
        // string, so it has no effect on the fastqc process
        def isSingleEnd = fq instanceof Path
        def r1 = !isSingleEnd ? "${fq[0]}" : "${fq}"
        def r2 = !isSingleEnd ? "${fq[1]}" : ''

        """
        OUTDIR=${sample_id}_fastqc_logs
        mkdir \$OUTDIR
        /usr/local/bin/fastqc -o \$OUTDIR -f fastq -q ${r1} ${r2}
        """
}


process BWA_ALIGN {

    tag "BWA on $sample_id"
    publishDir "${params.output_dir}/bwa", mode:"copy"
    container "docker.io/biocontainers/bwa:v0.7.17_cv1"
    cpus 4
    memory '8 GB'
    //disk '150 GB'

    input:
        path 'bwa_index_zip'
        tuple val(sample_id), path(fq)


    output:
        path "${sample_id}.sam"

    script:

        // This sets r1 and r2 to the fastq files
        // if paired. If single-end, r2 is the empty
        // string, so it has no effect on the fastqc process
        def isSingleEnd = fq instanceof Path
        def r1 = !isSingleEnd ? "${fq[0]}" : "${fq}"
        def r2 = !isSingleEnd ? "${fq[1]}" : ''

        """
        unzip ${bwa_index_zip} -d bwa_index
        /opt/conda/bin/bwa mem -o ${sample_id}.sam bwa_index/${params.genome_id} ${r1} ${r2}
        """
}


process SORT_AND_COMPRESS {

    tag "SAMBAMBA sort and compress on $samfile"
    publishDir "${params.output_dir}/sorted_bams", mode:"copy"
    container "docker.io/blawney/sambamba:0.8.2"
    cpus 4
    memory '8 GB'

    input:
        tuple val(sample_id), path(samfile)

    output:
        path "${sample_id}.sorted.bam*"

    script:

        // Don't exhaust all the memory- use 90% of it
        def totalMem = (0.9*task.memory.toGiga()).intValue()

        """
        /opt/sambamba-0.8.2-linux-amd64-static view -S -f bam ${samfile} > ${sample_id}.bam
        /opt/sambamba-0.8.2-linux-amd64-static sort -m ${totalMem}GB ${sample_id}.bam
        """
}

workflow {

    fq_ch = Channel.fromFilePairs(params.fastq_files_pattern, size: params.is_paired ? 2 : 1)
            .ifEmpty{error "Could not find paired fastq. Is this a single-end experiment?"}

    FASTQC(fq_ch)

    sam_ch = BWA_ALIGN(params.bwa_index_path, fq_ch).map(
        samfile -> tuple(samfile.baseName, samfile)
    )

    SORT_AND_COMPRESS(sam_ch)

}
