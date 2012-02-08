#!/usr/local/ensembl/bin/perl

=head1 NAME

mapping_stats.pl - print some statistics about a whole genome alignment between
two assemblies.

=head1 SYNOPSIS

mapping_stats.pl [arguments]

Required arguments:

  --dbname, db_name=NAME              database name NAME
  --host, --dbhost, --db_host=HOST    database host HOST
  --port, --dbport, --db_port=PORT    database port PORT
  --user, --dbuser, --db_user=USER    database username USER
  --pass, --dbpass, --db_pass=PASS    database passwort PASS
  --assembly=ASSEMBLY                 assembly version ASSEMBLY

  --altdbname=NAME                    alternative database NAME
  --altassembly=ASSEMBLY              alternative assembly version ASSEMBLY

Optional arguments:

  --althost=HOST                      alternative databases host HOST
  --altport=PORT                      alternative database port PORT
  --altuser=USER                      alternative database username USER
  --altpass=PASS                      alternative database password PASS

  --chromosomes, --chr=LIST           only process LIST toplevel seq_regions

  --conffile, --conf=FILE             read parameters from FILE
                                      (default: conf/Conversion.ini)

  --logfile, --log=FILE               log to FILE (default: *STDOUT)
  --logpath=PATH                      write logfile to PATH (default: .)
  --logappend, --log_append           append to logfile (default: truncate)

  -v, --verbose=0|1                   verbose logging (default: false)
  -i, --interactive=0|1               run script interactively (default: true)
  -n, --dry_run, --dry=0|1            don't write results to database
  -h, --help, -?                      print help (this message)

=head1 DESCRIPTION

This script prints some statistics about a whole genome alignment between two
assemblies, like the alignment coverage and length of alignment blocks.

=head1 RELATED FILES

The whole process of creating a whole genome alignment between two assemblies
is done by a series of scripts. Please see

  ensembl/misc-scripts/assembly/README

for a high-level description of this process, and POD in the individual scripts
for the details.

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 AUTHOR

Patrick Meidl <meidl@ebi.ac.uk>, Ensembl core API team

=head1 CONTACT

Please post comments/questions to the Ensembl development list
<dev@ensembl.org>

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use FindBin qw($Bin);
use vars qw($SERVERROOT);

BEGIN {
    $SERVERROOT = "$Bin/../../..";
    unshift(@INC, "$SERVERROOT/ensembl/modules");
    unshift(@INC, "$SERVERROOT/bioperl-live");
}

use Getopt::Long;
use Pod::Usage;
use Bio::EnsEMBL::Utils::ConversionSupport;

$| = 1;

my $support = new Bio::EnsEMBL::Utils::ConversionSupport($SERVERROOT);

# parse options
$support->parse_common_options(@_);
$support->parse_extra_options(
    'assembly=s',
    'altdbname=s',
    'altassembly=s',
    'althost=s',
    'altport=n',
    'chromosomes|chr=s@',
);
$support->allowed_params(
    $support->get_common_params,
    'assembly',
    'altdbname',
    'altassembly',
    'althost',
    'altport',
    'chromosomes',
);

if ($support->param('help') or $support->error) {
    warn $support->error if $support->error;
    pod2usage(1);
}

$support->comma_to_list('chromosomes');

# ask user to confirm parameters to proceed
$support->confirm_params;

# get log filehandle and print heading and parameters to logfile
$support->init_log;

$support->check_required_params(
    'assembly',
    'altdbname',
    'altassembly'
);

# first set connection parameters for alternative db if not different from
# reference db
map { $support->param("alt$_", $support->param($_)) unless ($support->param("alt$_")) } qw(host port user);

# reference database
my $R_dba = $support->get_database('ensembl');
my $R_sa = $R_dba->get_SliceAdaptor;

# database containing the alternative assembly
my $A_dba = $support->get_database('core', 'alt');
my $A_sa = $A_dba->get_SliceAdaptor;

my $fmt1 = "%-40s%12s\n";
my $fmt2 = "%-40s%11.1f%%\n";
my $fmt3 = "%-44s%8.0f (%2.0f%%)\n";

$support->log("Looping over toplevel seq_regions...\n\n");

foreach my $chr ($support->sort_chromosomes) {
  $support->log_stamped("Toplevel seq_region $chr...\n", 1);

  # determine non-N sequence length of alternative toplevel seq_region
  my $A_slice = $A_sa->fetch_by_region('toplevel', $chr);

  unless ($A_slice) {
    $support->log("Not found in alternative db. Skipping.\n", 2);
    next;
  }
  
  my $cs_name = $A_slice->coord_system_name;

  my $start = 1;
  my $A_chr_length = $A_slice->length;
  my $n;
  my $end;
  
  while ($start < $A_chr_length) {
    $end = $start + 10000000;
    $end = $A_chr_length if ($end > $A_chr_length);
    my $sub_slice = $A_slice->sub_Slice($start, $end);
    my $seq = $sub_slice->seq;
    $n += $seq =~ tr/N/N/;
    $start = $end + 1;
  }

  my $A_length = $A_chr_length - $n;

  # determine total length of mapping to alternative assembly
  my $mapping_length = 0;
  my %blocks;
  my %blocklength;

  # toplevel seq_region length order of magnitude
  my $oom = length($A_length);
  
  my $R_slice = $R_sa->fetch_by_region($cs_name, $chr);
  my @segments = @{ $R_slice->project($cs_name, $support->param('altassembly')) };

  my $alignments = 0;

  foreach my $seg (@segments) {
    my $sl = $seg->to_Slice;

    # ignore PAR region (i.e. we project to the symlinked seq_region)
    next if ($sl->seq_region_name ne $chr);
    
    my $l = $sl->length;
    $mapping_length += $l;
    
    my $c_oom = $oom;
    
    while ($c_oom) {
      if ($l > 10**($c_oom-1) and $l <= 10**$c_oom) {
        $blocks{10**$c_oom}++;
        $blocklength{10**$c_oom} += $l;
      }
      $c_oom--;
    }
    $blocks{10}++ if ($l == 1);

    $alignments++;
  }  
  
  # print stats
  $support->log("\n");
  
  $support->log(sprintf($fmt1, "Reference toplevel seq_region length:",
      $support->commify($R_slice->length)), 2);
  $support->log(sprintf($fmt1, "Alternative toplevel seq_region length:",
      $support->commify($A_chr_length)), 2);
  $support->log(sprintf($fmt1, "Non-N sequence length (alternative):",
      $support->commify($A_length)), 2);
  $support->log(sprintf($fmt1, "Alternative mapping length:",
      $support->commify($mapping_length)), 2);
  $support->log(sprintf($fmt2, "Mapping percentage:",
      $mapping_length/$A_length*100), 2);
  
  $support->log("\n");
  
  $support->log(sprintf($fmt1, "Total alignments:", $alignments), 2);
  
  if ($alignments) {
    for (my $i = 0; $i < $oom; $i++) {
      my $from = 10**$i;
      my $to = 10**($i+1);
      $support->log(sprintf($fmt3, "    ".$support->commify($from)." - ".$support->commify($to)." bp:", $blocks{$to}, $blocklength{$to}/$R_slice->length*100), 2);
    }
  }
  
  $support->log("\n");
  
}

# finish logfile
$support->finish_log;

