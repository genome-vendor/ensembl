package XrefMapper::ciona_intestinalis;

use  XrefMapper::BasicMapper;

use vars '@ISA';

@ISA = qw{ XrefMapper::BasicMapper };

sub get_set_lists {

  return [["ExonerateGappedBest1", ["ciona_intestinalis","*"]]];

}

sub gene_description_filter_regexps {

  return ();

}

1;
