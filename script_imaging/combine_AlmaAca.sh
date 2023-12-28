#!/bin/bash

##### README ####################################################
#
# History:
# v0 (2023.Dec.05): revised from the script "combine_single.csh" 
#                   obtained from
#                   https://github.com/baobabyoo/almica
#
#################################################################

#### Flow control ###############################################
#
# 1. Convert input data from FITS to Miriad format
#
# 2. Correct headers if necessary
#
# 3. Imaging ACA alone
#
# 4. Implement the 12m dish PB to ACA
#
# 5. Generate ACA visibility model
#
# 6. Jointly image ACA visibility model with 12m
#
# 7. Output FITS
#
#################################################################

# flow control #######################################
#
#   converting FITS files to Miriad format files
if_fitstomiriad='yes'
#   modify headers (important and hard when you're combining
#   data taken from different observatories).
if_setheaders='nyes'
#   deconvolve single-dish image. Miriad allows you to use
#   MEM or clean to do this. However, MEM is somewhat tricky
#   to control for unexperienced users. If you are not familiar
#   with image deconvolution, it is better to use clean.
if_imagingACA='nyes'
#   convert single dish (i.e., total-power or tp) image to visibility
if_tp2vis='nyes'
#   re-weight the total power visibility by adjusting tsys artificially
if_tprewt='nyes'
#   duplicate the ACA and TP visibilities and move them to a isolated folder.
#   This is convenient for the scripted imaging in the later time.
#   The filesize is not big anyway.
if_duplicateACATP='nyes'
#   creating ACA + TP image
if_acaim='nyes'
#   rescale the flux density of the ACA+TP clean model.
#   This is in case of absolute flux calibration errors.
#   If this is not a concern, simply use a scaling factor 1.0.
if_acatpscale='nyes'
#   convert the ACA+TP clean model to ALMA visibility.
if_tp2almavis='nyes'
#   reweight the ACA+TP visibility model before jointly imaging with the
#   ALMA 12m-dish data (i.e., artificially adjusting the Tsys parameter).
if_acatprewt='nyes'
#   Duplicate all visibility files to a isolated folder before
#   jointly imaging all data.
if_duplicateALL='nyes'
#   Producing the final image. I recommend to continue doing this within
#   Miriad since it is fast. You can also do the following steps in CASA
#   if that is what you prefer. Those are normal imaging steps.
if_finalim='nyes'
#   Removing some files that were produced in the steps,
#   which are useful for troubleshooting but not for science analysis.
#   Some of those are image cubes and can have very big sizes.
if_cleanup='nyes'
#   Linearly combine the single-dish image for one last time.
#   This is useful since clean does not conserve total flux in general.
if_reimmerge='nyes'
#


##### Parameters ################################################

# name of your spectral line. I usually use this as part of my output filename.
# In this case, it is the CO J=2-1 line.
# You can set this to anything you like. It does not matter.
linename="co_2to1"

# The rest frequency of your line. The sets the velocity grid.
linerestfreq=230.53800000 # in GHz unit

# The directory where your visibility data are located.
visdir_12m="../fits/12m/" 
visdir_7m='../fits/7m/'

# The ids (integers) of the data files (see the notes at the beginning).
fields_12m=$(seq 0 1 3)
fields_7m=$(seq 1 1 4)

# The primary beam FWHM of the files with id=1, id=2, and id=3, i.e.,
# for the visibility files XXX_1.fits, XXX_2.fits, and XXX_3.fits
pbfwhm_12m='26.2'
pbfwhm_7m='45.57'

# Filename of the ACA visibility
name_12m='ALMA12m'
name_7m='ACA7m'

# spectral window
spw=$(seq 0 1 3)

# Filename of all of the ALMA 12-m visibility
all12mvis='co_2to1_1.uv.miriad,co_2to1_2.uv.miriad' # ***

# Filename of one of the ALMA 12-m visibility. It can be any one of those.
# This is for the script to extract header information.
Mainvis='co_2to1_1.uv.miriad' # ***

# A relative Tsys for adjusting weighting.
tsys_single='60'

# parameters for ACA cleaning - - - - - - - - - -

# size of the initial ACA image in units of pixels
acaimsize='128,128'

# cell size for the initial ACA image in units of arcsecond.
acacell='0.8'

# number of iterations for the initial ACA imaging (per channel)
acaniters=1500

# cutoff level fo the initial ACA imaging
acacutoff=0.15
      
# options for the initial ACA imaging (in the clean task)
acaoptions='positive' 
      
# The region in the ACA image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
acaregion='boxes(45,45,85,85)' # ***


# paramaters for final imaging  - - - - - - - - - -

# Briggs robust parameter for the final imaging.
robust=2.0

# size of the final image in units of pixels
imsize='6000,6000' # ***

# cell size for the final image in units of arcsecond.
cell='0.01' # ***

# number of iterations for the final imaging (per channel)
niters=1000000 # ***

# cutoff level fo the final imaging
cutoff=0.005 # ***

# The region in the final image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
region='boxes(1200,1200,4800,4800)' # ***

# tapering FWHM in units of arcsecond.
# You can comment out the tapering part in the final cleaning command if it is not needed.
taper='0.1,0.1' # ***

#################################################################
# Notes.
# 
# The FWHM of the ALMA primary beam is 21" at 300 GHz for a 12 m 
# antenna and a 35? for a 7 m antenna, and scales linearly with 
# wavelength
#
# ###############################################################


##### Step 0. Converting FITS visibilities to Miriad format #####

if [ $if_fitstomiriad == 'yes' ]
then

   # 12m data
   echo '########## Importing 12m data ##########'
   for field_id in $fields_12m
     do
	# 12m data
	filename=$name_12m'_'$field_id'.cvel.fits' 
	outname=$name_12m'_'$field_id'.uv.miriad'
	rm -rf $outname

	fits in=$filename\
        stokes='ii' \
        op=uvin \
        out=$outname
     done

   # 7m data
   echo '########## Importing ACA data ##########'
   for field_id in $fields_7m
     do
	filename=$name_7m'_'$field_id'.cvel.fits' # ***
	outname=$name_7m'_'$field_id'.uv.miriad'
        rm -rf $outname

        fits in=$filename \
        stokes='ii' \
        op=uvin \
        out=$outname

     done

fi

#################################################################



##### Step 1. Set headers #######################################

if [ $if_setheaders == 'yes' ]
then
  
  # 12m data (set the primary beam)
  # this step is necessary for certain distributions of Miriad
  # (i.e., in case it does not recognize ALMA, ACA, or TP)
  for field_id in $fields_12m
  do
     pb="gaus('$pbfwhm_12m')"
     puthd in=$name_12m'_'$field_id'.uv.miriad'/telescop \
           value='single' \
           type=a

     puthd in=$linename'_'$field_id'.uv.miriad'/pbtype \
           value=$pb \
           type=a

     puthd in=$linename'_'$field_id'.uv.miriad'/restfreq \
           value=$linerestfreq \
           type=d
  done

  # 7m data (set the primary beam)
  # this step is necessary for certain distributions of Miriad
  # (i.e., in case it does not recognize ALMA, ACA, or TP)
  for field_id in $fields_7m
  do
     pb="gaus('$pbfwhm_7m')"
     puthd in=$name_7m'_'$field_id'.uv.miriad'/telescop \
           value='single' \
           type=a

     puthd in=$name_7m'_'$field_id'.uv.miriad'/pbtype \
           value=$pb \
           type=a

     puthd in=$name_7m'_'$field_id'.uv.miriad'/restfreq \
           value=$linerestfreq \
           type=d
  done

fi

#################################################################


##### Step 2. Imaging ACA #######################################
if [$if_imagingACA == 'yes' ]
then
  if (-e $linename.acamap.temp ) then
     rm -rf $linename.acamap.temp
  fi

  if (-e $linename.acabeam.temp ) then
     rm -rf $linename.acabeam.temp
  fi

  if (-e $linename.acamodel.temp ) then
     rm -rf $linename.acamodel.temp
  fi

  if (-e $linename.acaresidual.temp ) then
     rm -rf $linename.acaresidual.temp
  fi

  if (-e $linename.acaclean.temp ) then
     rm -rf $linename.acaclean.temp
  fi


  # produce dirty image (i.e., fourier transform)
  invert vis=$ACAvis \
         map=$linename.acamap.temp   \
         beam=$linename.acabeam.temp \
         options=double    \
         imsize=$acaimsize \
         cell=$acacell

  # perform cleaning (i.e., produce the clean model image)
  clean map=$linename.acamap.temp \
        beam=$linename.acabeam.temp \
        out=$linename.acamodel.temp \
        niters=$acaniters \
        cutoff=$acacutoff \
        region=$acaregion \
        options=$acaoptions

  # produce the clean image (for inspection)
  restor map=$linename.acamap.temp \
         beam=$linename.acabeam.temp \
         mode=clean \
         model=$linename.acamodel.temp \
         out=$linename.acaclean.temp

  # produce the residual image (for insepction)
  restor map=$linename.acamap.temp \
         beam=$linename.acabeam.temp \
         mode=residual \
         model=$linename.acamodel.temp \
         out=$linename.acaresidual.temp

 fi
#################################################################




