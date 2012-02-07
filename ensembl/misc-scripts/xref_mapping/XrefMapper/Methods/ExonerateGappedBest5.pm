package XrefMapper::Methods::ExonerateGappedBest5;

use XrefMapper::Methods::ExonerateBasic;

use vars '@ISA';

@ISA = qw{XrefMapper::Methods::ExonerateBasic};



sub options {

  return ('--gappedextension FALSE', '--model', 'affine:local', '--subopt', 'no', '--bestn', '5');

}

sub query_identity_threshold {

  return 90;

}

sub target_identity_threshold {

  return 90;

}


1;
