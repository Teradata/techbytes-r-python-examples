The R and Python TechBytes Demo

--------------------------------------------------------------------------------
README-R_Py_TechBytes-Demo_Data:
README file for R_Py_TechBytes-Demo_Data ZIP bundle
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

This compressed container holds synthetic data and accompanies the "R and
Python TechBytes demo" so you can try out hands-on the code examples across
the aforementioned parts of this TechBytes demo.

The demo data is a collection of 3 data sets, namely:
- Accounts
- Customer
- Transactions
that you will need to upload to your target Vantage system Advanced SQL Engine
before you can run the TechBytes examples.
- The data are provided in the following comma-separated CSV files:
  "Accounts.csv"         ( 1.2 MB)
  "Customer.csv"         ( 0.4 MB)
  "Transactions.csv.zip" (24.1 MB; contains "Transactions.csv" of size 78.3 MB)
- Before taking any further action, uncompress the archive file named
  "Transactions.csv.zip" to extract the data file "Transactions.csv".
- Each data file corresponds to one table.
- The first row in each data file is a header. The data start in the second row.
You can upload the datasets to the target system in any way that is most
convenient for you. Two commonly used techniques you can try are the following:

Upload option 1: Use the Teradata Studio software.
a. Launch the software, and establish a connection to the target Vantage
   system.
b. Then navigate in the left pane to the desired database where you wish
   to create the new tables from the data sets.
c. Click on the database name to expand the list of objects in it.
d. Right-click on the "Tables" in the desired target database, and select
   "Teradata" > "Data Transfer".
   1. This action will launch a Data Transfer Wizard window. Use the
      "External File" source option that uses the Smart Load utility, and
      click on the "Launch" button.
   2. The window will switch to an "Import Data" window where you will need
      to navigate to the input data file location on your computer.
   3. Ensure the "Column Labels in First Row" button is checked.
   4. Specify "Comma" under "File Options" > "Column Delimiter".
   5. Specify "None" under "File Options" > "Character String Delimiter".
   6. Specify "Unix, Linux, Mac OS X v10.0 and above (LF)" under
      "File Options" > "Line Separator".
   7. Push the "Finish" button in the bottom.
e. The following screen is the "Table Column Data Types". It displays a sample
   of the data and their interpreted types in the manner Teradata Studio plans
   to import them in the database. Use the information in the following
   Section 3 "Table DDL details for the data" to make any changes as needed
   on this screen. For instance, upon importing the "Accounts.csv" data set,
   the following steps were taken:
   1. The Primary Index filed needed to be set to "Unique".
   2. The table type specification (set/multiset) can be specified as desired.
   3. The "acct_nbr" column was interpreted as BIGINT type by Teradata Studio.
      By clicking in the type field, a Column Type Dialog pop-up window
      launches, where the column type can be explicitly modified. In our case,
      the "acct_nbr" column type needed to be changed to VARCHAR with arguments
      "Size" set to the value 18, and "Character Set" set to "Latin". Also,
      per the specification in Section 3 below, the "Primary Index" button
      was checked for the "acct_nbr" column, too. When done, close the Column
      Type Dialog window by pushing the "OK" button to return to the "Table
      Column Data Types" screen. Repeat the present step as necessary for all
      columns in the table.
   When done, push the "Next" button in the bottom of the "Table Column Data
   Types" screen.
f. The following "SQL Preview" screen displays a preview of the table DDL based
   on your preceding input. Ensure this preview matches the specifications
   provided in Section 3 "Table DDL details for the data" below.
g. Push the "Finish" button. This will confirm for you that the table has been
   created in the target database, and the pop-up wizard window closes.
h. The data upload begins automatically. Wait until the upload is complete.
   The uploading protocol is JDBC-based, so you can expect relatively slow
   uploads. Regardless, the uploads are expected to be quite fast the small
   datasets of this demo, except maybe for the rather larger "Transactions.csv"
   dataset.
i. The table schemas will be interpreted automatically. After the upload,
   verify in Teradata Studio that the tables are present in the desired
   destination locations.

Upload option 2: Use the Fastload utility.
If your client is equipped with the Teradata Fastload utility, then you can use
the fastload script files that accompany the data files in the present bundle
to efficiently upload the data in the CSV files to a target Vantage system
Advanced SQL Engine. Please read the fastload script files for detailed
instructions about using them.


3. Table DDL details for the data
--------------------------------------------------------------------------------

- Accounts table DDL, based on the data in the "Accounts.csv" file

CREATE SET TABLE Accounts ,FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT,
     DEFAULT MERGEBLOCKRATIO,
     MAP = TD_MAP1
     (
      acct_nbr VARCHAR(18) CHARACTER SET LATIN NOT CASESPECIFIC,
      cust_id INTEGER,
      acct_type CHAR(2) CHARACTER SET LATIN NOT CASESPECIFIC,
      account_active CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC,
      acct_start_date DATE FORMAT 'YY/MM/DD',
      starting_balance DECIMAL(11,3),
      ending_balance DECIMAL(11,3))
UNIQUE PRIMARY INDEX ( acct_nbr );


- Customer table DDL, based on the data in the "Accounts.csv" file

CREATE SET TABLE Customer ,FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT,
     DEFAULT MERGEBLOCKRATIO,
     MAP = TD_MAP1
     (
      cust_id INTEGER,
      income DECIMAL(15,1),
      age INTEGER,
      years_with_bank INTEGER,
      nbr_children INTEGER,
      gender CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC,
      marital_status CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC,
      postal_code CHAR(5) CHARACTER SET LATIN NOT CASESPECIFIC,
      state_code CHAR(2) CHARACTER SET LATIN NOT CASESPECIFIC)
UNIQUE PRIMARY INDEX ( cust_id );


- Transactions table DDL, based on the data in the "Accounts.csv" file

CREATE SET TABLE Transactions ,FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT,
     DEFAULT MERGEBLOCKRATIO,
     MAP = TD_MAP1
     (
      tran_id INTEGER,
      acct_nbr VARCHAR(18) CHARACTER SET LATIN NOT CASESPECIFIC,
      tran_amt DECIMAL(9,2),
      principal_amt DECIMAL(15,2),
      interest_amt DECIMAL(11,3),
      new_balance DECIMAL(9,2),
      tran_date DATE FORMAT 'YY/MM/DD',
      tran_time INTEGER,
      channel CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC,
      tran_code CHAR(2) CHARACTER SET LATIN NOT CASESPECIFIC)
UNIQUE PRIMARY INDEX ( tran_id ,acct_nbr );
