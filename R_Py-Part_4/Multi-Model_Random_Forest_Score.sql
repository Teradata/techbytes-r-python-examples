--------------------------------------------------------------------------------
-- The contents of this file are Teradata Public Content and have been released
-- to the Public Domain.
-- Tim Miller & Alexander Kolovos - October 2019 - v.1.0
-- Copyright (c) 2019 by Teradata
-- Licensed under BSD; see "license.txt" file in the bundle root folder.
--
--------------------------------------------------------------------------------
-- R and Python TechBytes Demo - Part 4: R in-nodes with SCRIPT and ExecR
--------------------------------------------------------------------------------
-- File: Multi-Model_Random_Forest_Score.sql
--------------------------------------------------------------------------------
-- The R and Python TechBytes Demo comprises of 5 parts:
-- Part 1 consists of only a Powerpoint overview of R and Python in Vantage
-- Part 2 demonstrates the Teradata R package tdplyr for clients
-- Part 3 demonstrates the Teradata Python package teradaml for clients
-- Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
-- Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator
--------------------------------------------------------------------------------
--
-- This file scores the data in the MultiModelTest test table on the basis of
-- the multiple models in the RFStateCodeModels table, in the context of Use
-- Case 2 of the present TechBytes demo Part 4. It assumes these tables have
-- been both created in advance on a target Vantage system. The following
-- utilizes the ExecR Table Operator in the Vantage Advanced SQL Engine, and
-- demonstrates using R code with ExecR. Execute the present file in a SQL
-- interpreter such as Teradata Studio.
--
-- In terms of the TechBytes demo use case, the code uses pre-built models for
-- multiple state codes to predict the propensity of a financial services
-- customer base in these states to open a credit card account. The test table
-- data and models are partitioned based on the state code they refer to,
-- and this achieves simultaneous multiple model scoring across multiple AMPs.
--------------------------------------------------------------------------------

SELECT d.oc1 AS cust_id,
       d.oc2 AS statecode,
       d.oc3 AS Prob0,
       d.oc4 AS Prob1,
       d.oc5 AS Actual
FROM TD_SYSGPL.ExecR (
ON (SELECT cust_id, cast(tot_income as FLOAT) as tot_income,
           tot_age, tot_cust_years, tot_children, female_ind,
           single_ind, married_ind, seperated_ind,
           TRANSLATE(statecode USING UNICODE_TO_LATIN) AS scode,
           ck_acct_ind, sv_acct_ind, cc_acct_ind, ck_avg_bal,
           sv_avg_bal, cc_avg_bal, ck_avg_tran_amt, sv_avg_tran_amt,
           cc_avg_tran_amt, q1_trans_cnt, q2_trans_cnt,
           q3_trans_cnt, q4_trans_cnt, SAMPLE_ID
FROM MultiModelTest)
PARTITION BY scode
ON (SELECT statecode,
           rf_model
    FROM RFStateCodeModels) DIMENSION
RETURNS (oc1 INTEGER, oc2 VARCHAR(5), oc3 FLOAT, oc4 FLOAT, oc5 INTEGER)
USING
  KeepLog(1)
  Operator('
	library(tdr)

	# Open input to read stream 0 with no options

	direction_in <- "R"
	stream_in <- 0
	options <- 0
	handle_in_data <- tdr.Open(direction_in, stream_in, options)

	# Create the entire input dataframe and a dataframe to read data "chunks"

	dfIn <- data.frame()
	dfInChunk <- data.frame()

	# Initialize buffer and read the first data chunk

	buffSize <- as.integer(512*1024)
	dfInChunk <- tdr.TblRead(handle_in_data, buffSize)
	dfInRows <- nrow(dfInChunk)

	# For AMPs that receive no data, close the input stream and return
	# Note: Callng quit() and exiting the script prematurely will cause 7833 errors (ERRUDFExitTaken)

	if (dfInRows == 0)
	{
	  dfIn <- NULL
	  tdr.Close(handle_in_data)
	} else
	{

	  # Bind chunk to input dataframe and read remaining chunks, binding on each iteration

	  while( nrow(dfInChunk) > 0 ) {
 	   dfIn <- rbind(dfIn, dfInChunk)
 	   dfInChunk <- tdr.TblRead(handle_in_data, buffSize)
 	   dfInRows <- dfInRows + nrow(dfInChunk)
	  }

	  # Close the data input stream and open a stream to read the model

	  tdr.Close(handle_in_data)

	  handle_in_model <- tdr.Open("R", 1, 0)

	  myState <- dfIn$scode[1]

	  while ((out <- tdr.Read(handle_in_model) == 0)) {

	    statecode <- tdr.GetAttributeByNdx(handle_in_model, as.integer(0), NULL)

	    if ( trimws(statecode$value) == trimws(myState) ) {
	      locator <- tdr.GetAttributeByNdx(handle_in_model, as.integer(1), NULL)
	      inlob <- tdr.LobOpen_CL(locator, 0, 0)
	      fit_model_blob <- tdr.LobRead(inlob$contextID, inlob$LOBlen)
	      fit_model_raw <- unlist(fit_model_blob$buffer)
	      RF_model <- unserialize(fit_model_raw)
	      break
	    }
	  }

	  # Close the model input stream

	  tdr.Close(handle_in_model)

	  # Load the randomForest package and call predict for all state models

	  suppressPackageStartupMessages(library("randomForest"))
	  Predicted <- suppressWarnings( predict(RF_model, newdata=dfIn, type="vote") );

	  # Build the data frame to export - customer identifier, state code, Probability of 0/1 and the actual value (cc_acct_ind)

	  Scores <- data.frame(dfIn$cust_id, dfIn$scode, Predicted, dfIn$cc_acct_ind, stringsAsFactors = FALSE)

	  # Open up the output handle and write the entire dataframe as a Teradata table

 	  direction_out <- "W"
	  stream_out <- 0
	  handle_out <- tdr.Open(direction_out, stream_out, options)
	  tdr.TblWrite(handle_out, Scores)
	  tdr.Close(handle_out)
	}
  ')
) AS d;
