process DEACON {
    tag "$meta.id"
    label 'process_medium'

    publishDir "${params.outdir}/deacon", mode: 'copy'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1' :
        'biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    input:
    tuple val(meta), path(index), path(reads)

    output:
    tuple val(meta), path("${meta.id}*.fq.gz"), emit: fastq_filtered
    tuple val(meta), path("${meta.id}.json")  , emit: log
    tuple val("${task.process}"), val('deacon'), eval('deacon --version | head -n1 | sed "s/deacon //g"'), topic: versions, emit: versions_deacon

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    deacon filter \\
        --deplete \\
        --threads ${task.cpus} \\
        --summary ${prefix}.json \\
        -o ${prefix}_1.fq.gz \\
        -O ${prefix}_2.fq.gz \\
        ${index} \\
        ${reads[0]} \\
        ${reads[1]}
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}.R1.fq.gz
    touch ${prefix}.R2.fq.gz
    echo '{}' > ${prefix}.json
    """
}
