#!/bin/csh
#
#---------------------------------------------------------

set source=$1    
set rms=$2  

sed -e 's/-/ /g' rms_$source-sorted > intermed3; sed -e 's/+/ /g' intermed3 > intermed4; sed -e 's/:RMS of errors         =/ /g' intermed4 > rms_sorted
# rm intermed*

gawk '{if($5>rms) {print $3,$4}}' rms=$rms rms_sorted > baselines_to_flag.txt 
# gawk '{if($4>rms) {print $2,$3}}' rms=$rms rms_sorted > baselines_to_flag.txt 

echo \#\!\/bin\/csh > uvflag.csh     # writing script to do flagging - $1 and $2 are the fields in baselines_to_flag.txt 
gawk '{print "uvflag vis="source" select=ant\"("$1")("$2")\" options=brief flagval=f"}' source=$source baselines_to_flag.txt >> uvflag.csh

chmod +x uvflag.csh
./uvflag.csh  #this gets updated each time one of these scrips is run

echo "baselines flagged"; wc -l baselines_to_flag.txt 
