process BBMAP {
    tag "$meta.id"
    label 'process_high_memory'

    publishDir "${params.outdir}/bbmap", mode: 'copy'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5a/5aae5977ff9de3e01ff962dc495bfa23f4304c676446b5fdf2de5c7edfa2dc4e/data' :
        'community.wave.seqera.io/library/bbmap_pigz:07416fe99b090fa9' }"

    input:
    tuple val(meta), path(fastq)
    path  ref

    output:
    tuple val(meta), path("*.bam")  , emit: bam
    tuple val(meta), path("*.fq.gz"), emit: reads
    tuple val(meta), path("*.log")  , emit: log
    tuple val("${task.process}"), val('bbmap'), eval('bbversion.sh | grep -v "Duplicate cpuset"'), topic: versions, emit: versions_bbmap

    script:
    def prefix = task.ext.prefix ?: meta.id
    def mem    = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx8g"
    """
    bbmap.sh \\
        ${mem} \\
        threads=${task.cpus} \\
        in1=${fastq[0]} \\
        in2=${fastq[1]} \\
        path=${ref} \\
        outm=${prefix}.host.bam \\
        outu1=${prefix}.unhost_R1.fq.gz \\
        outu2=${prefix}.unhost_R2.fq.gz \\
        2> ${prefix}.bbmap.log
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}.host.bam
    touch ${prefix}.unhost_R1.fq.gz
    touch ${prefix}.unhost_R2.fq.gz
    touch ${prefix}.bbmap.log
    """
}
