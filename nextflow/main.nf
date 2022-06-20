#!/usr/bin/env nextflow

// enable dsl2
nextflow.enable.dsl = 2

// include modules
include {print_help} from "${params.nfpath}/nextflow/modules/help.nf"

// import subworkflows
include {profiledb} from "${params.nfpath}/nextflow/workflows/workflow.nf"


def raiseError ( value ) {
    sleep(2000)
    println(value)
    System.exit(1)
}

if (params.help) {
    print_help()
    exit 0
}

// main workflow
workflow {

    if ( params.fasta ) {
        Channel.fromPath(params.fasta).set{ ch_fasta }
    }
    else {
        println("Please provide the path of your fasta file")
        System.exit(1)
    }

    main:
    if ( params.workflow == 'profiledb') {
        profiledb(ch_fasta)
    }

}
