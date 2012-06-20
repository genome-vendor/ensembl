
=head1 LICENSE

  Copyright (c) 1999-2012 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

    http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

=head1 NAME

Bio::EnsEMBL::Utils::CliHelper

=head1 VERSION

$Revision: 1.1 $

=head1 SYNOPSIS

  use Bio::EnsEMBL::Utils::CliHelper;

  my $cli = Bio::EnsEMBL::Utils::CliHelper->new();

  # get the basic options for connecting to a database server
  my $optsd = $cli->get_dba_opts();

  # add the print option
  push(@$optsd,"print|p");

  # process the command line with the supplied options plus a reference to a help subroutine
  my $opts = $cli->process_args($optsd,\&usage);
  
  # use the command line options to get an array of database details
  for my $db_args (@{$cli->get_dba_args_for_opts($opts)}) {
    # use the args to create a DBA
    my $dba = new Bio::EnsEMBL::DBSQL::DBAdaptor(%{$db_args});
    ...
  }
  
  For adding secondary databases, a prefix can be supplied. For instance, to add a second set of
  db params prefixed with dna (-dnahost -dbport etc.) use the prefix argument with get_dba_opts and 
  get_dba_args_for_opts:
  # get the basic options for connecting to a database server
  my $optsd =
   [ @{ $cli_helper->get_dba_opts() }, @{ $cli_helper->get_dba_opts('gc') } ];
  # process the command line with the supplied options plus a help subroutine
  my $opts = $cli_helper->process_args( $optsd, \&usage );
  # get the dna details
  my ($dna_dba_details) =
    @{ $cli_helper->get_dba_args_for_opts( $opts, 1, 'dna' ) };
  my $dna_db =
    Bio::EnsEMBL::DBSQL::DBAdaptor->new( %{$dna_dba_details} ) );

=head1 DESCRIPTION

Utilities for a more consistent approach to parsing and handling EnsEMBL script command lines

=head1 METHODS

See subroutines.

=cut

package Bio::EnsEMBL::Utils::CliHelper;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Getopt::Long qw(:config auto_version no_ignore_case);

use Bio::EnsEMBL::DBSQL::DBConnection;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $dba_opts = [ {
	   args => [ 'host', 'dbhost', 'h' ],
	   type => '=s' }, {
	   args => [ 'port', 'dbport', 'P' ],
	   type => ':i' }, {
	   args => [ 'user', 'dbuser', 'u' ],
	   type => '=s' }, {
	   args => [ 'pass', 'dbpass', 'p' ],
	   type => ':s' }, {
	   args => ['dbname'],
	   type => ':s' }, {
	   args => ['pattern','dbpattern'],
	   type => ':s' }, {
	   args => ['driver'],
	   type => ':s' }, {
	   args => ['species_id'],
	   type => ':i' } ];

=head2 new()

  Description : Construct a new instance of a CliHelper object
  Returntype  : Bio::EnsEMBL::Utils:CliHelper
  Status      : Under development

=cut

sub new {
	my ( $class, @args ) = @_;
	my $self = bless( {}, ref($class) || $class );
	return $self;
}

=head2 get_dba_opts()

  Arg [1]     : Optional prefix for dbnames e.g. dna
  Description : Retrieves the standard options for connecting to one or more Ensembl databases
  Returntype  : Arrayref of option definitions
  Status      : Under development

=cut

sub get_dba_opts {
	my ( $self, $prefix ) = @_;
	$prefix ||= '';
	my @dba_opts = map {
		my $opt = join '|', map { $prefix . $_ } @{ $_->{args} };
		$opt . $_->{type};
	} @{$dba_opts};
	return \@dba_opts;
}

=head2 process_args()

    Arg [1]     : Arrayref of supported command line options (e.g. from get_dba_opts)
    Arg [2]     : Ref to subroutine to be invoked when -help or -? is supplied
    Description : Retrieves the standard options for connecting to one or more Ensembl databases
    Returntype  : Hashref of parsed options
    Status      : Under development

=cut

sub process_args {
	my ( $self, $opts_def, $usage_sub ) = @_;
	my $opts = {};
	push @{$opts_def}, q/help|?/ => $usage_sub;
	GetOptions( $opts, @{$opts_def} )
	  || croak 'Could not parse command line arguments';
	return $opts;
}

=head2 get_dba_args_for_opts()

    Arg [1]     : Hash of options (e.g. parsed from command line options by process_args())
    Arg [2]     : If set to 1, the databases are assumed to have a single species only. Default is 0.
    Arg [3]     : Optional prefix to use when parsing e.g. dna
    Description : Uses the parsed command line options to generate an array of DBAdaptor arguments 
                : (e.g. expands dbpattern, finds all species_ids for multispecies databases)
                : These can then be passed directly to Bio::EnsEMBL::DBSQL::DBAdaptor->new()
    Returntype  : Arrayref of DBA argument hash refs 
    Status      : Under development

=cut

sub get_dba_args_for_opts {
	my ( $self, $opts, $single_species, $prefix ) = @_;
	$prefix ||= '';
	$single_species ||= 0;
	my ( $host, $port, $user, $pass, $dbname, $pattern, $driver ) =
	  map { $prefix . $_ } qw(host port user pass dbname pattern driver);
	my @db_args;
	my $dbc =
	  Bio::EnsEMBL::DBSQL::DBConnection->new( -USER   => $opts->{$user},
											  -PASS   => $opts->{$pass},
											  -HOST   => $opts->{$host},
											  -PORT   => $opts->{$port},
											  -DRIVER => $opts->{$driver} );
	my @dbnames;
	if ( defined $opts->{$pattern} ) {
		# get a basic DBConnection and use to find out which dbs are involved
		@dbnames =
		  grep { m/$opts->{pattern}/smx }
		  @{ $dbc->sql_helper()->execute_simple(q/SHOW DATABASES/) };
	} elsif ( defined $opts->{$dbname} ) {
		push @dbnames, $opts->{$dbname};
	} else {
		print Dumper($opts);
		croak 'dbname or dbpattern arguments required';
	}

	for my $dbname (@dbnames) {

		my $multi       = 0;
		my @species_ids = qw/1/;
		if ( !$single_species ) {
			@species_ids = @{
				$dbc->sql_helper()->execute_simple(
"SELECT DISTINCT(species_id) FROM $dbname.meta WHERE species_id>0" ) };
			if ( scalar(@species_ids) > 1 ) {
				$multi = 1;
			}
			if ( defined $opts->{species_id} ) {
				@species_ids = ( $opts->{species_id} );
			}
		}
		for my $species_id (@species_ids) {
			push @db_args, {
				-HOST            => $opts->{$host},
				-USER            => $opts->{$user},
				-PORT            => $opts->{$port},
				-PASS            => $opts->{$pass},
				-DBNAME          => $dbname,
				-DRIVER          => $opts->{$driver},
				-SPECIES_ID      => $species_id,
				-MULTISPECIES_DB => $multi };
		}
	} ## end for my $dbname (@dbnames)
	return \@db_args;
} ## end sub get_dba_args_for_opts

=head2 get_dba_args_for_opts()

    Arg [1]     : Hash of options (e.g. parsed from command line options by process_args())
    Arg [2]     : If set to 1, the databases are assumed to have a single species only. Default is 0.
    Arg [3]     : Optional prefix to use when parsing e.g. dna
    Description : Uses the parsed command line options to generate an array DBAdaptors. 
                : Note this can overload connections on a server
    Returntype  : Arrayref of Bio::EnsEMBL::DBSQL::DBAdaptor
    Status      : Under development

=cut

sub get_dbas_for_opts {
	my ( $self, $opts, $single_species, $prefix ) = @_;

# get all the DBA details that we want to work with and create DBAs for each in turn
	my $dbas;
	for my $args ( @{ $self->get_dba_args_for_opts($opts, $single_species, $prefix) } ) {
		push @{$dbas}, Bio::EnsEMBL::DBSQL::DBAdaptor->new( %{$args} );
	}
	return $dbas;
}
1;
