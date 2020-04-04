--------------------------------------------------------------------------------
-- The contents of this file are Teradata Public Content and have been released
-- to the Public Domain.
-- Tim Miller & Alexander Kolovos - April 2020 - v.1.1
-- Copyright (c) 2020 by Teradata
-- Licensed under BSD; see "license.txt" file in the bundle root folder.
--
--------------------------------------------------------------------------------
-- R and Python TechBytes Demo - Part 4: R in-nodes with SCRIPT and ExecR
--------------------------------------------------------------------------------
-- File: Multi-Model_Random_Forest_Build.sql
--------------------------------------------------------------------------------
-- The R and Python TechBytes Demo comprises of 5 parts:
-- Part 1 consists of only a Powerpoint overview of R and Python in Vantage
-- Part 2 demonstrates the Teradata R package tdplyr for clients
-- Part 3 demonstrates the Teradata Python package teradaml for clients
-- Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
-- Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator
--------------------------------------------------------------------------------
--
-- This file builds multiple models in the context of Use Case 2 of the present
-- TechBytes demo Part 4. It assumes the table MultiModelTrain has been created
-- in advance on a target Vantage system. The following utilizes the ExecR
-- Table Operator in the Vantage Advanced SQL Engine, and demonstrates using
-- R code with ExecR. Execute the present file in a SQL interpreter such as
-- Teradata Studio.
--
-- In terms of the TechBytes demo use case, the code aims to build a model
-- to predict the propensity of a financial services customer base to open
-- a credit card account. In the present use case, a model is requested for
-- each one in a series of state codes. The data for each state code reside
-- separately on individual AMPs of the target Vantage system Advanced SQL
-- Engine. ExecR executes the R code simultaneously on each AMP. The R code
-- naturally exits on the empty AMPs, whereas the AMPs with data each produce
-- a model based on the corresponding state code for which they carry data.
-- Upon completion, all models are collected as output by ExecR, and stored
-- in the RFStateCodeModels table.
-- In case of repeated executions, the "CREATE TABLE" query that calls ExecR
-- will fail if the RFStateCodeModels table already exists. To prevent this,
-- the query is preceded by a "DROP TABLE" statement. The initial "DROP TABLE"
-- statement is expected to fail when the RFStateCodeModels table is absent.
--------------------------------------------------------------------------------
-- File Changelog
--  v.1.0     2019-10-29     First release
--  v.1.1     2020-04-02     Added change log; no code changes in present file
--------------------------------------------------------------------------------

DROP TABLE RFStateCodeModels;

CREATE TABLE RFStateCodeModels AS (
  SELECT CAST (d.oc1 AS CHAR(5)) AS statecode,
               d.oc2 AS rf_model
  FROM TD_SYSGPL.ExecR (
  ON (SELECT cust_id, cast(tot_income as FLOAT) as tot_income,
             tot_age, tot_cust_years, tot_children, female_ind,
             single_ind, married_ind, seperated_ind,
             TRANSLATE(statecode USING UNICODE_TO_LATIN) AS scode,
             ck_acct_ind, sv_acct_ind, cc_acct_ind, ck_avg_bal,
             sv_avg_bal, cc_avg_bal, ck_avg_tran_amt, sv_avg_tran_amt,
             cc_avg_tran_amt, q1_trans_cnt, q2_trans_cnt,
             q3_trans_cnt, q4_trans_cnt, SAMPLE_ID
  FROM MultiModelTrain)

  PARTITION BY scode
  RETURNS (oc1 VARCHAR(5), oc2 BLOB)
  USING
    KeepLog(1)
    Operator('
    library(tdr)

  	# Open input to read stream 0 with no options

  	direction_in <- "R"
  	stream_in <- 0
  	options <- 0
  	handle_in <- tdr.Open(direction_in, stream_in, options)

  	# Create the entire input dataframe and a dataframe to read data "chunks"

  	dfIn <- data.frame()
  	dfInChunk <- data.frame()

  	# Initialize buffer and read the first data chunk

  	buffSize <- as.integer(512*1024)
  	dfInChunk <- tdr.TblRead(handle_in, buffSize)
  	dfInRows <- nrow(dfInChunk)

  	# For AMPs that receive no data, close the input stream and return
  	# Note: Callng quit() and exiting the script prematurely will cause 7833 errors (ERRUDFExitTaken)

  	if (dfInRows == 0)
  	{
  	  dfIn <- NULL
  	  tdr.Close(handle_in)
  	} else
  	{

  	  # Bind chunk to input dataframe and read remaining chunks, binding on each iteration

  	  while( nrow(dfInChunk) > 0 ) {
  	    dfIn <- rbind(dfIn, dfInChunk)
  	    dfInChunk <- tdr.TblRead(handle_in, buffSize)
  	    dfInRows <- dfInRows + nrow(dfInChunk)
  	  }

  	  # Close input stream

  	  tdr.Close(handle_in)

  	  # Build Random Forest Models for 6 statecodes (and other)

  	  suppressPackageStartupMessages(library("randomForest"))

  	  dfIn$cc_acct_ind=as.factor(dfIn$cc_acct_ind)

  	  RFmodel <- suppressWarnings(
   	   randomForest(formula = (cc_acct_ind ~
  	                           tot_income +
  	                           tot_age +
                                 tot_cust_years +
                                 tot_children +
                                 female_ind +
                                 single_ind +
                                 married_ind +
                                 seperated_ind +
                                 ck_acct_ind +
                                 sv_acct_ind +
                                 ck_avg_bal +
                                 sv_avg_bal +
                                 ck_avg_tran_amt +
                                 sv_avg_tran_amt +
                                 q1_trans_cnt +
                                 q2_trans_cnt +
                                 q3_trans_cnt +
                                 q4_trans_cnt),
                      data = dfIn,
                      ntree = 500,
                      nodesize = 1,
                      mtry = 5
          )
  	  )

  	  # Open output stream

  	  direction_out <- "W"
  	  stream_out <- 0
  	  handle_out <- tdr.Open(direction_out, stream_out, options)

  	  # Prepare the state code and model for insertion into the database.
  	  # First serialize the model, locate the model in the BLOB column and append it to the output

  	  BLOBidx <- 1
  	  Scodeidx <- 0
  	  outRFModel <- serialize(RFmodel, NULL)
  	  locator <- tdr.LobCol2Loc(stream_out, BLOBidx)
  	  tdr.LobAppend(locator, outRFModel)

  	  # Next, set the attribute for statecode, write the data and close the output stream.

  	  tdr.SetAttributeByNdx(handle_out, Scodeidx, list(value = dfIn$scode, nullindicator=0), NULL)
  	  tdr.Write(handle_out)
  	  tdr.Close(handle_out)
  	}
    ')
  ) AS d
) WITH DATA PRIMARY INDEX (statecode);

SELECT * FROM RFStateCodeModels;
