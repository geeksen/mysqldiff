#!/usr/bin/perl

# //////
# --@-@
#     >  Geeksen's Lab
# ____/  http://github.com/geeksen/
#
# Copyright (c) 2014 Terry Geeksen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use strict;
use warnings;

# For Debug
#use Data::Dumper;

my $data = './data/';
my $diff = '/usr/bin/diff';

use DBI;
&main;

sub main
{
	if (0 == scalar @ARGV)
	{
		print "Usage: ./mysqldiff.pl db_name\n";
		return;
	}
	my $DB_NAME = $ARGV[0];

	$data .= $DB_NAME;

	my @tables;
	my @confs = &read_dir_and_filter($data, 'conf');

	if (0 == scalar @confs)
	{
		print "$data not found\n";
		return;
	}

	foreach my $conf (@confs)
	{
		my @target_splited = split /_/, $conf;
		my $target = $target_splited[1];

		if (2 < scalar @target_splited)
		{
			print "conf_FILE must be like conf_ORIGINAL or conf_TARGET0X\n";
			return;
		}
	
		open my $CONF, '<', $data . '/' . $conf or die $!;

		my $file = '';
		while (0 != (my $n = read $CONF, my $tmp, 1024)) { $file .= $tmp; }
		close $CONF;

		$file =~ s/\\r//g;
		my @lines = split /\n/, $file;

		my $db   = $lines[0];
		my $host = $lines[1];
		my $port = $lines[2];
		my $uid  = $lines[3];
		my $pwd  = $lines[4];

		#if ($db ne $DB_NAME)
		#{
			#print "db_name and db_name in $conf are different\n";
			#return;
		#};

		my $dbh = DBI->connect('DBI:mysql:' . $db . ':' . $host . ':' . $port, $uid, $pwd) or die $!;
		my $sth = $dbh->prepare('show tables');
		$sth->execute;

		@tables = ();
		while (my $row = $sth->fetchrow_hashref)
		{
			push @tables, $row->{'Tables_in_' . $DB_NAME};
		}
		$sth->finish;

		open my $TABLE_LIST, '>', $data . '/table_list_' . $target or die $!;
		foreach my $table (@tables)
		{
			print $TABLE_LIST $table . "\n";
		}
		close $TABLE_LIST;

		foreach my $table (@tables)
		{
			$sth = $dbh->prepare("show tables like '" . $table . "'");
			$sth->execute;
			if (0 == $sth->rows) { next; }
			$sth->finish;

			$sth = $dbh->prepare('show create table `' . $table . '`');
			$sth->execute;

			if (my $row = $sth->fetchrow_hashref)
			{
				open my $CREATE_TABLE, '>', $data . '/create_table_' . $table . '_' . $target or die $!;
				print $CREATE_TABLE $row->{'Create Table'};
				close $CREATE_TABLE;
			}
			$sth->finish;
		}

		$dbh->disconnect;
	}

	foreach my $conf (@confs)
	{
		if ('conf_ORIGINAL' eq $conf)
		{
			next;
		}

		my @target_splited = split /_/, $conf;
		my $target = $target_splited[1];

		# Diff Table List
		my $diff_table_list = "$diff $data/table_list_ORIGINAL $data/table_list_$target";

		print "\n";
		print "====\n";
		print $diff_table_list . "\n";
		print `$diff_table_list`;

		#unlink $data . '/table_list_ORIGINAL';
		#unlink $data . '/table_list_' . $target';

		# Diff Create Table
		foreach my $table (@tables)
		{
			my $diff_create_table = $diff . ' ' . $data . '/create_table_' . $table . '_ORIGINAL ' . $data . '/create_table_' . $table . '_' . $target;

			print "====\n";
			print $diff_create_table . "\n";
			print `$diff_create_table`;

			#unlink $data . '/create_table_' . $table . '_ORIGINAL';
			#unlink $data . '/create_table_' . $table . '_' . $target;
		}

		print "\n";
	}
}

sub read_dir_and_filter
{
        my $path = $_[0];
        my $filter = $_[1];

	if (! -d $path)
	{
		return ();
	}

        opendir(my $D, $path) or die $!;
        my @files = readdir $D;
        closedir $D;

        my @filtered = ();
        foreach my $file (@files)
        {
                if ($file =~ /^\./) { next; }
                if ($file =~ /$filter/) { push @filtered, $file; }
        }

        return sort @filtered;
}


