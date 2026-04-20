include { SHOVILL       } from '../../modules/local/shovill/shovill'
include { PBP_TYPER     } from '../../modules/local/pbp_typer/pbp_typer'
include { EMM_TYPER     } from '../../modules/local/emm_typer/emm_typer'


workflow PBP_EMM {

    take:
    ch_reads
    summfle_script

    main:

    ch_versions = channel.empty()

    //
    // SHOVILL: assemble reads into contigs
    //
    SHOVILL (
        ch_reads
    )
    ch_versions = ch_versions.mix(SHOVILL.out.versions)

    //
    // PBP_TYPER: type penicillin binding proteins
    //
    // PBP_TYPER (
    //     SHOVILL.out.contigs,
    //     params.pbp_database
    // )
    // ch_versions = ch_versions.mix(PBP_TYPER.out.versions)

    //
    // Renaming channel
    //
    ch_emm_typer_input = SHOVILL.out.contigs
        .filter{it ->
        it }
        .combine(summfle_script)

    //
    // EMM_TYPER: type emm gene
    //
    EMM_TYPER (
        // tuple val(meta), file(contigs), file(script)
        ch_emm_typer_input
    )
    ch_versions = ch_versions.mix(EMM_TYPER.out.versions)


    emit:
    versions = ch_versions
    // TODO: PBP output type
    // TODO: EMM type sequences
    // TODO: PHYLOGENETICS
    // TODO: QUAST
}
