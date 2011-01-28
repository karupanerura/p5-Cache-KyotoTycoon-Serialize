package Cache::KyotoTycoon::Serialize;
use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use Carp;

use parent 'Cache::KyotoTycoon';

use Storable qw(nfreeze thaw);
use Sub::Install qw(reinstall_sub);
use List::MoreUtils qw(any);

my @_setter = qw(set add replace append);
our $AUTOLOAD;

*_serialize = \&nfreeze;
*_deserialize = \&thaw;

sub import{
    my($class, @args) = @_;

    my $option_qr = qr/^-/;

    my %_flags = (
	-compat => sub{
	    my $class = shift;

	    my $org =  \&Cache::KyotoTycoon::new;

	    reinstall_sub(+{
		code => sub{
		    shift;
		    return $org->(__PACKAGE__, @_);
		},
		into => 'Cache::KyotoTycoon',
		as => 'new',
	    });
	},
    );

    my %_options = (
	-serializer => sub{
	    my($class, $value) = @_;

	    if(ref($value) eq 'CODE'){
		*_serialize = $value;
	    }else{
		croak('-serializer option need code reference.');
	    }
	},
	-deserializer => sub{
	    my($class, $value) = @_;

	    if(ref($value) eq 'CODE'){
		*_deserialize = $value;
	    }else{
		croak('-deserializer option need code reference.');
	    }
	},
    );

    while(scalar(@args)){
	my $optname = shift(@args);

	if($optname =~ $option_qr){
	    if(any {$_ eq $optname} keys %_flags){
		$_flags{$optname}->($class);
		next;
	    }

	    my $value = shift(@args);

	    if(any {$_ eq $optname} keys %_options){
		$_options{$optname}->($class, $value);
		next;
	    }
	}
    }
}

sub cas {
    my ($self, @args) = @_;

    $args[1] = _serialize($args[1]);
    $args[2] = _serialize($args[2]);

    $self->SUPER::cas(@args);
}

sub get{
    my @result = SUPER::get(@_);
    $result[0] = _deserialize($result[0]);

    return wantarray ? @result : $result[0]; 
}

sub set_bulk {
    my ($self, $vals, $xt) = @_;
    my %args = (DB => $self->db);
    while (my ($k, $v) = each %$vals) {
        $args{"_$k"} = _serialize($v);
    }
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('set_bulk', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return $body->{num};
}

sub get_bulk {
    my ($self, $keys) = @_;
    my %args = (DB => $self->db);
    for my $k (@$keys) {
        $args{"_$k"} = '';
    }
    my ($code, $body, $msg) = $self->{client}->call('get_bulk', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    my %ret;
    while (my ($k, $v) = each %$body) {
        if ($k =~ /^_(.+)$/) {
            $ret{$1} = _deserialize($v);
        }
    }
    die "fatal error" unless keys(%ret) == $body->{num};
    return wantarray ? %ret : \%ret;
}

# AUTOLOAD

sub setter{
    my ($self, $setter, @args) = @_;

    $args[1] = _serialize($args[1]);

    {
	no strict 'refs';
	$self->$setter(@args);
    }
}

sub AUTOLOAD{
    my ($self, @args) = @_;

    if($AUTOLOAD =~ m/(?:.*)::(.*)/io){
	my $method = $1;
	(any { $_ eq $method } @_setter) ?
	    $self->setter($self, $method, @args):
	    die('Undefined subroutine &' . $AUTOLOAD);
    }
}

# DESTROY

sub DESTROY{
    my $self = shift;

    $self->SUPER::DESTROY if(Cache::KyotoTycoon->can('DESTROY')); # for future
}

1;
__END__

=head1 NAME

Cache::KyotoTycoon::Serialize - serialize/deserialize support for Cache::KyotoTycoon

=head1 SYNOPSIS

  use Cache::KyotoTycoon;
  use Cache::KyotoTycoon::Serialize qw(-compat);

  my $dbi = Cache::KyotoTycoon->new(
    addr => '127.0.0.1'
  );

  $dbi->add('key', +{
    # datas ...
  }); # You can pass any reference data to KyotoTycoon!

or

  use Cache::KyotoTycoon::Serialize;

  my $dbi = Cache::KyotoTycoon::Serialize->new(
    addr => '127.0.0.1'
  );

  $dbi->add('key', +{
    # datas ...
  }); # You can pass reference data to KyotoTycoon!

You can use the serialize/deserialize subroutine you like if you can pass options.

  use Data::MessagePack;
  use Cache::KyotoTycoon::Serialize(
    -serializer   => sub{ Data::MessagePack->pack(shift); }
    -deserializer => sub{ Data::MessagePack->unpack(shift); }
  );

  my $dbi = Cache::KyotoTycoon::Serialize->new(
    addr => '127.0.0.1'
  );

  $dbi->add('key', +{
    # datas ...
  }); # You can pass reference data to KyotoTycoon!

=head1 DESCRIPTION

Cache::KyotoTycoon::Serialize is serialize/deserialize support for Cache::KyotoTycoon.
If some module need Cache::* object and the module caching reference data,
I propose you should use this module.

=head1 AUTHOR

Kenta Sato E<lt>kenta.sato.1990@gmail.comE<gt>

=head1 SEE ALSO

Cache::KyotoTycoon
Storable

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
