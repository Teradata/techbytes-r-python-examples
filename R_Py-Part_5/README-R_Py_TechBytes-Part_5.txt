The R and Python TechBytes Demo

--------------------------------------------------------------------------------
README-R_Py_TechBytes-Part_5:
README file for Part 5 of the R and Python TechBytes Demo
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


2. R and Python TechBytes Demo - Part 5 Information
--------------------------------------------------------------------------------

The present Part 5 of the demo is a bundle with the following files:
  "R_Py_TechBytes-Part_5-Demo.py"
  "R_Py_TechBytes-Part_5-Demo.ipynb"
  "R_Py_TechBytes-Part_5-Demo.sql"
  "stoRFScore.py"
  "stoRFFitMM.py"
  "stoRFScoreMM.py"
and relies on the demo data delivered with the file
  "R_Py_TechBytes-Demo_Data.zip"
in addition to the Analytic Data Set ADS_Py table in the target Vantage system
that was created in Part 3 of the demo.

The present Part 5 guides the user through fitting models and scoring with
Python in the Vantage Advanced SQL Engine nodes, by using the Vantage facilities
of the SCRIPT Table Operator. Some necessary data manipulation and
transformation for these tasks is featured, too, on the client side.
These features are demonstrated in two different scenarios that showcase
two commonly encountered use cases end-to-end, as follows:

[1] Fitting and scoring a single model

In this scenario, the user fits a model in Python on a client machine. The
model is exported as a pickled-serialized file that contains the model object,
and the user wishes to use this model for scoring in-database with a Python
scoring script against a Vantage table. We demonstrate uploading the model
file and the Python scoring script into Vantage. Then we use a SQL script to
invoke the SCRIPT Table Operator in the target Vantage system. SCRIPT performs
the scoring task by executing the Python script in the Vantage Advanced SQL
Engine nodes.

[2] Fitting and scoring multiple models

In this scenario, the user has a table in Vantage where the data can be
partitioned by some feature. The user wishes to fit one model for each
different data partition by using a fitting and a scoring Python script.
We demonstrate employing the SCRIPT Table Operator to execute sequentially
these Python scripts to perform a fitting task that is followed by a scoring
task, where multiple partitions are processed simultaneously in the Vantage
Advanced SQL Engine nodes.

- In the fitting iteration, the Python fitting script is uploaded into the
  Vantage Advanced SQL Engine, and then executed with the SCRIPT Table
  Operator against the input table with the training data. The SCRIPT query
  partitions the input data by the user-specified feature to mandate a
  different model fit for every partition. A different instance of the
  Python code is run on each Advanced SQL Engine AMP, where one or more
  data partitions may exist. The output is a table with the fitted models
  for all data partitions from the AMPs that contain data.

- In the scoring iteration, the Python scoring script is uploaded into the
  Vantage Advanced SQL Engine, and then executed with the SCRIPT Table
  Operator against an input table that merges the test/score data and the
  fitted models table. The partitioning feature is specified in the SCRIPT
  query to drive scoring for each partition according to the corresponding
  partition model. By having a different instance of the Python code run on
  each Advanced SQL Engine AMP, simultaneous multiple model scoring is achieved.

Preparation of the training and test/score data tables is performed earlier
in Python on the client with the teradataml add-on package.


3. How to run Part 5 of the "R and Python TechBytes Demo"
--------------------------------------------------------------------------------

Before you begin:
Note 1: To execute Python code in the Vantage Advanced SQL Engine, the Python
        interpreter and any Python add-on libraries needed by the Python
        scripts that will run in SCRIPT must be installed in advance on all
        Engine nodes. For this demo, the Python add-on libraries "numpy",
        "pandas", "sklearn", "pickle", and "base64" are needed.
Note 2: Carefully adjust the code where indicated in all demo files to provide
        credentials, file paths, or desired names as prompted by the comments.

All demo files contains ample comments and notes that explain each process step.

Use your favorite Python interpreter or IDE (such as Jupyter Notebooks or
PyCharm) on a client machine to execute the statements in the Python file
"R_Py_TechBytes-Part_5-Demo.py". In case you work with Jupyter Notebooks,
use directly the notebook file "R_Py_TechBytes-Part_5-Demo.ipynb" that has
identical code with "R_Py_TechBytes-Part_5-Demo.py". Follow the step-by-step
instructions in the file.

There are 2 use cases to follow through, as follows:

[1] Fitting and scoring a single model

a. Start from the top of the "R_Py_TechBytes-Part_5-Demo.py" file, and across
   the use case [1] code. At the end of Section 1, a Python model has been
   built, and saved into the "RFmodel_py.out" file in your client's filesystem.
b. Section 2 prompts you to review and execute the use case [1] segment in the
   "R_Py_TechBytes-Part_5-Demo.sql" SQL file. Use a SQL Interpreter like
   Teradata Studio to view and edit that SQL file, and specify as needed the
   locations of the model and fitting script files on your client machine to
   have them uploaded to the Vantage system. The SQL code then executes
   the Python scoring script in the Engine via the SCRIPT Table Operator.
   Review the Python script "stoRFScore.py" prior to using it in SCRIPT,
   because there is a line that loads and opens the Python model file to read
   the model information into the Python script. In this line, you need to
   provide the database name where the model file "RFmodel_py.out" has been
   uploaded to.
c. The use case concludes with the output of the SCRIPT Table Operator returned
   on the screen of the SQL Interpreter. The process produces scored rows of
   the test/score table data.

[2] Fitting and scoring multiple models

a. If you have not already loaded the necessary add-on libraries or connected
   to the target Vantage system, start with the statements at the top of the
   "R_Py_TechBytes-Part_5-Demo.py" file that precedes the use case [1] code.
   Otherwise, begin where the use case [2] code starts in the file.
b. Execute the use case [2] Section 1 code that uses the teradataml add-on
   library to create the "MultiModelTrain_Py" and "MultiModelTest_Py" tables
   in the target Vantage system from the demo data tables (see the README file
   in the "R_Py_TechBytes-Demo_Data.zip" file.)
c. Review use case [2] Section 2 comments in the "R_Py_TechBytes-Part_5-Demo.py"
   file, and then the Python fitting script code in the "stoRFFitMM.py" file.
   Use a SQL Interpreter like Teradata Studio to execute the SQL code in
   "Part (A): Model fitting" of the "R_Py_TechBytes-Part_5-Demo.sql" SQL file.
   Ensure you specify for the SQL code the location path of the Python fitting
   script on your client to have it uploaded into the target Vantage system.
   Finally, execute the query with SCRIPT to produce the output table
   "RFStateCodeModelsPy" with the multiple fitted models information.
c. Review use case [2] Section 3 comments in the "R_Py_TechBytes-Part_5-Demo.py"
   file, and then the Python scoring script code in the "stoRFScoreMM.py" file.
   Use a SQL Interpreter like Teradata Studio to execute the SQL code in
   "Part (B): Scoring with models" of the "R_Py_TechBytes-Part_5-Demo.sql"
   SQL file. Ensure you specify for the SQL code the location path of the
   Python scoring script on your client to have it uploaded into the target
   Vantage system. When you execute the query with SCRIPT, the output will be
   rows scored according to the model for the corresponding partition that
   the input data belong to.
