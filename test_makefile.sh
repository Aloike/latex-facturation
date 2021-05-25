#!/bin/bash

set -e
set -x


DIR_SRC='factures'
DIR_OUT='out'

FILENAME='FactureDemo'
FILE_EXT_PDF='pdf'
FILE_EXT_TEX='tex'


make ${FILENAME}

make ${FILENAME}.${FILE_EXT_PDF}
make ${FILENAME}.${FILE_EXT_TEX}

make ${DIR_SRC}/${FILENAME}.${FILE_EXT_PDF}
# make ${DIR_SRC}/${FILENAME}.${FILE_EXT_TEX}

make ${DIR_OUT}/${DIR_SRC}/${FILENAME}.${FILE_EXT_PDF}
