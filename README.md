# multi-dish
Scripts to reduce data from large radio telescopes (GMRT, VLA)

These scripts run the [MIRIAD](https://www.atnf.csiro.au/computing/software/miriad/) package for the reduction of interferometric (mult-dish) data. While this is fine for the six dish Australia Telescope Compact Array (ATCA), which has 15 antenna baseline pairs and limited bandwidth, for the large interfometers - the Giant Metrewave Radio Telescope ([GMRT](http://www.gmrt.ncra.tifr.res.in)) and Very Large Array ([VLA](https://public.nrao.edu/telescopes/vla/)), up to 30 dishes (435 antenna pairs) and very low frequnecies (for hydrogen at high redshift) in a hostile radio frequency environment, mean that  some automation is required.

prep-freq.csh - loads and calibrates the data
prep-freq.csh - is a version of this which splits the data down into smaller frequency bands (for wide-band data)
rms.csh - will measure the rms noise level of each baseline pair
flag_rms.csh - will remove the baseline pairs with a noise level above a specified threshold
image-*csh  - will produce an image and 3D cube of the remaining data (by frequency band)

![](https://raw.githubusercontent.com/steviecurran/multi-dish/refs/heads/main/GMRT.jpg)
