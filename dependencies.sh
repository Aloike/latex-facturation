#!/bin/sh

set -e
set -x

#sudo apt install -y \
#	texlive \
#	texlive-binaries \
#	texlive-lang-english \
#	texlive-lang-french \
#	texlive-latex-extra

YEAR=`date '+%Y'`
DIR_INSTALL="/usr/local/texlive/${YEAR}"

sudo mkdir -p "${DIR_INSTALL}"
cd "${DIR_INSTALL}"

wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

tar -xvzf install-tl-unx.tar.gz

cd install-tl-${YEAR}*/
./install-tl


sed --in-place \
	-e 's@PATH="\(.*\)"@PATH="'"${DIR_INSTALL}"'/bin/x86_64-linux:\1"@' \
	/etc/environment


if [ ! -d "${HOME}/texmf" ]
then
	# `init-usertree` is needed on first run of tlmgr.
	tlmgr init-usertree
fi



# eforms (provided by acrotex) is an optional package to generate electronic signature areas in the resulting pdf.
#tlmgr install acrotex

#DIR_SEARCH_STY="$(kpsewhich -var-value=TEXMFHOME)/tex/latex/"
DIR_SEARCH_STY="$(kpsewhich -var-value=TEXMFLOCAL)/tex/latex/"
if [[ ! -d "${DIR_SEARCH_STY}" ]]
then
	mkdir -p "${DIR_SEARCH_STY}"
fi
cd "${DIR_SEARCH_STY}"
wget https://mirrors.ctan.org/macros/latex/contrib/acrotex.zip
unzip acrotex.zip
cd acrotex
pdflatex acrotex.ins
mktexlsr "$(kpsewhich -var-value=TEXMFLOCAL)"
#mktexlsr "$(kpsewhich -var-value=TEXMFHOME)"
#rsync -r acrotex/* .
#rm -rvf acrotex acrotex.zip
#tar -C "$(kpsewhich -var-value=TEXMFLOCAL)" --strip-components=1 -xf acrotex.tar.lzma
#mktexlsr "$(kpsewhich -var-value=TEXMFLOCAL)"

exit $?

