#!/usr/bin/bash

sudo -E pipenv run twistd -ny $(pipenv run installer)/resources/examples/tkap.tac
