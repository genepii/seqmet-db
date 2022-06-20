#!/bin/bash

PIPERUN_DIR="${PWD}"
NF_PATH="${PIPERUN_DIR%%/piperun}"

for PIPERUN in "$@"
do
echo "${PIPERUN}"
cd "${NF_PATH}/piperun/${PIPERUN}"
RUN_ID="${PIPERUN%%_*}_${PIPERUN##*_}"
DATA_TYPE="${PIPERUN##*_}"
    for JSON in *.json
    do
    rm -rf work .nextflow* trace.txt* report.html*
    LOG=""
    "${NF_PATH}/nextflow/nextflow" -C "${NF_PATH}/nextflow/nextflow.config" run "${NF_PATH}/nextflow/main.nf" -params-file "${JSON}" -with-trace --prefix "${RUN_ID}" || LOG="error"
    chmod -fR 775 "${NF_PATH}/piperun/${PIPERUN}"
    if [[ "${LOG}" != "" ]]; then echo "${RUN_ID} failed"; echo "${RUN_ID} failed - $(date)" >> "${NF_PATH}/piperun/launch_piperun.log"; continue; fi
    cp -r "${JSON}" trace.txt "${NF_PATH}/result/${PIPERUN}/"
        if [[ "${PIPERUN%%_*}" == "000000" ]]
        then
        echo "${DATA_TYPE}"
        else
        echo "${DATA_TYPE}"
        fi
    done
done
