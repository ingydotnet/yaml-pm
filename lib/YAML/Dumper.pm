package YAML::Dumper;
use YAML::Dumper::Base -Base;

use YAML::Node;
use YAML::Transfer;

# Context constants
use constant KEY => 3;
use constant BLESSED => 4;
use constant FROMARRAY => 5;
use constant VALUE => "\x07YAML\x07VALUE\x07";

# Common YAML character sets
my $ESCAPE_CHAR = '[\\x00-\\x08\\x0b-\\x0d\\x0e-\\x1f]';
my $FOLD_CHAR = '>';
my $LIT_CHAR = '|';    

sub stream {
    my ($stream) = @_;
    if (not defined $stream) {
        return $self->{$stream};
    }
    elsif (ref($stream) eq 'CODE') {
        $self->{stream_fetch} = $stream;
        $self->{stream_eos} = 0;
    }
    elsif ($stream eq '') {
        $self->{stream} = '';
    }
    else {
        $self->{stream} .= $stream;
    }
}

#==============================================================================
# Save the contents of a Dump operation to a file. If the file exists
# and has data, and a concatenation was requested, then verify the
# existing header.
sub DumpFile {
    my $filename = shift;
    local $/ = "\n"; # reset special to "sane"
    my $mode = '>';
    if ($filename =~ /^\s*(>{1,2})\s*(.*)$/) {
        ($mode, $filename) = ($1, $2);
    }
    if ($mode eq '>>' && -f $filename && -s $filename) {
        open MYYAML, "< $filename" 
            or $self->die('YAML_LOAD_ERR_FILE_INPUT', $filename, $!);
        my $line = <MYYAML>;
        close MYYAML;
        $self->die('YAML_DUMP_ERR_FILE_CONCATENATE', $filename)
          unless $line =~ /^---(\s|$)/;
    }
    open MYYAML, "$mode $filename"
      or $self->die('YAML_DUMP_ERR_FILE_OUTPUT', $filename, $!);
    print MYYAML YAML::Dump(@_);
    close MYYAML;
}
    
# OO version of Dump. YAML->new->dump($foo); 
sub dump {
    # local $| = 1; # set buffering to "hot" (for testing) XXX
    local $/ = "\n"; # reset special to "sane" XXX (danger) fix for callbacks
    $self->stream('');
    $self->document(0);
    for my $document (@_) {
        $self->{document}++;
        $self->transferred({});
        $self->id_refcnt({});
        $self->id_anchor({});
        $self->anchor(1);
        $self->level(0);
        $self->offset->[0] = 0 - $self->indent_width;
        $self->_prewalk($document);
        $self->_emit_header($document);
        $self->_emit_node($document);
    }
    return $self->{stream};
}

# Every YAML document in the stream must begin with a YAML header, unless
# there is only a single document and the user requests "no header".
sub _emit_header {
    my ($node) = @_;
    if (not $self->use_header and 
        $self->document == 1
       ) {
        $self->die('YAML_DUMP_ERR_NO_HEADER')
          unless ref($node) =~ /^(HASH|ARRAY)$/;
        $self->die('YAML_DUMP_ERR_NO_HEADER')
          if ref($node) eq 'HASH' and keys(%$node) == 0;
        $self->die('YAML_DUMP_ERR_NO_HEADER')
          if ref($node) eq 'ARRAY' and @$node == 0;
        # XXX Also croak if aliased, blessed, or ynode
        $self->headless(1);
        return;
    }
    $self->{stream} .= '---';
    if ($self->use_version) {
#         $self->{stream} .= " #YAML:1.0";
    }
}

# Walk the tree to be dumped and keep track of its reference counts.
# This function is where the Dumper does all its work. All transfers
# happen here.
sub _prewalk {
    my $value;
    my ($class, $type, $node_id) = YAML::Node::info(\$_[0]);
    # Handle typeglobs
    if ($type eq 'GLOB') {
        $value = $self->transferred->{$node_id} = 
          YAML::Transfer::glob::yaml_dump($_[0]);
        return $self->_prewalk($value);
    }
    # Handle regexps
    if (ref($_[0]) eq 'Regexp') {  
        $self->transferred->{$node_id} = YAML::Transfer::regexp::yaml_dump($_[0]);
        return;
    }
    # Handle Purity for scalars. XXX can't find a use case yet. Might be YAGNI.
    if (not ref $_[0]) {
        $self->{id_refcnt}{$node_id}++ if $self->purity;
        return;
    }
    # Make a copy of original
    $value = $_[0];
    ($class, $type, $node_id) = YAML::Node::info($value);
    # Look for things already transferred.
    if ($self->transferred->{$node_id}) {
        (undef, undef, $node_id) = (ref $self->transferred->{$node_id})
          ? YAML::Node::info($self->transferred->{$node_id})
          : YAML::Node::info(\ $self->transferred->{$node_id});
        $self->{id_refcnt}{$node_id}++;
        return;
    }
    # Handle code refs
    if ($type eq 'CODE') {
        $self->transferred->{$node_id} = 'crufty tracking reference placeholder';
        YAML::Transfer::code::yaml_dump($self->dump_code,
                                        $_[0], 
                                        $self->transferred->{$node_id});
        ($class, $type, $node_id) = 
          YAML::Node::info(\ $self->transferred->{$node_id});
        $self->{id_refcnt}{$node_id}++;
        return;
    }
    # Handle blessed things
    elsif (defined $class) {
        no strict 'refs';
        if (defined &{$class . "::yaml_dump"}) {
            $value = eval "&${class}::yaml_dump(\$value)";
        }
        elsif ($type eq 'SCALAR') {
            $self->transferred->{$node_id} = 'tracking reference placeholder';
            YAML::Transfer::blessed::yaml_dump
              ($_[0], $self->transferred->{$node_id});
            ($class, $type, $node_id) =
              YAML::Node::info(\ $self->transferred->{$node_id});
            $self->{id_refcnt}{$node_id}++;
            return;
        }
        else {
            $value = YAML::Transfer::blessed::yaml_dump($value);
        }
        $self->transferred->{$node_id} = $value;
        (undef, $type, $node_id) = YAML::Node::info($value);
    }
    # Handle YAML Blessed things
    if (defined YAML->global_object()->{blessed_map}{$node_id}) {
        $value = YAML->global_object()->{blessed_map}{$node_id};
        $self->transferred->{$node_id} = $value;
        ($class, $type, $node_id) = YAML::Node::info($value);
        return $self->_prewalk($value);
    }
    # Handle hard refs
    if ($type eq 'REF' or $type eq 'SCALAR') {
        $value = YAML::Transfer::ref::yaml_dump($value);
        $self->transferred->{$node_id} = $value;
        (undef, $type, $node_id) = YAML::Node::info($value);
    }
    # Handle ref-to-glob's
    elsif ($type eq 'GLOB') {
        my $ref_ynode = $self->transferred->{$node_id} =
          YAML::Transfer::ref::yaml_dump($value);

        my $glob_ynode = $ref_ynode->{&VALUE} = 
          YAML::Transfer::glob::yaml_dump($$value);

        (undef, undef, $node_id) = YAML::Node::info($glob_ynode);
        $self->transferred->{$node_id} = $glob_ynode;
        return $self->_prewalk($glob_ynode);
    }
      
    # Increment ref count for node
    return if ++($self->{id_refcnt}{$node_id}) > 1;

    # Continue walking
    if ($type eq 'HASH') {
        $self->_prewalk($value->{$_}) for keys %{$value};
    }
    elsif ($type eq 'ARRAY') {
        $self->_prewalk($_) for @{$value};
    }
}

# Every data element and sub data element is a node. Everything emitted
# goes through this function.
sub _emit_node {
    my ($type, $node_id);
    my $ref = ref($_[0]);
    if ($ref and $ref ne 'Regexp') {
        (undef, $type, $node_id) = YAML::Node::info($_[0]);
    }
    else {
        $type = $ref || 'SCALAR';
        (undef, undef, $node_id) = YAML::Node::info(\$_[0]);
    }

    my ($ynode, $family) = ('') x 2;
    my ($value, $context) = (@_, 0); # XXX don't copy scalars
    if (defined $self->transferred->{$node_id}) {
        $value = $self->transferred->{$node_id};
        $ynode = ynode($value);
        if (ref $value) {
            $family = defined $ynode ? $ynode->family->short : '';
            (undef, $type, $node_id) = YAML::Node::info($value);
        }
        else {
            $family = ynode($self->transferred->{$node_id})->family->short;
            $type = 'SCALAR';
            (undef, undef, $node_id) = 
              YAML::Node::info(\ $self->transferred->{$node_id});
        }
    }
    elsif ($ynode = ynode($value)) {
        $family = $ynode->family->short;
    }

    if ($self->use_aliases) {
        $self->{id_refcnt}{$node_id} ||= 0;
        if ($self->{id_refcnt}{$node_id} > 1) {
            if (defined $self->{id_anchor}{$node_id}) {
                $self->{stream} .= ' *' . $self->{id_anchor}{$node_id} . "\n";
                return;
            }
            my $anchor = $self->anchor_prefix . $self->{anchor}++;
            $self->{stream} .= ' &' . $anchor;
            $self->{id_anchor}{$node_id} = $anchor;
        }
    }

    return $self->_emit_scalar($value, $family) if $type eq 'SCALAR' and $family;
    return $self->_emit_str($value) if $type eq 'SCALAR';
    return $self->_emit_mapping($value, $family, $node_id, $context) if $type eq 'HASH';
    return $self->_emit_sequence($value, $family) if $type eq 'ARRAY';
    warn YAML_DUMP_WARN_BAD_NODE_TYPE($type) if $^W;
    return $self->_emit_str("$value");
}

# A YAML mapping is akin to a Perl hash. 
sub _emit_mapping {
    my ($value, $family, $node_id, $context) = @_;
    $self->{stream} .= " !$family" if $family;

    # Sometimes 'keys' fails. Like on a bad tie implementation.
    my $empty_hash = not(eval {keys %$value});
    warn YAML_EMIT_WARN_KEYS($@) if $^W and $@;
    return ($self->{stream} .= " {}\n") if $empty_hash;
        
    # If CompressSeries is on (default) and legal is this context, then
    # use it and make the indent level be 2 for this node.
    if ($context == FROMARRAY and $self->compress_series and
        not (defined $self->{id_anchor}{$node_id} or $family or $empty_hash)
       ) {
        $self->{stream} .= ' ';
        $self->offset->[$self->level+1] = $self->offset->[$self->level] + 2;
    }
    else {
        $context = 0;
        $self->{stream} .= "\n" unless $self->headless && not($self->headless = 0);
        $self->offset->[$self->level+1] =
            $self->offset->[$self->level] + $self->indent_width;
    }

    $self->{level}++;
    my @keys;
    if ($self->sort_keys == 1) {
        if (ynode($value)) {
            @keys = keys %$value;
        }
        else {
            @keys = sort keys %$value;
        }
    }
    elsif ($self->sort_keys == 2) {
        @keys = sort keys %$value;
    }
    # XXX This is hackish but sometimes handy. Not sure whether to leave it in.
    elsif (ref($self->sort_keys) eq 'ARRAY') {
        my $i = 1;
        my %order = map { ($_, $i++) } @{$self->sort_keys};
        @keys = sort {
            (defined $order{$a} and defined $order{$b})
              ? ($order{$a} <=> $order{$b})
              : ($a cmp $b);
        } keys %$value;
    }
    else {
        @keys = keys %$value;
    }
    # Force the YAML::VALUE ('=') key to sort last.
    if (exists $value->{&VALUE}) {
        for (my $i = 0; $i < @keys; $i++) {
            if ($keys[$i] eq &VALUE) {
                splice(@keys, $i, 1);
                push @keys, &VALUE;
                last;
            }
        }
    }

    for my $key (@keys) {
        $self->_emit_key($key, $context);
        $context = 0;
        $self->{stream} .= ':';
        $self->_emit_node($value->{$key});
    }
    $self->{level}--;
}

# A YAML series is akin to a Perl array.
sub _emit_sequence {
    my ($value, $family) = @_;
    $self->{stream} .= " !$family" if $family;

    return ($self->{stream} .= " []\n") if @$value == 0;
        
    $self->{stream} .= "\n"
        unless $self->headless && not($self->headless = 0);

    # XXX Really crufty feature. Better implemented by ynodes.
    if ($self->inline_series and
        @$value <= $self->inline_series and
        not (scalar grep {ref or /\n/} @$value)
       ) {
        $self->{stream} =~ s/\n\Z/ /;
        $self->{stream} .= '[';
        for (my $i = 0; $i < @$value; $i++) {
            $self->_emit_str($value->[$i], KEY);
            last if $i == $#{$value};
            $self->{stream} .= ', ';
        }
        $self->{stream} .= "]\n";
        return;
    }

    $self->offset->[$self->level + 1] = $self->offset->[$self->level] +
    $self->indent_width;
    $self->{level}++;
    for my $val (@$value) {
        $self->{stream} .= ' ' x $self->offset->[$self->level];
        $self->{stream} .= '-';
        $self->_emit_node($val, FROMARRAY);
    }
    $self->{level}--;
}

# Emit a mapping key
sub _emit_key {
    my ($value, $context) = @_;
    $self->{stream} .= ' ' x $self->offset->[$self->level]
      unless $context == FROMARRAY;
    $self->_emit_str($value, KEY);
}

# Emit a blessed SCALAR
sub _emit_scalar {
    my ($value, $family) = @_;
    $self->{stream} .= " !$family";
    $self->_emit_str($value, BLESSED);
}

sub _emit {
    $self->{stream} .= join '', @_;
}

# Emit a string value. YAML has many scalar styles. This routine attempts to
# guess the best style for the text.
sub _emit_str {
    my $type = $_[1] || 0;

    # Use heuristics to find the best scalar emission style.
    $self->offset->[$self->level + 1] =
        $self->offset->[$self->level] + $self->indent_width;
    $self->{level}++;

    my $sf = $type == KEY ? '' : ' ';
    my $sb = $type == KEY ? '? ' : ' ';
    my $ef = $type == KEY ? '' : "\n";
    my $eb = "\n";

    while (1) {
        $self->_emit($sf), $self->_emit_plain($_[0]), $self->_emit($ef), last 
          if not defined $_[0];
        $self->_emit($sf, '=', $ef), last
          if $_[0] eq VALUE;
        $self->_emit($sf), $self->_emit_double($_[0]), $self->_emit($ef), last
          if $_[0] =~ /$ESCAPE_CHAR/;
        if ($_[0] =~ /\n/) {
            $self->_emit($sb), $self->_emit_block($LIT_CHAR, $_[0]), $self->_emit($eb), last
              if $self->use_block;
            $self->_emit($sb), $self->_emit_block($FOLD_CHAR, $_[0]), $self->_emit($eb), last
              if $self->use_fold;
            $self->_emit($sf), $self->_emit_double($_[0]), $self->_emit($ef), last
              if length $_[0] <= 30;
            $self->_emit($sb), $self->_emit_block($FOLD_CHAR, $_[0]), $self->_emit($eb), last
              if $_[0] =~ /^\S[^\n]{76}/m;
            $self->_emit($sf), $self->_emit_double($_[0]), $self->_emit($ef), last
              if $_[0] !~ /\n\s*\S/;
            $self->_emit($sb), $self->_emit_block($LIT_CHAR, $_[0]), $self->_emit($eb), last;
        }
        $self->_emit($sf), $self->_emit_plain($_[0]), $self->_emit($ef), last
          if $self->is_valid_plain($_[0]);
        $self->_emit($sf), $self->_emit_double($_[0]), $self->_emit($ef), last
          if $_[0] =~ /'/;
        $self->_emit($sf), $self->_emit_single($_[0]), $self->_emit($ef);
        last;
    }

    $self->{level}--;

    return;
}

# Check whether or not a scalar should be emitted as an plain scalar.
sub is_valid_plain {
    return 0 unless length $_[0];
    # refer: parse_inline_simple()
    return 0 if $_[0] =~ /^[\s\{\[\~\`\'\"\!\@\#\%\&\*\^]/;
    return 0 if $_[0] =~ /[\{\[\]\},]/;
    return 0 if $_[0] =~ /[:\-\?]\s/;
    return 0 if $_[0] =~ /\s#/;
    return 0 if $_[0] =~ /\:(\s|$)/;
    return 0 if $_[0] =~ /\s$/;
    return 1;
}

# A nested scalar is either block or folded 
sub _emit_block {
    my ($indicator, $value) = @_;
    $self->{stream} .= $indicator;
    $value =~ /(\n*)\Z/;
    my $chomp = length $1 ? (length $1 > 1) ? '+' : '' : '-';
    $value = '~' if not defined $value;
    $self->{stream} .= $chomp;
    $self->{stream} .= $self->indent_width if $value =~ /^\s/;
    if ($indicator eq $FOLD_CHAR) {
        $value = $self->fold($value);
        chop $value unless $chomp eq '+';
    }
    $self->{stream} .= $self->indent($value);
}

# Plain means that the scalar is unquoted.
sub _emit_plain {
    $self->{stream} .= defined $_[0] ? $_[0] : '~';
}

# Double quoting is for single lined escaped strings.
sub _emit_double {
    (my $escaped = $self->escape($_[0])) =~ s/"/\\"/g;
    $self->{stream} .= qq{"$escaped"};
}

# Single quoting is for single lined unescaped strings.
sub _emit_single {
    my $item = shift;
    $item =~ s{'}{''}g;
    $self->{stream} .= "'$item'";
}

#==============================================================================
# Utility subroutines.
#==============================================================================

# Indent a scalar to the current indentation level.
sub indent {
    my ($text) = @_;
    return $text unless length $text;
    $text =~ s/\n\Z//;
    my $indent = ' ' x $self->offset->[$self->level];
    $text =~ s/^/$indent/gm;
    $text = "\n$text";
    return $text;
}

# Fold a paragraph to fit within a certain columnar restraint.
sub fold {
    my ($text) = @_;
    my $folded = '';
    $text =~ s/^(\S.*)\n(?=\S)/$1\n\n/gm;
    while (length $text > 0) {
        if ($text =~ s/^([^\n]{0,76})(\n|\Z)//) {
            $folded .= $1;
        }
        elsif ($text =~ s/^(.{0,76})\s//) { 
            $folded .= $1;
        }
        else {
            $self->die("bad news") unless $text =~ s/(.*?)(\s|\Z)//;
            $folded .= $1;
        }
        $folded .= "\n";
    }
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
