package YAML::Marshall;
use Spiffy -Base;
use YAML::Node();

sub import() {
    my ($package, $mixin, $tag) = @_;
    if ($mixin eq '-mixin' && $tag) {
        my $class = caller;
        no warnings 'once';
        $YAML::TagClass->{$tag} = $class;
        no strict 'refs';
        ${$class . "::YamlTag"} = $tag;
        pop @_;
    }

    goto &Spiffy::import;
}

sub yaml_dump {
    no strict 'refs';
    my $tag = ${ref($self) . "::YamlTag"} || 'perl/' . ref($self);
    $self->yaml_node($self, $tag);
}

sub yaml_load() {
    my ($class, $node) = @_;
    if (my $ynode = $class->yaml_ynode($node)) {
        $node = $ynode->{NODE};
    }
    bless $node, $class;
}

sub yaml_node {
    YAML::Node->new(@_);
}

sub yaml_ynode {
    YAML::Node::ynode(@_);
}

__END__

=head1 NAME

YAML::Marshall - YAML marshalling class you can mixin to your classes

=head1 SYNOPSIS

    package Bar;
    use Foo -base;
    use YAML::Marshall -mixin;

=head1 DESCRIPTION

For classes that want to handle their own YAML serialization.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
