# hostzap

![hostzap logo](./docs/hostzap.png)

A Nextflow pipeline for host read removal from paired-end sequencing data.
Given a samplesheet of FASTQ files, hostzap runs one or more host depletion tools
and outputs the cleaned reads alongside summary statistics.

## Tools

| Tool | Method |
|------|--------|
| [Kraken2](https://github.com/DerrickWood/kraken2) | k-mer classification |
| [BBMap](https://sourceforge.net/projects/bbmap/) | Sequence alignment |
| [Hostile](https://github.com/bede/hostile) | Targeted host removal |
| [Deacon](https://github.com/tgstoecker/deacon) | Host sequence depletion |

Each tool can be skipped individually with `--skip_kraken2`, `--skip_bbmap`,
`--skip_hostile`, or `--skip_deacon`.

## Usage

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --kraken2_db /path/to/kraken2_db \
  --hostile_index human-t2t-hla
```

The samplesheet must be a CSV with three columns:

```
sample-id,forward-absolute-filepath,reverse-absolute-filepath
sample1,/data/sample1_R1.fastq.gz,/data/sample1_R2.fastq.gz
```

## Requirements

- Nextflow (DSL2)
- Docker, Singularity (conda is not tested and not recommended)
