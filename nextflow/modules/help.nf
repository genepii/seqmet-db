def print_help() {
  log.info"""
  Usage:
    cd seqmet-db/piperun
    ./launch_piperun.sh [piperun_folder_name]

  Description:
    genepii/seqmet-db is a bioinformatics pipeline able to generate various databases used by genepii/seqmet.

  Workflow options:
    All parameters can be changed in the params json file of the piperun.

  """.stripIndent()
}
