#!/bin/csh
#
#---------------------------------------------------------
# Script to find rms noise on each remaining baseline (which still have to be flagged0

ls -d *.cal
#set source=$1  #so for example ./rms.csh 0454+066.1011
echo "Input file: "
set source =  $< 
echo "No of ants [30 for GMRT, 27 for VLA]: "
set ants =  $< 

set a=1
unset select

while ($a < $ants + 1) #31
set b=$a  #starts after a, i.e. 18-5 not done is 5-8 already done

while ($b < $ants) #actually leq #THIS DOES a=1 TO ALL THE b VALUES
@ b = $b + 1     #the space following the  @ and around 
		     #the  = and  + operator are needed

   echo "Trying baseline $a[1] to $b[1]"

# uvspec vis=$source  select=ant"($a)($b)",pol"(LL)",pol"(RR)" interval=2e6 options=avall axis=dfreq device=/ps nxy=1,1 log=$a-$b.txt 
uvspec vis=$source  select=ant"($a)($b)" interval=2e6 options=avall axis=dfreq device=/ps nxy=1,1 log=$a-$b.txt 

#mkdir plots        
# cp pgplot.ps plots/$a-$b.ps  #plots saved for reference
#to get stats to run of command line, e.g. echo 1555-f.sca | stats

echo $a-$b.txt | stats >& output_$source-$a-$b  

#need the ampersand to pass on standard errors (### Warning:  Failed to converge)

if ( ! -e $b ) then  #if b does not exist - want to dispose of this
           #echo Error: Baseline $a to $b does not exist
        endif

    end
@ a = $a + 1  
  end

grep errors output_$source* > rms_$source 

#grep RMS rms_$source | sort -nr +4 > rms_$source-sorted
#doesn't work on biffa
grep RMS rms_$source | sort -nrk 5  > rms_$source-sorted
#5th column


#   a2ps -l115 rms_$source-sorted #print the results

rm output_*
rm *-*.txt
rm core.*
rm core



