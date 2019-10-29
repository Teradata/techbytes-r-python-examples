################################################################################
# * The contents of this file are Teradata Public Content and have been released
# * to the Public Domain.
# * Tim Miller & Alexander Kolovos - October 2019 - v.1.0
# * Copyright (c) 2019 by Teradata
# * Licensed under BSD; see "license.txt" file in the bundle root folder.
#
# ##############################################################################
# R and Python TechBytes Demo - Part 4: R in-nodes with SCRIPT and ExecR
# ------------------------------------------------------------------------------
# File: RFScore.r
# ------------------------------------------------------------------------------
# The R and Python TechBytes Demo comprises of 5 parts:
# Part 1 consists of only a Powerpoint overview of R and Python in Vantage
# Part 2 demonstrates the Teradata R package tdplyr for clients
# Part 3 demonstrates the Teradata Python package teradaml for clients
# Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
# Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator
# ##############################################################################
#
# This TechBytes demo utilizes a use case to predict the propensity of a
# financial services customer base to open a credit card account.
#
# The present file is the scoring script to be used in USE CASE [1] of this
# demo. Scoring will take place in the Advanced SQL Engine of the target
# Vantage system via the SCRIPT Table Operator, and demonstrates using R code
# with SCRIPT.
#
# The present script
# a. reads the RFmodel object prepared in the context of USE CASE [1] in the
#    "R_Py_TechBytes-Part_4-Demo.r" file
# b. performs the predict() task on each AMP in the Advanced SQL Engine of the
#    target Vantage system.
# To execute the present script in the database, follow the steps in Section 2
# of USE CASE [1] in the "R_Py_TechBytes-Part_4-Demo.r" file.
################################################################################

DELIMITER='\t'

stdin <- file(description="stdin",open="r")

inputDF <- data.frame();

# NOTE: You must know in advance the name and type of the input columns.
#       Cite them in following two vectors to feed the colClasses and col.names
#       arguments of the read.table() function.
#
# cust_id         <integer>
# tot_income      <double>
# tot_age         <integer>
# tot_cust_years  <integer>
# tot_children    <integer>
# female_ind      <integer>
# single_ind      <integer>
# married_ind     <integer>
# seperated_ind   <integer>
# ca_resident_ind <integer>
# ny_resident_ind <integer>
# tx_resident_ind <integer>
# il_resident_ind <integer>
# az_resident_ind <integer>
# oh_resident_ind <integer>
# ck_acct_ind     <integer>
# cc_acct_ind     <factor>
# sv_acct_ind     <integer>
# ck_avg_bal      <double>
# sv_avg_bal      <double>
# cc_avg_bal      <double>
# ck_avg_tran_amt <double>
# sv_avg_tran_amt <double>
# cc_avg_tran_amt <double>
# q1_trans_cnt    <integer>
# q2_trans_cnt    <integer>
# q3_trans_cnt    <integer>
# q4_trans_cnt    <integer>

cn <- c("cust_id", "tot_income", "tot_age", "tot_cust_years", "tot_children", "female_ind",
        "single_ind", "married_ind", "seperated_ind", "ca_resident_ind", "ny_resident_ind",
        "tx_resident_ind", "il_resident_ind", "az_resident_ind", "oh_resident_ind",
        "ck_acct_ind", "cc_acct_ind", "sv_acct_ind", "ck_avg_bal", "sv_avg_bal", "cc_avg_bal",
        "ck_avg_tran_amt", "sv_avg_tran_amt", "cc_avg_tran_amt", "q1_trans_cnt",
        "q2_trans_cnt", "q3_trans_cnt", "q4_trans_cnt")

ct <- c("integer", "double", "integer", "integer", "integer", "integer", "integer",
        "integer", "integer", "integer", "integer", "integer", "integer", "integer", "integer",
        "integer", "factor", "integer", "double", "double", "double", "double", "double",
        "double", "integer", "integer", "integer", "integer")

inputDF <- try(read.table(stdin, sep=DELIMITER, flush=TRUE, header=FALSE, quote="",
                          na.strings="", colClasses=ct, col.names=cn), silent=TRUE)

close(stdin)

# For AMPs that receive no data, choose to simply quit the script immediately.

if (class(inputDF) == "try-error") {
  inputDF <- NULL
  quit()
}

# "tdatuser" is the user who executes the present script within the Script TO,
# and this user must have permission to read output objects from the specified
# destinations in the following. Ensure "root" user pre-sets proper permissions.

suppressPackageStartupMessages(library("randomForest"))

# Before you execute the following statement, replace <DBNAME> with the
# database name in the target Vantage Advanced SQL Engine where the .Rds
# R model file was saved in the bottom of Section 1 of the Use Case [1]
# segment in the "R_Py_TechBytes-Part_4-Demo.r" file.
ScoreModel <- readRDS("./<DBNAME>/RFmodel.rds")

Predicted <- predict(ScoreModel, newdata=inputDF, type="vote")

# Build export data frame:

Scores <- data.frame(inputDF$cust_id, Predicted, inputDF$cc_acct_ind)

# Export results to Teradata through standard output

write.table(Scores, file=stdout(), col.names=FALSE, row.names=FALSE,
            quote=FALSE, sep="\t", na="")
