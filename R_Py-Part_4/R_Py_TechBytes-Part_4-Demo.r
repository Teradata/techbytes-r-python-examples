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
# File: R_Py_TechBytes-Part_4-Demo.r
# ------------------------------------------------------------------------------
# The R and Python TechBytes Demo comprises of 5 parts:
# Part 1 consists of only a Powerpoint overview of R and Python in Vantage
# Part 2 demonstrates the Teradata R package tdplyr for clients
# Part 3 demonstrates the Teradata Python package teradataml for clients
# Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
# Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator
# ##############################################################################
#
# This TechBytes demo utilizes a use case to predict the propensity of a
# financial services customer base to open a credit card account.
#
# The present demo Part 4 showcases two scenarios: We show the 2 use case types
# that are most broadly used with the Vantage SCRIPT and ExecR table operators:
#
# 1) Fitting and scoring a single model
#
#    First, we take a 25% sample extracted from the database and build a Random
#    Forest model on an R client. This Random Forest model is then saved as a
#    .Rds native R file, and installed back on the Vantage Advanced SQL Engine.
#    We formulate a scoring script and execute this on the Advanced SQL Engine
#    by using the SCRIPT table operator to score the entire data set. We use
#    the same analytic data set as used in the tdplyr demo (Part 2).
#
# 2) Fitting and scoring multiple models
#
#    Next we utilize the statecode variable as a partition to built a Random
#    Forest model for every state. This is done by using the ExecR Table
#    Operator with a PARTITION BY statecode in the query.
#    This creates a model for each of the CA, NY, TX, IL, AZ, OH and Other
#    state codes and persists the model in the database via CREATE TABLE AS
#    statement.
#    Then we run a scoring script via the ExecR Table Operator against these
#    persisted Random Forest models to score the entire data set. We utilize
#    the same analytic data set as in the tdplyr demo, with one change as
#    indicated by (d) below. This is so we can demonstrate the in-database
#    capability of simultaneously building many models. Various features will
#    be generated by joining and aggregating from three tables (10K customers,
#    100K accounts, 1M+ transactions) into an analytic data set.  We will show
#    how to use dplyr verbs to do this:
#
#   (a) Pull through the cust_id, income, age, years_with_bank, nbr_children
#       from the Customer table.
#   (b) Create a gender indicator variable (female_ind) from gender in the
#       Customer table.
#   (c) Create marital status indicator variables (single_ind, married_ind,
#       seperated_ind) from marital_status in the Customer table.
#   (d) Recode the state_code variable into, CA, NY, TX, IL, AZ, OH and Other
#       in Customer table. This replaces the location indicator variables
#       (ca_resident, ny_resident, tx_resident, il_resident, az_resident,
#       oh_resident) in the Analytic Data Set used in the tdplyr demo.
#   (e) Create account indicator variables (ck_acct_ind, cc_acct_ind,
#       sv_acct_ind) from acct_type in the Account table.
#   (f) Create average balance variables (ck_avg_bal, cc_avg_bal, sv_avg_bal)
#       by taking the mean of the beginning_balance and ending_balance in the
#       Account table.
#   (g) Create average transaction amounts (ck_avg_tran_amt, cc_avg_tran_amt,
#       sv_avg_tran_amt) by taking the average of the principal_amt and
#       interest_amt in the Transactions table.
#   (h) Create quarterly transaction counts (q1_nbr_trans, q2_nbr_trans,
#       q3_nbr_trans, q4_nbr_trans) by taking the count of tran_id's based
#       upon tran_date in the Transactions table.
#
################################################################################

# Load tdplyr and dependency packages. Will be using them in both use cases.
# Also, load the randomForest package to create a random forest model on the
# client.

LoadPackages <- function() {
  library(odbc)
  library(DBI)
  library(dplyr)
  library(dbplyr)
  library(teradatasql)
  library(tdplyr)
  library(dbplot)
  library(randomForest)
}

suppressPackageStartupMessages(LoadPackages())

###
### Connection
###

# Establish a connection to Teradata Vantage server with the Teradata R native
# driver. Before you execute the following statement, replace the variables
# <HOSTNAME>, <UID>, and <PWD> with the target Vantage system hostname, your
# database user ID, and password, respectively.
con <- td_create_context(host = "<HOSTNAME>", dType="native", uid = "<UID>", pwd = "<PWD>")

# With a Teradata R native driver connection, submit a SQL statement explicitly
# to specify a default database <DBNAME>:
dbExecute(con, "DATABASE <DBNAME>")

# Alternatively: Use an ODBC-based connection by specifying in the following
# your target Vantage system DSN name <DSN>, and the <UID>, <PWD>, and <DBNAME>
# variables appropriately. The <DBNAME> variable is optional.
# con <- DBI::dbConnect(odbc(), dsn="<DSN>", uid="<UID>", pwd="<PWD>", dbname="<DBNAME>")
# Set the execution context.
# td_set_context(con)

################################################################################
################################################################################
# USE CASE [1]: Single model fitting and scoring example
################################################################################
################################################################################

################################################################################
# USE CASE [1] - Section 1: Fit and save model (on client)
#                Note: To proceed with the present section, ensure you have
#                      first executed Section 1 of the R and Python TechBytes
#                      Demo - Part 2. You will need to have the Analytic Data
#                      Set (ADS) ADS_R table in the target Vantage system.
################################################################################

# Next, we extract a 25% sample from the tdplyr demo analytic data set and
# read it into a data frame.

tdADSTrain <- dbGetQuery(con, "SELECT * FROM ADS_R SAMPLE .25")
glimpse(tdADSTrain)

# Change the class of the dependent variable to a factor to indicate to
# randomForest that we want to built a classification tree.

tdADSTrain$cc_acct_ind=as.factor(tdADSTrain$cc_acct_ind)

RFmodel <- randomForest(formula = (cc_acct_ind ~
                                   tot_income +
                                   tot_age +
                                   tot_cust_years +
                                   tot_children +
                                   female_ind +
                                   single_ind +
                                   married_ind +
                                   seperated_ind +
                                   ca_resident_ind +
                                   ny_resident_ind +
                                   tx_resident_ind +
                                   il_resident_ind +
                                   az_resident_ind +
                                   oh_resident_ind +
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
                         data = tdADSTrain,
                         ntree = 500,
                         nodesize = 1,
                         mtry = 5
)

RFmodel

# Save the model to a .Rds R data file "RFModel.rds". The saved model will then
# need to be installed on the target Vantage system (see following Section 2)
# together with the scoring script in file "RFScore.r" so you can perform the
# scoring operation with the SCRIPT Table Operator.
# Before you execute the following statement, specify the target path to save
# the .Rds file on your client machine. Replace the <modelPATH> variable
# suitably for your platform. Here are some example <modelPATH> strings for
# different client platforms:
# On Windows OS, specify a path like: "C:\\Users\\me\\Path\\To\\RFmodel.rds"
# On MacOS, specify a path like     : "/Users/me/Path/To/RFmodel.rds"
# On Linux, specify a path like     : "/home/me/Path/To/RFmodel.rds"
#
# Note: You will need the <modelPATH> value again in the following Section 2.

saveRDS(RFmodel, <modelPATH>)

# For scoring with the model, use the scoring script file "RFScore.r" that is
# distributed with the present TechBytes demo material.
# Consider that the scoring script file resides in a path <scriptPATH>, defined
# in a similar way as the <modelPATH> above.
# Example: Assume you are on the MacOS platform and you want to store the
#          "RFScore.r" model file in your home directory /Users/me. Then
#          scriptPATH = /Users/me/RFScore.r
# Note: You will need the <scriptPATH> value again in the following Section 2.

################################################################################
# USE CASE [1] - Section 2: Score with model (in database; uses SCRIPT)
################################################################################
# We use the following queries to:
# a. Install the .rds model file and the scoring script in a target database
#    on the target Vantage system. You will need to edit the scoring script
#    file "RFScore.r" to specify this target database name where needed,
#    so that the the scoring script can find the model.
#    The calls to SYSUIF.INSTALL_FILE() specify for your Vantage system the
#    locations where the R script and saved model files can be picked up from
#    your client to be installed on the target Vantage system.
#    The calls to SYSUIF.REMOVE_FILE() remove from the Vantage system any
#    existing files of the same name before the installation. It is expected
#    for these calls to fail if no files with the specified names pre-exist.
# b. Execute the SCRIPT Table Operator (STO) to score the entire data set.
#    Observe that the STO query output is stored into a table that we name
#    RFSingleModelScores. In case of repeated executions, the query will fail
#    if the table already exists. To prevent this, the STO query is preceded by
#    a DROP TABLE statement that is expected to fail when the table is absent.
#
# Reminder: In case of errors, STO full standard error output is channeled to:
#           /var/opt/teradata/tdtemp/uiflib/scriptlog
# Note: A CLIv2 based interface (i.e. bteq or JDBC) needs to be used in order
#       to securely install the scoring script and saved model file.
# Below, we build a bteq script with the desired queries, and execute it.
################################################################################

# Before you execute the following bteq script, provide unquoted values for the
# following variables in the bteq script:
# 1. Specify the target Vantage Advanced SQL Engine hostname <HOSTNAME>, and
#    your user ID <UID> and password <PWD> credentials in the ".LOGON " command.
# 2. Replace the "scriptPath" and the "modelPATH" variables with the path
#    location values you assigned them earlier.
# 3. Specify the database <DBNAME> where the script and model files will reside.
#    Note the you need to specify the same name
#    - in both the "DATABASE" and "SET SESSION SEARCHUIFDBPATH" statements
#    - in the "SCRIPT_COMMAND" clause of the STO query
#    - in the "RFScore.r" script where R expects to pick up the model file
#      from the database on the target server

bteqScript <-"
  .LOGON <HOSTNAME>/<UID>,<PWD>

  DATABASE <DBNAME>;

  SET SESSION SEARCHUIFDBPATH = <DBNAME>;

  -- Install the scoring script from the specified location:

  CALL SYSUIF.REMOVE_FILE('RFScore',1);
  CALL SYSUIF.INSTALL_FILE('RFScore','RFScore.r','cz!scriptPATH');

  -- Install the R Model file from the specified location:

  CALL SYSUIF.REMOVE_FILE('RFmodel',1);
  CALL SYSUIF.INSTALL_FILE('RFmodel','RFmodel.rds','cb!modelPATH');

  DROP TABLE RFSingleModelScores;

  CREATE TABLE RFSingleModelScores AS (
  SELECT CAST (cust_id AS INTEGER) AS cust_id,
         CAST (Prediction0 AS FLOAT ) AS Prediction0,
         CAST (Prediction1 AS FLOAT ) AS Prediction1,
         CAST (cc_acct_ind AS INTEGER) AS Actual
  FROM SCRIPT (ON (SELECT * FROM ADS_R)
               SCRIPT_COMMAND('R --vanilla --slave -f ./<DBNAME>/RFScore.r')
               RETURNS ('cust_id VARCHAR(20), Prediction0 VARCHAR(20), Prediction1 VARCHAR(20), cc_acct_ind VARCHAR(20)')
              ) AS D
  ) WITH DATA PRIMARY INDEX (cust_id);
.QUIT
"

# Before you execute the following statement, specify the target path to save
# the bteq script on your client machine as a file named "STO_Score.bteq".
# Replace the <bteqPATH> variable suitably for your platform. Here are some
# example <bteqPATH> strings for different client platforms:
# On Windows OS, <bteqPATH> should look like: "C:\\Temp\\STO_Score.bteq"
# On MacOS, <bteqPATH> should look like     : "/Users/me/Path/To/STO_Score.bteq"
# On Linux, <bteqPATH> should look like     : "/home/me/Path/To/STO_Score.bteq"

write(bteqScript, <bteqPATH>)

# The following statement assumes the bteq utility is installed on your client
# machine, and executes the bteq script.
# Note 1: From the following couple of statements, only execute the one that is
#         appropriate for your platform, as follows:
#         On Windows OS : Uncomment, adjust, and execute the "shell" statement
#         On MacOS/Linux: Uncomment, adjust, and execute the "system" statement
# Note 2: [Only for MacOS and Linux users of the bteq utility]
#         The R system() function might fail to find the path to the "bteq"
#         executable, if its installation location is in a directory other than
#         the ones that /bin/sh looks into by default. In this case, you may
#         need to invoke bteq by specifying the entire /path/to/bteq explicitly.
#         The path must contain no space characters, otherwise you may first
#         need to soft-link the bteq executable to a more standard location on
#         your system, such as /usr/local/bin.
# Assume the script output goes into a file called "STO_Score.out", and that
# the script error output goes into a file called "STO_Score.err". Further on,
# as above for the bteqPATH, use similar path specifications for the variables
# 1. STOoutPATH for the SCRIPT output file
# 2. STOerrPATH for the SCRIPT error file
# Example: Assume you are on the MacOS platform and you want to store all files
#          in your home directory /Users/me. Further on, assume that
#          STOoutPATH = /Users/me/STO_Score.out
#          STOerrPATH = /Users/me/STO_Score.err
#          Then, the following statement should be submitted as:
# system("bteq < /Users/me/TO_Score.bteq > /Users/me/STO_Score.out 2> /Users/me/STO_Score.err", wait=TRUE)

#shell("bteq < bteqPATH > STOoutPATH 2> STOerrPATH", wait=TRUE)
#system("bteq < bteqPATH > STOoutPATH 2> STOerrPATH", wait=TRUE)

# If the SCRIPT Table Operator query executes successfully on the target
# Vantage system, then the following statement queries a sample of 10 rows
# from the output table with the scoring results.

tdRFSingleModelScores <- dbGetQuery(con, "SELECT * FROM RFSingleModelScores SAMPLE 10")
tdRFSingleModelScores

################################################################################
################################################################################
# END OF USE CASE [1]: Single model scoring example
################################################################################
################################################################################


################################################################################
################################################################################
# USE CASE [2]: Multiple models fitting and scoring example
################################################################################
################################################################################

################################################################################
# USE CASE [2] - Section 1: Transform data and create model and test data sets
################################################################################
# Begin the multi-model build example, quickly review the wrangling we did to
# create the analytic data set. For the present use case, change the location
# indicators to 7 state codes, namely: CA, NY, TX, IL, OH, AZ and Other.
################################################################################

# Note that we retain the same libraries and connection that were loaded
# and created earlier in the beginning part of Use Case 1.
#
# Create tibbles for the Customer, Accounts and Transactions tables in the
# Vantage Advanced SQL Engine.

tdCustomer <- tbl(con, "Customer")
tdAccounts <- tbl(con, "Accounts")
tdTransactions <- tbl(con, "Transactions")

# First grab the customer demographic variables and create the indicator
# variables for gender and marital_status.
# Recode state_code into the top 6 states and Others").

cust <- tdCustomer %>%
  select(cust_id, income, age, gender, years_with_bank, nbr_children, marital_status, state_code) %>%
  mutate(female = ifelse(gender == 'F', as.integer(1), as.integer(0)),
         single = ifelse(marital_status == '1', as.integer(1), as.integer(0)),
         married = ifelse(marital_status == '2', as.integer(1), as.integer(0)),
         seperated = ifelse(marital_status == '3', as.integer(1), as.integer(0)),

# The creation of the state code indicator variables has been removed and the
# following was added for a partitioning key for the multi-model use case -
# this is the only difference between the analytic data sets in the first and
# second examples.

         statecode = case_when(state_code == 'CA' ~ 'CA',
                               state_code == 'NY' ~ 'NY',
                               state_code == 'TX' ~ 'TX',
                               state_code == 'IL' ~ 'IL',
                               state_code == 'AZ' ~ 'AZ',
                               state_code == 'OH' ~ 'OH',
                               TRUE ~ 'OTHER')
  )

# Next, get the account information required for the aggregation and create the
# indicator variables for acct_type

acct <- tdAccounts %>%
  select(cust_id, acct_type, starting_balance, ending_balance, acct_nbr) %>%
  mutate(ck_acct = ifelse(acct_type == 'CK', as.integer(1), as.integer(0)),
         sv_acct = ifelse(acct_type == 'SV', as.integer(1), as.integer(0)),
         cc_acct = ifelse(acct_type == 'CC', as.integer(1), as.integer(0)))

# Next, get the transaction information required for the aggregation and pull
# out the quarter the transaction was made.

trans <- tdTransactions %>%
  select(acct_nbr, principal_amt, interest_amt, tran_id, tran_date) %>%
  mutate(acct_mon = month(as.Date(tran_date)),
         q1_trans = ifelse(acct_mon %in% c(1,2,3), as.integer(1), as.integer(0)),
         q2_trans = ifelse(acct_mon %in% c(4,5,6), as.integer(1), as.integer(0)),
         q3_trans = ifelse(acct_mon %in% c(7,8,9), as.integer(1), as.integer(0)),
         q4_trans = ifelse(acct_mon %in% c(10,11,12), as.integer(1), as.integer(0)))

# Finally, pull everything together into a training data set - Accounts and
# Transactions are LEFT OUTER joined to Customer and all variables must be
# aggregated and rolled up by cust_id

ADS_R2 <- cust %>%
  left_join(acct, by = "cust_id") %>%
  left_join(trans, by = "acct_nbr") %>%
  group_by(cust_id) %>%
  summarise(tot_income = min(income, na.rm=TRUE),
            tot_age = min(age, na.rm=TRUE),
            tot_cust_years = min(years_with_bank, na.rm=TRUE),
            tot_children = min(nbr_children, na.rm=TRUE),
            female_ind = min(female, na.rm=TRUE),
            single_ind = min(single, na.rm=TRUE),
            married_ind = min(married, na.rm=TRUE),
            seperated_ind = min(seperated, na.rm=TRUE),

# Adding the statecode to the analytic data set

            statecode = min(statecode, na.rm=TRUE),

            ck_acct_ind = ifelse(is.null(max(ck_acct, na.rm=TRUE)), as.integer(0),
                                 max(ck_acct, na.rm=TRUE)),
            cc_acct_ind = ifelse(is.null(max(cc_acct, na.rm=TRUE)), as.integer(0),
                                 max(cc_acct, na.rm=TRUE)),
            sv_acct_ind = ifelse(is.null(max(sv_acct, na.rm=TRUE)), as.integer(0),
                                 max(sv_acct, na.rm=TRUE)),
            ck_avg_bal = ifelse(is.null(mean(ck_acct*(starting_balance+ending_balance), na.rm=TRUE)), as.integer(0),
                                mean(ck_acct*(starting_balance+ending_balance), na.rm=TRUE)),
            sv_avg_bal = ifelse(is.null(mean(sv_acct*(starting_balance+ending_balance), na.rm=TRUE)), as.integer(0),
                                mean(sv_acct*(starting_balance+ending_balance), na.rm=TRUE)),
            cc_avg_bal = ifelse(is.null(mean(cc_acct*(starting_balance+ending_balance), na.rm=TRUE)), as.integer(0),
                                mean(cc_acct*(starting_balance+ending_balance), na.rm=TRUE)),
            ck_avg_tran_amt = ifelse(is.null(mean(CK_acct*(principal_amt + interest_amt), na.rm=TRUE)), as.integer(0),
                                     mean(CK_acct*(principal_amt + interest_amt), na.rm=TRUE)),
            sv_avg_tran_amt = ifelse(is.null(mean(SV_acct*(principal_amt + interest_amt), na.rm=TRUE)), as.integer(0),
                                     mean(SV_acct*(principal_amt + interest_amt), na.rm=TRUE)),
            cc_avg_tran_amt = ifelse(is.null(mean(CC_acct*(principal_amt + interest_amt), na.rm=TRUE)), as.integer(0),
                                     mean(CC_acct*(principal_amt + interest_amt), na.rm=TRUE)),
            q1_trans_cnt = ifelse(is.null(sum(q1_trans, na.rm=TRUE)), as.integer(0),
                                  sum(q1_trans, na.rm=TRUE)),
            q2_trans_cnt = ifelse(is.null(sum(q2_trans, na.rm=TRUE)), as.integer(0),
                                  sum(q2_trans, na.rm=TRUE)),
            q3_trans_cnt = ifelse(is.null(sum(q3_trans, na.rm=TRUE)), as.integer(0),
                                  sum(q3_trans, na.rm=TRUE)),
            q4_trans_cnt = ifelse(is.null(sum(q4_trans, na.rm=TRUE)), as.integer(0),
                                  sum(q4_trans, na.rm=TRUE))
  )

# DROP the ADS_R2 table if it exists, and create it in the Advanced SQLE.
# Create a tibble and take a glimpse at it.
# Optionally, you can explicitly remove an existing table with:
# dbRemoveTable(con, "ADS_R2")
# or just use the overwrite=TRUE option to copy_to()

copy_to(con, ADS_R2, name="ADS_R2", overwrite=TRUE)
tdADS_R2 <- tbl(con, "ADS_R2")
glimpse(tdADS_R2)

# Split the data set up into training and testing data sets (60/40%)

ADS_Train_Test2 <- "SELECT cust_id
                          ,tot_income
                          ,tot_age
                          ,tot_cust_years
                          ,tot_children
                          ,female_ind
                          ,single_ind
                          ,married_ind
                          ,seperated_ind
                          ,statecode
                          ,ck_acct_ind
                          ,sv_acct_ind
                          ,cc_acct_ind
                          ,ck_avg_bal
                          ,sv_avg_bal
                          ,cc_avg_bal
                          ,ck_avg_tran_amt
                          ,sv_avg_tran_amt
                          ,cc_avg_tran_amt
                          ,q1_trans_cnt
                          ,q2_trans_cnt
                          ,q3_trans_cnt
                          ,q4_trans_cnt
                          ,SAMPLEID AS SAMPLE_ID
                  FROM ADS_R2 SAMPLE .60, .40"

# DROP the table if it exists, and create it with db_compute() and take a
# glimpse at it

dbRemoveTable(con, "ADS_Train_Test2")
db_compute(con, "ADS_Train_Test2", ADS_Train_Test2, temporary=FALSE, table.type = "PI", primary.index = "cust_id")
tdTrain_Test2 <- tbl(con, "ADS_Train_Test2")
glimpse(tdTrain_Test2)

# Use the 60% sample to train

MultiModelTrain <- tbl(con, "ADS_Train_Test2") %>% filter(SAMPLE_ID == "1")
copy_to(con, MultiModelTrain, name="MultiModelTrain", overwrite=TRUE)

# Use the 40% sample to test

MultiModelTest <- tbl(con, "ADS_Train_Test2") %>% filter(SAMPLE_ID == "2")
copy_to(con, MultiModelTest, name="MultiModelTest", overwrite=TRUE)

# Clean-up: Remove the context of present tdplyr connection

td_remove_context()

################################################################################
# USE CASE [2] - Section 2: Build multiple models (in database; uses ExecR)
################################################################################

# The multi-model build takes place in the target Vantage system Advanced
# SQL Engine. To perform this task, simply execute the code in the
# "Multi-Model_Random_Forest_Build.sql" SQL script file in a SQL interpreter
# such as Teradata Studio, by connecting to the target Vantage system and the
# database where the MultiModelTrain table resides.
# The above SQL script file demonstrates using R with the ExecR Table Operator.
# The SQL script uses as input the training MultiModelTrain table that was
# created in the preceding Section 1. The output of this task is the
# RFStateCodeModels table in the target Vantage system Advanced SQL Engine,
# and contains the built models for all state codes.

################################################################################
# USE CASE [2] - Section 3: Score multiple models (in database; uses ExecR)
################################################################################

# The multi-model scoring takes place in the target Vantage system Advanced
# SQL Engine. To perform this task, simply execute the code in the
# "Multi-Model_Random_Forest_Score.sql" SQL script file in a SQL interpreter
# such as Teradata Studio, by connecting to the target Vantage system and the
# database where the MultiModelTrain table resides.
# The above SQL script file demonstrates again using R with the ExecR Table
# Operator. The SQL script uses as input the RFStateCodeModels table with the
# models built in the preceding Section 2, and the MultiModelTest table that
# was created in the earlier Section 1 to score the test table data with
# these models. The output of the scoring task is the sought information
# about the propensity of the financial services customers in the test table
# to open a credit card account.

################################################################################
################################################################################
# END OF USE CASE [2]: Multiple models fitting and scoring example
################################################################################
################################################################################