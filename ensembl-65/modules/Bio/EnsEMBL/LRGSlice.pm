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

Bio::EnsEMBL::LRGSlice - Arbitary Slice of a genome

=head1 SYNOPSIS

  $sa = $db->get_SliceAdaptor;

  $slice =
    $sa->fetch_by_region( 'LRG', 'LRG3');

  # get some attributes of the slice
  my $seqname = $slice->seq_region_name();
  my $start   = $slice->start();
  my $end     = $slice->end();

  # get the sequence from the slice
  my $seq = $slice->seq();

  # get some features from the slice
  foreach $gene ( @{ $slice->get_all_Genes } ) {
    # do something with a gene
  }

  foreach my $feature ( @{ $slice->get_all_DnaAlignFeatures } ) {
    # do something with dna-dna alignments
  }

=head1 DESCRIPTION

A LRG Slice object represents a region of a genome.  It can be used to retrieve
sequence or features from an area of interest.

=head1 METHODS

=cut

package Bio::EnsEMBL::LRGSlice;
use vars qw(@ISA);
use strict;

use Bio::PrimarySeqI;

use Bio::EnsEMBL::Slice;

use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::Slice);

sub new{
  my $class = shift;

  my $self = bless {}, $class ;

  my $slice = $self = $class->SUPER::new( @_);

 return $self;
}

sub stable_id {
    my $self = shift;
    return $self->seq_region_name;
}


sub display_xref {
    my $self = shift;
    return $self->seq_region_name;
}

sub feature_Slice {
  my $self = shift;
  return $self->{_chrom_slice} if defined($self->{_chrom_slice});

  my $max=-99999999999;
  my $min=9999999999;
  my $chrom;
  my $strand;

#  print STDERR "working out feature slcie\n";
  foreach my $segment (@{$self->project('chromosome')}) {
    my $from_start = $segment->from_start();
    my $from_end    = $segment->from_end();
    my $to_name    = $segment->to_Slice->seq_region_name();
    $chrom = $to_name;

    my $to_start    = $segment->to_Slice->start();
    my $to_end    = $segment->to_Slice->end();
    if($to_start > $max){
      $max = $to_start;
    }
    if($to_start < $min){
      $min = $to_start;
    }
    if($to_end > $max){
      $max = $to_end;
    }
    if($to_end <  $min){
      $min = $to_end;
    }
    my $ori        = $segment->to_Slice->strand();
    $strand = $ori;
  }
  if(!defined($chrom)){
    warn "Could not project to chromosome for ".$self->name."??\n";
    return undef;
  }
  my $chrom_slice = $self->adaptor->fetch_by_region("chromosome",$chrom, $min, $max, $strand);
  $self->{_chrom_slice} = $chrom_slice;
  return $self->{_chrom_slice};
}

sub DESTROY{
}

sub get_all_differences{
  my $self = shift;
  
  my @results;
  
  # get seq_region_attrib diffs (always same-length substitutions)
  ################################################################
  
  my $sth = $self->adaptor->prepare(qq{
    SELECT sra.value
    FROM seq_region_attrib sra, attrib_type at
    WHERE at.code = '_rna_edit'
    AND at.attrib_type_id = sra.attrib_type_id
    AND sra.seq_region_id = ?
  });
  
  $sth->execute($self->get_seq_region_id);
  
  my $edit_string;
  
  $sth->bind_columns(\$edit_string);
  
  while($sth->fetch()) {
    my ($start, $end, $edit) = split " ", $edit_string;
    
    my $slice = $self->sub_Slice($start, $end);
    my $chr_proj = $slice->project("chromosome");
    my $ref_seq = '-';
    if(scalar @$chr_proj == 1) {
      $ref_seq = $chr_proj->[0]->[2]->seq;
    }
    
    
    my $diff = {
      'start' => $start,
      'end'   => $end,
      'type'  => 'substitution',
      'seq'   => $edit,
      'ref'   => $ref_seq,
    };
    
    push @results, $diff;
  }
  
  # get more complex differences via projections
  ##############################################
  
  # project the LRG slice to contig coordinates
  my @segs = @{$self->project("contig")};
  
  # if the LRG projects into more than one segment
  if(scalar @segs > 1) {
    
    my ($prev_end, $prev_chr_start, $prev_chr_end, $prev_was_chr);
    
    foreach my $seg(@segs) {
      
      # is this a novel LRG contig, or does it project to a chromosome?
      my @chr_proj = @{$seg->[2]->project("chromosome")};
      
      # if it is a normal contig
      if(scalar @chr_proj) {
        
        # check if there has been a deletion in LRG
        if($prev_was_chr && $prev_end == $seg->[0] - 1) {
          
          # check it's not just a break in contigs
          unless(
             ($chr_proj[0]->[2]->strand != $self->strand && $prev_chr_start == $chr_proj[0]->[2]->end + 1) ||
             ($chr_proj[0]->[2]->strand != $self->strand && $prev_chr_end == $chr_proj[0]->[2]->start - 1)
          ) {
            
            # now get deleted slice coords, depends on the strand rel to LRG
            my ($s, $e);
            
            # opposite strand
            if($chr_proj[0]->[2]->strand != $self->strand) {
              ($s, $e) = ($prev_chr_start - 1, $chr_proj[0]->[2]->end + 1);
            }
            
            # same strand
            else {
              ($s, $e) = ($prev_chr_end + 1, $chr_proj[0]->[2]->start - 1);
            }
            
            if($s > $e) {
              warn "Oops, trying to create a slice from $s to $e (could have been ", $prev_chr_start - 1, "-", $chr_proj[0]->[2]->end + 1, " or ", $prev_chr_end + 1, "-", $chr_proj[0]->[2]->start - 1, ")";
            }
            
            else {
              # get a slice representing the sequence that was deleted
              my $deleted_slice = $self->adaptor->fetch_by_region("chromosome", $chr_proj[0]->[2]->seq_region_name, $s, $e);
              
              my $diff = {
                'start' => $seg->[0],
                'end'   => $prev_end,
                'type'  => 'deletion',
                'seq'   => '-',
                'ref'   => $deleted_slice->seq." ".$deleted_slice->start.'-'.$deleted_slice->end,
              };
              
              push @results, $diff;
            }
          }
        }
        
        $prev_was_chr = 1;
        
        $prev_chr_start = $chr_proj[0]->[2]->start;
        $prev_chr_end = $chr_proj[0]->[2]->end;
      }
      
      # if it is an LRG made-up contig for an insertion
      else {
        $prev_was_chr = 0;
        
        my $diff = {
          'start' => $seg->[0],
          'end'   => $seg->[1],
          'type'  => 'insertion',
          'seq'   => substr($self->seq, $seg->[0] - 1, $seg->[1] - $seg->[0] + 1),
          'ref'   => '-',
        };
        
        push @results, $diff;
      }
      
      $prev_end = $seg->[1];
    }
  }
  
  # return results sorted by start, then end position
  return [sort {$a->{start} <=> $b->{start} || $a->{end} <=> $b->{end}} @results];
}

1;
