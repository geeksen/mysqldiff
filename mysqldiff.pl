#!/usr/bin/perl

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
		my @sites = split /_/, $conf;
		my $site = $sites[1];
	
		open my $F1, '<', $data . '/' . $conf or die $!;

		my $file = '';
		while (0 != (my $n = read $F1, my $tmp, 1024)) { $file .= $tmp; }
		close $F1;

		$file =~ s/\\r//g;
		my @lines = split /\n/, $file;

		my $db   = $lines[0];
		my $host = $lines[1];
		my $port = $lines[2];
		my $uid  = $lines[3];
		my $pwd  = $lines[4];

		if ($db ne $DB_NAME)
		{
			print "db_name and db_name in $conf are different\n";
			return;
		};

		my $dbh = DBI->connect('DBI:mysql:' . $db . ':' . $host . ':' . $port, $uid, $pwd) or die $!;
		my $sth = $dbh->prepare('show tables');
		$sth->execute;

		@tables = ();
		while (my $row = $sth->fetchrow_hashref)
		{
			push @tables, $row->{'Tables_in_' . $DB_NAME};
		}
		$sth->finish;

		open my $F2, '>', $data . '/table_list_' . $site or die $!;
		foreach my $table (@tables)
		{
			print $F2 $table . "\n";
		}
		close $F2;

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
				open my $F3, '>', $data . '/create_table_' . $table . '_' . $site or die $!;
				print $F3 $row->{'Create Table'};
				close $F3;
			}
			$sth->finish;
		}

		$dbh->disconnect;
	}

	# Diff Table List
	my $command_diff_table_list = "$diff $data/table_list_LOCAL $data/table_list_REMOTE";
	my $result_diff_table_list = `$command_diff_table_list`;

	print "====\n";
	print $command_diff_table_list . "\n";
	print $result_diff_table_list . "\n";

	#unlink $data . '/table_list_LOCAL';
	#unlink $data . '/table_list_REMOTE';

	# Diff Create Table
	foreach my $table (@tables)
	{
		my $command_diff_create_table = $diff . ' ' . $data . '/create_table_' . $table . '_LOCAL ' . $data . '/create_table_' . $table . '_REMOTE';
		my $result_diff_create_table = `$command_diff_create_table`;

		print "====\n";
		print $command_diff_create_table . "\n";
		print $result_diff_create_table . "\n";

		#unlink $data . '/create_table_' . $table . '_LOCAL';
		#unlink $data . '/create_table_' . $table . '_REMOTE';
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

