#!/usr/bin/env nextflow

// enable dsl2
nextflow.enable.dsl = 2

// import modules
include {filter_fasta} from "${params.nfpath}/nextflow/modules/module.nf"
include {gentsv_nextclade} from "${params.nfpath}/nextflow/modules/module.nf"
include {gentsv_pangolin} from "${params.nfpath}/nextflow/modules/module.nf"
include {join_assignment} from "${params.nfpath}/nextflow/modules/module.nf"
include {filter_assignment} from "${params.nfpath}/nextflow/modules/module.nf"
include {downsample_fasta} from "${params.nfpath}/nextflow/modules/module.nf"
include {assign_fasta} from "${params.nfpath}/nextflow/modules/module.nf"
include {map_minimap2} from "${params.nfpath}/nextflow/modules/module.nf"
include {callvar_freebayes} from "${params.nfpath}/nextflow/modules/module.nf"
include {gentsv_mutprofile} from "${params.nfpath}/nextflow/modules/module.nf"
include {gentsv_mutmatrix} from "${params.nfpath}/nextflow/modules/module.nf"

// workflows
workflow profiledb {
    take:
        ch_fasta
    main:

        filter_fasta(Channel.from(params.filter_fasta.ref).combine(ch_fasta))

        gentsv_nextclade(filter_fasta.out.join(Channel.from(params.gentsv_nextclade.dataset)))

        gentsv_pangolin(filter_fasta.out)

        join_assignment(gentsv_nextclade.out.join(gentsv_pangolin.out))

        filter_assignment(join_assignment.out)

        downsample_fasta(filter_fasta.out.join(filter_assignment.out.idlist))

        assign_fasta(downsample_fasta.out.join(filter_assignment.out.downsample))

        map_minimap2(assign_fasta.out.flatten().combine(Channel.fromPath(params.map_minimap2.ref)))

        callvar_freebayes(map_minimap2.out.bam)

        gentsv_mutprofile(join_assignment.out)

        gentsv_mutmatrix(gentsv_mutprofile.out.tsv)

}
