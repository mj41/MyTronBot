# Main Tron Communications package.
package Tron;
use strict;
use warnings;
our $VERSION = 1.10;

# auto flush buffers
$|++;

# Takes your move and sends it to the contest engine.
# Send and integer in the range 1 through 4
# Where the corresponding directions are
#  * 1 -- NORTH
#  * 2 -- EAST
#  * 3 -- SOUTH
#  * 4 -- WEST
sub MakeMove{
    my ( $direction ) = @_;
    die "Need to provide a direction to makeMove.\n" unless defined $direction;

    if( $direction =~ /^[1-4]$/ ){
        print   "$direction\n";
    } else {
        die "Invalid move $direction.\n";
    }
    return 1;
}


# Definition of Map object storing game state.
package Map;

# instantiate a new Map object
# returns a Map class with members width and height set to zero
# the map state and player positions will be populated in the
# ReadFromFile method
#
# The final state of the Map object is
#   $self = {
#       w    => board width
#       h    => board height
#       mp   => ( x, y )
#       op   => ( x, y )
#       m    => ( list of rows of the board any entry which is not ' '
#                 is considered to be a wall)
#   }
#
#   example map
#    X ->
#   ##########
# Y #1       #
# | #        #
# v #       2#
#   #        #
#   ##########
#
#   You will access the player positions though the
#   $self->{mp} and $self->{op} accessors
#
#   If you wish to store old states you can create a new Map object
#   and copy the m, op and mp reference onto the new object
sub new {
    my $class = shift;
    my %self = (
        m_x => 0, # max x value
        m_y => 0, # max y value
        mp => [ 0, 0 ],
        op => [ 0, 0 ],
        m => [],
        );

    bless( \%self, $class);
    return \%self;
}


# Parses an incoming map file and overwrite the map data
# in the current Map object with new Map array, player tuples
#
# IMPORTANT: It is critical that you call this function at the
#            begining of each turn to bring your game state up
#            to see the result of the previous turns moves
#
# Once the function has been called all data in the Map object
# will be lost if not already copied else where.
#
# ReadFromFile takes an optional File name but defaults
# to reading from the standard input stream, Your submissions will
# want to leave it reading from the standard in.  However, passing
# in files could be useful for testing specific scenarios.
#
# Map file consists of 1 line with two ints specifiying x and y dimentions
# followed by y lines of x characters representing the map.  The players
# position is represented by a 1 and the oponent by a 2
# example
#    6 4
#    ######
#    #1# 2#
#    #   ##
#    ######

sub ReadFromFile {
    my ($self, $file) = @_;
    my $fh;

    # Check to see if an input file has been specified.
    if( defined $file){
        open $fh, "<", $file;
    }else{
        $fh = *STDIN;
    }

    # reset self hash
    $self->{m} = [];   # map
    $self->{mp} = [];  # my snake possition
    $self->{op} = [];  # oponnent snake position
    $self->{m_x} = 0;  # max x position value (width-1)
    $self->{m_y} = 0;  # max y position value (height-1)

    my $line = <$fh>;

    die 'Map "width height" line not found.' unless defined $line;
    chomp $line;
    ( $self->{m_x}, $self->{m_y} )= split( /\s+/, $line );
    $self->{m_x}--;
    $self->{m_y}--;

    my $row = 0;
    # Keep reading while we have not seen all the expected rows.
    while( $row < $self->{m_y}+1 ) {
        $line = <$fh> ;
        chomp($line);

        # Break the string into a list of characters and add it to the
        # end of the map.
        push( @{ $self->{m}->[$row] }, split(//, $line ) );

        if( length($line) != $self->{m_x}+1 ){
            die "invalid line width on line $row, length is ".length($line)." expected ".($self->{m_x}+1)."\n";
        }
        # check to see if the players position is on this line
        if( index( $line, '1') > 0 ){
            if( @{$self->{mp}} ){
                die "found a second definition of my position on $row\n";
            }
            $self->{mp}->[0] = index( $line, '1');
            $self->{mp}->[1] = $row;
        }
        # check to see if the opponents position is on this line
        if( index( $line, '2' ) > 0 ){
            if( @{$self->{op}} ){
                die "found a second definition of opponents position on $row\n";
            }
            $self->{op}->[0] = index( $line, '2');
            $self->{op}->[1] = $row;
        }
        ++$row;
    }
    if( $row != $self->{m_y}+1 ){
        die "wrong number of row in map, expected ".($self->{m_y}+1).", got $row\n";
    }

}

1;
