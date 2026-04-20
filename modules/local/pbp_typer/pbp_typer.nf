process PBP_TYPER {
  tag           "${meta.id}"
  label         "process_medium"
  container     'staphb/pbptyper:2.0.0'


  input:
  tuple val(meta), file(contigs)
  path(db)

  output:
  path "pbptyper/${meta.id}.tsv"            , emit: collect, optional: true
  path "pbptyper/${meta.id}.fastani.tsv"    , emit: fastani
  path "pbptyper/${meta.id}-1A.tblastn.tsv" , emit: tblast_1A
  path "pbptyper/${meta.id}.2B.tblastn.tsv" , emit: tblast_2B
  path "pbptyper/${meta.id}.2X.tblastn.tsv" , emit: tblast_2X
  path "logs/${task.process}/*.log"         , emit: log
  path "versions.yml"                       , emit: versions

  when:
  task.ext.when == null || task.ext.when

  script:
  def prefix = task.ext.prefix ?: "${meta.id}"
  """
    mkdir -p pbptyper logs/${task.process}
    log_file=logs/${task.process}/${prefix}.${workflow.sessionId}.log

    pbptyper \
      --input ${contigs} \
      --targets ${db} \
      --min_pident 95 \
      --min_coverage 95 \
      --prefix ${prefix} \
      --outdir ./ \
      | tee -a \$log_file

    cut -f 2 {samplename}.tsv | tail -n 1 > pbptype.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbptyper: \$(echo \$(pbptyper --version 2>&1) | sed 's/^.*pbptyper, version //;' )
    END_VERSIONS
  """
}
