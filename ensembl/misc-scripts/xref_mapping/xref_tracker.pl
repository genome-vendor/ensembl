#!/usr/local/ensembl/bin/perl


use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use XrefMapper::db;
use XrefMapper::SubmitMapper;
use XrefMapper::BasicMapper;

use vars qw(@INC);

$| = 1;

my $file;

GetOptions ('file=s'                    => \$file);
           

my $mapper = XrefMapper::BasicMapper->process_file($file, 0);

my $status = $mapper->xref_latest_status(1);
print "\n\nlast finished status is $status\n" ;


if($status eq "mapping_submitted"){
  my %pend_count;
  my %run_count;
  my %total_jobs;
  my %job_to_type;
  my %run;
  my %pend;

  my $sql = "select job_id, type, array_size from mapping";
  my $sth = $mapper->xref->dbc->prepare($sql);
  $sth->execute;
  my ($job_id, $type, $size);
  $sth->bind_columns(\$job_id, \$type, \$size);
  while($sth->fetch){
    $total_jobs{$job_id} = $size;
    $job_to_type{$job_id} = $type;
    $pend{$job_id} = 0;
    $run{$job_id} = 0;
  }
  $sth->finish;

  print "Summary of bjobs running\n";
  open(README, "bjobs|") or die "can't issue bsubs command";
  while(<README>){
    #82187   ianl    PEND  normal     bc-9-1-01               *78857[51] Mar 18 12:20    
    my @array = split;
    if($array[2] eq "PEND"){
      $pend{$array[0]}++;
    }
    if($array[2] eq "RUN"){
      $run{$array[0]}++;
    }
  }
  close README;	
  
  foreach my $job_id (keys %job_to_type){
    my $finished =  $total_jobs{$job_id} - ($pend{$job_id} + $run{$job_id});
    my $percent = ($finished/$total_jobs{$job_id}) *100;
    print "$percent% jobs finished for ".$job_to_type{$job_id}."\n";
    print "\t".$pend{$job_id}." still pending\n" if($pend{$job_id});
    print "\t".$run{$job_id}." still running\n"  if($run{$job_id});
  }
  

}
elsif($status eq "mapping_finished"){
  print "Summary of jobs being processed\n";

  my %label;

  $label{"SUBMITTED"} = "jobs still to be processed.";
  $label{"SUCCESS"}   = "jobs succcessfully parsed.";
  $label{"FAILED"}    = "jobs failed and could not be parsed successfully.";
  my $sql = "select status, count(1) from mapping_jobs group by status";
  my $sth = $mapper->xref->dbc->prepare($sql);
  $sth->execute;
  my ($status, $count);
  $sth->bind_columns(\$status, \$count);
  while($sth->fetch()){
    print "\t$count ".$label{$status}."\n";
  }
  $sth->finish;
}
else{
  print "No further information is known at this time\n";
}

