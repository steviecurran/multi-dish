#!/bin/csh
#
#---------------------------------------------------------
#Script to prepare data before imaging
#ls 
ls -d *fits*
ls -d *.lta      # prep-gmrt_10.csh  has all the lta conversion stuff
echo "Input file to reduce - WITHOUT .fits EXTENSION: "
set file = $<  

echo "From scratch [y/n]: "
set scr =  $< 
if ($scr != "n") then

    mkdir $file-data      #putting in sub-directory as it gets messy
    cd $file-data

    # pwd
    #echo ../$file.fits

    fits in=../$file.fits op=uvin out=$file.uv
    qvack vis=$file.uv interval=0.5 mode=source

    unset select
    unset options
    uvsplit vis=$file.uv 
   # rm -rf $file.uv  # remove by hand later as may need for freq selected
    mv $file.uv ../.
  else
    cd $file-data
    rm -rf *.cal  
endif  

ls -d *.*
du -sm *.*

echo "Input bandpass calibrator (full names): "
set bpass =  $< 
echo "Input phase calibrator: "
set phase = $< 
echo "Input target (enter even if same as $phase): "
set target = $< 

echo "Rest freq. [GHz]:"
set  freq = $<

# if ($phase != $target) then 
    set all = $bpass,$phase,$target
 #   else
 #   set all = $bpass,$phase
# endif      # see if this works for self cal sources
 echo "NOW WORKING ON $all"

set int = 120

uvplt vis="$all" axis=time,amp device=/xs nxy=1,1 options=nobase  # $all replaces $bpass,$phase,$target
uvplt vis=$target axis=time,amp device=/xterm nxy=1,1 options=nobase

 puthd in=$bpass/restfreq value=$freq  #wildcards don't work - put in later once sources dsignated   
 puthd in=$phase/restfreq value=$freq  #
if ($phase != $target) then  
    puthd in=$target/restfreq value=$freq  
endif 

if ($scr != "n") then
echo "Flagging edge channels"
    unset line
    unset select
    uvflag vis="$all" edge=5 flagval=f options=noquery
endif 

mfcal  vis=$bpass refant=3 interval=$int
gpplt vis=$bpass device=/xs yaxis=amp options=bandpass nxy=5,4

echo "Flag bad (missing) antennae [y/n]: " 
set flagant =  $<
    if ($flagant == "y") then 
    echo "enter ants sepatated by commas, e.g. 1,7,19"
set ant =  $< 
unset edge
unset line
uvflag vis="$all" select=ant"$ant" flagval=f options=noquery
echo "Flagging ants $ant for $all"
endif 

mfcal vis=$bpass interval=$int
uvplt vis="$bpass,$phase" axis=time,amp device=/xs nxy=1,1 options=nobase

echo "Calibrating bandpass [ $bpass ]"
unset options
mfcal vis=$bpass interval=$int
uvplt vis=$bpass select=ant"(1)" axis=time,phase device=/xs nxy=5,4
   
echo "BLFLAG bandpass calibrator - not recommended [y/n]? "
set blans = $< 
while ($blans == "y") 
    blflag vis=$bpass options=nobase device=/xs
    mfcal vis=$bpass edge=1 interval=0.1
    uvplt vis=$bpass axis=time,amp  device=/xs nxy=1,1 options=nobase
    echo "BLFLAG [y/n]? "
    set blans = $<
end

unset select

 echo "Interval = $int, change [y/n]? "
 set mans = $< 
 while ($mans == "y") 
	echo "Input interval: "
	set int = $< 
   mfcal vis=$bpass interval=$int
    gpplt vis=$bpass device=/xs options=bandpass nxy=5,4
    uvplt vis=$bpass select=ant"(1)" axis=time,amp device=/xs nxy=5,4
    uvplt vis=$bpass select=ant"(1)" axis=time,phase device=/xs nxy=5,4  #takes too long to do all ants
    echo "Interval = $int, change [y/n]? "
    set mans = $< 
    end

unset options
gpcopy vis=$bpass out=$phase mode=copy
unset options
# echo "crash?"

    set int = 120
#gpcal vis=$phase interval=5  ### Fatal Error:  No data read from input file
mfcal vis=$phase interval=$int

echo "Interval = $int, change [y/n]? "
 set mans2 = $< 
 while ($mans2 == "y") 
	echo "Input interval: "
	set int = $< 
   mfcal vis=$phase interval=$int
    gpplt vis=$phase device=/xs options=bandpass nxy=5,4
  #  uvplt vis=$phase select=ant"(1)" axis=time,amp device=/xs nxy=5,4
  #  uvplt vis=$phase select=ant"(1)" axis=time,phase device=/ps nxy=5,4  #takes too long to do all ants
  #  gv pgplot.ps &
    echo "Interval = $int, change [y/n]? "
    set mans2 = $< 
    end

unset select 
set bpassnoex = `echo $bpass | tr '.' ' ' | awk '{print $1}'`
echo $bpassnoex

# calplot source=$bpassnoex xrange=$freq device=/xs
# echo "Apply GPBOOT? (y/n)?"
# set boot = $<
 #    if ($boot != "n") then
gpboot vis=$phase cal=$bpass # do here
# endif

uvspec vis=$phase interval=2e6 options=avall stokes=i axis=dfreq,amp device=/xs nxy=1,1

if ($phase != $target) then 
    echo "Copying delays from $phase to $target"
    gpcopy vis=$phase out=$target mode=copy
    uvcat vis=$target out=$target.cal options=unflagged
    unset stokes
    uvspec vis=$target.cal interval=2e6 options=avall axis=channel,amp device=/xs nxy=1,1 
  else
    echo "$phase is same as $target, uvcat to $phase.cal"
    uvcat vis=$phase out=$phase.cal options=unflagged
    unset stokes
    uvspec vis=$phase.cal interval=2e6 options=avall axis=channel,amp device=/xs nxy=1,1 log=rms.txt
endif

# gpcopy vis=$bpass out=$target.cal mode=copy options=nopass,nopol  # instead of gpboot BUT FUCKS PHASE CAL

#echo "Flag  channel 175 (y/n)?" 
#   set flag = $<
#   if ($flag == "y") then
#      uvflag vis=$target.cal line=channel,1,175 flagval=f
#   endif

cd ..
cp  /Users/stephencurran/data_logs/*.def $file-data/.
