################################################################################
# * The contents of this file are Teradata Public Content and have been released
# * to the Public Domain.
# * Tim Miller & Alexander Kolovos - October 2019 - v.1.0
# * Copyright (c) 2019 by Teradata
# * Licensed under BSD; see "license.txt" file in the bundle root folder.
#
# ##############################################################################
# R and Python TechBytes Demo - Part 5: Python in-nodes with SCRIPT
# ------------------------------------------------------------------------------
# File: stoRFScoreMM.py
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
# The present file is the Python scoring script to be used with the SCRIPT
# table operator, as described in the following use case 2 of the present demo
# Part 5:
#
# 2) Fitting and scoring multiple models
#
#    We utilize the statecode variable as a partition to built a Random
#    Forest model for every state. This is done by using SCRIPT Table Operator
#    to run a model fitting script with a PARTITION BY statecode in the query.
#    This creates a model for each of the CA, NY, TX, IL, AZ, OH and Other
#    state codes, and perists the model in the database via CREATE TABLE AS
#    statement.
#    Then we run a scoring script via the SCRIPT Table Operator against
#    these persisted Random Forest models to score the entire data set.
#
#    For this use case, we build an analytic data set nearly identical to the
#    one in the teradataml demo (Part 3), with one change as indicated by item
#    (d) below. This is so we can demonstrate the in-database capability of
#    simultaneously building many models.
#    60% of the analytic data set rows are sampled to create a training
#    subset. The remaining 40% is used to create a testing/scoring dataset.
#    The train and test/score datasets are used in the SCRIPT operations.
################################################################################
import sys
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
import pickle
import base64

###
### Read input
###

delimiter = '\t'
inputData = []

try:
    line = input()
    if line == '':   # Exit if user provides blank line
        pass
    else:
        allArgs = line.split(delimiter)
        inputData.append(allArgs[0:-2])
        modelSerB64 = allArgs[-1]
except (EOFError):   # Exit if reached EOF or CTRL-D
    pass

while 1:
    try:
        line = input()
        if line == '':   # Exit if user provides blank line
            break
        else:
            allArgs = line.split(delimiter)
            inputData.append(allArgs[0:-2])
    except (EOFError):   # Exit if reached EOF or CTRL-D
        break

#for line in sys.stdin.read().splitlines():
#    line = line.split(delimiter)
#    inputData.append(line)

###
### If no data received, gracefully exit rather than producing an error later.
###

if not inputData:
    sys.exit()

## In the input information, all rows have the same number of column elements
## except for the first row. The latter also contains the model info in its
## last column. Isolate the serialized model from the end of first row.
#modelSerB64 = inputData[0][-1]

###
### Set up input DataFrame according to input schema
###

# Know your data: You must know in advance the number and data types of the
# incoming columns from the database!
# For numeric columns, the database sends in floats in scientific format with a
# blank space when the exponential is positive; e.g., 1.0 is sent as 1.000E 000.
# The following input data read deals with any such blank spaces in numbers.

columns = ['cust_id', 'tot_income', 'tot_age', 'tot_cust_years', 'tot_children',
           'female_ind', 'single_ind', 'married_ind', 'separated_ind',
           'statecode', 'ck_acct_ind', 'sv_acct_ind', 'cc_acct_ind',
           'ck_avg_bal', 'sv_avg_bal', 'cc_avg_bal', 'ck_avg_tran_amt',
           'sv_avg_tran_amt', 'cc_avg_tran_amt', 'q1_trans_cnt',
           'q2_trans_cnt', 'q3_trans_cnt', 'q4_trans_cnt', 'SAMPLE_ID']

df = pd.DataFrame(inputData, columns=columns)
#df = pd.DataFrame.from_records(inputData, exclude=['nRow', 'model'], columns=columns)
del inputData

df['cust_id'] = pd.to_numeric(df['cust_id'])

df['tot_income'] = df['tot_income'].apply(lambda x: "".join(x.split()))
df['tot_income'] = pd.to_numeric(df['tot_income'])

df['tot_age'] = pd.to_numeric(df['tot_age'])
df['tot_cust_years'] = pd.to_numeric(df['tot_cust_years'])
df['tot_children'] = pd.to_numeric(df['tot_children'])
df['female_ind'] = pd.to_numeric(df['female_ind'])
df['single_ind'] = pd.to_numeric(df['single_ind'])
df['married_ind'] = pd.to_numeric(df['married_ind'])
df['separated_ind'] = pd.to_numeric(df['separated_ind'])
df['statecode'] = df['statecode'].apply(lambda x: x.replace('"', ''))
df['ck_acct_ind'] = pd.to_numeric(df['ck_acct_ind'])
df['sv_acct_ind'] = pd.to_numeric(df['sv_acct_ind'])
df['cc_acct_ind'] = pd.to_numeric(df['cc_acct_ind'])
df['sv_acct_ind'] = pd.to_numeric(df['sv_acct_ind'])
df['cc_acct_ind'] = pd.to_numeric(df['cc_acct_ind'])

df['ck_avg_bal'] = df['ck_avg_bal'].apply(lambda x: "".join(x.split()))
df['ck_avg_bal'] = pd.to_numeric(df['ck_avg_bal'])
df['sv_avg_bal'] = df['sv_avg_bal'].apply(lambda x: "".join(x.split()))
df['sv_avg_bal'] = pd.to_numeric(df['sv_avg_bal'])
df['cc_avg_bal'] = df['cc_avg_bal'].apply(lambda x: "".join(x.split()))
df['cc_avg_bal'] = pd.to_numeric(df['cc_avg_bal'])
df['ck_avg_tran_amt'] = df['ck_avg_tran_amt'].apply(lambda x: "".join(x.split()))
df['ck_avg_tran_amt'] = pd.to_numeric(df['ck_avg_tran_amt'])
df['sv_avg_tran_amt'] = df['sv_avg_tran_amt'].apply(lambda x: "".join(x.split()))
df['sv_avg_tran_amt'] = pd.to_numeric(df['sv_avg_tran_amt'])
df['cc_avg_tran_amt'] = df['cc_avg_tran_amt'].apply(lambda x: "".join(x.split()))
df['cc_avg_tran_amt'] = pd.to_numeric(df['cc_avg_tran_amt'])

df['q1_trans_cnt'] = pd.to_numeric(df['q1_trans_cnt'])
df['q2_trans_cnt'] = pd.to_numeric(df['q2_trans_cnt'])
df['q3_trans_cnt'] = pd.to_numeric(df['q3_trans_cnt'])
df['q4_trans_cnt'] = pd.to_numeric(df['q4_trans_cnt'])
df['SAMPLE_ID'] = pd.to_numeric(df['SAMPLE_ID'])

###
### Unpack the transformed serialized fitted model
###
modelSerB64 = modelSerB64.partition("'")[2]
modelSer = base64.b64decode(modelSerB64)
classifier = pickle.loads(modelSer)

###
### Score the test table data with the given model
###

predictor_columns = ["tot_income", "tot_age", "tot_cust_years", "tot_children",
                     "female_ind", "single_ind", "married_ind", "separated_ind",
                     "ck_acct_ind", "sv_acct_ind", "ck_avg_bal", "sv_avg_bal",
                     "ck_avg_tran_amt", "sv_avg_tran_amt", "q1_trans_cnt",
                     "q2_trans_cnt", "q3_trans_cnt", "q4_trans_cnt"]

# Specify the rows to be scored by the model and call the predictor.
X_test = df[predictor_columns]
#Prediction = classifier.predict(X_test)
PredictionProba = classifier.predict_proba(X_test)

df = pd.concat([df, pd.DataFrame(data=PredictionProba, columns=['Prob0', 'Prob1'])], axis=1)

# Export results to NewSQL Engine through standard output in expected format.
for index, row in df.iterrows():
    print(row['cust_id'], delimiter, row['statecode'], delimiter,
          row['Prob0'], delimiter, row['Prob1'], delimiter, row['cc_acct_ind'])
