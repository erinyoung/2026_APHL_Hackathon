// include { SRST2 as MLST                 } from '../../modules/local/bbduk/bbduk'
// include { SRST2 as VIRULENCE_SURFACE    } from '../../modules/local/fastqc/fastqc'
// include { SRST2 as AMR_TYPING           } from '../../modules/local/shovil/shovill'

// workflow VIRULENCE_ANALYSIS {
//     take:
//     input_samples

//     main:

//     ch_versions = Channel.empty()

//     FASTQC(input)

//     ch_versions = ch_versions.mix(FASTQC.out.versions())

//     emit:
//     versions = ch_versions
//     // TODO: PBP output type
//     // TODO: EMM type sequences
//     // TODO: PHYLOGENETICS
//     // TODO: QUAST
// }
