#!/bin/bash

TKAP_PATH=${HOME}/Workspace/Sandbox/twisted-klein

export PIPENV_PIPFILE=${TKAP_PATH}/Pipfile
export PIPENV_DOTENV_LOCATION=${TKAP_PATH}/.env

exec sudo -E pipenv run twistd -ny ${TKAP_PATH}/src/tkap/resources/examples/tkap.tac