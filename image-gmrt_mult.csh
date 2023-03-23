#!/bin/csh
#
#---------------------------------------------------------
#Script to invert, deconvolve and restore GMRT observations
#test run here on smaller data sets before mving to ASTRO
#./image.csh | tee image.log WILL WRITE TO TERMINAL/SCREEN AND FILE!
#GOOD FOR INTERACTIVE SHELLS

echo "Invert single [s], multiple [m] pols or multiple pols and dates [mp]? "
set pols = $<
if ($pols  == "s") then
    echo "Input directory (e.g. 16MAR.USB.RR)"
    set dir = $<
    cd $dir
    ls -d *.*
    echo "Input full source name to image, e.g. j0816+4823.320.cal: "
    set source = $<  #prompting for source name

    unset type
    if ($dir == "07JAN.USB.LL" || $dir == "07JAN.USB.RR") then
	set freq=0.336366
    endif
    if ($dir == "08JAN.USB.LL" || $dir == "08JAN.USB.RR") then
	set freq=0.336366
    endif
    if ($dir == "16MAR.USB.LL" || $dir == "16MAR.USB.RR") then
	set freq=0.320214
    endif
    echo "puthd in=$source/restfreq value=$freq"
    puthd in=$source/restfreq value=$freq
else
     if ($pols  == "m") then
	echo "Input date (e.g. 16MAR.USB)"
	set date = $<
	rm -rf $date.LL_RR
	mkdir $date.LL_RR
	echo "Creating $date.LL_RR where combined polarisations will be imaged" 
	ls -d $date.LL/*.cal
	ls -d $date.RR/*.cal
	echo "Input full source name to image, e.g. j0816+4823.320.cal: "
	set source = $<  #prompting for source name

	unset type
		    if ($date == "07JAN.USB" || $date == "08JAN.USB") then
		    set freq=0.336366
		    endif
		    if ($date == "16MAR.USB") then
		    set freq=0.320214
		    endif
	echo "puthd in=$source/restfreq value=$freq"
	puthd in=$date.LL/$source/restfreq value=$freq
	puthd in=$date.RR/$source/restfreq value=$freq
    else # mp - pols_dates
	echo "Input one of the dates (e.g. 07JAN.USB)"
	set date = $<
	ls -d $date.RR/*.cal
	echo "Input full source name to image, e.g. j0801+472.336.cal: "
	set source = $<  #prompting for source name
	rm -rf $source.pols_dates
	mkdir $source.pols_dates
	echo "Writing results to $source.pols_dates"
	unset type
	       if ($source == "j0801+472.336.cal") then
	       set freq=0.336366
	       endif
	       echo "puthd in=$source/restfreq value=$freq"
	     #  puthd in=*/$source/restfreq value=$freq #doens't work
	      # use this fix just now
	       puthd in=07JAN.USB.LL/$source/restfreq value=$freq
	       puthd in=07JAN.USB.RR/$source/restfreq value=$freq
	       puthd in=08JAN.USB.LL/$source/restfreq value=$freq
	       puthd in=08JAN.USB.RR/$source/restfreq value=$freq
    endif
endif

unset interval
unset log
unset options

echo "Need to invert first (y/n)?"
set inv = $<

if ($inv == "y") then
 #   echo "Remove $source.imap and $source.beam, which are created by invert (y/n)?"
    set rem = y #$<
      if ($rem == "y") then
      rm -Rf $source.imap $source.beam
       echo "Removed $source.imap and $source.beam"
endif


if ($pols  == "s") then
    uvspec vis=$source interval=2e6 options=avall axis=velocity,amp device=/xs nxy=1,1 log=vel.log 
    head vel.log
    tail vel.log
else
     uvspec vis=$date.LL/$source interval=2e6 options=avall axis=velocity,amp device=/xs nxy=1,1 log=vel.log 
#    uvspec vis=$date.RR/$source interval=2e6 options=avall axis=velocity,amp device=/xs nxy=1,1 log=vel_rr.log 
	head vel.log
	tail vel.log  #should also work for pols + dates
endif

#/scratch/sjc/./vel-range       # C program which will determine the following
#that was for astro, for biffa
/home/sjc/data/gmrt_dla_08/./vel-range

echo "First velocity channel [km/s]? "
set fich = $<
echo "Number of velocity channels:"
set noch = $<
echo "Increment ? "
set inc = $<

if ($pols  == "s") then
invert vis=$source map=$source.imap beam=$source.beam slop=0.5 line=vel,$noch,$fich,$inc,$inc cell=1 imsize=120 #imsize=120 #select="-ant(1)"

    else 
	if ($pols  == "m") then
	    invert vis=$date.LL/$source,$date.RR/$source map=$date.LL_RR/$source.imap beam=$date.LL_RR/$source.beam slop=0.5 line=vel,$noch,$fich,$inc,$inc imsize=120

     # TO GET AVERAGE OF THIS AS IMAGE COULD BE A MESS	    
    rm -rf $date.LL_RR.cat
    uvcat vis=$date.LL/$source,$date.RR/$source out=$date.LL_RR.cat stokes=ii options=unflagged

	else #pols + dates
	ls -d $source.pols_dates
	pwd
	echo "$source"
	    invert vis=*/$source map=$source.pols_dates/$source.imap beam=$source.pols_dates/$source.beam line=vel,$noch,$fich,$inc,$inc imsize=120
	echo "Inverting with cell=1 imsize=120"
#	endif
endif


echo "No of iterations to be used:"
set iter = $<
#set iter = 500;
#set iter = 10000;
#echo "Set for automation - can change if wanted"

#now invert has been done with the multiple files can redefine
if ($pols  == "s") then
    set source = $source
else
    if ($pols  == "m") then
    set source = $date.LL_RR/$source
    else 
    set source = $source.pols_dates/$source
    endif
endif  #so should only need one version of following

rm -Rf $source-$iter.model $source-$iter-restore.icln $source-$iter.m0 $source-$iter-mom0.ps $source-$iter-resid.icln 

unset model
unset options

echo "Running CLEAN on $source.imap (using $source.beam) with $iter iterations. Will write file to $source-$iter.model"

clean map=$source.imap beam=$source.beam out=$source-$iter.model niters=$iter #region=@cgcurs.region

echo "Now RESTORing image from $source-$iter.model, outputting to $source-$iter-restore.imap"

restor model=$source-$iter.model map=$source.imap beam=$source.beam mode=clean out=$source-$iter-restore.icln  #in order to run again

restor model=$source-$iter.model map=$source.imap beam=$source.beam mode=resid out=$source-$iter-resid.icln 

echo "Intensity map $source-$iter-restored.ps produced"

echo "Producing zeroth moment (intensity map) - $source-$iter.m0"

unset type
#puthd in=$source-$iter-restore.icln/restfreq value=$freq #needs rest freq too

moment in=$source-$iter-restore.icln out=$source-$iter.m0 mom=0 clip=0.001

cgdisp in=$source-$iter.m0 type=p range=0,0,lin device=/ps nxy=1,1 labtyp=hms,dms beamtyp=b,l,3 options=wedge,full #region=@cgcurs.region  # DOESN'T WORK WITH THIS

mv pgplot.ps $source-$iter-mom0.ps
echo "Intensity map saved as $source-$iter-mom0.ps"
#gzip $source-$iter-mom0.ps

df | grep sjc

#gv $source-$iter-mom0.ps

echo "If source larger than beam may want to consider extracting spectrum"
echo "Extracing spectrum..."

unset region
unset yrange
unset options 

imspect in=$source-$iter-restore.icln xaxis=dfreq yaxis=sum device=/ps log=$source-$iter.sca region=arcsec,box"(-1,-1,1,1)" #region=arcsec,box"(-1,-1,1,1)"
#made larger to cover beam

echo "yaxis=sum gives the total - the default is the average"
mv pgplot.ps $source-$iter-spectrum.ps
echo "Spectrum saved as $source-$iter-spectrum.ps"

du -sm $source*
#echo "Remove $source.imap and $source.beam, which are created by invert (y/n)?"
#    set rem2 = $<
#      if ($rem2 == "y") then
#      rm -Rf $source.imap $source.beam
#       echo "Removed $source.imap and $source.beam"
#endif
echo " "

imfit in=$source-$iter.m0 region=arcsec,box"(-30,-30,30,30)" object=gauss
