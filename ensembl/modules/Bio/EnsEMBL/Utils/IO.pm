package Bio::EnsEMBL::Utils::IO;

=pod

=head1 LICENSE

  Copyright (c) 1999-2011 The European Bioinformatics Institute and
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

=pod

=head1 NAME

Bio::EnsEMBL::Utils::IO

=head1 SYNOPSIS

	use Bio::EnsEMBL::Utils::IO qw/slurp work_with_file slurp_to_array fh_to_array/;
	#or
	# use Bio::EnsEMBL::Utils::IO qw/:slurp/; #brings in any method starting with slurp
	# use Bio::EnsEMBL::Utils::IO qw/:array/; #brings in any method which ends with _array
	# use Bio::EnsEMBL::Utils::IO qw/:all/;   #brings all methods in
	
	#As a scalar
  my $file_contents = slurp('/my/file/location.txt');
  print length($file_contents);
  
  #As a ref
  my $file_contents_ref = slurp('/my/file/location.txt', 1);
  print length($$file_contents_ref);
  
  #Sending it to an array
  my $array = slurp_to_array('/my/location');
  work_with_file('/my/location', 'r', sub {
    $array = process_to_array($_[0], sub {
      #Gives us input line by line
      return "INPUT: $_";
    });
  });
  
  #Simplified vesion but without the post processing
  $array = fh_to_array($fh);
  
  #Sending this back out to another file
  work_with_file('/my/file/newlocation.txt', 'w', sub {
    my ($fh) = @_;
    print $fh $$file_contents_ref;
    return;
  });
	
=head1 DESCRIPTION

A collection of subroutines aimed to helping IO based operations

=head1 METHODS

See subroutines.

=head1 MAINTAINER

$Author: ady $

=head1 VERSION

$Revision: 1.2 $

=cut

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw/slurp slurp_to_array fh_to_array process_to_array work_with_file/;
our %EXPORT_TAGS = (
  all => [@EXPORT_OK],
  slurp => [qw/slurp slurp_to_array/],
  array => [qw/fh_to_array process_to_array slurp_to_array/]
);
use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Scalar qw(:assert);
use IO::File;

=head2 slurp()

  Arg [1]     : string $file
  Arg [2]     : boolean; $want_ref
  Arg [3]     : boolean; $binary
                Indicates if we want to return a scalar reference
  Description : Forces the contents of a file into a scalar. This is the 
                fastest way to get a file into memory in Perl. You can also
                get a scalar reference back to avoid copying the file contents
                in Scalar references. If the input file is binary then specify
                with the binary flag
  Returntype  : Scalar or reference of the file contents depending on arg 2
  Example     : my $contents = slurp('/tmp/file.txt');
  Exceptions  : If the file did not exist or was not readable
  Status      : Stable

=cut

sub slurp {
	my ($file, $want_ref, $binary) = @_;
	my $contents;
	work_with_file($file, 'r', sub {
	  my ($fh) = @_;
	  local $/ = undef;
	  binmode($fh) if $binary;
	  $contents = <$fh>;
	  return;
	});
	return ($want_ref) ? \$contents : $contents;
}

=head2 slurp_to_array()

  Arg [1]     : string $file
  Arg [2]     : boolean $chomp
  Description : Sends the contents of the given file into an ArrayRef
  Returntype  : ArrayRef
  Example     : my $contents_array = slurp_to_array('/tmp/file.txt');
  Exceptions  : If the file did not exist or was not readable
  Status      : Stable

=cut

sub slurp_to_array {
  my ($file, $chomp) = @_;
  my $contents;
  work_with_file($file, 'r', sub {
	  my ($fh) = @_;
	  $contents = fh_to_array($fh, $chomp);
	  return;
	});
	return $contents;
}

=head2 fh_to_array()

  Arg [1]     : Glob/IO::Handle $fh
  Arg [2]     : boolean $chomp
  Description : Sends the contents of the given filehandle into an ArrayRef. 
                Will perform chomp on each line if specified. If you require
                any more advanced line based processing then see 
                L<process_to_array>.
  Returntype  : ArrayRef
  Example     : my $contents_array = fh_to_array($fh);
  Exceptions  : None
  Status      : Stable

=cut

sub fh_to_array {
  my ($fh, $chomp) = @_;
  if($chomp) {
    return process_to_array($fh, sub {
      my ($line) = @_;
      chomp($line);
      return $line;
    });
  }
  my @contents = <$fh>;
  return \@contents;
}

=head process_to_array

  Arg [1]     : Glob/IO::Handle $fh
  Arg [2]     : CodeRef $callback
  Description : Sends the contents of the given file handle into an ArrayRef
                via the processing callback. Assumes line based input.
  Returntype  : ArrayRef
  Example     : my $array = process_to_array($fh, sub { return "INPUT: $_"; });
  Exceptions  : If the fh did not exist or if a callback was not given.
  Status      : Stable

=cut

sub process_to_array {
  my ($fh, $callback) = @_;
  assert_file_handle($fh, 'FileHandle');
  assert_ref($callback, 'CODE', 'callback');
  my @contents;
  while( my $line = <$fh> ) {
    push(@contents, $callback->($line));
  }
  return \@contents;
}

=head2 work_with_file()

  Arg [1]     : string $file
  Arg [2]     : string; $mode 
                Supports all modes specified by the C<open()> function as well as those 
                supported by IO::File
  Arg [3]     : CodeRef the callback which is given the open file handle as
                its only argument
  Description : Performs the nitty gritty of checking if a file handle is open
                and closing the resulting filehandle down.
  Returntype  : None
  Example     : work_with_file('/tmp/out.txt', 'w', sub { 
                  my ($fh) = @_; 
                  print $fh 'hello'; 
                  return;
                });
  Exceptions  : If we could not work with the file due to permissions
  Status      : Stable

=cut

sub work_with_file {
  my ($file, $mode, $callback) = @_;
  throw "We need a mode to open the requested file with" if ! $file;
  assert_ref($callback, 'CODE', 'callback');
  my $fh = IO::File->new($file, $mode) or
    throw "Cannot open '${file}' in  mode '${mode}': $!";
  $callback->($fh);
  close($fh) or throw "Cannot close FH from ${file}: $!";
  return;
}

1;
