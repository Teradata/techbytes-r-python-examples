## TechBytes: Using R and Python with Vantage

This bundle contains v.1.1 of the R and Python code for the 5-part demo of the TechBytes series "Using R and Python with Vantage".

### The TechBytes series "Using R and Python with Vantage"

Teradata TechBytes are offering a 5-part set of videos about R and Python on the Teradata YouTube channel. This series demonstrates the R and Python capabilities in Teradata Vantage, and ways to use R and Python for Client and In-database analytics on a target Vantage system. The demo utilizes a core use case to predict the propensity of a financial services customer base to open a credit card account. The demo comprises of
the following parts:

* Part 1 consists of only an overview of R and Python in Vantage
* Part 2 demonstrates the Teradata R package **tdplyr** for clients
* Part 3 demonstrates the Teradata Python package **teradataml** for clients
* Part 4 demonstrates using R in-nodes with the SCRIPT and ExecR Table Operators
* Part 5 demonstrates using Python in-nodes with the SCRIPT Table Operator

### The R and Python TechBytes demo

The present package offers the entire code for Parts 2-5 of the above R and Python TechBytes demo. The code has been richly annotated with comments to guide you through each step. In addition, the package contains in a separate folder all the necessary input data that are needed for the demo so that you can reproduce the demo analyses for either language. The present bundle has no content related to the demo Part 1, hence there is no further reference to it. Finally, the package offers a separate folder (Part 0) with a script that reproduces the analyses of Parts 2 and 3 in SQL.

To reproduce the R and Python TechBytes demo analyses with the present bundle, the following are needed:

* A corresponding language interpreter installed on a client machine with the ability to install add-on packages from the respective language repositories.
* The Teradata R package **tdplyr** and the Teradata Python package **teradataml**, both available through the website https://downloads.teradata.com.
* Access to a Teradata Vantage system that at the minimum carries the Advanced SQL Engine component.
    + To execute the demo Parts 2 and 3 in their entirety, the target Vantage system must also feature a Machine Learning Engine component.
    + To execute the demo Part 4, the target Vantage system must have the "teradata-R" and "teradata-R-addons" packages installed (or otherwise an installation of the R interpreter, the R add-on library "randomForest" and its dependencies.)
    + To execute the demo Part 5, the target Vantage system must have the "teradata-python" and "teradata-python-addons" packages installed (or otherwise an installation of the Python interpreter, the Python add-on libraries "numpy", "pandas", "sklearn", "pickle", "base64" and their dependencies.)
* A SQL interpreter, such as Teradata Studio that is available through the website https://downloads.teradata.com.

### Table of Contents

The present package comprises of the following folders and files. See the README file in each one of those folders for more specific information.

* README-R_Py_TechBytes-Demo.txt
* license.txt
* R_Py-Input_Tables/
    + Accounts.csv
    + Accounts.fastload
    + Customer.csv
    + Customer.fastload
    + README-R_Py_TechBytes-Demo_Data.txt
    + Transactions.csv.zip
    + Transactions.fastload
* R_Py-Part_0/
    + README-R_Py_TechBytes-Part_0.txt
    + R_Py_TechBytes-Part_0-Demo.sql
* R_Py-Part_2/
    + README-R_Py_TechBytes-Part_2.txt
    + R_Py_TechBytes-Part_2-Demo.r
* R_Py-Part_3/
    + README-R_Py_TechBytes-Part_3.txt
    + R_Py_TechBytes-Part_3-Demo.ipynb
    + R_Py_TechBytes-Part_3-Demo.py
* R_Py-Part_4/
    + Multi-Model_Random_Forest_Build.sql
    + Multi-Model_Random_Forest_Score.sql
    + README-R_Py_TechBytes-Part_4.txt
    + RFScore.r
    + R_Py_TechBytes-Part_4-Demo.r
* R_Py-Part_5/
    + README-R_Py_TechBytes-Part_5.txt
    + R_Py_TechBytes-Part_5-Demo.ipynb
    + R_Py_TechBytes-Part_5-Demo.py
    + R_Py_TechBytes-Part_5-Demo.sql
    + stoRFFitMM.py
    + stoRFScore.py
    + stoRFScoreMM.py

### Changelog

* 2019-10-29: v.1.0: Initial release
* 2020-04-03: v.1.1: Bug fixes, usage of new functions

For file-specific change logs, please look into the corresponding files. Unmodified files may have no changelog section, and can still follow the versioning in the repository.
