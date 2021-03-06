#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;

##############################################################
#  script: identify_contigs_for_RefChr_by_mummer.pl
#  author: Jia-Xing Yue (GitHub ID: yjx1217)
#  last edited: 2018.05.15
#  description: identify contigs corresponding to the specified reference chromosome based on mummer show-coords output
#  example: perl identify_contigs_for_RefChr_by_mummer.pl -i mummer.coords -query_chr_list query_chr.list -cov 90 -o chrMT.match.list
##############################################################


my ($input, $output, $query_chr_list, $cov);
$cov = 75;
GetOptions('input|i:s' => \$input, # input blast tabular output
	   'query_chr_list|q:s' => \$query_chr_list, # a simple list file containing query chr ids from the reference genome
	   'coverage|cov:s' => \$cov, # cummulative query contig coverage
	   'output|o:s' => \$output); # filtered blast tabular output


my $input_fh = read_file($input);
my %match = ();
my $output_fh = write_file($output);

my $query_chr_list_fh = read_file($query_chr_list);
my %query_chr = parse_list_file($query_chr_list_fh);
my @query_chr = keys %query_chr;

while (<$input_fh>) {
    chomp;
    (1..4) and next;
    /^\#/ and next;
    /^\s*$/ and next;
    my ($ref_start, $ref_end, $query_start, $query_end, $ref_match_length, $query_match_length, $ref_length, $query_length, $ref_cov, $query_cov, $ref_id, $query_id) = split /\t/, $_;
    foreach my $query_chr (@query_chr) {
	if ($ref_id =~ /$query_chr/) {
	    if (exists $match{$query_id}) {
		$match{$query_id} += $query_cov;
	    } else {
		$match{$query_id} = $query_cov;
	    }
	}
    }
}

foreach my $query_id (sort {$match{$b} <=> $match{$a}} keys %match) {
    print "query_id=$query_id, cov=$match{$query_id}\n";
    if ($match{$query_id} >= $cov) {
	print $output_fh "$query_id\n";
    }
}


sub read_file {
    my $file = shift @_;
    my $fh;
    if ($file =~ /\.gz$/) {
        open($fh, "gunzip -c $file |") or die "can't open pipe to $file";
    } else {
        open($fh, $file) or die "can't open $file";
    }
    return $fh;
}

sub write_file {
    my $file = shift @_;
    my $fh;
    if ($file =~ /.gz$/) {
        open($fh, "| gzip -c >$file") or die "can't open $file\n";
    } else {
        open($fh, ">$file") or die "can't open $file\n";
    }
    return $fh;
}  


sub parse_list_file {
    my $fh = shift @_;
    my %list = ();
    while (<$fh>) {
	chomp;
	/^#/ and next;
	/^\s*$/ and next;
	my $line = $_;
	if (not exists $list{$line}) {
	    $list{$line} = 1;
	} else {
	    $list{$line}++;
	}
    }
    return %list;
}
