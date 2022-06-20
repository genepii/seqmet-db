# seqmet-db

<p align="center">
  <img alt="HCL logo" src="https://github.com/genepii/seqmet-db/blob/main/doc/hcl_logo_full.png" width="30%">
&nbsp; &nbsp; &nbsp; &nbsp;
  <img alt="genEPII logo" src="https://github.com/genepii/seqmet-db/blob/main/doc/genepii_logo_full.png" width="63%">
</p>

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.3-23aa62.svg)](https://www.nextflow.io/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg)](https://sylabs.io/docs/)

## Introduction

**genepii/seqmet-db** is a bioinformatics pipeline able to generate various databases used by genepii/seqmet.

The pipeline is built using [Nextflow](https://www.nextflow.io), is implemented with DSL2, rely on Singularity containers for its processes and on a json parameters file for flexibility and traceability. This framework permits to easily maintain the pipeline while keeping its portability and the reproducibility of its results. The pipeline is expected to be easy to install and be compliant with quality control demands of the French accreditation comity.

Currently it only permits to generate files for SARS-CoV-2, however flu and other viruses will be added progressively. It generates for different purposes:
1. fasta files containing a randomly selected subset of sequences for each lineage, usually done on the full GISAID dataset after filtering sequences passing quality checks. These sequences are considered representative of the diversity in a given lineage.
2. vcf files reporting SNPs and indels as reported by minimap2/freebayes for each lineage. These files are used by seqmet to detect potential co-infections in a given sample.
3. profile file reporting substitutions and indels as reported by nextclade and their frequency for each lineage. This file is equivalent to the lineage comparison done on outbreak.info.
4. matrix file reporting substitutions and indels as reported by nextclade for each lineage. This file facilitates lineages profile comparison.

## Pipeline summary

While the workflow and core processes of this pipeline are fixed, many variables can be tweaked in the parameters json file which permits a high flexibility but could also leads to highly variable results. A template of this json is provided, in the piperun folder, and should be used for testing before any issue is submitted. Our team will support any technical or methodological issues but won't be able to deal with any issue encountered when this json default parameters are changed.

1. Filter raw fasta file to only keep sequences passing basic filtering criteria ([`in-house script`])
2. Generate nextclade report ([`Nextclade`](https://github.com/nextstrain/nextclade))
3. Generate pangolin report ([`pangolin`](https://github.com/cov-lineages/pangolin))
4. Join multiple assignment files ([`in-house script`])
5. Filter assignment file based on nextclade and pangolin quality scores and potential downsampling
6. Filter fasta file to only keep sequences selected in the previous step ([`seqkit`](https://github.com/shenwei356/seqkit))
7. Sort fasta sequences according to their lineage
8. Map sequences on the appropriate reference ([`Minimap2`](https://github.com/lh3/minimap2))
9. Variant calling and vcf formatting ([`freebayes`](https://github.com/freebayes/freebayes)) ([`vt`](https://github.com/atks/vt))
10. Generate a lineage profile file ([`in-house script`])
11. Generate a lineage matrix file ([`in-house script`])

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.10.3`)

2. Install [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (`>=3.0`)

3. Clone this repository and prepare the nextflow config file and json parameters file:

   > - Build the singularity containers `dbkit`, `nextclade`, `pangolin`, `varcall` using the definition files found in singularity/def.
   > - Edit nextflow.config to indicate the absolute path of the cloned repository, the absolute path of the singularity containes built previously, the maximum memory and threads to use, and the folder to mount in the containers (same as the cloned repository if working locally).
   > - Edit the json parameters template found in piperun/000000_seqmet-db_profiledb_ncov to replace "/path/to/seqmet-db" by the absolute path of the cloned repository.

4. Test the pipeline on the provided dataset with a single command using the json template:

   ```console
   cd seqmet-db/piperun
   ./launch_piperun.sh 000000_seqmet-db_profiledb_ncov
   ```

6. Try on your on dataset, with different parameters:

   ```console
   cd seqmet-db/piperun
   mkdir date_seqmet-db_profiledb_ncov
   cp 000000_seqmet-db_profiledb_ncov/params_01.json date_seqmet-db_profiledb_ncov/
   # Edit date_seqmet-db_profiledb_ncov/params_01.json with your raw fasta absolute path in `fasta`, edit absolute result folder path in `result` and tweak any process parameters as suited
   ./launch_piperun.sh date_seqmet-db_profiledb_ncov
   ```

## Documentation

Documentation is still work-in-progress and will be available at [wiki](https://github.com/genepii/seqmet-db/wiki).

## Credits

The pipeline is primarily designed, written, tested and maintained by Bruno Simon ([@sib0](https://github.com/sib0)) from [GenEPII Sequencing Platform, Institut des Agents Infectieux, Hospices Civils de Lyon, Lyon, France](https://genepii.univ-lyon1.fr/).

In-house scripts were written conjointly with Hadrien Regue ([@HadrienRegue](https://github.com/HadrienRegue)) and Theophile Boyer ([@BoyerTheo](https://github.com/BoyerTheo)) from [GenEPII Sequencing Platform, Institut des Agents Infectieux, Hospices Civils de Lyon, Lyon, France](https://genepii.univ-lyon1.fr/).

## Citations

If you use genepii/seqmet-db for your analysis, please cite it using the following doi: [medrxiv.org/content/10.1101/2022.03.24.22272871v1](https://doi.org/10.1101/2022.03.24.22272871)

You can cite the `seqmet-db` publication as follows:

> **Detection and prevalence of SARS-CoV-2 co-infections during the Omicron variant circulation, France, December 2021 - February 2022**
>
> Antonin Bal, Bruno Simon, Gregory Destras, Richard Chalvignac, Quentin Semanas, Antoine Oblette, Gregory Queromes, Remi Fanget, Hadrien Regue, Florence Morfin, Martine Valette, Bruno Lina, Laurence Josset.
>
> medRxiv 2022.03.24.22272871 doi: [10.1101/2022.03.24.22272871](https://doi.org/10.1101/2022.03.24.22272871).
