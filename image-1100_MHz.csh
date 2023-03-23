#!/bin/csh
#
#---------------------------------------------------------
#Script to invert, deconvolve and restore GMRT observations
#test run here on smaller data sets before mving to ASTRO
#./image.csh | tee image.log WILL WRITE TO TERMINAL/SCREEN AND FILE!
#GOOD FOR INTERACTIVE SHELLS


ls -d *.cal
echo "Input full source name to image: "
set source = $<  #prompting for source name

unset interval
unset log
unset options

#uvindex vis=$source  GIVES FIRST CHANNEL SO NO GOOD

#echo "Have to add rest freq"
#echo "Rest freq. [GHz]:"
#set  freq = $<
#unset type
#puthd in=$source/restfreq value=$freq
# DONE IN prep-gmrt.csh AS puthd BUGGERED


# echo "Need to invert first (y/n)?"
set inv = y #$<
      rm -Rf $source.imap $source.beam
   
  uvspec vis=$source interval=2e6 options=avall axis=velocity,amp device=/xs nxy=1,1 log=vel.log select=pol"(LL)",pol"(RR)"  #
    #emacs vel.log &										     
   wc -l vel.log										    #
   head vel.log										    #
   tail vel.log										    #
   /Users/stephencurran/C/astro/./vel-range  							    #
   echo "First velocity channel [km/s]? "							    #
   set fich = $<										    #
   echo "Number of velocity channels:"								    #
   set noch = $<										    #
   echo "Increment ? "										    #
   set inc = $<										    #

 invert vis=$source map=$source.imap beam=$source.beam sup=0 options=double slop=0.5 cell=0.2 imsize=200 line=vel,$noch,$fich,$inc,$inc select=pol"(LL)",pol"(RR)" # incase cross pols in

endif

echo "No of iterations to be used:"
#set iter = $<
set iter = 500;
echo "Set to 500 for automation - can change if wanted"
echo "Running CLEAN on $source.imap (using $source.beam) with $iter iterations. Will write file to $source-$iter.model"
rm -Rf $source-$iter.model $source-$iter-restore.icln $source-$iter.m0 $source-$iter-mom0.ps
unset model
unset options
clean map=$source.imap beam=$source.beam out=$source-$iter.model niters=$iter options = negstop   # give this a bash#region=@cgcurs.region

echo "Now RESTORing image from $source-$iter.model, outputting to $source-$iter-restore.imap"

restor model=$source-$iter.model map=$source.imap beam=$source.beam mode=clean out=$source-$iter-restore.icln  #in order to run again

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
 echo " "

# cp image-gmrt.csh ../.
# cp image-gmrt.csh /Users/stephencurran/data_logs/2012/.   # to keep updated
 
