The R and Python TechBytes Demo

--------------------------------------------------------------------------------
README-R_Py_TechBytes-Part_4:
README file for Part 4 of the R and Python TechBytes Demo
Copyright (c) 2020 by Teradata
Licensed under BSD; see "license.txt" file in the bundle root folder.
================================================================================


1. General Introduction
--------------------------------------------------------------------------------

The R and Python TechBytes demo is a demo in 5 parts that demonstrates the
R and Python capabilities in Teradata Vantage, and ways to use R and Python
for in-database analytics on a target Vantage system.
The demo utilizes a core use case to predict the propensity of a financial
services customer base to open a credit card account. The demo comprises of
the following parts:
- Part 1 consists of only a Powerpoint overview of R and Python in Vantage
- Part 2 demonstrates the Teradata R package tdplyr for clients
- Part 3 demonstrates the Teradata Python package teradataml for clients
- Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
- Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator

The R and Python TechBytes demo Parts videos are available on the Teradata
YouTube channel. The present file is part of a bundle that offers the entire
code for Parts 2-5 together with the necessary input data so that you can
reproduce the demo analyses for either language. The present bundle has no
content related to the demo Part 1, hence there is no further reference to it.

To reproduce the R and Python TechBytes demo analyses with the present bundle,
you will need the following:
a. A corresponding language interpreter installed on a client machine with the
   ability to install add-on packages from one of the language's repositories.
b. The Teradata R package (tdplyr) and the Teradata Python package (teradataml),
   both available through the website downloads.teradata.com.
c. Access to a Teradata Vantage system that to the very minimum carries the
   Advanced SQL Engine (database) component.
   - To execute the demo Parts 2 and 3 in their entirety, the target Vantage
     system must also feature a Machine Learning Engine component, too.
   - To execute the demo Part 4, the target Vantage system must be equipped
     with the "teradata-R" and "teradata-R-addons" packages.
   - To execute the demo Part 5, the target Vantage system must be equipped
     with the "teradata-python" and "teradata-python-addons" packages.
d. A SQL interpreter, such as Teradata Studio that is available through the
   website downloads.teradata.com.


2. R and Python TechBytes Demo - Part 4 Information
--------------------------------------------------------------------------------

The present Part 4 of the demo is a bundle with the following files:
  "R_Py_TechBytes-Part_4-Demo.r"
  "RFScore.r"
  "Multi-Model_Random_Forest_Build.sql"
  "Multi-Model_Random_Forest_Score.sql"
and relies on the demo data delivered with the file
  "R_Py_TechBytes-Demo_Data.zip"
in addition to the Analytic Data Set ADS_R table in the target Vantage system
that was created in Part 2 of the demo.

The present Part 4 guides the user through fitting models and scoring with R
in the Vantage Advanced SQL Engine nodes, by using the Vantage facilities
of the SCRIPT and ExecR Table Operators. Some necessary data manipulation and
transformation for these tasks is featured, too, on the client side.
These features are demonstrated in two different scenarios that showcase
two commonly encountered use cases end-to-end, as follows:

[1] Fitting and scoring a single model

In this scenario, the user fits a model in R on a client machine. The model
is saved as a .Rds native R file that contains the model object, and the user
wishes to use this model for scoring in-database with an R scoring script
against a Vantage table. We demonstrate uploading the .Rds file and the R
scoring script into Vantage. Then we use a SQL script to invoke the SCRIPT
Table Operator in the target Vantage system. SCRIPT performs the scoring task
by executing the R script in the Vantage Advanced SQL Engine nodes.

Interestingly, we demonstrate how the SQL script can be executed from within
R on the client, by assuming that a CLIv2-based interface (such as bteq) is
available on the client.

[2] Fitting and scoring multiple models

In this scenario, the user has a table in Vantage where the data can be
partitioned by some feature. The user wishes to fit one model for each
different data partition by means of using R fitting and scoring scripts.
We demonstrate how to use the ExecR Table Operator to embed R code that
performs in separate calls the fitting and scoring tasks in the Vantage
Advanced SQL Engine nodes.

- In the fitting iteration, SQL code is executed with a call to ExecR that
  (a) has the model fitting R code, and (b) partitions the input data by the
  user-specified feature. A different instance of the R code is run on each
  Advanced SQL Engine AMP, where one or more data partitions may exist.
  The output is a table with the fitted models for all data partitions from
  the AMPs that contain data.

- In the scoring iteration, SQL code is executed with a different call to
  ExecR that (a) has the scoring R code, and (b) receives input from the
  test/score data table and the saved models table. Again, ExecR partitions
  the input data by the user-specified feature, and thus achieves simultaneous
  multiple model scoring.

Preparation of the training and test/score data tables is performed earlier
in R on the client with the tdplyr add-on package.


3. How to run Part 4 of the "R and Python TechBytes Demo"
--------------------------------------------------------------------------------

Before you begin:
Note 1: To execute R code in the Vantage Advanced SQL Engine, the R interpreter
        and any needed R add-on libraries needed by the R scripts that will run
        in SCRIPT and ExecR must be installed in advance on all Engine nodes.
        For this demo, the R add-on library "randomForest" is needed.
Note 2: Carefully adjust the code where indicated in all demo files to provide
        credentials, file paths, or desired names as prompted by the comments.

All demo files contains ample comments and notes that explain each process step.

Use your favorite R interpreter or IDE (such as RStudio) on a client machine to
execute the statements in the R file "R_Py_TechBytes-Part_4-Demo.r". Follow the
step-by-step instructions in the file.

There are 2 use cases to follow through, as follows:

[1] Fitting and scoring a single model

a. Start from the top of the "R_Py_TechBytes-Part_4-Demo.r" file, and across
   the use case [1] code. At the end of Section 1, an R model has been built,
   and you save it into a file "RFModel.rds" in your client's filesystem.
b. Section 2 uses your R session to submit SQL code to the target Vantage
   system. This code essentially uploads the fitted model file and your R
   scoring script "RFScore.r" from your client into a target database that you
   specify in the Vantage Advanced SQL Engine. The SQL code then executes
   the script in the Engine via the SCRIPT Table Operator.
   Review the R script "RFScore.r" prior to using it in SCRIPT, because there
   is a line that reads the R model into the script with the readRDS() function.
   In this line, you need to provide the database name where the script
   "RFModel.rds" has been uploaded to.
c. The use case concludes by fetching a sample of the scored data locally to
   your client.

[2] Fitting and scoring multiple models

a. If you have not already loaded the necessary add-on libraries or connected
   to the target Vantage system, start with the statements at the top of the
   "R_Py_TechBytes-Part_4-Demo.r" file that precedes the use case [1] code.
   Otherwise, begin where the use case [2] code starts in the file.
b. Execute the use case [2] Section 1 code that uses the tdplyr add-on library
   to create the "MultiModelTrain" and "MultiModelTest" tables in the target
   Vantage system from the demo data tables (see the README file in the
   "R_Py_TechBytes-Demo_Data.zip" file.)
c. Review use case [2] Section 2 comments in the "R_Py_TechBytes-Part_4-Demo.r"
   file, and then the code in the "Multi-Model_Random_Forest_Build.sql" file.
   Use a SQL Interpreter like Teradata Studio to execute the SQL script code
   and perform the multiple model fitting task.
c. Review use case [2] Section 3 comments in the "R_Py_TechBytes-Part_4-Demo.r"
   file, and then the code in the "Multi-Model_Random_Forest_Score.sql" file.
   Use a SQL Interpreter like Teradata Studio to execute the SQL script code
   and perform the multiple model scoring task.
