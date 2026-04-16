process KRAKEN2 {
    tag "$meta.id"
    label 'process_high'

    publishDir "${params.outdir}/kraken2", mode: 'copy'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0f/0f827dcea51be6b5c32255167caa2dfb65607caecdc8b067abd6b71c267e2e82/data' :
        'community.wave.seqera.io/library/kraken2_coreutils_pigz:920ecc6b96e2ba71' }"

    input:
    tuple val(meta), path(reads)
    path  db
    val   save_output_fastqs
    val   save_reads_assignment

    output:
    tuple val(meta), path('*.classified{.,_}*')  , optional: true, emit: classified_reads_fastq
    tuple val(meta), path('*.unclassified{.,_}*'), optional: true, emit: unclassified_reads_fastq
    tuple val(meta), path('*classifiedreads.txt'), optional: true, emit: classified_reads_assignment
    tuple val(meta), path('*report.txt')                         , emit: report
    tuple val("${task.process}"), val('kraken2'), eval('kraken2 --version 2>&1 | head -1 | sed "s/^.*Kraken version //; s/ .*//"'), topic: versions, emit: versions_kraken2
    tuple val("${task.process}"), val('pigz'),    eval('pigz --version 2>&1 | sed "s/pigz //g"'),                                   topic: versions, emit: versions_pigz

    script:
    def prefix              = task.ext.prefix ?: meta.id
    def classified_opt      = save_output_fastqs    ? "--classified-out ${prefix}.classified#.fastq"     : ''
    def unclassified_opt    = save_output_fastqs    ? "--unclassified-out ${prefix}.unclassified#.fastq" : ''
    def assignment_opt      = save_reads_assignment ? "--output ${prefix}.classifiedreads.txt"           : '--output /dev/null'
    """
    kraken2 \\
        --db ${db} \\
        --threads ${task.cpus} \\
        --report ${prefix}.kraken2.report.txt \\
        ${classified_opt} \\
        ${unclassified_opt} \\
        ${assignment_opt} \\
        --paired \\
        ${reads}

    if [ "${save_output_fastqs}" = "true" ]; then
        [ -f "${prefix}.classified_1.fastq"   ] && pigz "${prefix}.classified_1.fastq"   || true
        [ -f "${prefix}.classified_2.fastq"   ] && pigz "${prefix}.classified_2.fastq"   || true
        [ -f "${prefix}.unclassified_1.fastq" ] && pigz "${prefix}.unclassified_1.fastq" || true
        [ -f "${prefix}.unclassified_2.fastq" ] && pigz "${prefix}.unclassified_2.fastq" || true
    fi
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}.classified_1.fastq.gz
    touch ${prefix}.classified_2.fastq.gz
    touch ${prefix}.unclassified_1.fastq.gz
    touch ${prefix}.unclassified_2.fastq.gz
    touch ${prefix}.classifiedreads.txt
    touch ${prefix}.kraken2.report.txt
    """
}
