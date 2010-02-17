use Tron;

my $input_file = undef;
my $debug = 0;
my $simulate = 0;
my $generate_maps = 0;

$input_file = $ARGV[0] if $ARGV[0];


# Devel lines.
# Comment this lines before zip and upload.
#
use strict;
use warnings;
use Data::Dumper::Concise;
$debug = $ARGV[1];
$simulate = $ARGV[2];
$generate_maps = $ARGV[3];



# Directions:
#     1
#   4 * 2
#     3
#
# 1 y--   ... NORTH -- Negative Y direction
# 2 x++   ... EAST  -- Positive X direction
# 3 y++   ... SOUTH -- Positive Y direction
# 4 x--   ...  WEST  -- Negative X direction
#
#
# h .. height , w ... width
#
#    y |
#       - x
#
#  m_y |
#       _ m_x
#
# m ... map
# mp ... my position
# op ... oponnet position
# m_x ... max x value ( = width-1 )
# m_y ... max y value ( = height-1 )

sub deb {
    my ( $str ) = @_;
    return 1 unless $str;
    print $str;
    return 1;
}


sub map_str {
    my ( $g_obj, $meta, $nx, $ny ) = @_;

    my $str = '';

    foreach my $y ( 0..($g_obj->{m_y}) ) {
        foreach my $x ( 0..$g_obj->{m_x} ) {
            if ( defined $nx && defined $y && $y == $ny && $x == $nx ) {
                $str .= '+';
            } else {
                $str .= $g_obj->{m}->[$y][$x];
            }
        }
        $str .= ' ';

        foreach my $x ( 0..$g_obj->{m_x} ) {
            if ( $g_obj->{m}->[$y][$x] ne ' ' ) {
                $str .= '#';
            } elsif ( defined $meta->{walls}->[$y][$x] ) {
                if ( $meta->{walls}->[$y][$x] ) {
                    $str .= $meta->{walls}->[$y][$x];
                } else {
                    $str .= ' ';
                }
            } else {
                $str .= '+';
            }
        }
        $str .= ' ';

        foreach my $x ( 0..$g_obj->{m_x} ) {
            if ( $g_obj->{m}->[$y][$x] ne ' ' ) {
                $str .= '#';
            } elsif ( defined $meta->{walls_x}->[$y][$x] ) {
                if ( $meta->{walls_x}->[$y][$x] ) {
                    $str .= $meta->{walls_x}->[$y][$x];
                } else {
                    $str .= ' ';
                }
            } else {
                $str .= '+';
            }
        }
        $str .= ' ';

        foreach my $x ( 0..$g_obj->{m_x} ) {
            if ( $g_obj->{m}->[$y][$x] ne ' ' ) {
                $str .= '#';
            } elsif ( defined $meta->{walls_y}->[$y][$x] ) {
                if ( $meta->{walls_y}->[$y][$x] ) {
                    $str .= $meta->{walls_y}->[$y][$x];
                } else {
                    $str .= ' ';
                }
            } else {
                $str .= '+';
            }
        }
        $str .= ' ';

        $str .= "\n";
    }

    return $str;
}


sub direction_is_valid {
    my ( $g_obj, $meta, $dr, $snake_num ) = @_;

    my $snake_key = 'mp';
    $snake_key = 'op' if $snake_num == 2;

    my $debug = 0;

    my $x = $g_obj->{ $snake_key }->[0];
    my $y = $g_obj->{ $snake_key }->[1];
    deb("trying direction for snake $snake_key: $dr, p: $x,$y -> ") if $debug;

    if ( $dr == 1 ) {
        $y--;
    } elsif ( $dr == 2 ) {
        $x++;
    } elsif ( $dr == 3 ) {
        $y++;
    } elsif ( $dr == 4 ) {
        $x--;
    }
    deb("p: $x,$y") if $debug;

    if ( $g_obj->{m}->[$y][$x] ne ' ' ) {
        deb(" => wall\n") if $debug;
        return 0;
    }

    if ( $debug ) {
        deb(" => ok\n");
        deb( map_str( $g_obj, $meta, $x, $y ) );
        deb("\n");
    }
    return 1;
}


sub _rec_StepsToEnd {
    my ( $g_obj, $dr_list, $x, $y, $map, $steps, $deep ) = @_;

    $deep++;
    return $steps if $deep >= 8;
    return $steps if $simulate && $deep >= 4; # go only 4 steps to deep if developing

    my $dr = $dr_list->[ $#$dr_list ];
    if ( 0 && $debug ) {
        deb("\n") if $deep == 1;
        deb("steps to end - deep $deep - steps $steps - dr: $dr - $x, $y - keys: " );
        foreach my $key ( sort keys %$map ) {
            deb( "$key " );
        }
        deb("\n");
    }

    if ( $dr == 1 ) {
        $y--;
    } elsif ( $dr == 2 ) {
        $x++;
    } elsif ( $dr == 3 ) {
        $y++;
    } elsif ( $dr == 4 ) {
        $x--;
    }

    my $max_steps = $steps;
    foreach my $new_dr ( 1..4 ) {
        # there is next move available
        if ( $g_obj->{m}->[$y][$x] eq ' ' && (not exists $map->{"$x,$y"}) ) {
            my $new_steps = $steps + 1;
            my $new_dr_list = [ @$dr_list, $new_dr ];
            my $new_map = { %$map };
            $new_map->{"$x,$y"} = 1;
            my $new_max_steps = _rec_StepsToEnd(
                $g_obj,
                $new_dr_list,
                $x,
                $y,
                $new_map,
                $new_steps,
                $deep
            );
            $max_steps = $new_max_steps if $new_max_steps > $max_steps;
        }
    }

    return $max_steps;
}


sub StepsToEnd {
    my ( $g_obj, $dr ) = @_;

    my $x = $g_obj->{'mp'}->[0];
    my $y = $g_obj->{'mp'}->[1];

    my $steps = _rec_StepsToEnd( $g_obj, [ $dr ], $x, $y, {}, 0, 0 );
    deb( "steps = $steps (dr: $dr)\n") if $debug;
    return $steps;
}



# ToDo - this is initial version of sub to grab meta info around our snake position
#
sub AddToBlindMap {
    my ( $g_obj, $meta, $c_x1, $c_y1, $c_x2, $c_y2 ) = @_;

    deb("AddToBlindMap -- $c_x1, $c_y1, $c_x2, $c_y2\n") if $debug;
    my $m_obj = $g_obj->{m};
    foreach my $y ($c_y1..$c_y2) {
        foreach my $x ($c_x1..$c_x2) {
            my ( $walls_x, $walls_y ) = ( 0, 0 );
            # my pos 0
            $walls_y++ if $y-1 <= 0             || ($m_obj->[$y-1][$x  ] ne ' '); # dr 1
            $walls_x++ if $x+1 >= $g_obj->{m_x} || ($m_obj->[$y  ][$x+1] ne ' '); # dr 2
            $walls_y++ if $y+1 >= $g_obj->{m_y} || ($m_obj->[$y+1][$x  ] ne ' '); # dr 3
            $walls_x++ if $x-1 <= 0             || ($m_obj->[$y  ][$x-1] ne ' '); # dr 4
            $meta->{walls}->[$y]->[$x] = $walls_x + $walls_y;
            $meta->{walls_x}->[$y]->[$x] = $walls_x;
            $meta->{walls_y}->[$y]->[$x] = $walls_y;
        }
    }
    return 1;
}


sub ExtendBlindMap {
    my ( $g_obj, $meta ) = @_;

    my ( $x1, $y1, $x2, $y2 ) = @{ $meta->{walls_dim} };
    my ( $c_x1, $c_y1, $c_x2, $c_y2 ) = ( $x1, $y1, $x2, $y2 );

    my $prev_mp_dr = $meta->{prev_mp_dr};
    deb("ExtendBlindMap init -- dr $prev_mp_dr -- $x1, $y1, $x2, $y2\n") if $debug;
    my $check_dr = $meta->{prev_mp_dr};
    foreach my $num ( 0..3 ) {
        $check_dr = ( $prev_mp_dr + $num - 1) % 4 + 1;

        if ( $check_dr == 1 && $y1-1 > 0 ) {
            $y1--;
            $c_y1 = $y1;
            $c_y2 = $y1;
            last;
        }

        if ( $check_dr == 2 && $x2+1 < $g_obj->{m_x} ) {
            $x2++;
            $c_x1 = $x2;
            $c_x2 = $x2;
            last;
        }

        if ( $check_dr == 3 && $y2+1 < $g_obj->{m_y} ) {
            $y2++;
            $c_y1 = $y2;
            $c_y2 = $y2;
            last;
        }

        if ( $check_dr == 4 && $x1-1 > 0 ) {
            $x1--;
            $c_x1 = $x1;
            $c_x2 = $x1;
            last;
        }
    }
    deb("ExtendBlindMap -- check_dr $check_dr -- $c_x1, $c_y1, $c_x2, $c_y2 -- $x1, $y1, $x2, $y2\n") if $debug;
    AddToBlindMap( $g_obj, $meta, $c_x1, $c_y1, $c_x2, $c_y2 );
    $meta->{walls_dim} = [ $x1, $y1, $x2, $y2 ];

    # refresh around our new pos
    my ( $mp_x, $mp_y ) = ( $g_obj->{mp}->[0], $g_obj->{mp}->[1] );
    AddToBlindMap( $g_obj, $meta, $mp_x,   $mp_y,   $mp_x,   $mp_y   );
    AddToBlindMap( $g_obj, $meta, $mp_x,   $mp_y-1, $mp_x,   $mp_y-1 ) if $mp_y-1 > 0;
    AddToBlindMap( $g_obj, $meta, $mp_x+1, $mp_y  , $mp_x+1, $mp_y   ) if $mp_x+1 < $g_obj->{m_x};
    AddToBlindMap( $g_obj, $meta, $mp_x,   $mp_y+1, $mp_x,   $mp_y+1 ) if $mp_y+1 < $g_obj->{m_y};
    AddToBlindMap( $g_obj, $meta, $mp_x-1, $mp_y  , $mp_x-1, $mp_y   ) if $mp_x-1 > 0;


    # refresh after opponent move, if was inside our area
    my ( $op_x, $op_y ) = ( $g_obj->{op}->[0], $g_obj->{op}->[1] );
    if ( $x1 < $op_x && $op_x < $x2 && $y1 < $op_y && $op_y < $y2 ) {
        AddToBlindMap( $g_obj, $meta, $op_x,   $op_y, $op_x,   $op_y );
    }
    if ( $op_y-1 > 0 && $x1 < $op_x && $op_x < $x2 && $y1 < $op_y-1 && $op_y-1 < $y2 ) {
        AddToBlindMap( $g_obj, $meta, $op_x,   $op_y-1, $op_x,   $op_y-1 );
    }
    if ( $op_x+1 < $g_obj->{m_x} && $x1 < $op_x+1 && $op_x+1 < $x2 && $y1 < $op_y-1 && $op_y-1 < $y2 ) {
        AddToBlindMap( $g_obj, $meta, $op_x+1, $op_y  , $op_x+1, $op_y   );
    }
    if ( $op_y+1 < $g_obj->{m_y} && $x1 < $op_x && $op_x < $x2 && $y1 < $op_y+1 && $op_y+1 < $y2 ) {
        AddToBlindMap( $g_obj, $meta, $op_x,   $op_y+1, $op_x,   $op_y+1 );
    }
    if ( $op_x-1 > 0 && $x1 < $op_x-1 && $op_x-1 < $x2 && $y1 < $op_y && $op_y < $y2 ) {
        AddToBlindMap( $g_obj, $meta, $op_x-1, $op_y  , $op_x-1, $op_y   );
    }

    return 1;
}


sub InitBlindMap {
    my ( $g_obj, $meta ) = @_;

    my $blind_x_dim = 20;
    my $blind_y_dim = $blind_x_dim;

    my $cb_x1_overlap = 0;
    my $cb_y1_overlap = 0;
    my $cb_x2_overlap = 0;
    my $cb_y2_overlap = 0;

    my $cb_x1 = $g_obj->{mp}->[0] - $blind_x_dim;
    if ( $cb_x1 < 0 ) {
        $cb_x1_overlap = -$cb_x1;
        $cb_x1 = 0;
    }

    my $cb_y1 = $g_obj->{mp}->[1] - $blind_y_dim;
    if ( $cb_y1 < 0 ) {
        $cb_y1_overlap = -$cb_y1;
        $cb_y1 = 0;
    }

    my $cb_x2 = $g_obj->{mp}->[0] + $blind_x_dim;
    if ( $cb_x2 > $g_obj->{m_x} ) {
        $cb_x2_overlap = $cb_x2 - $g_obj->{m_x};
        $cb_x2 = $g_obj->{m_x};
    }

    my $cb_y2 = $g_obj->{mp}->[1] + $blind_y_dim;
    if ( $cb_y2 > $g_obj->{m_y} ) {
        $cb_y2_overlap = $cb_y2 - $g_obj->{m_y};
        $cb_y2 = $g_obj->{m_y};
    }

    $cb_x1 -= $cb_x2_overlap;
    $cb_x1 = 0 if $cb_x1 < 0;

    $cb_y1 -= $cb_y2_overlap;
    $cb_y1 = 0 if $cb_y1 < 0;

    $cb_x2 += $cb_x1_overlap;
    $cb_x2 = $g_obj->{m_x} if $cb_x2 > $g_obj->{m_x};

    $cb_y2 += $cb_y1_overlap;
    $cb_y2 = $g_obj->{m_y} if $cb_y2 > $g_obj->{m_y};

    deb( "init blind map: $cb_x1, $cb_y1 x $cb_x2, $cb_y2\n") if $debug;
    AddToBlindMap( $g_obj, $meta, $cb_x1, $cb_y1, $cb_x2, $cb_y2 );
    $meta->{walls_dim} = [ $cb_x1, $cb_y1, $cb_x2, $cb_y2 ];
    return 1;
}


sub RefreshMeta {
    my ( $g_obj, $meta ) = @_;

    my $mp_x_diff = $g_obj->{mp}->[0] - $meta->{prev_mp}->[0];
    my $mp_y_diff = $g_obj->{mp}->[1] - $meta->{prev_mp}->[1];
    my $prev_mp_dr = $meta->{prev_mp_dr};

    my $op_x_diff = $g_obj->{op}->[0] - $meta->{prev_op}->[0];
    my $op_y_diff = $g_obj->{op}->[1] - $meta->{prev_op}->[1];

    my $prev_op_dr = 0;
    if ( $op_y_diff == -1 ) {
        $prev_op_dr = 1;
    } elsif ( $op_x_diff == 1 ) {
        $prev_op_dr = 2;
    } elsif ( $op_y_diff == 1 ) {
        $prev_op_dr = 3;
    } elsif ( $op_y_diff == -1 ) {
        $prev_op_dr = 4;
    }

    deb("prev dr $prev_mp_dr, diff $mp_x_diff, $mp_y_diff - opponent prev dr $prev_op_dr, diff $op_x_diff, $op_y_diff\n") if $debug;
    ExtendBlindMap( $g_obj, $meta );

    return 1;
}


# Choose next move.
sub ChooseMove {
    my ( $g_obj, $meta ) = @_;

    my %available_dr = ();
    for my $dr (1..4) {
       $available_dr{$dr} = 1 if direction_is_valid( $g_obj, $meta, $dr, 1 );
    }

   # remove blind alleys
    my $max_steps = 0;
    foreach my $dr ( keys %available_dr ) {
        my $steps = StepsToEnd( $g_obj, $dr ) + 1;
        $max_steps = $steps if $steps > $max_steps;
        $available_dr{$dr} = $steps;
    }
    foreach my $dr ( keys %available_dr ) {
        delete $available_dr{$dr} if $available_dr{$dr} < $max_steps;
    }

    # If there is not another change, than move to wall.
    $available_dr{1} = 0 unless %available_dr;


    my ( $x_diff, $y_diff ) = opponentPosDiff( $g_obj );
    my ( $x_init_diff, $y_init_diff ) = opponentInitPosDiff( $g_obj, $meta );

    if ( $debug ) {
       deb('available directions ');
       deb( Dumper( \%available_dr ) );
       deb("diff: $x_diff, $y_diff; op init diff: $x_init_diff, $y_init_diff\n");
    }

    my $sel_dr = undef;
    # todo
    my @avalible_dr_order = ();

    $sel_dr = $meta->{start_dr}->[0];
    if ( exists $available_dr{ $sel_dr } ) {
        if ( ( $sel_dr == 1 || $sel_dr == 3 )
             && abs($y_init_diff) > abs($meta->{init_op_diff}->[1] / 2)
           )
        {
            return ( $sel_dr, 'init_dr_1' );
        }

        if ( ( $sel_dr == 2 || $sel_dr == 4 )
             && abs($x_init_diff) > abs($meta->{init_op_diff}->[0] / 2)
           )
        {
            return ( $sel_dr, 'init_dr_1' );
        }
    }

    $sel_dr = $meta->{start_dr}->[1];
    if ( exists $available_dr{ $sel_dr } ) {
        if ( ( $sel_dr == 1 || $sel_dr == 3 )
             && abs($y_init_diff) > abs($meta->{init_op_diff}->[1] / 2)
           )
        {
            return ( $sel_dr, 'init_dr_2' );
        }

        if ( ( $sel_dr == 2 || $sel_dr == 4 )
             && abs($x_init_diff) > abs($meta->{init_op_diff}->[0] / 2)
           )
        {
            return ( $sel_dr, 'init_dr_2' );
        }
    }

    # repeat directions found on init
    foreach my $num ( 0..3 ) {
        $sel_dr = $meta->{start_dr}->[ $num ];
        return ( $sel_dr, 'first_dr' ) if exists $available_dr{ $sel_dr };
    }

    my @available_dr = keys %available_dr;
    my $dr_num = int rand scalar @available_dr;
    return ( $available_dr[ $dr_num ], 'rand' );
}


sub opponentPosDiff {
    my ( $g_obj ) = @_;
    my $x_diff = $g_obj->{op}->[0] - $g_obj->{mp}->[0];
    my $y_diff = $g_obj->{op}->[1] - $g_obj->{mp}->[1];
    return ( $x_diff, $y_diff );
}


sub opponentInitPosDiff {
    my ( $g_obj, $meta ) = @_;
    my $x_diff = $meta->{init_op}->[0] - $g_obj->{mp}->[0];
    my $y_diff = $meta->{init_op}->[1] - $g_obj->{mp}->[1];
    return ( $x_diff, $y_diff );
}


sub InitMetaData {
    my ( $meta, $g_obj ) = @_;

    $meta->{init_mp} = [ $g_obj->{mp}->[0], $g_obj->{mp}->[1] ];
    $meta->{init_op} = [ $g_obj->{op}->[0], $g_obj->{op}->[1] ];

    $meta->{prev_mp} = [ $g_obj->{mp}->[0], $g_obj->{mp}->[1] ];
    $meta->{prev_op} = [ $g_obj->{op}->[0], $g_obj->{op}->[1] ];

    my ( $x_diff, $y_diff ) = opponentPosDiff( $g_obj );
    $meta->{init_op_diff} = [ $x_diff, $y_diff ];

    my $start_dr = [];
    if ( abs($x_diff) >= abs($y_diff) ) {
        if ( $x_diff > 0 ) {
           push @$start_dr, 2;
        }  else {
           push @$start_dr, 4;
        }
        if ( $y_diff > 0 ) {
           push @$start_dr, 3;
        }  else {
           push @$start_dr, 1;
        }

    } else {
        if ( $y_diff > 0 ) {
           push @$start_dr, 3;
        }  else {
           push @$start_dr, 1;
        }
        if ( $x_diff > 0 ) {
           push @$start_dr, 2;
        }  else {
           push @$start_dr, 4;
        }
    }

    push @$start_dr, ($start_dr->[0] + 2 - 1) % 4 + 1;
    push @$start_dr, ($start_dr->[1] + 2 - 1) % 4 + 1;

    $meta->{start_dr} = $start_dr;

    InitBlindMap( $g_obj, $meta );

    if ( $debug ) {
        # deb( Dumper($meta) );
        deb( map_str($g_obj, $meta) );
    }
    return  1;
}


sub ChooseopponentMove {
    my ( $g_obj, $meta, $op_dr ) = @_;

    my %available_dr = ();
    for my $dr (1..4) {
       $available_dr{$dr} = 0 if direction_is_valid( $g_obj, $meta, $dr, 2 );
    }
    # If there is not another change, than move to wall.
    $available_dr{1} = 0 unless %available_dr;

    return 3 if $op_dr == 1 && exists $available_dr{3};
    return 4 if $op_dr == 2 && exists $available_dr{4};
    return 1 if $op_dr == 3 && exists $available_dr{1};
    return 2 if $op_dr == 4 && exists $available_dr{2};

    my @available_dr = keys %available_dr;
    my $dr_num = int rand scalar @available_dr;
    my $dr = $available_dr[ $dr_num ];
    return $dr;
}


sub SimulateMakeMove {
    my ( $g_obj, $meta, $dr, $snake_num ) = @_;

    my $snake_key = 'mp';
    $snake_key = 'op' if $snake_num == 2;

    my $s_x = $g_obj->{ $snake_key }->[0];
    my $s_y = $g_obj->{ $snake_key }->[1];
    my ( $x, $y ) = ( $s_x, $s_y );

    if ( $dr == 1 ) {
        $y--;
    } elsif ( $dr == 2 ) {
        $x++;
    } elsif ( $dr == 3 ) {
        $y++;
    } elsif ( $dr == 4 ) {
        $x--;
    }

    if ( $g_obj->{m}->[$y][$x] ne ' ' ) {
        if ( $debug ) {
            deb("Finish position:\n");
            deb( map_str($g_obj, $meta) );
            deb( Dumper($meta) );
            deb("\n\n\n");
        }
        die "You ara moving snake $snake_num to wall or something to position $x, $y.\n";
    }

    $g_obj->{m}->[$s_y][$s_x] = '#';
    $g_obj->{m}->[$y][$x] = "$snake_num";
    $g_obj->{ $snake_key } = [ $x, $y ];
    return 1;
}


deb("Starting. Debug is on.\n") if $debug;

# Main loop
my $g_obj = new Map();
my $meta = {};

if ( $generate_maps && $debug ) {
    foreach my $input_file ( glob('maps/*') ) {
        print "Map $input_file:\n";
        $meta = {};
        $g_obj->ReadFromFile( $input_file );
        InitMetaData( $meta, $g_obj );
        print "\n\n";
    }
    exit;
}



my ( $dr, $dr_info ) = ( 0, '' );

my $move_num = 1;

$g_obj->ReadFromFile( $input_file );
InitMetaData( $meta, $g_obj );

while( 1 ) {
    # save prev move info
    $meta->{prev_mp} = [ $g_obj->{mp}->[0], $g_obj->{mp}->[1] ];
    $meta->{prev_mp_dr} = $dr;
    $meta->{prev_op} = [ $g_obj->{op}->[0], $g_obj->{op}->[1] ];

    # refresh game info after move
    $g_obj->ReadFromFile( $input_file ) if !$simulate && $move_num > 1;

    RefreshMeta( $g_obj, $meta );
    if ( $debug ) {
        deb("map after moves:\n");
        deb( map_str($g_obj, $meta) );
        deb( "\n" );
    }

    ( $dr, $dr_info ) = ChooseMove( $g_obj, $meta );
    deb("choosed direction: $dr ($dr_info)\n") if $debug;

    unless ( $simulate ) {
        Tron::MakeMove( $dr );
    } else {
        # ToDo
        # Run our snake first and then opponent snake.
        # They can collide!
        SimulateMakeMove( $g_obj, $meta, $dr, 1 );
        my $op_dr = ChooseopponentMove( $g_obj, $meta, $dr );
        SimulateMakeMove( $g_obj, $meta, $op_dr, 2 );
    }

    $move_num++;
    $meta->{move_num} = $move_num;
}

