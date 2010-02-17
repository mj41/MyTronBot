#!/bin/bash

echo > temp/maps.txt
perl MyTronBot.pl map 1 1 1 >> temp/maps.txt 2>&1

echo > temp/out.txt
perl MyTronBot.pl maps/playground.txt 1 1 0	>> temp/out.txt 2>&1
perl MyTronBot.pl maps/keyhole.txt 1 1 0  	>> temp/out.txt 2>&1
perl MyTronBot.pl maps/empty-room.txt 1 1 0	>> temp/out.txt 2>&1

if [ 0=1 ]; then
	perl MyTronBot.pl maps/quadrant.txt 1 1 0	>> temp/out.txt 2>&1
	perl MyTronBot.pl maps/center.txt 1 1 0 	>> temp/out.txt 2>&1
	perl MyTronBot.pl maps/trix.txt 1 1 0 		>> temp/out.txt 2>&1
	perl MyTronBot.pl maps/u.txt 1 1 0 			>> temp/out.txt 2>&1
fi

