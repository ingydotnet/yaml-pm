package YAML; 
$VERSION = '0.25';

# This module implements a Loader and Dumper for the YAML serialization
# language, VERSION 1.0 TRIAL1. (http://www.yaml.org/spec/)

require Exporter;
@ISA = qw(Exporter);
# Basic interface is Load & Store
@EXPORT = qw(Load Store);
# Provide a bunch of aliases for TMTOWTDI's sake
@EXPORT_OK = qw(
                LoadFile StoreFile
                Dumper Eval 
                Indent Undent Denter
                freeze thaw
		SetTestNumber TestLoad
	       );
# Compatibility modes	       
%EXPORT_TAGS = (
                all => [qw(Load Store LoadFile StoreFile)],
                test => [qw(SetTestNumber TestLoad)],
                Dumper => [qw(Dumper Eval)],
                Denter => [qw(Indent Undent Denter)],
                Storable => [qw(freeze thaw)],
                POE => [qw(freeze thaw)],
               );

use strict;
use overload;
use Carp;

# Context constants
use constant SCALAR => 1;
use constant COLLECTION => 2;
use constant KEY => 3;

# These are the user changable options
$YAML::Separator = '---';
$YAML::UseHeader = 1;
$YAML::UseVersion = 1;
$YAML::SortKeys = 1;
$YAML::FirstAnchor = 'id001';
$YAML::ExplicitTypes = 0;
$YAML::WidthType = 'absolute';
$YAML::MaxWidth = 0;
$YAML::BestWidth = 80;

# Common YAML character sets
my $WORD_CHAR = '[A-Za-z-]';
my $ESCAPE_CHAR = '[\\x00-\\x08\\x0b-\\x0d\\x0e-\\x1f]';
my $INDICATOR_CHAR = '[#-:?*&!|\\\\^@%]';

# $o is the YAML object. It contains the complete state of the YAML.pm 
# process. This is set at the file scope level so that I can avoid using
# OO syntax or passing the object around in function calls.
#
# When callback are added to YAML.pm the calling code will have to save
# the object so that it won't get clobbered. Also YAML.pm can't be subclassed.
# 
# The purpose of this is for efficiency and also for much simpler code.
my $o;

# YAML OO constructor function
sub new {
    my $class = shift;
    my $o = {
 	     stream => '',
	     level => 0,
	     anchor => $YAML::FirstAnchor,
	     Separator => $YAML::Separator,
	     UseHeader => $YAML::UseHeader,
	     UseVersion => $YAML::UseVersion,
	     SortKeys => $YAML::SortKeys,
	     ExplicitTypes => $YAML::ExplicitTypes,
	     WidthType => $YAML::WidthType,
	     MaxWidth => $YAML::MaxWidth,
	     BestWidth => $YAML::BestWidth,
	    };
    bless $o, $class;
    while (my ($option, $value) = splice(@_, 0, 2)) {
	$o->{$option} = $value;
    }
    return $o if is_valid($o);
}

sub is_valid { 
    my $o = shift;
    croak msg_invalid_separator() unless $o->{Separator} =~ /--$WORD_CHAR+/;
    # NOTE: Add more tests...
}

#==============================================================================
# Save the contents of a Store operation to a file. If the file exists
# and has data, and a concatenation was requested, then verify the
# existing header.
sub StoreFile {
    my $filename = shift;
    local $/ = "\n"; # reset special to "sane"
    my $mode = '>';
    if ($filename =~ /^\s*(>{1,2})\s*(.*)$/) {
        ($mode, $filename) = ($1, $2);
    }
    if ($mode eq '>>' && -f $filename && -s $filename) {
        open MYYAML, "< $filename" 
            or croak msg_file_input($filename, $!);
        my $line = <MYYAML>;
        close MYYAML;
        unless ($line =~ /^(--\S+)/ and
                $YAML::Separator eq $1
               ) {
            croak msg_file_concatenate($filename);
        }
    }
    open MYYAML, "$mode $filename"
        or croak msg_file_output($filename, $!);
    print MYYAML YAML::Store(@_);
    close MYYAML;
}
    
# Serialize a list of elements
sub Store {
    $o = YAML->new();
    return store(@_);
}

# Aliases for Store
*Indent = \&Store;    # alias for Data::Denter users
*Denter = \&Store;    # alias for Data::Denter users
*Dumper = \&Store;    # alias for Data::Dumper users
*freeze = \&Store;    # alias for Storable or POE users

# OO version of Store. YAML->new->store($foo); 
sub store {
    local $| = 1; # set buffering to "hot" (for testing)
    local $/ = "\n"; # reset special to "sane"
    _emit(@_);
    return $o->{stream};
}

# Top level emit function. Take the list of elements and emit them in
# order into a single string (aka YAML Stream).
sub _emit {
    $o->{documents} = @_;
    $o->{document} = 0;
    for my $document (@_) {
        $o->{node_ids} = [];
        $o->{id2anchor} = {};
        $o->{id2offset} = {};
        $o->{document}++;
        _emit_separator($document);
        $o->{level} = -1;
        _emit_node($document);
    }
}

# Every YAML document in the stream must begin with a YAML header, unless
# there is only a single document and the user requests "no header".
sub _emit_separator {
    if ($o->{UseHeader} or
        $o->{documents} > 1
       ) {
        $o->{stream} .= $o->{Separator};
        if ($o->{UseVersion}) {
            $o->{stream} .= " YAML:1.0";
        }
    }
}

# Every data element and sub data element is a node. Everything emitted
# goes through this function.
sub _emit_node {
    my ($value) = @_;
    my ($class, $type, $node_id) = ('') x 3;

    if (ref(\$value) eq 'GLOB') {
        $value = bless [ $value ], 'perl/:glob';
        ($class, $type, $node_id) =
          (overload::StrVal($value) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);
        $type = $class;  
    } 
    elsif (not ref $value) {
        return _emit_str($value);
    }
    elsif (ref($value) eq 'GLOB') {
        ($class, $type, $node_id) =
          (overload::StrVal($value) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);
        $type = 'REF';
    }
    else {
        ($class, $type, $node_id) =
          (overload::StrVal($value) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);
    }

    if (defined $o->{id2offset}{$node_id}) {
        if (not defined $o->{id2anchor}{$node_id}) {
            my $found = 0;
            my $anchor = $o->{anchor}++;
            for my $id (@{$o->{node_ids}}) {
                if ($found) {
                    $o->{id2offset}{$id} += length($anchor) + 2;
                }
                if ($id eq $node_id) {
                    substr($o->{stream}, $o->{id2offset}{$id}, 0, " &$anchor");
                    $o->{id2anchor}{$id} = $anchor;
                    $found = 1;
                }
            }
        }
        $o->{stream} .= ' *' . $o->{id2anchor}{$node_id} . "\n";
        return;
    }
    else {
        push @{$o->{node_ids}}, $node_id;
        $o->{id2offset}{$node_id} = length($o->{stream});
    }

    return _emit_map($value, $class) if $type eq 'HASH';
    return _emit_seq($value, $class) if $type eq 'ARRAY';
    return _emit_ptr($value) if $type eq 'SCALAR';
    return _emit_ptr($value) if $type eq 'REF';
    #return _emit_code($value) if $type eq 'CODE';
    return _emit_glob($value) if $type eq 'perl/:glob';
    warn "Can't perform YAML serialization for type '$type'\n" if $^W;
    return _emit_str("$value");
}

# A YAML map is akin to a Perl hash. 
sub _emit_map {
    my ($value, $class) = @_;
    if ($class) {
        $o->{stream} .= " !perl/$class";
    }
    elsif ($o->{ExplicitTypes}) {
        $o->{stream} .= " !map";
    }

    if ((keys %$value) == 0) {
        $o->{stream} .= $class ? "\n" : " !map\n"; 
        return;
    }
        
    $o->{stream} .= "\n";

    $o->{level}++;
    for my $key ($o->{SortKeys} ? (sort keys %$value) : (keys %$value)) {
        _emit_key($key);
        $o->{stream} .= ':';
        _emit_node($value->{$key});
    }
    $o->{level}--;
}

# A YAML sequence is akin to a Perl array.
sub _emit_seq {
    my ($value, $class) = @_;
    if ($class) {
        $o->{stream} .= " !perl/\@$class";
    }
    elsif ($o->{ExplicitTypes}) {
        $o->{stream} .= " !map";
    }

    if (@$value == 0) {
        $o->{stream} .= $class ? "\n" : " !seq\n"; 
        return;
    }
        
    $o->{stream} .= "\n";

    $o->{level}++;
    for my $val (@$value) {
        $o->{stream} .= ' ' x $o->{level};
        $o->{stream} .= '-';
        _emit_node($val);
    }
    $o->{level}--;
}

# Emit a map key
sub _emit_key {
    my ($value) = @_;
    $o->{stream} .= ' ' x $o->{level};
    _emit_str($value, KEY);
}

# A YAML pointer is akin to a Perl reference
sub _emit_ptr {
    my ($value) = @_;
    $o->{level}++;
    $o->{stream} .= " !ptr\n" . (' ' x $o->{level}) . "=:";
    _emit_node($$value);
    $o->{level}--;
}

# The "glob" is a Perl specific data structure. It uses the YAML map
# with the following predefined keys: Symbol, HASH, ARRAY, SCALAR,
# CODE, IO.
sub _emit_glob {
    my ($node) = @_;
    my $glob = $node->[0];
    my $symbol = '';
    if ($glob =~ /^\*(.*)$/) {
        $symbol = $1;
    }
    else {
        croak "'$glob' is an invalid value for Perl glob";
    }
    $o->{stream} .= " !perl/:glob\n";
    $o->{level}++;
    $o->{stream} .= (' ' x $o->{level}) . "Symbol:";
    _emit_node($symbol);
    for my $type (qw(SCALAR HASH ARRAY CODE IO)) {
        my $value = *{$glob}{$type};
        $value = $$value if $type eq 'SCALAR';
        if (defined $value) {
            $o->{stream} .= (' ' x $o->{level}) . "$type:";
            if (tied $value) {
                $o->{stream} .= " tied\n";
            }
            elsif ($type =~ /^(SCALAR|ARRAY|HASH)$/) {
                _emit_node($value);
            }
            else {
                $o->{stream} .= " defined\n";
            }
        }
    }
    $o->{level}--;
}

# Emit a string value. YAML has six styles. This routine attempts to
# guess the best style for the text.
sub _emit_str {
    my ($value, $type) = (@_, 0);
    my $level = $o->{level};

    # Guess the best text emission style for now.
    $o->{level}++;

    if (defined $value and
        $value =~ /\n.+/ or        # more than one line
        $level == -1
       ) {
        $o->{stream} .= ($type == KEY) ? '? ' : ' ';
        if ($value =~ /\n[ \t]/ &&  # whitespace at start of any line but first
            $value !~ /$ESCAPE_CHAR/
           ) {  
            _emit_block($value);
        }
        elsif ($value =~ /$ESCAPE_CHAR/) {
            _emit_escaped($value);
        }
        else {
            if (is_valid_implicit($value)) {
                $o->{stream} .= '! ';
            }
            _emit_plain($value);
        }
        $o->{stream} .= "\n";
    }
    else {
        $o->{stream} .= ' ' if $type != KEY;
        if (is_valid_implicit($value)) {
            _emit_implicit($value);
        }
        elsif ($value =~ /$ESCAPE_CHAR|\n|\'/) {
            _emit_double($value);
        }
        else {
            _emit_single($value);
        }
        $o->{stream} .= "\n" if $type != KEY;
    }
    
    $o->{level}--;

    return;
}

# Check whether or not a scalar should be emitted as an implicit.
sub is_valid_implicit {
    return 1 if not defined $_[0];
    return 0 if $_[0] =~ /\s|\:( |$)/;
    if ($_[0] =~ /^[a-zA-Z]/) {
	return 0 if $_[0] =~ /\:/;
	return 1;
    }
    if ($_[0] =~ /^([+-]?\d+)$/) {                    # !int
        return 1 if length($1) <= 10;   # TODO: check integer range
    }
    if ($_[0] =~ /^[+-]?(\d*)(?:\.(\d*))?([Ee][+-]?\d+)?$/) {     # !real
        return 1 if length($3) ? length($1) : length($1) + length($2);
    }
    return 0;
}

# A block is akin to a Perl here-document.
sub _emit_block {
    my ($value) = @_;
    my $chomped = not ($value =~ s/\n\Z//);
    $o->{stream} .= '|' . ($chomped ? '|' : '') . indent($value);
}

# Plain means normal flowing text. Can be more than one line. Gets
# folded for readability.
sub _emit_plain {
    my ($value) = @_;
    $o->{stream} .= '\\' . indent(fold($value));
}

# Similar to plain, but contains escaped values.
sub _emit_escaped {
    my ($value) = @_;
    $o->{stream} .= '\\\\' . indent(fold(escape($value)));
}

# Implicit means that the scalar is unquoted. It is analyzed for its type
# implicitly using regexes.
sub _emit_implicit {
    my ($value) = @_;
    if (not defined $value) {
        $o->{stream} .= '~';
    }
    else {
        $o->{stream} .= $value;
    }
}

# Double quoting is for single lined escaped strings.
sub _emit_double {
    my ($value) = @_;
    $o->{stream} .= '"' . escape($value) . '"';
}

# Single quoting is for single lined unescaped strings.
sub _emit_single {
    my ($value) = @_;
    $o->{stream} .= "'$value'";
}

#==============================================================================
# Read a YAML stream from a file and call Load on it.
sub LoadFile {
    my $filename = shift;
    local $/ = "\n"; # reset special to "sane"
    open MYYAML, $filename or croak msg_file_input($filename, $!);
    my $yaml = join '', <MYYAML>;
    close MYYAML;
    return Load($yaml);
}

# Deserialize a YAML stream into a list of data elements
sub Load {
    croak usage_load() unless @_ == 1;
    $o = YAML->new;
    $o->{stream} = defined $_[0] ? $_[0] : '';
    return load();
}

# Aliases for Load
*Undent = \&Load;
*Eval = \&Load;
*thaw = \&Load;

# OO version of Load
sub load {
    local $| = 1; # set buffering to "hot" (for testing)
    local $/ = "\n"; # reset special to "sane"
    return _parse();
}

# Top level function for parsing. Parse each document in order and
# handle processing for YAML headers.
sub _parse {
    my (%properties, $preface);
    $o->{stream} =~ s|\015\012|\012|g;
    $o->{stream} =~ s|\015|\012|g;
    $o->{line} = 0;
    croak msg_bad_chars() if $o->{stream} =~ /$ESCAPE_CHAR/;
    if (length $o->{stream}) {
        unless ($o->{stream} =~ s/(.)\n\Z/$1/s) {
            croak msg_no_newline();
        }
    }
    @{$o->{lines}} = split /\x0a/, $o->{stream}, -1;
    $o->{line} = 1;
    _parse_throwaway_comments();
    $o->{eos} = $o->{done} = not @{$o->{lines}};
    $o->{document} = 0;
    $o->{documents} = [];
    $o->{separator} = '';
    if ((not $o->{eos}) && $o->{lines}[0] =~ /^(--\S+)/) {
        $o->{separator} = $1;
    }
    my $separator = $o->{separator};
    while (not $o->{eos}) {
        $o->{anchor2node} = {};
        $o->{document}++;
        $o->{done} = 0;
        $o->{level} = -1;

        if ($separator) {
            if($o->{lines}[0] =~ /^\Q$separator\E\s*(.*)$/) {
                my @words = split /\s+/, $1;
                %properties = ();
                while (@words && $words[0] =~ /^\w+:\S/) {
                    my ($key, $value) = split ':', shift(@words), 2;
                    if (defined $properties{$key}) {
                        warn msg_multiple_properties($key, $o->{document});
                        next;
                    }
                    $properties{$key} = $value;
                }
                $o->{preface} = join ' ', @words;
            }
            else {
                croak msg_no_separator($separator);
            }
            _parse_next_line(COLLECTION);
            if ($o->{done}) {
                $o->{indent} = -1;
                $o->{content} = '';
            }
        }
        else {
            $o->{lines}[0] =~ /^( *)(\S.*)$/;
            $o->{indent} = length($1);
            $o->{content} = $2;
            $o->{preface} = '';
        }

        $properties{YAML} ||= '1.0';
        ($o->{major_version}, $o->{minor_version}) = 
          split /\./, $properties{YAML}, 2;
        if ($o->{major_version} ne '1') {
            croak msg_bad_major_version($properties{YAML});
        }
        if ($o->{minor_version} ne '0') {
            warn msg_bad_minor_version($properties{YAML});
        }

        push @{$o->{documents}}, _parse_node();
    }
    return wantarray ? @{$o->{documents}} : $o->{documents}[0];
}

# This function is the dispatcher for parsing each node. Every node
# recurses back through here. (Inlines are an exception as they have
# their own sub-parser.
sub _parse_node {
    my $preface = $o->{preface};
    my ($node, $type, $explicit, $implicit, $class,
        $anchor, $alias, $indicator) = ('') x 8;
    ($anchor, $alias, $explicit, $implicit, $class, $preface) = 
      _parse_qualifiers($preface);
    if ($anchor) {
	$o->{anchor2node}{$anchor} = bless [], 'YAML-anchor2node';
    }
    $o->{inline} = '';
    while (length $preface) {
        my $line = $o->{line} - 1;
        if ($preface =~ s/^(\\{1,2}|\|{1,2})\s*//) {
            $indicator = $1;
        }
        else {
            croak msg_text_after_indicator() if $indicator;
            croak msg_top_level_inline() if $o->{level} == -1;
            $o->{inline} = $preface;
            $preface = '';
        }
    }
    $o->{level}++;
    if ($alias) {
        croak msg_no_anchor($alias) unless defined $o->{anchor2node}{$alias};
	if (ref($o->{anchor2node}{$alias}) ne 'YAML-anchor2node') {
            $node = $o->{anchor2node}{$alias};
	}
	else {
	    $node = do {my $sv = "*$alias"};
	    push @{$o->{anchor2node}{$alias}}, [\$node, $o->{line}]; 
	}
    }
    elsif (length $o->{inline}) {
        $node = _parse_inline($implicit);
        if (length $o->{inline}) {
            croak msg_single_line_parse(); 
        }
    }
    elsif ($indicator =~ /^\|(\|?)/) {
        $node = _parse_block(length $1);
        $node = _parse_implicit($node) if $implicit;
    }
    elsif ($indicator eq "\\") {
        $node = _parse_unfold();
        $node = _parse_implicit($node) if $implicit;
    }
    elsif ($indicator eq "\\\\") {
        $node = _parse_unfold();
        $node = _unescape($node);
        $node = _parse_implicit($node) if $implicit;
    }
    elsif ($explicit =~ /^[%\@\$*~]$/ or 
           $o->{indent} == $o->{level}) {
        if ($explicit eq '@' or $o->{content} =~ /^-/) {
            $node = _parse_seq($anchor);
        }
        elsif ($explicit eq '%' or $o->{content} =~ /(^\?|\:( |$))/) {
            $node = _parse_map($anchor);
        }
        else {
            croak msg_parse_node();
        }
    }
    elsif ($preface =~ /^\s*$/) {
        $node = _parse_implicit('');
    }
    else {
        croak msg_parse_node();
    }
    $o->{level}--;

    if ($explicit) {
        if ($class) {
            bless $node, $class;
        }
        else {
            $node = _parse_explicit($node, $explicit);
        }
    }
    if ($anchor) {
	if (ref($o->{anchor2node}{$anchor}) eq 'YAML-anchor2node') {
	    for my $ref (@{$o->{anchor2node}{$anchor}}) {
		${$ref->[0]} = $node;
		warn "Can't resolve YAML alias '*$anchor' at line $ref->[1]\n";
	    }
	}
        $o->{anchor2node}{$anchor} = $node;
    }
    return $node;
}

# Preprocess the qualifiers that may be attached to any node.
sub _parse_qualifiers {
    my ($preface) = @_;
    my ($anchor, $alias, $explicit, $implicit, $class, $token) = ('') x 6;
    $o->{inline} = '';
    while ($preface =~ /^[&*!]/) {
        my $line = $o->{line} - 1;
        if ($preface =~ s/^\!(\S+)\s*//) {
            croak msg_many_explicit() if $explicit;
            $explicit = $1;
            if ($explicit =~ 
                /^(?:yaml\:)?perl\/(\b|[\@\$*~])(\w[\w:]*)$/) {
                ($explicit, $class) = ($1, $2);
		$explicit ||= '%';
            }
            elsif ($explicit =~ 
                /^(?:yaml\:)?perl\/:(\w+)$/) {
                $explicit = $1;
            }
            elsif ($explicit =~ 
                /^((?:yaml\:)?.*)$/) {
                $explicit = $1;
            }
            else {
                croak msg_bad_explicit($explicit);
            }
        }
        elsif ($preface =~ s/^\!\s*//) {
            croak msg_many_implicit() if $implicit;
            $implicit = 1;
        }
        elsif ($preface =~ s/^\&([^ ,:]+)\s*//) {
            $token = $1;
            croak msg_bad_anchor() unless $token =~ /^[a-zA-Z0-9]+$/;
            croak msg_many_anchor() if $anchor;
            croak msg_anchor_alias() if $alias;
            $anchor = $token;
        }
        elsif ($preface =~ s/^\*([^ ,:]+)\s*//) {
            $token = $1;
            croak msg_bad_alias() unless $token =~ /^[a-zA-Z0-9]+$/;
            croak msg_many_alias() if $alias;
            croak msg_alias() if $anchor;
            $alias = $token;
        }
    }
    return ($anchor, $alias, $explicit, $implicit, $class, $preface); 
}

# A lookup table for mapping Perl types to YAML types. 
my %type_map = 
  (
   UNDEF => 'null',
   SCALAR => 'ptr',
   REF => 'ptr',
   HASH => 'map',
   ARRAY => 'seq',
   STRING => 'str',
  );

# Morph a node to it's explicit type  
sub _parse_explicit {
    my ($node, $explicit) = @_;
    my $implicit = '';
    $implicit = 'UNDEF' unless defined $node;
    $implicit ||= ref $node || 'STRING';
    $implicit = $type_map{$implicit};
    return $node if $explicit eq $implicit;
    no strict 'refs';
    my $handler = "YAML::_parse_${implicit}_to_$explicit";
    if (defined &$handler) {
        return &$handler($node);
    }
    else {
        croak msg_no_convert($implicit, $explicit);
    }
}

# Morph to a perl reference
sub _parse_map_to_ptr {
    my ($node) = @_;
    croak msg_no_default_value('ptr') unless exists $node->{'='};
    return \$node->{'='};
}

# Special support for an empty map
sub _parse_str_to_map {
    my ($node) = @_;
    croak msg_non_empty_string('map') unless $node eq '';
    return {};
}

# Special support for an empty sequence
sub _parse_str_to_seq {
    my ($node) = @_;
    croak msg_non_empty_string('sequence') unless $node eq '';
    return [];
}

# Support for sparse sequences
sub _parse_map_to_seq {
    my ($node) = @_;
    my $seq = [];
    for my $index (keys %$node) {
        croak msg_bad_map_to_seq($index) unless $index =~ /^\d+/;
        $seq->[$index] = $node->{$index};
    }
    return $seq;
}

# Support for !int
sub _parse_str_to_int {
    my ($node) = @_;
    croak msg_bad_str_to_int() unless $node =~ /^-?\d+$/;
    return $node;
}

# Parse a YAML map into a Perl hash
sub _parse_map {
    my ($anchor) = @_;
    my $map = {};
    $o->{anchor2node}{$anchor} = $map;
    my $key;
    while (not $o->{done} and $o->{indent} == $o->{level}) {
        if ($o->{content} =~ s/^\?\s*//) {
            $o->{preface} = $o->{content};
            _parse_next_line(COLLECTION);
            $key = _parse_node();
            $key = "$key";
        }
        elsif ($o->{content} =~ s/^\=\s*//) {
            $key = '=';
        }
        else {
            $o->{inline} = $o->{content};
            $key = _parse_inline();
            $key = "$key";
            $o->{content} = $o->{inline};
            $o->{inline} = '';
        }
            
        unless ($o->{content} =~ s/^:\s*//) {
            croak msg_bad_map_element();
        }
        $o->{preface} = $o->{content};
        my $line = $o->{line};
        _parse_next_line(COLLECTION);
        my $value = _parse_node();
        if (exists $map->{$key}) {
            warn msg_duplicate_key();
        }
        else {
            $map->{$key} = $value;
        }
    }
    return $map;
}

# Parse a YAML sequence into a Perl array
sub _parse_seq {
    my ($anchor) = @_;
    my $seq = [];
    $o->{anchor2node}{$anchor} = $seq;
    while (not $o->{done} and $o->{indent} == $o->{level}) {
        if ($o->{content} =~ /^-\s*(.*)$/) {
            $o->{preface} = $1;
        }
        else {
            croak msg_map_seq_element();
        }
        _parse_next_line(COLLECTION);
        push @$seq, _parse_node();
    }
    return $seq;
}

# Parse an inline value. Since YAML supports inline collections, this is
# the top level of a sub parsing.
sub _parse_inline {
    my ($top_implicit) = (@_, 0);
    $o->{inline} =~ s/^\s*(.*)\s*$/$1/;
    my ($node, $anchor, $alias, $explicit, $implicit, $class) = ('') x 6;
    ($anchor, $alias, $explicit, $implicit, $class, $o->{inline}) = 
      _parse_qualifiers($o->{inline});
    if ($anchor) {
	$o->{anchor2node}{$anchor} = bless [], 'YAML-anchor2node';
    }
    $implicit ||= $top_implicit;
    if ($alias) {
        croak msg_no_anchor($alias) unless defined $o->{anchor2node}{$alias};
	if (ref($o->{anchor2node}{$alias}) ne 'YAML-anchor2node') {
            $node = $o->{anchor2node}{$alias};
	}
	else {
	    $node = do {my $sv = "*$alias"};
	    push @{$o->{anchor2node}{$alias}}, [\$node, $o->{line}]; 
	}
    }
    elsif ($o->{inline} =~ /^[{]/) {
        $node = _parse_inline_map($anchor);
    }
    elsif ($o->{inline} =~ /^[[]/) {
        $node = _parse_inline_seq($anchor);
    }
    elsif ($o->{inline} =~ /^"/) {
        $node = _parse_inline_double_quoted();
        $node = _unescape($node);
        $node = _parse_implicit($node) if $implicit;
    }
    elsif ($o->{inline} =~ /^'/) {
        $node = _parse_inline_single_quoted();
        $node = _parse_implicit($node) if $implicit;
    }
    else {
        $node = _parse_inline_implicit();
    }
    if ($explicit) {
        if ($class) {
            bless $node, $class;
        }
        else {
            $node = _parse_explicit($node, $1);
        }
    }
    if ($anchor) {
	if (ref($o->{anchor2node}{$anchor}) eq 'YAML-anchor2node') {
	    for my $ref (@{$o->{anchor2node}{$anchor}}) {
		${$ref->[0]} = $node;
		warn "Can't resolve YAML alias '*$anchor' at line $ref->[1]\n";
	    }
	}
        $o->{anchor2node}{$anchor} = $node;
    }
    return $node;
}

# Parse the inline YAML map into a Perl hash
sub _parse_inline_map {
    my ($anchor) = @_;
    my $node = {};
    $o->{anchor2node}{$anchor} = $node;

    croak msg_inline_map() unless $o->{inline} =~ s/^\{\s*//;
    while (not $o->{inline} =~ s/^\}//) {
        my $key = _parse_inline();
        croak msg_inline_map() unless $o->{inline} =~ s/^\: \s*//;
        my $value = _parse_inline();
        if (exists $node->{$key}) {
            warn msg_duplicate_key();
        }
        else {
            $node->{$key} = $value;
        }
        next if $o->{inline} =~ /^\}/;
        croak msg_inline_map() unless $o->{inline} =~ s/^\,\s*//;
    }
    return $node;
}

# Parse the inline YAML sequence into a Perl array
sub _parse_inline_seq {
    my ($anchor) = @_;
    my $node = [];
    $o->{anchor2node}{$anchor} = $node;

    croak msg_inline_map() unless $o->{inline} =~ s/^\[\s*//;
    while (not $o->{inline} =~ s/^\]//) {
        my $value = _parse_inline();
        push @$node, $value;
        next if $o->{inline} =~ /^\]/;
        croak msg_inline_sequence() unless $o->{inline} =~ s/^\,\s*//;
    }
    return $node;
}

# Parse the inline double quoted string.
sub _parse_inline_double_quoted {
    my $node;
    if ($o->{inline} =~ /^"((?:\\"|[^"])*)"\s*(.*)$/) {
        $node = $1;
        $o->{inline} = $2;
        $node =~ s/\\"/"/g;
    } else {
        croak msg_bad_double();
    }
    return $node;
}


# Parse the inline single quoted string.
sub _parse_inline_single_quoted {
    my $node;
    if ($o->{inline} =~ /^'((?:''|[^'])*)'\s*(.*)$/) {
        $node = $1;
        $o->{inline} = $2;
        $node =~ s/''/'/g;
    } else {
        croak msg_bad_single();
    }
    return $node;
}

# Parse the inline unquoted string and do implicit typing.
sub _parse_inline_implicit {
    my $value;
    if ($o->{inline} =~ /^(|[^!@#%^&*].*?)(?=[,[\]{}]|: |- |:\s*$|$)/) {
        $value = $1;
        substr($o->{inline}, 0, length($1)) = '';
    }
    else {
        croak msg_bad_implicit($value);
    }
    return _parse_implicit($value);
}

# Apply regex matching for YAML's implicit types. !str, !int, !real,
# !null and !time
sub _parse_implicit {
    my ($value) = @_;
    $value =~ s/\s*$//;
    return $value if $value eq '';
    return $value if $value =~ /^[a-zA-Z]/;
    return eval $value if $value =~ /^-?\d+$/;
    return eval $value 
      if ($value =~ /^[+-]?(\d*)(?:\.(\d*))?([Ee][+-]?\d+)?$/) and
         (length($3) ? length($1) : length($1) + length($2));
    return undef if $value =~ /^~$/;
    return $value if $value =~ /^\d?\d:\d\d$/;
    croak msg_bad_implicit($value);
}

# Unfold a YAML multiline scalar into a single string.
sub _parse_unfold {
    my $node = '';
    my $space = 0;
    while (not $o->{done} and $o->{indent} == $o->{level}) {
        if (length $o->{content}) {
            $node .= $o->{content};
            unless ($node =~ s/\\\s*$//) {
                $node .= ' ';
                $space = 1;
            }
        }
        else {
            chop $node if $space;
            $space = 0;
            $node .= "\n";
        }
        _parse_next_line(SCALAR);
    }
    chop $node if $space;
    return $node;
}

# Parse a YAML block style scalar. This is like a Perl here-document.
sub _parse_block {
    my ($chomp) = @_;
    my $block = '';
    while (not $o->{done} and $o->{indent} == $o->{level}) {
        $block .= $o->{content} . "\n";
        _parse_next_line(SCALAR);
    }
    chop $block if $chomp;
    return $block;
}

# Handle Perl style '#' comments. Comments must be at the same indentation
# level as the collection line following them.
sub _parse_throwaway_comments {
    my $count = 0;
    my $indent;
    while ($count <= $#{$o->{lines}} and
           $o->{lines}[$count] =~ m|^( *)\#|
          ) {
        $indent = length($1) if not defined $indent;
        $count++;
        if (length($1) != $indent) {
            croak msg_comment_indent();
        }
        $o->{line}++;
    }
    if ($count > 0) {
        if ($count <= $#{$o->{lines}} and
            $o->{lines}[$count] =~ m|^ {$indent}\S|) {
            splice(@{$o->{lines}}, 0, $count);
        }
        else {
            croak msg_comment_indent();
        }
    }
}

# This is the routine that controls what line is being parsed. It gets called
# once for each line in the YAML stream.
sub _parse_next_line {
    my ($type) = @_;
    my $level = $o->{level};
    shift @{$o->{lines}};
    $o->{line}++;
    if ($type == COLLECTION &&
        $o->{preface} =~ /^(\\{1,2}|\|{1,2})\s*$/
       ) {
        $type = SCALAR;
        $level++;
    }
    if ($type != SCALAR) {
        _parse_throwaway_comments();
    }
    if (not @{$o->{lines}}) {
        $o->{eos}++;
        $o->{done}++;
        return;
    }
    my $separator = $o->{separator};
    if ($separator and $o->{lines}[0] =~ /^\Q$separator/) {
        $o->{done}++;
        return;
    }
    if ($type == SCALAR and $level >= 0 and
        $o->{lines}[0] =~ /^ {$level}(.*)$/
       ) {
        $o->{indent} = $level;
        $o->{content} = $1;
    }
    elsif ($o->{lines}[0] =~ /^\s*$/) {
        $o->{indent} = $level;
        $o->{content} = '';
    }
    else {
        $o->{lines}[0] =~ /^( *)(\S.*)$/;
        $o->{indent} = length($1);
        $o->{content} = $2;
    }
    croak msg_indentation() if $o->{indent} - $level > 1;
}

#==============================================================================
# Utility subroutines.
#==============================================================================

# Indent a scalar to the current indentation level.
sub indent {
    my ($text) = @_;
    return $text unless length $text;
    $text =~ s/\n\Z//;
    my $indent = ' ' x $o->{level};
    $text = "\n$text";
    $text =~ s/^/$indent/gm;
    # (my $t = $text) =~ s/\n/+/g;print "indent>$t<\n"; 
    return $text;
}

# Fold a paragraph to fit within a certain columnar restraint.
sub fold {
    my ($text) = @_;
    my $folded = '';
    $text =~ s/([^\n]\n+)/$1\n/g;
    while (length $text > 0) {
        if (length($text) <= 75) {
            $folded .= $text;
            $text = '';
        }
        elsif (substr($text, 60, 16) =~ /^(.* )/) {
            $folded .= substr($text, 0, 60 + length($1), '');
            chop($folded);
        }
        else {
            $folded .= substr($text, 0, 75, '') . '\\';
        }
        $folded .= "\n";
    }
    chop $folded;
    # (my $f = $folded) =~ s/\n/+/g;print "folded>$f<\n"; 
    return $folded;
}

# Escapes for unprintable characters
my @escapes = qw(\z   \x01 \x02 \x03 \x04 \x05 \x06 \a
                 \x08 \t   \n   \v   \f   \r   \x0e \x0f
                 \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17
                 \x18 \x19 \x1a \e   \x1c \x1d \x1e \x1f
                );

# Escape the unprintable characters
sub escape {
    my ($text) = @_;
    $text =~ s/\\/\\\\/g;
    $text =~ s/([\x00-\x1f])/$escapes[ord($1)]/ge;
    return $text;
}

# Printable characters for escapes
my %unescapes = 
  (
   z => "\x00", a => "\x07", t => "\x09",
   n => "\x0a", v => "\x0b", f => "\x0c",
   r => "\x0d", e => "\x1b", '\\' => '\\',
  );
   
# Transform all the backslash style escape characters to their literal meaning
sub _unescape {
    my ($node) = @_;
    $node =~ s/\\([never\\fartz]|x([0-9a-fA-F]{2}))/
              (length($1)>1)?pack("H2",$2):$unescapes{$1}/gex;
    return $node;
}

#==============================================================================
# These subroutines are used to support the YAML test suite
#==============================================================================
my $test_number = 1;

sub SetTestNumber {
    $test_number = shift;
}

sub TestLoad {
    eval "use lib qw(./t/testlib)";
    croak $@ if $@;
    eval "use Yumper";
    croak $@ if $@;
    eval "use diagnostics";
    croak $@ if $@;

    my $test = shift;
    my ($yaml, $yumper, $dumper, @objects);
    if (-f "./t/data/yaml/$test" &&
        -f "./t/data/dumper/$test"
       ) {
        open MYYAML, "< ./t/data/yaml/$test" or croak $!;
        open DUMPER, "< ./t/data/dumper/$test" or croak $!;
        $yaml = join '', <MYYAML>;
        $dumper = join '', <DUMPER>;
        close MYYAML;
        close DUMPER;
        eval { @objects = YAML::Load($yaml) };
        if (not $@) {
            $yumper = Yumper(@objects);
            if ($yumper eq $dumper) {
                print "ok $test_number\n";
            }
            else {
                print "not ok $test_number\n"
            }
        }
        else {
            warn $@;
            print "not ok $test_number\n";
        }
    }
    else {
        warn "Invalid test file '$test'\n";
        print "not ok $test_number\n";
    }
    $test_number++;
}

#==============================================================================
# Messages
#==============================================================================
sub wl0 {
    return <<END;
YAML Load Warning:
  $_[0]
In YAML Stream line #$o->{line}; Document #$o->{document}.
END
}

sub wl1 {
    my $line = $o->{line} - 1;
    return <<END;
YAML Load Warning:
  $_[0]
In YAML Stream line #$line; Document #$o->{document}.
END
}

sub el0 {
    my $msg = <<END;
YAML Load Error:
  $_[0]
END
    $msg .= <<END if $o->{line} > 0;
In YAML Stream line #$o->{line}; Document #$o->{document}.
END
    return $msg;
}

sub el1 {
    my $line = $o->{line} - 1;
    return <<END;
YAML Load Error:
  $_[0]
In YAML Stream line #$line; Document #$o->{document}.
END
}

# Store messages
sub msg_invalid_separator {
    "Invalid value for YAML Option: 'Separator'\n";
}
sub msg_file_input {
    "Couldn't open $_[0] for input:\n$_[1]";
}
sub msg_file_concatenate {
    "Can't concatenate to YAML file $_[0]\n";
}
sub msg_file_output {
    "Couldn't open $_[0] for output:\n$_[1]";
}

# Load messages
sub usage_load {
    "usage: YAML::Load(\$yaml_stream_scalar)\n";
}
sub msg_bad_chars {
    el0 "Invalid characters in stream. This parser only supports printable ASCII";
}
sub msg_no_newline {
    el0 "Stream does not end with newline character";
}
sub msg_bad_major_version {
    el1 "Can't parse a $_[0] document with a 1.0 parser";
}
sub msg_bad_minor_version {
    wl1 "Parsing a $_[0] document with a 1.0 parser";
}
sub msg_multiple_properties {
    wl0 "$_[0] property used more than once";
}
sub msg_no_separator {
    el0 "Expected separator '$_[0]'";
}
sub msg_text_after_indicator {
    el1 "No text allowed after indicator";
}
sub msg_top_level_inline {
    el1 "Can't define a top level inline scalar";
}
sub msg_no_anchor {
    el1 "No anchor for alias '*$_[0]'";
}
sub msg_single_line_parse {
    el1 "Couldn't parse single line value";
}
sub msg_parse_node {
    el1 "Can't parse node";
}
sub msg_bad_explicit {
    el1 "Unsupported explicit transfer: '$_[0]'";
}
sub msg_many_explicit {
    el1 "More than one explicit transfer";
}
sub msg_many_implicit {
    el1 "More than one implicit request";
}
sub msg_bad_anchor {
    el1 "Invalid anchor";
}
sub msg_many_anchor {
    el1 "More than one anchor";
}
sub msg_anchor_alias {
    el1 "Can't define both an anchor and an alias";
}
sub msg_bad_alias {
    el1 "Invalid alias";
}
sub msg_many_alias {
    el1 "More than one alias";
}
sub msg_no_convert {
    el1 "Can't convert implicit '$_[0]' node to explicit '$_[1]' node";
}
sub msg_no_default_value {
    el1 "No default value for '$_[0]' explicit transfer";
}
sub msg_non_empty_string {
    el1 "Only the empty string can be converted to a '$_[0]'";
}
sub msg_bad_map_to_seq {
    el1 "Can't transfer map as sequence.\nNon numeric key '$_[0]' encountered";
}
sub msg_bad_str_to_int {
    el1 "Can't transfer string to integer";
}
sub msg_bad_map_element {
    el0 "Invalid element in map";
}
sub msg_duplicate_key {
    wl1 "Duplicate map key found. Ignoring.";
}
sub msg_map_seq_element {
    el0 "Invalid element in sequence";
}
sub msg_inline_map {
    el1 "Can't parse inline map";
}
sub msg_inline_sequence {
    el1 "Can't parse inline sequence";
}
sub msg_bad_double {
    el1 "Can't parse double quoted string";
}
sub msg_bad_single {
    el1 "Can't parse single quoted string";
}
sub msg_bad_inline_implicit {
    el1 "Can't parse inline implicit value '$_[0]'";
}
sub msg_bad_implicit {
    el1 "Unrecognized implicit value '$_[0]'";
}
sub msg_comment_indent {
    el0 "Bad indentation width for throwaway";
}
sub msg_indentation {
    el0 "Error. Invalid indentation level";
}

1;
