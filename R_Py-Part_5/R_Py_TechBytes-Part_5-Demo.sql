--------------------------------------------------------------------------------
-- The contents of this file are Teradata Public Content and have been released
-- to the Public Domain.
-- Tim Miller & Alexander Kolovos - April 2020 - v.1.1
-- Copyright (c) 2020 by Teradata
-- Licensed under BSD; see "license.txt" file in the bundle root folder.
--
--------------------------------------------------------------------------------
-- R and Python TechBytes Demo - Part 5: Python in-nodes with SCRIPT
--------------------------------------------------------------------------------
-- File: R_Py_TechBytes-Part_5-Demo.sql
--------------------------------------------------------------------------------
-- The R and Python TechBytes Demo comprises of 5 parts:
-- Part 1 consists of only a Powerpoint overview of R and Python in Vantage
-- Part 2 demonstrates the Teradata R package tdplyr for clients
-- Part 3 demonstrates the Teradata Python package teradataml for clients
-- Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
-- Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator
--------------------------------------------------------------------------------
--
-- This TechBytes demo utilizes a use case to predict the propensity of a
-- financial services customer base to open a credit card account.
--
-- The present file contains the SQL statements to be submitted to the target
-- Vantage system Advanced SQL Engine for two different scenarios in the use
-- cases 1 and 2 of this demo Part 5. Specifically:
--
-- 1) Fitting and scoring a single model
--
--    We want to execute the scoring script "stoRFScore.py" in the Advanced
--    SQL Engine by using the SCRIPT table operator to score the entire test
--    data set.
--    The present SQL script
--    a) loads into the Advanced SQL Engine the model previously created
--    b) loads into the Advanced SQL Engine the above Python script
--    c) executes a query with the SCRIPT Table Operator that invokes the
--       Python interpreter installed in the target Vantage Advanced SQL Engine.
--       The call to the interpreter specifies the Python scoring script as an
--       argument. As a result, an instance of the script is executed on each
--       Advanced SQL Engine AMP, and thus achieves scaled scoring.
--
-- 2) Fitting and scoring multiple models
--
--    We want to build a Random Forest model in the Advanced SQL Engine for
--    every state in the training dataset, by using the Python training script
--    "stoRFFitMM.py" with the SCRIPT Table Operator. Subsequently, we want to
--    score the testing dataset with the Python scoring script "stoRFScoreMM.py"
--    also via the SCRIPT Table Operator. The present SQL script executes in a
--    sequence each one of the above (A) model fitting and (B) scoring tasks.
--    For each task, the present SQL script
--    a) loads into the Advanced SQL Engine the corresponding Python script
--    b) executes a query with the SCRIPT Table Operator that invokes the
--       Python interpreter installed in the target Vantage Advanced SQL Engine.
--       The call to the interpreter specifies the appropriate Python script
--       as an argument.
--
--    In the model fitting task (A), SCRIPT partitions the data on the database
--    by the state code variable. This achieves gathering all rows for a single
--    state into a single AMP. As a result, when the fitting script executes,
--    multiple model fittings take place simultaneously across the system AMPs,
--    thus scaling the fitting process. The resulting models information is
--    stored as the table "RFStateCodeModelsPy" in the Advanced SQL Engine.
--
--    In the scoring task (B), SCRIPT merges the models and test dataset tables
--    information to provide the scoring script with the necessary input for
--    scoring the test dataset.
--
--------------------------------------------------------------------------------
-- Reminder: In case of errors, the SCRIPT Table Operator full standard error
--           output is channeled to the file
--           /var/opt/teradata/tdtemp/uiflib/scriptlog
--           on each Advanced SQL Engine node of the target Vantage system.
--------------------------------------------------------------------------------
-- File Changelog
--  v.1.0     2019-10-29     First release
--  v.1.1     2020-04-02     Added change log; no code changes in present file
--  v.1.1.1   2020-04-24     Bug fix: Column "sampleid" confused with keyword
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Use Case [1]: Model built external to Vantage is scored in Vantage
--------------------------------------------------------------------------------


-- Before you execute the following statements, replace <DBNAME> with the
-- database name in the target Vantage Advanced SQL Engine where the score/test
-- dataset table "ADS_Py" resides. This s the database where the model and
-- script files to be uploaded to, as well.
DATABASE <DBNAME>;
SET SESSION SEARCHUIFDBPATH = <DBNAME>;

-- Import the model into Vantage with the SYSUIF.INSTALL_FILE() XSP.
-- If you modify the model, then you need to re-install it in the database.
--
-- The SYSUIF.REMOVE_FILE() XSP removes the old version. If no previous version
-- of the file exists in the database, then the following statement will fail.
call SYSUIF.REMOVE_FILE('RFmodel_py',1);
-- The SYSUIF.INSTALL_FILE() XSP installs the specified file into the database.
-- Before you execute the following statement, replace "modelPATH" with the
-- full path to the saved model file on your client machine.
-- Example: Assume you are on the MacOS platform and you want to store the
--          "RFmodel_py.out" model file in your home directory /Users/me. Then
--          modelPATH = /Users/me/RFmodel_py.out
call SYSUIF.INSTALL_FILE('RFmodel_py','RFmodel_py.out','cz!modelPATH');

-- Now import into Vantage the scoring script that uses the model.
-- If you modify the script, then you need to re-install it in the database.
--
-- The SYSUIF.REMOVE_FILE() XSP removes the old version. If no previous version
-- of the file exists in the database, then the following statement will fail.
CALL SYSUIF.REMOVE_FILE('stoRFScore',1);
-- The SYSUIF.INSTALL_FILE() XSP installs the specified file into the database.
-- Before you execute the following statement, replace "scriptPATH" with the
-- full path to the Python scoring script file on your client machine.
-- Example: Assume you are on the MacOS platform and you want to store the
--          "stoRFScore.py" script file in your home directory /Users/me. Then
--          scriptPATH = /Users/me/stoRFScore.py
CALL SYSUIF.INSTALL_FILE('stoRFScore','stoRFScore.py','cz!scriptPATH');

-- Invoke the Python interpreter from SCRIPT and specify the script name to
-- execute for scoring the ADS_Py rows on every AMP with your imported model.
-- The script should account for a graceful exit on AMPs that have no data.
--
-- Before you execute the following statement, replace <DBNAME> with the
-- database name you specified in the beginning of Use Case [1] in this file,
-- in which table "ADS_Py" and the model and script files reside.
SELECT d.oc1 AS cust_id,
       d.oc3 AS Prob0,
       d.oc4 AS Prob1,
       d.oc5 AS Actual
FROM SCRIPT( ON(SELECT *
                FROM ADS_Py)
             SCRIPT_COMMAND('python3 ./<DBNAME>/stoRFScore.py')
             RETURNS ('oc1 INTEGER, oc3 FLOAT, oc4 FLOAT, oc5 INTEGER')
           ) AS d;


--------------------------------------------------------------------------------
-- Use Case [2]: Simultaneously build multiple models based upon state code
--------------------------------------------------------------------------------

-- Before you execute the following statements, replace <DBNAME> with the
-- database name in the target Vantage Advanced SQL Engine where the tables
-- "MultiModelTrain_Py" and "MultiModelTest_Py" reside, and where you want
-- the script files and output tables to be sent to.
DATABASE <DBNAME>;
SET SESSION SEARCHUIFDBPATH = <DBNAME>;

-- Part (A): Model fitting
--------------------------------------------------------------------------------
--
-- Import into Vantage the multiple model fitting script.
-- If you modify the script, then you need to re-install it in the database.
--
-- The SYSUIF.REMOVE_FILE() XSP removes the old version. If no previous version
-- of the file exists in the database, then the following statement will fail.
CALL SYSUIF.REMOVE_FILE('stoRFFitMM',1);
-- The SYSUIF.INSTALL_FILE() XSP installs the specified file into the database.
-- Before you execute the following statement, replace "mmfitscrPATH" with the
-- full path to the Python fitting script file on your client machine.
-- Example: Assume you are on the MacOS platform and you want to store the
--          "stoRFFitMM.py" script file in your home directory /Users/me. Then
--          mmfitscrPATH = /Users/me/stoRFFitMM.py
CALL SYSUIF.INSTALL_FILE('stoRFFitMM','stoRFFitMM.py','cz!mmfitscrPATH');

-- Use following statement, if applicable, to remove an existing table version.
-- If the table in not in the database, then the following statement will fail.
DROP TABLE RFStateCodeModelsPy;

-- Invoke the Python interpreter from SCRIPT, and specify the script name to
-- run and fit one model on every AMP that has a training data partition on it.
-- The SQL query shows that each AMP is expected to return the state code for
-- which it has data, and the fitted model for the corresponding partition.
-- When AMPs happen to host multiple partitions, as when there are more state
-- codes than AMPs on the Advanced SQL Engine, then the script will accordingly
-- produce a model for each partition. If there are fewer state codes than
-- AMPs on the Vantage Advanced SQL Engine, then some AMPs will receive no data.
-- The script should account for a graceful exit for AMPs with no data.
--
-- Before you execute the following statement, replace <DBNAME> with the
-- database name you specified in the beginning of Use Case [2] earlier.
-- In the following statement, the "sampleid" column of the input table is
-- enclosed in quotes to differentiate the name from the SQL keyword sampleid.
CREATE TABLE RFStateCodeModelsPy AS (
    SELECT d.oc1 AS statecode,
           d.oc2 AS rf_model
    FROM SCRIPT ( ON (SELECT cust_id, cast(tot_income as FLOAT) as tot_income,
                             tot_age, tot_cust_years, tot_children, female_ind,
                             single_ind, married_ind, separated_ind,
                             TRANSLATE(statecode USING UNICODE_TO_LATIN) AS scode,
                             ck_acct_ind, sv_acct_ind, cc_acct_ind, ck_avg_bal,
                             sv_avg_bal, cc_avg_bal, ck_avg_tran_amt, sv_avg_tran_amt,
                             cc_avg_tran_amt, q1_trans_cnt, q2_trans_cnt,
                             q3_trans_cnt, q4_trans_cnt, "sampleid"
                      FROM MultiModelTrain_Py)
                  PARTITION BY scode
                  SCRIPT_COMMAND('python3 ./<DBNAME>/stoRFFitMM.py')
                  RETURNS ('oc1 VARCHAR(10), oc2 CLOB')
                ) AS d
   ) WITH DATA
     PRIMARY INDEX (statecode);

-- Part (B): Scoring with models
--------------------------------------------------------------------------------
--
-- Import into Vantage the multiple model scoring script.
-- If you modify the script, then you need to re-install it in the database.
--
-- The SYSUIF.REMOVE_FILE() XSP removes the old version. If no previous version
-- of the file exists in the database, then the following statement will fail.
call SYSUIF.REMOVE_FILE('stoRFScoreMM',1);
-- The SYSUIF.INSTALL_FILE() XSP installs the specified file into the database.
-- Before you execute the following statement, replace "mmscoscrPATH" with the
-- full path to the Python scoring script file on your client machine.
-- Example: Assume you are on the MacOS platform and you want to store the
--          "stoRFScoreMM.py" script file in your home directory /Users/me. Then
--          mmscoscrPATH = /Users/me/stoRFScoreMM.py
call SYSUIF.install_file('stoRFScoreMM','stoRFScoreMM.py','cz!mmscoscrPATH');

-- Invoke the Python interpreter from SCRIPT, and specify the script name to
-- score one model on every AMP that has a test/scoring data partition on it
-- for the corresponding state code.
-- Observe the input data sent to the script: Essentially the test/scoring data
-- partition is passed to the script plus an additional column. We specify the
-- corresponding model for this partition's state code to be passed in the first
-- row of this extra column, and null in the rest of the rows. For this trick
-- to work correctly, it is critical to specify the "ORDER BY nRow" clause.
-- The script code should account for reading in the model from the input data
-- set first row. The script should also account for a graceful exit on AMPs
-- that have no data.
--
-- Before you execute the following statement, replace <DBNAME> with the
-- database name you specified in the beginning of Use Case [2] earlier.
-- In the following statement, the "sampleid" column of the nested input table
-- is enclosed in quotes to differentiate the name from the SQL keyword sampleid.
SELECT d.oc1 AS cust_id,
       d.oc2 AS statecode,
       d.oc3 AS Prob0,
       d.oc4 AS Prob1,
       d.oc5 AS Actual
FROM SCRIPT( ON(SELECT s.*,
                       CASE WHEN nRow=1 THEN m.rf_model ELSE null END
                FROM (SELECT x.cust_id, CAST (x.tot_income as FLOAT) as tot_income,
                             x.tot_age, x.tot_cust_years, x.tot_children, x.female_ind,
                             x.single_ind, x.married_ind, x.separated_ind,
                             TRANSLATE(x.statecode USING UNICODE_TO_LATIN) AS scode,
                             x.ck_acct_ind, x.sv_acct_ind, x.cc_acct_ind, x.ck_avg_bal,
                             x.sv_avg_bal, x.cc_avg_bal, x.ck_avg_tran_amt, x.sv_avg_tran_amt,
                             x.cc_avg_tran_amt, x.q1_trans_cnt, x.q2_trans_cnt,
                             x.q3_trans_cnt, x.q4_trans_cnt, x."sampleid",
                             row_number() OVER (PARTITION BY x.cust_id ORDER BY x.cust_id) AS nRow
                      FROM MultiModelTest_Py x) AS s, RFStateCodeModelsPy m
                WHERE s.scode = m.statecode)
             PARTITION BY scode
             ORDER BY nRow
             SCRIPT_COMMAND('python3 ./<DBNAME>/stoRFScoreMM.py')
             RETURNS ('oc1 INTEGER, oc2 VARCHAR(10), oc3 FLOAT, oc4 FLOAT, oc5 INTEGER')
           ) AS d;
