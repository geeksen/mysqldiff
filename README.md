mysqldiff
=========

Install Perl DBI/DBD Modules
----------------------------
* sudo apt-get install libdbi-perl
* sudo apt-get install libdbd-mysql-perl

Create Data Directory
---------------------
* mkdir -p ./data/db_name

Configuration
-------------
* vi ./data/db_name/conf_ORIGINAL
* vi ./data/db_name/conf_TARGET00
* vi ./data/db_name/conf_TARGET01

Run
---
* ./mysqldiff.pl db_name

