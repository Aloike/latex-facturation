#!/bin/bash

set -e
# set -x


CMD_MKDIR='mkdir -pv'

DIR_OUTPUT='out'


HUNSPELL_CMD='hunspell'

HUNSPELL_OPTIONS=
HUNSPELL_OPTIONS+=" -d en_US,fr_FR"     #< Set dictionaries.
HUNSPELL_OPTIONS+=" -i utf-8"           #< Set input encoding.
HUNSPELL_OPTIONS+=" -l"                 #< Produce a list of misspelled words from the standard input.
HUNSPELL_OPTIONS+=" -p rsrc/spelling/dictionnary.txt"   #< Set path of personal dictionary.
HUNSPELL_OPTIONS+=" -t"                 #< Input file is in TeX or LaTeX format.
HUNSPELL_OPTIONS+=" -u"                 #<
# HUNSPELL_OPTIONS+= --add-tex-command "texttt op"


LATEX_OPTIONS=
LATEX_OPTIONS+=" -file-line-error"
LATEX_OPTIONS+=" -halt-on-error"
LATEX_OPTIONS+=" -interaction=nonstopmode"
LATEX_OPTIONS+=" -output-directory=${DIR_OUTPUT}"


TEXTIDOTE_DOCKER_IMAGE='mahito1594/textidote'

TEXTIDOTE_ENABLED=${TEXTIDOTE_ENABLED:-1}

TEXTIDOTE_OPTIONS=
TEXTIDOTE_OPTIONS+=" --check en"
# TEXTIDOTE_OPTIONS+=" --firstlang fr"
# TEXTIDOTE_OPTIONS+=" --ignore sh:008" #!< "A paragraph heading should not end with a punctuation symbol."
# TEXTIDOTE_OPTIONS+=",lt:en:MORFOLOGIK_RULE_EN_US" #!< "Possible spelling mistake found (1084) [lt:en:MORFOLOGIK_RULE_EN_US]""
# TEXTIDOTE_OPTIONS+=",sh:nonp" #!< "If you are writing a research paper, do not force page breaks. [sh:nonp]"
# TEXTIDOTE_OPTIONS+=",sh:figref" #!< "Figure sssss is never referenced in the text [sh:figref]"
# TEXTIDOTE_OPTIONS+=" --output html"
TEXTIDOTE_OPTIONS+=" --output plain"
TEXTIDOTE_OPTIONS+=" --read-all"
# TEXTIDOTE_OPTIONS+=" --remove-macros "
TEXTIDOTE_OPTIONS+=" --type tex"

# ##############################################################################
# ##############################################################################

if [[ -z "${DBG}" ]]
then
	DBG=1
fi

if [[ "${DBG}" -eq 0 ]]
then
	CMD_LOG_DBG='echo 1>/dev/null'
else
	CMD_LOG_DBG='echo'
fi

# ##############################################################################
# ##############################################################################
#
##  @see    https://github.com/mahito1594/docker-textidote
#
function	F_build_textidote()
{
	echo ""
	echo "========================================"
	echo "    ${FUNCNAME[0]}"
	echo "========================================"


	# Get the docker image if not available locally
	if ! docker image inspect "${TEXTIDOTE_DOCKER_IMAGE}" 2>&1 > /dev/null
	then
		${CMD_LOG_DBG} "Image not available locally"

		docker pull "${TEXTIDOTE_DOCKER_IMAGE}"
	else
		${CMD_LOG_DBG} "Image available in local registry"
	fi


	# Generate a list of macros to ignore from the resource file
	local lFileIgnoredMacrosList="rsrc/textidote/ignore_macros.txt"
	if [[ ! -f "${lFileIgnoredMacrosList}" ]]
	then
		${CMD_LOG_DBG} "No file provided for ignored macros list."
	else
		# local lRemoveMacros="--remove-macros"
		local lRemoveMacros=""

		while read line
		do
			${CMD_LOG_DBG} "read line $line"
			
			if [[ -z "${lRemoveMacros}" ]]
			then
				lRemoveMacros="--remove-macros "
			else
				lRemoveMacros+=','
			fi
			
			lRemoveMacros+="$line"

		done < "${lFileIgnoredMacrosList}"
	fi


	# Generate a list of rules to ignore from the resource file
	local lFileIgnoredRulesList="rsrc/textidote/ignore_rules.txt"
	if [[ ! -f "${lFileIgnoredRulesList}" ]]
	then
		${CMD_LOG_DBG} "No file provided for ignored macros list."
	else
		# local lRemoveMacros="--remove-macros"
		local lRemoveRules=""

		while read line
		do
			# ${CMD_LOG_DBG} "read line $line"

			local lLinePreprocessed=`echo "$line"|sed -e 's@[[:space:]]*#.*$@@'`
			${CMD_LOG_DBG} "lLinePreprocessed=$lLinePreprocessed"
			if [[ -z "${lLinePreprocessed}" ]]
			then
				continue
			fi
			
			if [[ -z "${lRemoveRules}" ]]
			then
				lRemoveRules="--ignore "
			else
				lRemoveRules+=','
			fi
			
			lRemoveRules+="$lLinePreprocessed"

		done < "${lFileIgnoredRulesList}"
	fi


	# Run the analysis
	local lContainerOptions=''
	lContainerOptions+=" ${TEXTIDOTE_OPTIONS}"
	lContainerOptions+=" ${lRemoveMacros}"
	lContainerOptions+=" ${lRemoveRules}"
	lContainerOptions+=" master.tex"

	local lTextidoteOutputHtml="$(pwd)/${DIR_OUTPUT}/textidote-report.html"

	${CMD_LOG_DBG} "==> Running container with arguments: ${lContainerOptions}"
	if ! docker run \
		--rm \
		-v $PWD:/work \
		"${TEXTIDOTE_DOCKER_IMAGE}" \
		${lContainerOptions} \
		> "${lTextidoteOutputHtml}"
	then
		cat "${lTextidoteOutputHtml}"

		echo 	"TeXtidote returned with an error." \
			" Please see output at: '${lTextidoteOutputHtml}'."

		exit 1
	fi
}

# ##############################################################################
# ##############################################################################

function	F_build_main()
{
	echo ""
	echo "========================================"
	echo "    ${FUNCNAME[0]}"
	echo "========================================"


	pInvoiceDirPath="${1}"

	${CMD_LOG_DBG} "pInvoiceDirPath=${pInvoiceDirPath}"

	# Change the working directory to be the folder containing the sources.
	pushd "${pInvoiceDirPath}"

	# Create the output directory if it doesn't exist
	if [[ ! -d "${DIR_OUTPUT}" ]]
	then
		${CMD_MKDIR} "${DIR_OUTPUT}"
	fi


	# Spellchecking with Hunspell
	F_build_hunspell


	# Run a TeXtidote analysis if enabled.
	if [[ "${TEXTIDOTE_ENABLED}" -eq "0" ]]
	then
		${CMD_LOG_DBG} "TeXtidote is disabled."
	else
		F_build_textidote
	fi


	F_build_tex
}

# ##############################################################################
# ##############################################################################
#
##
#
function	F_build_hunspell()
{
	echo ""
	echo "========================================"
	echo "    ${FUNCNAME[0]}"
	echo "========================================"

	local	lHunspellOutputFile="${DIR_OUTPUT}/hunspell.txt"
	
	# Create the output file to be sure it exists
	touch "${lHunspellOutputFile}"


	${CMD_LOG_DBG} "HUNSPELL_OPTIONS=${HUNSPELL_OPTIONS}"

	#! Sed on the input file to avoind spell-checking the content of
	#! `texttt` commands.
	cat master.tex \
		| sed -e 's@\\texttt{.*}@@g' \
		| ${HUNSPELL_CMD} ${HUNSPELL_OPTIONS} \
		| tee ${lHunspellOutputFile}

	local lHunspellErrorsCount=`cat ${lHunspellOutputFile}|wc -l`
	echo "Found ${lHunspellErrorsCount} spelling errors.";

	if [[ ! "${lHunspellErrorsCount}" -eq "0" ]]
	then
		exit 1
	fi
}

# ##############################################################################
# ##############################################################################
#
##
#
function	F_build_tex()
{
	echo ""
	echo "========================================"
	echo "    ${FUNCNAME[0]}"
	echo "========================================"

	# # Create the build directory if it doesn't exist
	# lTexBuildDir="$(pwd)/build"
	# if [[ ! -d "${lTexBuildDir}" ]]
	# then
	# 	${CMD_MKDIR} "${lTexBuildDir}"
	# fi

	# # Move to the build directory
	# pushd "${lTexBuildDir}"

	# Run the build command
	latexmk \
		-pdf \
		${LATEX_OPTIONS} \
		master.tex \
		> ${DIR_OUTPUT}/latexmk.log

	# If it went well, clean temprary files
	latexmk ${LATEX_OPTIONS} -c


	# Generate the output file name from the directory name and Git
	# description
	local lPdfFinalOutput="$(basename $(pwd))"

	# local lGitDescription=`git describe --long --tags --always --dirty`
	# ${CMD_LOG_DBG} "lGitDescription=${lGitDescription}"
	# lPdfFinalOutput+="-${lGitDescription}"

	lPdfFinalOutput+='.pdf'
	${CMD_LOG_DBG} "lPdfFinalOutput=${lPdfFinalOutput}"

	mv "${DIR_OUTPUT}/master.pdf" "${DIR_OUTPUT}/${lPdfFinalOutput}"
}

# ##############################################################################
# ##############################################################################

F_build_main ${@}

echo "========================================"
echo "    Done."

exit $?
