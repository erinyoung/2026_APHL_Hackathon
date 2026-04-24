process COMPARE_IO {

    container "quay.io/wslh-bioinformatics/pandas@sha256:9ba0a1f5518652ae26501ea464f466dcbb69e43d85250241b308b96406cac458"

    input:
    val samples_list
    path aligner_log

    output:
    path("sample_exclusion_status.csv") , emit: excluded

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in GAS/bin
    """
    compare_io.py \\
    -s $samples_list \\
    -l $aligner_log
    """

}
