#!/bin/bash

set -e
# set -x

CMD_CP='cp -rv'
CMD_MKDIR='mkdir -pv'

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

# if [[ "$#" -eq "2" ]]

# Set the path to the directory containing the invoices template
DIR_TEMPLATE="$(pwd)/template"
${CMD_LOG_DBG} "DIR_TEMPLATE=${DIR_TEMPLATE}"


# Set the path to the directory containing all the invoice years
DIR_INVOICES="$(pwd)/invoices"
${CMD_LOG_DBG} "DIR_INVOICES=${DIR_INVOICES}"
if [[ ! -d "${DIR_INVOICES}" ]]
then
	${CMD_MKDIR} "${DIR_INVOICES}"
fi


# Set the path to the directory containing all the invoices for the current year
DATE_CURRENT_YEAR=`date +%Y`
${CMD_LOG_DBG} "DATE_CURRENT_YEAR=${DATE_CURRENT_YEAR}"

DIR_INVOICES_THISYEAR="${DIR_INVOICES}/${DATE_CURRENT_YEAR}"
${CMD_LOG_DBG} "DIR_INVOICES_THISYEAR=${DIR_INVOICES_THISYEAR}"
if [[ ! -d "${DIR_INVOICES_THISYEAR}" ]]
then
	${CMD_MKDIR} "${DIR_INVOICES_THISYEAR}"
fi


# Count the invoices in the directory
STR_INVOICE_PREFIX="Facture${DATE_CURRENT_YEAR}"
lCurrentYearInvoicesCount=`ls -1 ${DIR_INVOICES_THISYEAR}/${STR_INVOICE_PREFIX}* | wc -l`
${CMD_LOG_DBG} "lCurrentYearInvoicesCount=${lCurrentYearInvoicesCount}"


# Calculate the next invoice number and add it to the new invoice dir name
lNextInvoiceCount=$((lCurrentYearInvoicesCount + 1))
${CMD_LOG_DBG} "lNextInvoiceCount=${lNextInvoiceCount}"

lNewInvoiceName="${STR_INVOICE_PREFIX}$(printf '%05d' ${lNextInvoiceCount})"
${CMD_LOG_DBG} "lNewInvoiceName=${lNewInvoiceName}"


# Ask the operator for a suffix and add it to the new invoice name
read -p "Invoice name suffix (can be left empty): " lNewInvoiceNameSuffix

if [[ -z "${lNewInvoiceNameSuffix}" ]]
then
	${CMD_LOG_DBG} "No suffix provided."
else
	lNewInvoiceName+="-${lNewInvoiceNameSuffix}"
	${CMD_LOG_DBG} "lNewInvoiceName=${lNewInvoiceName}"
fi


# Generate the new invoice directory path
lNewInvoiceDirPath="${DIR_INVOICES_THISYEAR}/${lNewInvoiceName}"
${CMD_LOG_DBG} "lNewInvoiceDirPath=${lNewInvoiceDirPath}"


# Copy the template to the new invoice directory
${CMD_CP} "${DIR_TEMPLATE}" "${lNewInvoiceDirPath}"



exit $?