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

Bio::EnsEMBL::Utils::Proxy

=head1 SYNOPSIS

  #Simple arounds logging proxy
  package myproxy;
  use base qw/Bio::EnsEMBL::Utils::Proxy/;
  sub __resolver {
    my ($invoker, $package, $method) = @_;
    return sub {
      my ($self, @args);
      warn "Entering into ${package}::${method}";
      my @capture = $self->$method(@args);
      warn "Exiting from ${package}::${method}";
      return @capture;
    };
  }
  
  1;

=head1 DESCRIPTION

This class offers Proxy objects similar to those found in Java's 
C<java.lang.reflect.Proxy> object. This class should be overriden and 
then implement C<__resolver()>. The C<__resolver()> method returns a 
subroutine to the intended action which the proxy object installs into
the calling class' scope.

All methods internal to the proxy are prefixed with a double underscore
to avoid corruption/intrusion into the normal public and private scope of 
most classes.

=head1 METHODS

=cut

package Bio::EnsEMBL::Utils::Proxy;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

use vars '$AUTOLOAD';

=head2 new

  Arg [1]    	: The object to proxy  
  Example			: my $newobj = Bio::EnsEMBL::Utils::Proxy->new($myobj);
  Description	: Provides a new instance of a proxy
  Returntype 	: Bio::EnsEMBL::Utils::Proxy the new instance
  Exceptions 	: None 
  Caller     	: public
  Status     	: -

=cut

sub new {
  my ($class, $proxy) = @_;
  my $self = bless({}, ref($class)||$class);
  $self->{__proxy} = $proxy;
  return $self;
}

=head2 __proxy
 
  Example			: -
  Description	: The proxy accessor
  Returntype 	: Any the proxied object
  Exceptions 	: None 
  Caller     	: -
  Status     	: -

=cut

sub __proxy {
  my ($self) = @_;
  return $_[0]->{__proxy};
}

=head2 isa

  Args        : Object type to test
  Example     : $obj->isa('Bio::EnsEMBL::Utils::Proxy');
  Description : Overriden to provide C<isa()> support for proxies. Will return
                true if this object is assignable to the given type or the
                proxied object is
  Returntype  : Boolean; performs same as a normal can
  Exceptions  : None
  Caller      : caller
  Status      : status

=cut


sub isa {
  my ($self, $class) = @_;
  return 1 if $self->SUPER::isa($class);
  return 1 if $self->__proxy()->isa($class);
  return 0;
}

=head2 can

  Args       	: Method name to test
  Example			: $obj->can('__proxy');
  Description	: Overriden to provide C<can()> support for proxies. Will return
                true if this object implements the given method or the
                proxied object can
  Returntype 	: Code; performs same as a normal can
  Exceptions 	: None
  Caller     	: caller
  Status     	: status

=cut

sub can {
  my ($self, $method) = @_;
  return 1 if $self->SUPER::can($method);
  return 1 if $self->__proxy()->can($method);
  return 0;
}

=head2 DESTROY

  Example			: -
  Description	: Provided because of AutoLoad
  Returntype 	: None 
  Exceptions 	: None
  Caller     	: -
  Status     	: -

=cut



sub DESTROY {
  # left blank
}

=head2 AUTOLOAD

  Example     : -
  Description : Performs calls to C<__resolver()> and installs the subroutine
                into the current package scope.
  Returntype  : None 
  Exceptions  : Thrown if C<__resolver()> could not return a subroutine
  Caller      : -
  Status      : -

=cut

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($package_name, $method_name) = $AUTOLOAD =~ m/ (.*) :: (.*) /xms;
  my $sub = $self->__resolver($package_name, $method_name, @args);
  if(! $sub) {
    my $type = ref $self ? 'object' : 'class';
    throw qq{Can't locate $type method "$method_name" via package "$package_name". No subroutine was generated};
  }
  *$AUTOLOAD = $sub;
  goto &$sub;
}

sub __resolver {
  my ($self, $package_name, $method, @args) = @_;
  #override to provide the subroutine to install
  throw "Unimplemented __resolver() in $package_name. Please implement";
}

1;

__END__
