process HOSTILE {
    tag "$meta.id"
    label 'process_medium'

    publishDir "${params.outdir}/hostile", mode: 'copy'

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7c/7caca3a47606de8e3460b35823193a471272aa6ab7cfafbf9aabf4615c9fa181/data'
        : 'community.wave.seqera.io/library/hostile:2.0.2--a7f5e5d341b6b94b'}"

    input:
    tuple val(meta)          , path(reads, stageAs: "input_reads/")
    tuple val(reference_name), path(reference_dir)

    output:
    tuple val(meta), path('*.fastq.gz'), emit: fastq
    tuple val(meta), path('*.json')    , emit: json
    path  'versions.yml'               , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    export HOME=\$PWD

    hostile clean \\
        --fastq1 ${reads[0]} \\
        --fastq2 ${reads[1]} \\
        --index ${reference_dir}/${reference_name} \\
        --threads ${task.cpus} \\
        -o . > ${prefix}.hostile.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hostile: \$(hostile --version 2>&1 | sed 's/hostile //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}.clean_1.fastq.gz
    touch ${prefix}.clean_2.fastq.gz
    echo '{}' > ${prefix}.hostile.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hostile: stub
    END_VERSIONS
    """
}
