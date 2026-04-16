#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { KRAKEN2 } from './modules/kraken2/main'
include { BBMAP   } from './modules/bbmap/main'
include { HOSTILE } from './modules/hostile/main'
include { DEACON  } from './modules/deacon/main'

// ============================================================
// Print header
// ============================================================
log.info """\
    H O S T - R E M O V A L   P I P E L I N E
    ===========================================
    input        : ${params.input}
    outdir       : ${params.outdir}
    ---
    skip_kraken2 : ${params.skip_kraken2}
    skip_bbmap   : ${params.skip_bbmap}
    skip_hostile : ${params.skip_hostile}
    skip_deacon  : ${params.skip_deacon}
    """.stripIndent()

// ============================================================
// Parameter validation
// ============================================================
def validateParams() {
    if (!params.input)  { error "ERROR: --input samplesheet CSV is required" }
    if (!params.outdir) { error "ERROR: --outdir output directory is required" }

    if (!params.skip_kraken2 && !params.kraken2_db) {
        error "ERROR: --kraken2_db is required unless --skip_kraken2 is set"
    }
    if (!params.skip_bbmap && !params.bbmap_db) {
        error "ERROR: --bbmap_db is required unless --skip_bbmap is set"
    }
    if (!params.skip_hostile && !params.hostile_db) {
        error "ERROR: --hostile_db is required unless --skip_hostile is set"
    }
    if (!params.skip_deacon && !params.deacon_db) {
        error "ERROR: --deacon_db is required unless --skip_deacon is set"
    }
}

// ============================================================
// Parse samplesheet CSV → channel of [ meta, [r1, r2] ]
// Expected columns: sample-id, forward-absolute-filepath, reverse-absolute-filepath
// ============================================================
def parseSamplesheet(csv) {
    Channel
        .fromPath(csv, checkIfExists: true)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def required = ['sample-id', 'forward-absolute-filepath', 'reverse-absolute-filepath']
            required.each { col ->
                if (!row.containsKey(col)) {
                    error "Samplesheet is missing required column: '${col}'"
                }
            }
            def meta = [ id: row['sample-id'] ]
            def r1   = file(row['forward-absolute-filepath'],  checkIfExists: true)
            def r2   = file(row['reverse-absolute-filepath'], checkIfExists: true)
            [ meta, [ r1, r2 ] ]
        }
}

// ============================================================
// Main workflow
// ============================================================
workflow {

    validateParams()

    ch_reads = parseSamplesheet(params.input)

    // ---- Kraken2 ------------------------------------------------
    if (!params.skip_kraken2) {
        KRAKEN2(
            ch_reads,
            file(params.kraken2_db, checkIfExists: true),
            true,   // save unclassified (non-host) reads as FASTQ
            false   // do not save per-read classification table
        )
    }

    // ---- BBMap --------------------------------------------------
    if (!params.skip_bbmap) {
        BBMAP(
            ch_reads,
            file(params.bbmap_db, checkIfExists: true)
        )
    }

    // ---- Hostile ------------------------------------------------
    if (!params.skip_hostile) {
        // hostile_db should point to the index prefix, e.g. /path/to/human-t2t-hla
        // The basename becomes reference_name, the parent dir becomes reference_dir
        def hostile_path = file(params.hostile_db, checkIfExists: true)
        ch_hostile_ref   = Channel.value([ hostile_path.name, hostile_path.parent ])

        HOSTILE(
            ch_reads,
            ch_hostile_ref
        )
    }

    // ---- Deacon -------------------------------------------------
    if (!params.skip_deacon) {
        ch_deacon = ch_reads.map { meta, reads ->
            [ meta, file(params.deacon_db, checkIfExists: true), reads ]
        }
        DEACON( ch_deacon )
    }
}
