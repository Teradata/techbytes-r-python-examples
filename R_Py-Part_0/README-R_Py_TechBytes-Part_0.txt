The R and Python TechBytes Demo

--------------------------------------------------------------------------------
README-R_Py_TechBytes-Part_0:
README file for Part 0 of the R and Python TechBytes Demo
Copyright (c) 2019 by Teradata
Licensed under BSD see "license.txt" file in the bundle root folder.
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


2. R and Python TechBytes Demo - Part 0 Information
--------------------------------------------------------------------------------

The present Part 0 of the demo essentially consists of the following file:
  "R_Py_TechBytes-Part_0-Demo.sql"
and relies on the demo data delivered with the file
  "R_Py_TechBytes-Demo_Data.zip"
This Part is an extra file in the present bundle. It proposes a script file to
perform in SQL code the analytic tasks featured in Parts 2 and 3.

Part 0 guides the user through data manipulation and transformation, model
fitting, and model scoring tasks, all performed in SQL.
- The user starts with data tables in the Advanced SQL Engine database of a
  target Vantage system. These tables can be created with the data files in
  the "R_Py_TechBytes-Demo_Data.zip" file of the demo.
- The data manipulation and transformation tasks are operations that are
  executed in the Advanced SQL Engine database of the target Vantage system.
- The analytic computations for the model fitting and scoring tasks are
  executed in the Machine Learning Engine of the target Vantage system, and
  make use of the analytic functions in the Machine Learning Engine.

Note: To perform the model fitting and scoring tasks in Section 2 of this
      demo, the target Vantage system must have a Machine Learning Engine
      component.
      In the absence of a Machine Learning Engine, model fitting and scoring
      tasks can be still performed by means of suitable R add-on libraries on
      the client and by moving the necessary data from Vantage to the client.
      However, the latter approach is outside the scope of the present demo.


3. How to run Part 0 of the "R and Python TechBytes Demo"
--------------------------------------------------------------------------------

Use your favorite SQL interpreter or IDE (such as Teradata Studio) to
execute the statements in the SQL file "R_Py_TechBytes-Part_0-Demo.sql".
Follow the step-by-step instructions in the file and adjust the code where
indicated to provide credentials, file paths, or desired names as prompted
by the comments. The code provides a hands-on experience by also providing
comments to explain each step of the process.
