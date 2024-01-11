#!/bin/bash

##### README ####################################################
#
# History:
# v0 (2023.Dec.05): revised from the script "combine_single.csh" 
#                   obtained from
#                   https://github.com/baobabyoo/almica
# v1 (2023.Jan.11): complete the step 0,1
#		    revise the step 2 in progress
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
if_fitstomiriad='nyes'

#   modify headers (important and hard when you're combining
#   data taken from different observatories).
if_setheaders='nyes'

#
if_imagingACA='yes'

#
if_im12aca='nyes'

if_acavis='nyes'

if_jointlyimag='nyes'

if_fitsoutput='nyes'

##### Parameters ################################################

# name of your spectral line. I usually use this as part of my output filename.
# In this case, it is the CO J=2-1 line.
# You can set this to anything you like. It does not matter.
#linename="co_2to1"

# The rest frequency of your line. The sets the velocity grid.
linerestfreq=230.53800000 # in GHz unit

# The directory where your visibility data are located.
visdir_12m="../fits/12m/" 
visdir_7m='../fits/7m/'

# The ids (integers) of the data files (see the notes at the beginning).
fields_12m=$(seq 0 1 0)
fields_7m=$(seq 1 1 1)

# The primary beam FWHM of the files with id=1, id=2, and id=3, i.e.,
# for the visibility files XXX_1.fits, XXX_2.fits, and XXX_3.fits
pbfwhm_12m='26.2'
pbfwhm_7m='45.57'

# Filename of the ACA visibility
name_12m='ALMA12m'
name_7m='ACA7m'

# spectral window
spw=$(seq 0 1 0)

# Filename of all of the ALMA 12-m visibility
all12mvis='co_2to1_1.uv.miriad,co_2to1_2.uv.miriad' # ***

# Filename of one of the ALMA 12-m visibility. It can be any one of those.
# This is for the script to extract header information.
Mainvis='co_2to1_1.uv.miriad' # ***

# A relative Tsys for adjusting weighting.
tsys_single='60'


##### parameters for ACA cleaning ##################

aca_imsize='128,128'  # size of the initial ACA image in units of pixels
aca_cell='0.8'        # cell size for the initial ACA image in units of arcsecond.
aca_niters=1500       # number of iterations for the initial ACA imaging (per channel)
aca_cutoff=0.15       # cutoff level fo the initial ACA imaging      
aca_options='positive'  # options for the initial ACA imaging (in the clean task)
      
# The region in the ACA image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
aca_region='boxes(45,45,85,85)' # ***


##### paramaters for final imaging ###################

robust=2.0                # Briggs robust parameter for the final imaging.
imsize='6000,6000' # ***  # size of the final image in units of pixels
cell='0.01' # ***         # cell size for the final image in units of arcsecond.
niters=1000000 # ***      # number of iterations for the final imaging (per channel)
cutoff=0.005 # ***        # cutoff level fo the final imaging

# The region in the final image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
region='boxes(1200,1200,4800,4800)' # ***

# tapering FWHM in units of arcsecond.
# You can comment out the tapering part in the final cleaning command if it is not needed.
taper='0.1,0.1' # ***

#################################################################
# Notes.
# 
# The FWHM of the ALMA primary beam is 19" at 300 GHz for a 12 m 
# antenna and a 33" for a 7 m antenna, and scales linearly with 
# wavelength
#
# ###############################################################


##### Step 0. Converting FITS visibilities to Miriad format #####

if [ $if_fitstomiriad == 'yes' ]
then

  for spw_id in $spw
  do 
    # 12m data
    echo '########## Importing 12m data ##########'
    for field_id in $fields_12m
      do
 	# 12m data
 	filename=$name_12m'_spw'$spw_id'_'$field_id'.cvel.fits' 
 	outname=$name_12m'_spw'$spw_id'_'$field_id'.uv.miriad'
	rm -rf $outname

	fits in=$visdir_12m$filename\
        op=uvin \
        out=$outname
      done

   # 7m data
#   echo '########## Importing ACA data ##########'
#   for field_id in $fields_7m
#     do
#	filename=$name_7m'_spw'$spw_id'_'$field_id'.cvel.fits' # ***
#	outname=$name_7m'_spw'$spw_id'_'$field_id'.uv.miriad'
#        rm -rf $outname

#        fits in=$visdir_7m$filename \
#        op=uvin \
#        out=$outname

#     done

  done
fi

#################################################################



##### Step 1. Set headers #######################################

if [ $if_setheaders == 'yes' ]
then

  for spw_id in $spw
  do

    # 12m data (set the primary beam)
    # this step is necessary for certain distributions of Miriad
    # (i.e., in case it does not recognize ALMA, ACA, or TP)
    for field_id in $fields_12m
    do
       pb="gaus('$pbfwhm_12m')"
       puthd in=$name_12m'_spw'$spw_id'_'$field_id'.uv.miriad'/telescop \
             value='single' \
             type=a

       puthd in=$name_12m'_spw'$spw_id'_'$field_id'.uv.miriad'/pbtype \
             value=$pb \
             type=a

       puthd in=$name_12m'_spw'$spw_id'_'$field_id'.uv.miriad'/restfreq \
             value=$linerestfreq \
             type=d
    done

    # 7m data (set the primary beam)
    # this step is necessary for certain distributions of Miriad
    # (i.e., in case it does not recognize ALMA, ACA, or TP)
    for field_id in $fields_7m
    do
       pb="gaus('$pbfwhm_7m')"
       puthd in=$name_7m'_spw'$spw_id'_'$field_id'.miriad'/telescop \
             value='single' \
             type=a

       puthd in=$name_7m'_spw'$spw_id'_'$field_id'.miriad'/pbtype \
             value=$pb \
             type=a

       puthd in=$name_7m'_spw'$spw_id'_'$field_id'.miriad'/restfreq \
             value=$linerestfreq \
             type=d
    done

  done
fi

#################################################################


##### Step 2. Imaging ACA alone #################################
if [ $if_imagingACA == 'yes' ]
then

  for spw_id in $spw
  do
    for field_id in $fields_7m
    do  
      if [ -e $name_7m.acamap.temp ]; then
         rm -rf $name_7m.acamap.temp
      fi

      if [ -e $name_7m.acabeam.temp ]; then
         rm -rf $name_7m.acabeam.temp
      fi

      if [ -e $name_7m.acamodel.temp ]; then
         rm -rf $name_7m.acamodel.temp
      fi

      if [ -e $name_7m.acaresidual.temp ]; then
         rm -rf $name_7m.acaresidual.temp
      fi

      if [ -e $name_7m.acaclean.temp ]; then
         rm -rf $name_7m.acaclean.temp
      fi


      # produce dirty image (i.e., fourier transform)
      invert vis=$name_7m'_spw'$spw_id'_'$field_id'.miriad' \
             map=$name_7m.acamap.temp   \
             beam=$name_7m.acabeam.temp \
             options=double    \
             imsize=$aca_imsize \
             cell=$aca_cell

      # perform cleaning (i.e., produce the clean model image)
      clean map=$name_7m.acamap.temp \
            beam=$name_7m.acabeam.temp \
            out=$name_7m.acamodel.temp \
            niters=$aca_niters \
            cutoff=$aca_cutoff \
            region=$aca_region \
            options=$aca_options

      # produce the clean image (for inspection)
      restor map=$name_7m.acamap.temp \
             beam=$name_7m.acabeam.temp \
             mode=clean \
             model=$name_7m.acamodel.temp \
             out=$name_7m.acaclean.temp

      # produce the residual image (for insepction)
      restor map=$name_7m.acamap.temp \
             beam=$name_7m.acabeam.temp \
             mode=residual \
             model=$name_7m.acamodel.temp \
             out=$name_7m.acaresidual.temp
   
     done
  done

fi
#################################################################


##### Step 3. Implement the 12m dish PB to ACA ##################
if [ $if_ip12aca == 'yes' ]
then

  if (-e $linename.acamodel.regrid.temp) then
     rm -rf $linename.acamodel.regrid.temp
  fi

  # regriding the model image to the original imagesize
  regrid in=$linename.acamodel.temp \
         tin=$linename.acamap.temp \
         out=$linename.acamodel.regrid.temp

  if (-e $linename.acamodel.regrid.pbcor.temp) then
     rm -rf $linename.acamodel.regrid.pbcor.temp
  fi

  # correct the aca primary beam to the model
  linmos in=$linename.acamodel.regrid.temp \
         out=$linename.acamodel.regrid.pbcor.temp

  if (-e $linename.acamodel.regrid.pbcor.demos.temp1) then
     rm -rf $linename.acamodel.regrid.pbcor.demos.temp1
  fi

  # implement (i.e., multiply) the 12m array primary beam
  demos map=$linename.acamodel.regrid.pbcor.temp \
        vis=$Mainvis \
        out=$linename.acamodel.regrid.pbcor.demos.temp

  if (-e $linename.acamodel.regrid.pbcor.demos.temp) then
     rm -rf $linename.acamodel.regrid.pbcor.demos.temp
  fi

  mv $linename.acamodel.regrid.pbcor.demos.temp1 $linename.acamodel.regrid.pbcor.demos.temp

fi

#################################################################

##### Step 4. Generate ACA visibility model #####################
if [ $if_acavis == 'yes' ]
then

  if (-e $ACAvis'.uvmodel') then
     rm -rf $ACAvis'.uvmodel'
  fi

  # replacing the visibility amplitude and phase based on the input image model
  uvmodel vis=$ACAvis \
          model=$linename.acamodel.regrid.pbcor.demos.temp \
          options='replace' \
          out=$ACAvis'.uvmodel'

  # change the system temperature of the re-generated, primary beam tapered, ACA visibility.
  # this is to adjust the relative weight to the ALMA 12m visibility.
  uvputhd vis=$ACAvis'.uvmodel' \
          hdvar=systemp \
          type=r \
          varval=$tsys_single \
          length=1 \
          out=$ACAvis'.uvmodel.temp'

  if (-e $ACAvis'.uvmodel') then
     rm -rf $ACAvis'.uvmodel'
  fi

  mv $ACAvis'.uvmodel.temp' $ACAvis'.uvmodel'

fi
#################################################################

##### Step 5. Jointly image ACA visibility model with 12m #######
if [ $if_jointlyimag == 'yes' ]
then

  ## INVERTING :
  if (-e $linename.map.temp ) then
     rm -rf $linename.map.temp
  fi

  if (-e $linename.beam.temp ) then
     rm -rf $linename.beam.temp
  fi

  # produce the dirty image
  invert vis=$all12mvis,$ACAvis'.uvmodel'      \
         map=$linename.map.temp                \
         beam=$linename.beam.temp              \
         options='systemp,double'              \
         robust=$robust                        \
#         line=channel,1,90,1,1 \
         imsize=$imsize       \
         fwhm=$taper          \
         cell=$cell


  ## CLEANING: 
  if (-e $linename.model.temp ) then
     rm -rf $linename.model.temp
  fi

  # produce the clean model
  clean map=$linename.map.temp \
        beam=$linename.beam.temp \
        out=$linename.model.temp \
        niters=$niters \
        region=$region \
        cutoff=$cutoff



  # RESTORING:

  if (-e $linename.clean.temp ) then
     rm -rf $linename.clean.temp
  fi

  if (-e $linename.residual.temp ) then
     rm -rf $linename.residual.temp
  fi

  # produce the final clean image
  restor map=$linename.map.temp \
         beam=$linename.beam.temp \
         mode=clean \
         model=$linename.model.temp \
         out=$linename.clean.temp

  # produce the final residual image
  restor map=$linename.map.temp \
         beam=$linename.beam.temp \
         mode=residual \
         model=$linename.model.temp \
         out=$linename.residual.temp



  # FINAL PBCOR:

  if (-e $linename.clean.pbcor.temp ) then
     rm -rf $linename.clean.pbcor.temp
  fi

  # the Miriad task to perform primary beam correction
  linmos in=$linename.clean.temp out=$linename.clean.pbcor.temp

fi
#################################################################



##### Step 6. FITS output #######################################
if [ $if_fitsoutput == 'yes' ]
then

  fits in=$linename.clean.pbcor.temp \
       op=xyout \
       out=$linename.clean.pbcor.fits

  fits in=$linename.clean.temp \
       op=xyout \
       out=$linename.clean.fits

  fits in=$linename.residual.temp \
       op=xyout \
       out=$linename.residual.fits

  fits in=$linename.map.temp \
       op=xyout \
       out=$linename.dirty.fits

  fits in=$linename.beam.temp \
       op=xyout \
       out=$linename.beam.fits

  if (-e fits_images) then
     mv $linename.clean.pbcor.fits ./fits_images/
     mv $linename.clean.fits ./fits_images/
     mv $linename.residual.fits ./fits_images/
     mv $linename.dirty.fits ./fits_images/
     mv $linename.beam.fits ./fits_images/
  else
     mkdir fits_images
     mv $linename.clean.pbcor.fits ./fits_images/
     mv $linename.clean.fits ./fits_images/
     mv $linename.residual.fits ./fits_images/
     mv $linename.dirty.fits ./fits_images/
     mv $linename.beam.fits ./fits_images/
  fi

  if (-e $linename ) then
     rm -rf $linename
     mkdir $linename
  else
     mkdir $linename
  fi

  mv ./$linename.*.temp ./$linename

fi
#################################################################


##### Cleaning up ###############################################
# rm -rf $linename*.uv.miriad*
#################################################################



##### Ending ####################################################

#################################################################
