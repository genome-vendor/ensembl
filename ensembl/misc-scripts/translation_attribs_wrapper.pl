#!/usr/local/ensembl/bin/perl

=head1 NAME

translation_attribs_wrapper.pl

Script to calculate peptide statistics and store them in
translation_attrib table.  This is mainly a wrapper around the
translation_attribs.pl script to submit several jobs to the farm.

=head1 SYNOPSIS

translation_attribs_wrapper.pl [arguments]

Required arguments:

  --user=user           username for the database

  --pass=pass           password for database

  --release=release     release number

Optional arguments:

  --binpath=PATH        directory where the binary script to
                        calculate pepstats is stored (default:
                        /software/pubseq/bin/emboss)

  --tmpdir=directory    directory to store temporary results of pepstats
                        (default: /tmp)

  --host=host           server where the core databases are stored
                        (default: ens-staging)

  --port=port           port (default: 3306)

  --path=path           path where the LSF output will be stored
                        (default: the current directory)

  --help                display help (this message)

=head1 DESCRIPTION

This script will calculate the peptide statistics for all core databases
in the server and store them as a translation_attrib values.  This is a
wraper around the translation_attrib and will simply submit jobs to the
farm grouping the core databases in patterns.

=head1 EXAMPLES

Calculate translation_attributes for all databases in ens-staging

  $ ./translation_attribs_wrapper.pl --user ensadmin \
    --pass password --release 51 --path /my/path/to/lsf/output

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Daniel Rios <dani@ebi.ac.uk>, Ensembl core API team

=head1 CONTACT

=cut

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Bio::EnsEMBL::Utils::Exception qw(throw);


## Command line options

my $binpath = "'/software/pubseq/bin/emboss'"; 
my $tmpdir = "'/tmp'";
my $host = "ens-staging";
my $path = $ENV{PWD};
my $release = undef;
my $user = undef;
my $pass = undef;
my $port = 3306;
my $help = undef;

GetOptions('binpath=s' => \$binpath,
	   'tmpdir=s' => \$tmpdir,
	   'host=s'    => \$host,
	   'user=s'    => \$user,
	   'pass=s'    => \$pass,
	   'port=s'    => \$port,
	   'release=i' => \$release,
	   'path=s'    => \$path,
	   'help'    => \$help
	   );

pod2usage(1) if($help);
throw("--user argument required") if (!defined($user));
throw("--pass argument required") if (!defined($pass));
throw("--release argument required") if (!defined($release));

my $queue = 'long';
my $memory = "'select[mem>4000] rusage[mem=4000]' -M4000000";
my $options = '';
if (defined $binpath){
    $options .= "--binpath $binpath ";
}
if (defined $tmpdir){
    $options .= "--tmpdir $tmpdir "
}
if (defined $host){
    $options .= "--host $host ";
}
if (defined $port){
    $options .= "--port $port ";
}

my @ranges = ('^[a-b]','^c','^d','^e','^f','^[g-h]','^[i-l]','^m[a-i]','^m[j-z]','^[n-o]','^p','^[q-r]','^[s-t]','^[u-z]');
my $core_db = ".*core_$release\_.*";
my $call;
foreach my $pattern (@ranges){
    $call = "bsub "
      . "-R 'select[(myens_staging1<=800)&&(myens_staging2<=800)]' "
      . "-o ${path}/output_translation_${pattern}.txt "
      . "-e ${path}/output_translation_${pattern}.err "
      . "-q $queue "
      . "-R$memory "
      . "perl ./translation_attribs.pl --user $user --pass $pass $options";
    $call .= " --pattern '" . $pattern . $core_db . "'";

    system($call);
#print $call,"\n";
}

#we now need to run it for the otherfeatures|vega databases, but only the pepstats

my $vega_db = ".*_vega_$release\_.*";
$call = "bsub -R 'select[(myens_staging1<=800)&&(myens_staging2<=800)]' -o '" . "$path/output_translation_vega.txt" . "' -q $queue -R$memory perl ./translation_attribs.pl --user $user --pass $pass $options";
$call .= " --pattern '" . $vega_db. "'";

system($call);
#print $call,"\n";

@ranges = ('^[a-b]','^c','^[d-e]','^[f-h]','^[i-m]','^[n-o]','^p','^[q-s]','^[t-z]');

my $other_db = ".*_otherfeatures_$release\_.*";

foreach my $pattern (@ranges){
    $call = "bsub -R 'select[(myens_staging1<=800)&&(myens_staging2<=800)]' -o '" . "$path/output_translation_other_$pattern.txt" . "' -q $queue -R$memory perl ./translation_attribs.pl --user $user --pass $pass $options";
    $call .= " --pattern '" . $pattern . $other_db. "'";
    
    system($call);
#print $call,"\n";
}
