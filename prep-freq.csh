#!/bin/csh
#
#---------------------------------------------------------
#Script to prepare data before imaging - this version splits into frequnecy of interest for (too) wide-band data
#ls 

#echo "After prep-gmrt to reduce data size by freq range [data already split]"
ls -d *
echo "Change to directory to work in if not already there"

#echo "Input directory [e.g 58481.948884108795-data]: "
#set dir = $<  
#cd $dir

ls -d *.*
# du -sm *.*


echo "Freq exentsion [e.g. 329]: "
 set ext = $<  
 

    echo "Start channel: "
    set f1 =  $< 
    echo "End channel: "
    set f2 =  $< 

    @ nchan = $f2 - $f1

set dir = $ext\_chans\_$f1\_to\_$f2 

   mkdir $dir
    du -sm *.$ext

echo "Input bandpass calibrator (full names): "
set bpass =  $< 
echo "Input phase calibrator: "
set phase = $< 
echo "Input target (enter even if same as $phase): "
set target = $< 

echo "Rest freq. [GHz]:"
set  freq = $<


    echo "uvaver from $f1 to $f2, no chans = $nchan"
 
    unset select
    unset options
   uvaver vis=$bpass line=channel,$nchan,$f1,1,1 options=nopass,nocal out=$dir/$bpass      # options as AFTER uvsplit, etc
  #  set bpass = $bpass\_$f1\_to\_$f2
   uvaver vis=$phase line=channel,$nchan,$f1,1,1 options=nopass,nocal out=$dir/$phase   
   #    set phase = $phase\_$f1\_to\_$f2
      # set target = $phase
if ($phase != $target) then 
    uvaver vis=$target line=channel,$nchan,$f1,1,1 options=nopass,nocal out=$dir/$target
  #  set target = $target\_$f1\_to\_$f2
endif 

cd $dir

  #redefine
   
    set all = $bpass,$phase,$target
    echo "NOW WORKING ON $all"

set int = 180

uvplt vis="$all" axis=time,amp device=/xs nxy=1,1 options=nobase  # $all replaces $bpass,$phase,$target
uvplt vis=$target axis=time,amp device=/xterm nxy=1,1 options=nobase

 puthd in=$bpass/restfreq value=$freq  #wildcards don't work - put in later once sources dsignated   
 puthd in=$phase/restfreq value=$freq  #
if ($phase != $target) then  
    puthd in=$target/restfreq value=$freq  
endif 

mfcal vis=$bpass interval=$int
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

set int = 180
mfcal vis=$phase interval=$int

echo "Interval = $int, change [y/n]? "
 set mans2 = $< 
 while ($mans2 == "y") 
	echo "Input interval: "
	set int = $< 
   mfcal vis=$phase interval=$int
    gpplt vis=$phase device=/xs options=bandpass nxy=5,4
    echo "Interval = $int, change [y/n]? "
    set mans2 = $< 
    end

unset select 
set bpassnoex = `echo $bpass | tr '.' ' ' | awk '{print $1}'`
echo $bpassnoex
gpboot vis=$phase cal=$bpass # do here

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

 cp ~/data_logs/*.def .

# cd ..
