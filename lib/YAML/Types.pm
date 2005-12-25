package YAML::Types;
use Spiffy -Base;

field type_classes => [];
const core_types => [qw'glob regexp io code'];

sub register {
    my $class = shift;
    # XXX ...;
}

################################################################################
package YAML::Type;
use Spiffy -Base;

sub yaml_type {
    '!perl/' . ref $_[0];
}

sub to_yaml {
    die;
}

sub from_yaml {
    die;
}

################################################################################
package UNIVERSAL;

{
    no warnings 'once';
    *to_yaml = \&YAML::Type::to_yaml;
    *from_yaml = \&YAML::Type::from_yaml;
    *yaml_type = \&YAML::Type::yaml_type;
}

################################################################################
package YAML::Type::glob;
use base 'YAML::Type';

field yaml_type => '!perl/glob';

sub is_type {
    ref \ $_[0] eq 'GLOB';
}

sub to_yaml {
    my $glob = shift;
    my $node = YAML::Node->new;
    # ...
    return $node
}

sub from_yaml {
    my $node = shift;
    my $glob = '...';
}

################################################################################
package YAML::Type::regexp;
use base 'YAML::Type';

################################################################################
package YAML::Type::code;
use base 'YAML::Type';

################################################################################
package YAML::Type::io;
use base 'YAML::Type';
