The R and Python TechBytes Demo
Release 0.5
--------------------------------------------------------------------------------
README-R_Py_TechBytes-Demo:
README file for R_Py_TechBytes-Demo ZIP bundle
Copyright (c) 2019 by Teradata
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


2. Information
--------------------------------------------------------------------------------

The present bundle comprises of the following folders and files. See the
README file in each one of those folders for more specific information.

README-R_Py_TechBytes-Demo.txt

license.txt

R_Py-Input_Tables/
    Accounts.csv
    Accounts.fastload
    Customer.csv
    Customer.fastload
    README-R_Py_TechBytes-Demo_Data.txt
    Transactions.csv
    Transactions.fastload

R_Py-Part_0/
    README-R_Py_TechBytes-Part_0.txt
    R_Py_TechBytes-Part_0-Demo.sql

R_Py-Part_2/
    README-R_Py_TechBytes-Part_2.txt
    R_Py_TechBytes-Part_2-Demo.r

R_Py-Part_3/
    README-R_Py_TechBytes-Part_3.txt
    R_Py_TechBytes-Part_3-Demo.ipynb
    R_Py_TechBytes-Part_3-Demo.py

R_Py-Part_4/
    Multi-Model_Random_Forest_Build.sql
    Multi-Model_Random_Forest_Score.sql
    README-R_Py_TechBytes-Part_4.txt
    RFScore.r
    R_Py_TechBytes-Part_4-Demo.r

R_Py-Part_5/
    README-R_Py_TechBytes-Part_5.txt
    R_Py_TechBytes-Part_5-Demo.ipynb
    R_Py_TechBytes-Part_5-Demo.py
    R_Py_TechBytes-Part_5-Demo.sql
    stoRFFitMM.py
    stoRFScore.py
    stoRFScoreMM.py
