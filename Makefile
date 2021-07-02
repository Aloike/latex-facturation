DIR_SRC:=factures
# DIR_OUTPUT:=$(DIR_SRC)
DIR_OUTPUT:=out


LATEX=pdflatex

LATEX_OPTIONS:=
LATEX_OPTIONS+= -file-line-error
LATEX_OPTIONS+= -halt-on-error
LATEX_OPTIONS+= -interaction=nonstopmode
LATEX_OPTIONS+= -output-directory=$(DIR_OUTPUT)




# ##############################################################################
#   DO NOT EDIT BELOW THIS LINE
# ##############################################################################

SHELL:=/bin/bash



# ------------------------------------------------------------------------------
#   Bash control chars definitions
# ------------------------------------------------------------------------------

# From https://stackoverflow.com/a/12099167
ifeq ($(OS),Windows_NT)
	echo "Windows not supported !"
	exit 1
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		ESC_CHAR:="\\e"
	endif
	ifeq ($(UNAME_S),Darwin)
		ESC_CHAR:="\\033"
	endif
endif


# Bash format definitions
FMT_CLR:="${ESC_CHAR}[0m"
FMT_BLD:="${ESC_CHAR}[1m"
FMT_UDL:="${ESC_CHAR}[4m"

# Bash colors list
COL_BLK:="${ESC_CHAR}[40m"
COL_BLU:="${ESC_CHAR}[44m"
COL_CYN:="${ESC_CHAR}[30;46m"
COL_GRE:="${ESC_CHAR}[47m"
COL_GRN:="${ESC_CHAR}[30;42m"
COL_ORG:="${ESC_CHAR}[30;43m"
COL_MAG:="${ESC_CHAR}[30;45m"
COL_RED:="${ESC_CHAR}[41m"
COL_YLW:="${ESC_CHAR}[30;103m"

# Control char to fill a line
CLREOL:="${ESC_CHAR}[K"

# Aliases to define which color to use for this makefile's traces
lColorDoc       :="${COL_GRN}"
lColorRM        :="${COL_RED}"



# ------------------------------------------------------------------------------
#   Auto-generated variables
# ------------------------------------------------------------------------------


#FILES_TEX:=$(shell (cd $(DIR_SRC) && ls -1 *.tex) )
FILES_TEX:=$(shell (find $(DIR_SRC) -type f -iname '*.tex') )
# FILES_TEX:=$(shell (find * -type f -iname '*.tex') )
# FILES_PDF:=$(FILES_TEX:.tex=.pdf)
FILES_PDF:=$(addprefix $(DIR_OUTPUT)/,$(FILES_TEX:.tex=.pdf))

#.PHONY: $(FILES_PDF) $(FILES_PDF:%=$(DIR_SRC)%)



# ------------------------------------------------------------------------------
#   Makefile log management
# ------------------------------------------------------------------------------

# To manage traces activation through command line call
ifndef TRACES
	TRACES=0
else
	#@echo "TRACES=${TRACES}"
	TRACES=1
endif


##  @brief  This variable defines the log file path
FILE_TRACE:=$(DIR_OUTPUT)/trace_$(shell date --rfc-3339=s |sed -e 's![ ]!_!g').log


# Here we define some aliases to manage traces redirections
ifeq (${TRACES},0)
#	echo "Traces are disabled."
	TRACE_REDIRECT:=1>/dev/null
	TRACE_LOG:=
else
#	echo "Traces are enabled."
	TRACE_REDIRECT:=2>&1|tee -a $(FILE_TRACE)
	TRACE_LOG:=$(TRACE_REDIRECT)
endif



define F_exec_cmd
	@pCmd=$(1); \
	     \
	echo 'exec' $${pCmd} \
	$(TRACE_REDIRECT) ;\
	\
	$${pCmd} $(TRACE_REDIRECT); \
	if [ ! "$$?" -eq "0" ] ; then echo "an error occured"; exit 1; fi;
endef



# ------------------------------------------------------------------------------
#   Makefile targets
# ------------------------------------------------------------------------------

#
##  @brief  Default target.
#
all: world clean



#
##  @brief  This target removes all intermediary files.
#
clean:
	@lTargets=("$(DIR_OUTPUT)/*.log"); \
	lTargets+=("$(DIR_OUTPUT)/*.aux"); \
	lTargets+=("$(DIR_OUTPUT)/*.out"); \
	echo -e "${lColorRM}    RM  $${lTargets[@]} ${CLREOL}${FMT_CLR}" #$(TRACE_REDIRECT); \
	rm -rvf $${lTargets[@]} $(TRACE_REDIRECT)



#
##  @brief  This target remove all output files.
#
flush: clean
	@lTargets=("$(DIR_OUTPUT)/*.pdf"); \
	echo -e "${lColorRM}    RM  $${lTargets[@]} ${CLREOL}${FMT_CLR}" #$(TRACE_REDIRECT); \
	rm -rvf $${lTargets[@]} $(TRACE_REDIRECT)
	rmdir -v $(DIR_OUTPUT) $(TRACE_REDIRECT)



list:
	@for lFile in $(FILES_TEX) ; \
	do \
		echo "TEX file  : $${lFile}"; \
	done
	@for lFile in $(FILES_PDF) ; \
	do \
		echo "PDF file  : $${lFile}"; \
	done



#
##  @brief  Generate all invoices.
#
world: $(FILES_PDF) #$(DIR_SRC)/*.pdf



#
##  @brief  Target to create the output directory.
#
$(DIR_OUTPUT):
	mkdir -p $@



#
##  @brief  Default target to build PDFs from LaTeX files.
#
# %.pdf:%.tex
# $(FILES_PDF): $(DIR_SRC)/%.pdf: $(DIR_SRC)/%.tex
$(FILES_PDF): $(DIR_OUTPUT)/%.pdf : %.tex $(DIR_OUTPUT)
	@echo -e "${lColorDoc}    TEX $@${CLREOL}${FMT_CLR}" $(TRACE_LOG)
#	# Multiple calls are needed to update references.
	@$(call F_exec_cmd,"${LATEX} ${LATEX_OPTIONS} $<")
	@$(call F_exec_cmd,"${LATEX} ${LATEX_OPTIONS} $<")



# %.tex:
# 	@echo -e "${lColorDoc}    TEX $@${CLREOL}${FMT_CLR}" $(TRACE_LOG)
# #	# Multiple calls are needed to update references.
# 	$(call F_exec_cmd,"${LATEX} ${LATEX_OPTIONS} $@")
# 	@$(call F_exec_cmd,"${LATEX} ${LATEX_OPTIONS} $@")



#
##  @brief  Alias target to build PDF files without specifying the directory.
#
$(DIR_SRC)/%.pdf %.pdf %.tex: $(DIR_OUTPUT)/$(DIR_SRC)/%.pdf
	@echo "make $@" $(TRACE_REDIRECT)



#
##  @brief  Alias target to build PDF files without specifying the directory nor
##          the extension.
#
%: $(DIR_OUTPUT)/$(DIR_SRC)/%.pdf
	@echo "make $@" $(TRACE_REDIRECT)
