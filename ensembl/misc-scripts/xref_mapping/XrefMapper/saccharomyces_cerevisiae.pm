package XrefMapper::saccharomyces_cerevisiae;

use  XrefMapper::BasicMapper;

use vars qw(@ISA);

@ISA = qw(XrefMapper::BasicMapper);


sub get_set_lists {

  return [["ExonerateGappedBest5", ["saccharomyces_cerevisiae","RefSeq_mRNA"]],
	  ["ExonerateGappedBest5", ["saccharomyces_cerevisiae","RefSeq_mRNA_predicted"]],
	  ["ExonerateGappedBest5", ["saccharomyces_cerevisiae","RefSeq_ncRNA"]],
	  ["ExonerateGappedBest5", ["saccharomyces_cerevisiae","RefSeq_ncRNA_predicted"]],
          ["ExonerateGappedBest1", ["saccharomyces_cerevisiae","*"]]];

}



# Cerevisiae is imported from SGD. The gene and transcript stable IDs
# are the SGD identifiers. The display_xref_ids for genes and
# transcripts are calculated directly rather than via the more complex
# priority-based method in BasicMapper.pm

sub build_display_xrefs {

  my ($self, $type, $external_db) = @_;

  print "Setting $type display_xrefs from $type stable IDs\n";
  my $dir = $self->core()->dir();

  my $sql = "UPDATE $type t, xref x, external_db e SET t.display_xref_id=x.xref_id WHERE t.stable_id=x.dbprimary_acc AND e.external_db_id=x.external_db_id AND e.db_name=\'${external_db}\'\n";

  open (SQL, ">$dir/${type}_display_xref.sql");

  print SQL $sql;

  close(SQL);

}


sub transcript_display_xref_sources {
    my $self     = shift;

    my @list = qw(
                SGD_GENE
                SGD_TRANSCRIPT
               );
    
    my %ignore;
     
    return [\@list,\%ignore];
}

sub gene_description_sources {
  return (
          "SGD_GENE"
         );
}


sub gene_description_filter_regexps {

  return ();

}



1;
