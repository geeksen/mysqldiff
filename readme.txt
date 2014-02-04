sudo apt-get install libdbi-perl
sudo apt-get install libdbd-mysql-perl

mkdir ./data/db_name
vi ./data/db_name/conf_LOCAL
vi ./data/db_name/conf_REMOTE

./mysqldiff.pl db_name
