
# A module to implement a fuzzy term set.
# Only triangular term sets are allowed.
# 
# Copyright Ala Qumsieh (aqumsieh@cpan.org) 2002.
# This program is distributed under the same terms as Perl itself.

package AI::FuzzyInference::Set;
use strict;

#our $VERSION = 0.02;
use vars qw/$VERSION/;  # a bit more backward compatibility.
$VERSION = 0.02;

1;

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $obj = bless {} => $class;

    $obj->_init;

    return $obj;
}

sub _init {
    my $self = shift;

    $self->{TS} = {};
}

sub add {
    my ($self,
	$name,
	$xmin,
	$xmax,
	@coords,
	) = @_;

    # make sure coords span the whole universe.
    if ($coords[0] > $xmin) {
	unshift @coords => ($xmin, $coords[1]);
    }

    if ($coords[-2] < $xmax) {
	push @coords => ($xmax, $coords[-1]);
    }

    $self->{TS}{$name} = \@coords;
}

sub delete {
    my ($self,
	$name,
	) = @_;

    delete $self->{TS}{$name};
}

sub membership {
    my ($self,
	$name,
	$val,
	) = @_;

    return undef unless $self->exists($name);

    my $deg = 0;
    my @c   = $self->coords($name);

    my $x1 = shift @c;
    my $y1 = shift @c;

    while (@c) {
	my $x2 = shift @c;
	my $y2 = shift @c;

	next if $x1 == $x2;    # hmm .. why do we have this?

	unless ($x1 <= $val && $val <= $x2) {
	    $x1 = $x2;
	    $y1 = $y2;
	    next;
	}
	$deg = $y2 - ($y2 - $y1) * ($x2 - $val) / ($x2 - $x1);
	last;
    }

    return $deg;
}

sub listAll {
    my $self = shift;

    return keys %{$self->{TS}};
}

sub listMatching {
    my ($self, $rgx) = @_;

    return grep /$rgx/, keys %{$self->{TS}};
}

sub max {    # max of two sets.
    my ($self,
	$set1,
	$set2,
	) = @_;

    my @coords1 = $self->coords($set1);
    my @coords2 = $self->coords($set2);

    my @newCoords;
    my ($x, $y, $other);
    while (@coords1 && @coords2) {
	if ($coords1[0] < $coords2[0]) {
	    $x     = shift @coords1;
	    $y     = shift @coords1;
	    $other = $set2;
	} else {
	    $x     = shift @coords2;
	    $y     = shift @coords2;
	    $other = $set1;
	}
	my $val    = $self->membership($other, $x);
	$val = $y if $y > $val;
	push @newCoords => $x, $val;
    }

    push @newCoords => @coords1 if @coords1;
    push @newCoords => @coords2 if @coords2;

    return @newCoords;
}

sub min {    # min of two sets.
    my ($self,
	$set1,
	$set2,
	) = @_;

    my @coords1 = $self->coords($set1);
    my @coords2 = $self->coords($set2);

    my @newCoords;
    my ($x, $y, $other);
    while (@coords1 && @coords2) {
	if ($coords1[0] < $coords2[0]) {
	    $x     = shift @coords1;
	    $y     = shift @coords1;
	    $other = $set2;
	} else {
	    $x     = shift @coords2;
	    $y     = shift @coords2;
	    $other = $set1;
	}
	my $val    = $self->membership($other, $x);
	$val = $y if $y < $val;
	push @newCoords => $x, $val;
    }

    push @newCoords => @coords1 if @coords1;
    push @newCoords => @coords2 if @coords2;

    return @newCoords;
}

sub complement {
    my ($self, $name) = @_;

    my @coords = $self->coords($name);
    my $i = 0;
    return map {$_ = ++$i % 2 ? $_ : 1 - $_} @coords;
}

sub coords {
    my ($self,
	$name,
	) = @_;

    return undef unless $self->exists($name);

    return @{$self->{TS}{$name}};
}

sub scale {  # product implication
    my ($self,
	$name,
	$scale,
	) = @_;

    my $i = 0;
    my @c = map { $_ *= ++$i % 2 ? 1 : $scale } $self->coords($name);

    return @c;
}

sub clip {   # min implication
    my ($self,
	$name,
	$val,
	) = @_;

    my $i = 0;
    my @c = map {
	$_ = ++$i % 2 ? $_ : $_ > $val ? $val : $_
	}$self->coords($name);

    return @c;
}

sub centroid {   # center of mass.
    my ($self,
	$name,
	) = @_;

    return undef unless $self->exists($name);

    my @coords = $self->coords($name);

    my $num = 0;
    my $den = 0;

    while (@coords) {
	my $x = shift @coords;
	my $y = shift @coords;

	$num += $x * $y;
	$den += $y;
    }

    return 0 unless $num && $den;

    return $num / $den;
}

sub median {
    my ($self,
	$name,
	) = @_;

    my @coords = $self->coords($name);

    # hmmm .. how do I do *this*?
    return 0;
}

sub exists {
    my ($self,
	$name,
	) = @_;

    return exists $self->{TS}{$name};
}
