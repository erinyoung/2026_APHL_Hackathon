include { SHOVILL                   } from '../../modules/local/shovill/shovill'
include { EMM_TYPER                 } from '../../modules/local/emm_typer/emm_typer'
include { MLST                      } from '../../modules/local/mlst/mlst'
include { PARSNP                    } from '../../modules/local/parsnp/parsnp'
include { QUAST                     } from '../../modules/local/quast/quast'
include { QUAST_SUMMARY             } from '../../modules/local/quast_summary'
include { PARSE_PARSNP_ALIGNER_LOG  } from '../../modules/local/parse_parsnp_aligner_log'
include { REMOVE_REFERENCE          } from '../../modules/local/remove_reference'
include { COMPARE_IO                } from '../../modules/local/compare_io'
include { IQTREE                    } from '../../modules/local/iqtree/iqtree'
include { SNPDISTS                  } from '../../modules/local/snpdists/snpdists'


workflow EMM_MLST {

    take:
    ch_reads
    summfle_script
    fasta
    add_reference
    samplesheet

    main:

    ch_versions = channel.empty()
    ch_for_mblocks = channel.empty()

    //
    // SHOVILL: assemble reads into contigs
    //
    SHOVILL (
        ch_reads
    )
    ch_versions = ch_versions.mix(SHOVILL.out.versions)


    //
    // MLST: type MLST genes
    //
    MLST (
        SHOVILL.out.contigs
    )
    ch_versions = ch_versions.mix(MLST.out.versions)

    //
    // Reformatting channel
    //
    ch_parsnp = SHOVILL.out.contigs
        .map { _meta, contigs -> contigs }
        .collect()
        .flatten()
        .collect()

    //
    // PARSNP: perform core genome alignment
    //
    PARSNP (
        ch_parsnp,
        fasta,
        params.parsnp_partition
    )

    //
    // Remove reference
    //
    if (add_reference == false) {

        ch_for_mblocks = REMOVE_REFERENCE {
            PARSNP.out.mblocks
        }
    } else {
        ch_for_mblocks = PARSNP.out.mblocks
    }

    //
    // Counting number of samples
    //
    ch_for_count = PARSNP.out.mblocks
        .map{ fasta_files -> [fasta_files.countFasta()] }
        .flatten()

    //
    // PARSER
    //
    PARSE_PARSNP_ALIGNER_LOG (
        PARSNP.out.log,
        add_reference
    )

    ch_compare = samplesheet
        .map { meta, _reads -> meta.id }
        .collect()

    //
    // COMPARE_IO
    //
    COMPARE_IO (
        ch_compare,
        PARSE_PARSNP_ALIGNER_LOG.out.aligner_log
    )

    //
    // IQTREE
    //
    IQTREE (
        PARSNP.out.mblocks,
        ch_for_count
    )
    ch_versions = ch_versions.mix(IQTREE.out.versions)

    //
    // SNPDISTS
    //
    SNPDISTS (
        PARSNP.out.mblocks
    )
    ch_versions = ch_versions.mix(SNPDISTS.out.versions)

    //
    // QUAST: quality control of assemblies
    //
    QUAST (
        SHOVILL.out.contigs
    )
    ch_versions = ch_versions.mix(QUAST.out.versions)

    //
    // QUAST_SUMMARY
    //
    QUAST_SUMMARY (
        QUAST.out.transposed_report.collect()
    )

    //
    // Reformatting channel
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
    phylogeny    =      IQTREE.out.phylogeny
    tsv          =      SNPDISTS.out.tsv
    aligner_log  =      PARSE_PARSNP_ALIGNER_LOG.out.aligner_log
    excluded     =      COMPARE_IO.out.excluded
    versions     =      ch_versions
}
