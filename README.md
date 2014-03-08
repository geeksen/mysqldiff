mysqldiff
=========

Install Perl DBI/DBD Modules
----------------------------
* sudo apt-get install libdbi-perl
* sudo apt-get install libdbd-mysql-perl

Install mysqldiff
-----------------
* git clone https://github.com/geeksen/mysqldiff.git
* cd mysqldiff

Configuration
-------------
* vi data/db_name/conf_ORIGINAL
* vi data/db_name/conf_TARGET00
* vi data/db_name/conf_TARGET01

Run
---
* chmod +x mysqldiff.pl
* ./mysqldiff.pl db_name

