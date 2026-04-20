/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Subworkflows
include { PBP_EMM               } from '../subworkflows/local/pbp_emm'
// include { VIRULENCE_ANALYSIS    } from '../subworkflows/local/virulence'

// Modules
include { REJECTED_SAMPLES       } from '../modules/local/rejected_samples/rejected_samples'
include { FASTP                  } from '../modules/local/fastp/fastp'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_gas_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Containerize just the perl scripts

workflow GAS {

    take:
    input_samples

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    channel.fromPath(workflow.projectDir + "/bin/summary_file.py", type: "file")
        .set { ch_summfle_script }

    //
    // Removing Empty Samples: set up to be healthomics compatible
    //

    input_samples
        .branch{ meta, _file ->
            single_end: meta.single_end
            paired_end: !meta.single_end
            }
        .set{ ch_filtered }

    ch_filtered.paired_end
        .map{ meta, file ->
            [meta, file, file[0].countFastq(), file[1].countFastq()]}
        .branch{ _meta, _file, count1, count2 ->
            pass: count1 > 0 && count2 > 0
            fail: count1 == 0 || count2 == 0 || count1 == 0 && count2 == 0
            }
        .set{ ch_paired_end }

    ch_paired_end.pass
        .map { meta, file, _count1, _count2 ->
            [meta, file]
            }
        .set{ ch_fully_filtered }

    ch_paired_end.fail
        .map { meta, _file, _count1, _count2 ->
            [meta.id]
            }
        .set{ ch_paired_end_fail }

    ch_paired_end_fail
        .flatten()
        .set{ ch_failed }

    ch_failed
        .ifEmpty{'NO_EMPTY_SAMPLES'}
        .collectFile(
                name: 'empty_samples.csv',
                newLine: true
            )
        .set{ ch_rejected_file }

    //
    // Rejected samples modules, healthomics compatible
    //

    REJECTED_SAMPLES (
        ch_rejected_file,
        "GAS"
    )

    ch_fully_filtered
        .branch { item ->
            ntc: !!(item[0]['id'] =~ params.ntc_regex)
            sample: true
        }
        .set{ ch_input_reads }

    if (params.ntc_regex != null) {
        ch_paired_end.fail
            .map { meta, _file, _count1, _count2 ->
                [meta.id]
                }
            .set{ ch_ntc_check }

        ch_ntc_check
            .branch { item ->
                ntc: !!(item =~ params.ntc_regex)
                sample: true
                }
            .set { ch_ntc_check }

        ch_ntc_check.ntc
            .collect()
            .ifEmpty("Empty")
            .set { ch_empty_ntc }
        } else  {
        ch_empty_ntc = channel.value("Empty")
        }

    ch_input_reads.ntc
        .map { meta, file -> [ meta + [is_ntc: true], file ] }
        .mix(
            ch_input_reads.sample.map { meta, file -> [ meta + [is_ntc: false], file ] }
        )
        .set{ ch_all_reads }
    //
    // FASTP on raw reads
    //
    FASTP (
        ch_all_reads
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)

    // // SUBWORKFLOW: pbp and emm typing

    PBP_EMM (
        ch_all_reads,
        ch_summfle_script
    )

    PBP_EMM
        .out
        .versions
        .mix(ch_versions)
        .set { ch_versions }

    emit:
    multiqc_report = channel.of([]) // MULTIQC.out.report.toList().ifEmpty("No MultiQC report generated") // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
