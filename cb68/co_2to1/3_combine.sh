#!/bin/bash

# Flow ---------------------------------------------------
#
# 1. Convert input data from FITS to Miriad format 
# 2. Correct headers if necessary
# 3. Generate TP visibilities at ACA pointings
# 4. Jointly image ACA and TP visibilities
#
# --------------------------------------------------------


# flow control -------------------------------------------
if_setheaders='nyes'
if_imag7m='nyes'
if_tpdeconvolve='nyes'
if_tp2vis='nyes'
if_tprewt='yes'
if_duplicateACATP='yes'
if_acaim='yes'
if_cleanup='nyes'
if_reimmerge='nyes'
#
# --------------------------------------------------------


# global information -------------------------------------
linerestfreq='230.5380' # in GHz unit

ch_start="1"
numch="1"
ch="channel,$numch,$ch_start,1,1"

# set the cellsize and dimension for the ACA images
aca_cell='0.5'
aca_imsize='256'
aca_cutoff='0.0001'
aca_niters='50000000'

# parameters for deconvolving the TP image
cutoff_tp='2.5'
niters_tp='15000'

# parameters for tp2vis
npts='1500'     # number of visibility points to use when running uvrandom
uvmax='10'      # maximum uv distance
tsys_tp='300000' # an artificial tsys for relative weighting


# ACA+TP imaging parameter
acatp_niters='5000000'
acatp_cutoff='0.0001'
acatp_method='clean'
# --------------------------------------------------------

# 7m data information
name_7m='aca7m_co_2to1'
fields_7m=$(seq 0 1 12)   # set the iterator to loop from pointing 0 to 12
pbfwhm_7m='45.54'

# TP data information
name_tp='tp_co_2to1_part'
pbfwhm_tp='25.25'
#crval3_tp=188.3402      # reset velocity header (important if this is not ALMATP)
#cdelt3_tp=-0.07937064   # reset velocity header (important if this is not ALMATP)
#crpix3_tp=1             # reset velocity header (important if this is not ALMATP)
tp_brightness_unit="Jy/beam"
tp_conv_f=1.0  # a constant to multiple to all pixels of your TP image.
tp_add_f=0.0   # a constant to add to all pixels of your TP image.

##########################################################


##### Reset headers to allow Miriad processing ###########

if [ $if_setheaders == 'yes' ]
then

   # 7m data (set the primary beam)
   for field_id in $fields_7m
   do
        pb="gaus("$pbfwhm_7m")"
        puthd in=$name_7m'_'$field_id'_part.miriad'/telescop \
	     	  value='single' type=a
		puthd in=$name_7m'_'$field_id'_part.miriad'/pbtype \
              value=$pb type=a
   done

   # TP (set beam size and velocity headers)
   puthd in=$name_tp'.image.miriad'/bmaj value=$pbfwhm_tp,arcsec type=double
   puthd in=$name_tp'.image.miriad'/bmin value=$pbfwhm_tp,arcsec type=double
   puthd in=$name_tp'.image.miriad'/bpa  value=0,degree type=double
   puthd in=$name_tp'.image.miriad'/ctype3 value='VELO-LSR' type=ascii
   puthd in=$name_tp'.image.miriad'/cunit3 value='km/s    ' type=ascii
   #puthd in=$name_tp'.image.miriad'/crval3 value=$crval3_tp type=double
   #puthd in=$name_tp'.image.miriad'/cdelt3 value=$cdelt3_tp type=double
   #puthd in=$name_tp'.image.miriad'/crpix3 value=$crpix3_tp type=double

   pb="gaus("$pbfwhm_tp")"
   puthd in=$name_tp'.image.miriad'/telescop \
         value='single' type=a
   puthd in=$name_tp'.image.miriad'/pbtype \
         value=$pb type=a


   # apply a multiplication constant tp_conv_f to the TP image
   rm -rf single_input.miriad
   if [ $tp_unit_convert == 'yes' ]
   then
     maths exp="(($name_tp.image.miriad)*$tp_conv_f)" \
		   out=single_input.miriad options=unmask
   else
     cp -r $name_tp'.image.miriad' single_input.miriad
   fi

   puthd in=single_input.miriad/bmaj value=$pbfwhm_tp,arcsec type=double
   puthd in=single_input.miriad/bmin value=$pbfwhm_tp,arcsec type=double
   puthd in=single_input.miriad/bpa  value=0,degree type=double
   puthd in=single_input.miriad/bunit value='Jy/beam' type=ascii

fi

##########################################################

##### Imaging ACA alone just for comparison ##############
if [ $if_imag7m == 'yes' ]
then
	rm -rf aca.map aca.beam
	invert vis=$name_7m'_'*'_part.miriad' map=aca.map beam=aca.beam robust=2.0 \
		   options=systemp,mosaic,double cell=$aca_cell imsize=$aca_imsize 

	rm -rf aca.model
	mossdi map=aca.map beam=aca.beam out=aca.model gain=0.1 \
		   niters=$aca_niters cutoff=$aca_cutoff options=positive
	
	rm -rf aca.clean aca.residual
	restor map=aca.map beam=aca.beam model=aca.model mode=clean out=aca.clean
	restor map=aca.map beam=aca.beam model=aca.model mode=residual out=aca.residual

fi

##### Deconvolve TP map ##################################

if [ $if_tpdeconvolve == 'yes' ]
then

   # Generate the TP Gaussian Beam
   rm -rf tp_beam
   imgen out=tp_beam imsize=$aca_imsize cell=$aca_cell \
         object=gaussian \
         spar=1,0,0,$pbfwhm_tp,$pbfwhm_tp,0


   for field_id in $fields_7m
   do
   		# Creat template ACA maps for regriding TP maps
        rm -rf 'single_input.aca_'$field_id'.temp.miriad'
		rm -rf temp.beam
		echo $ch
        invert vis=$name_7m'_'$field_id'_part.miriad'   \
               imsize=$aca_imsize cell=$aca_cell options=double \
               map='single_input.aca_'$field_id'.temp.miriad' beam=temp.beam line=$ch

		# Regrid TP maps
        rm -rf 'single_input.aca_'$field_id'.regrid.miriad'       
        regrid in=single_input.miriad tin='single_input.aca_'$field_id'.temp.miriad' \
               out='single_input.aca_'$field_id'.regrid.miriad' \
	    	   project=sin

        # Deconvolve the TP Map
		rm -rf 'single_input.aca_'$field_id'.model.miriad'
        clean map='single_input.aca_'$field_id'.regrid.miriad' beam=tp_beam \
	    	  out='single_input.aca_'$field_id'.model.miriad' options=positive\
	      	  niters=$niters_tp cutoff=$cutoff_tp gain='0.05'

		# Restore the deconvolved TP map for a sanity check
		rm -rf 'single_input.aca_'$field_id'.clean.miriad'
        restor map='single_input.aca_'$field_id'.regrid.miriad' beam=tp_beam \
	    	   model='single_input.aca_'$field_id'.model.miriad' \
               mode=clean out='single_input.aca_'$field_id'.clean.miriad'

        rm -rf 'single_input.aca_'$field_id'.residual.miriad'
        restor map='single_input.aca_'$field_id'.regrid.miriad' beam=tp_beam \
               model='single_input.aca_'$field_id'.model.miriad' \
               mode=residual out='single_input.aca_'$field_id'.residual.miriad'

		# Apply the ACA primary beam to TP clean models
		rm -rf temp1
		rm -rf 'single_input.aca_'$field_id'.demos.miriad'
        demos map='single_input.aca_'$field_id'.model.miriad' \
		      vis=$name_7m'_'$field_id'_part.miriad' \
	      	  out=temp
		mv temp1 'single_input.aca_'$field_id'.demos.miriad'

   done


   # clean up
   rm -rf temp.beam
   rm -rf tp_beam
   rm -rf single_input.aca_*.temp.miriad

fi

##########################################################



##### Convolve TP map to visibility ######################

if [ $if_tp2vis == 'yes' ]
then

   rm -rf uv_random.miriad
   uvrandom npts=$npts freq=$linerestfreq inttime=10 uvmax=$uvmax nchan=$numch \
            gauss=true out=uv_random.miriad

   
   for field_id in $fields_7m
   do

#        rm -rf single_input.aca_$field_id'.regrid.miriad'
#        regrid in=single_input.aca_$field_id.demos.miriad \
#               tin=single_input.alma_$field_id.temp.miriad \
#               out=single_input.alma_$field_id.regrid.miriad \
#               project=sin

		rm -rf 'single_input.aca_'$field_id'.uvmodel.miriad'
#        uvmodel vis=uv_random.miriad model=single_input.aca_$field_id.demos.miriad \
#                'select=uvrange(0,13)' options=replace,imhead \
#                out=single_input.aca_$field_id.uvmodel.miriad
        uvmodel vis=uv_random.miriad model='single_input.aca_'$field_id'.demos.miriad' \
                options=replace,imhead \
                out='single_input.aca_'$field_id'.uvmodel.miriad' "select=uvrange(0,$uvmax)" \


        rm -rf temp
        uvputhd vis='single_input.aca_'$field_id'.uvmodel.miriad' hdvar='telescop' \
				varval='TP' type=a out=temp
        rm -rf 'single_input.aca_'$field_id'.uvmodel.miriad'
        mv temp 'single_input.aca_'$field_id'.uvmodel.miriad'


   done

fi

##########################################################



##### Manually reweight the TP visibilities ##############
if  [ $if_tprewt == 'yes' ]
then

   echo '##### Reweighting TP visibility assuming Tsys ='$tsys_tp' Kelvin'

   for field_id in $fields_7m
   do

	 outname='single_input.aca_'$field_id'.uvmodel.rewt.miriad'
     rm -rf $outname
     uvputhd vis='single_input.aca_'$field_id'.uvmodel.miriad' hdvar=systemp type=r length=1 \
		 	 varval=$tsys_tp out=$outname
	 puthd in=$outname/jyperk value=1.0 type=r

	 pb="gaus("$pbfwhm_7m")"
         puthd in=$outname/telescop \
               value='single' type=a
         puthd in=$outname/pbtype \
               value=$pb type=a


   done

fi

##########################################################




##### Make a copy of relevant files for imaging ##########
if [ $if_duplicateACATP == 'yes' ]
then

   rm -rf intermediate_vis
   mkdir intermediate_vis

   # ACA and TP
   for field_id in $fields_7m
   do
       cp -r $name_7m'_'$field_id'_part_i.miriad' ./intermediate_vis/
	   cp -r 'single_input.aca_'$field_id'.uvmodel.rewt.miriad' ./intermediate_vis/
   done

fi
##########################################################



##### Imaging ACA and TP visibilities together ###########
if [ $if_acaim == 'yes' ]
then

   rm -rf acatp.map
   rm -rf acatp.beam
   invert "vis=./intermediate_vis/*" options=systemp,double,mosaic \
	  	  map=acatp.map beam=acatp.beam cell=$aca_cell imsize=$aca_imsize robust=2.0

   rm -rf acatp.model
   mossdi map=acatp.map beam=acatp.beam out=acatp.model gain=0.1 \
	      niters=$acatp_niters cutoff=$acatp_cutoff options=positive

   rm -rf acatp.clean
   rm -rf acatp.residual
   restor map=acatp.map beam=acatp.beam model=acatp.model \
	  	  mode=clean out=acatp.clean
   restor map=acatp.map beam=acatp.beam model=acatp.model \
          mode=residual out=acatp.residual
   rm -rf acatp.beam.fits
   fits in=acatp.beam op=xyout out=acatp.beam.fits
   fits in=acatp.clean op=xyout out=acatp.clean.fits

fi
##########################################################



##### Removing meta data #################################
if [ $if_cleanup == 'yes' ]
then
   echo '##### Removing meta data #############'
   rm -rf ./*uvmodel*
   rm -rf ./*regrid*
   rm -rf ./*temp*
   rm -rf ./single_input.miriad
   rm -rf ./single_input*.restor.miriad
   rm -rf ./single_input*.residual.miriad
   rm -rf ./temp.*
   rm -rf ./*.temp
   rm -rf ./uv_random.miriad
   rm -rf ./acatp*
   rm -rf ./intermediate_vis
   rm -rf ./*demos*
   rm -rf ./*deconv*
fi
##########################################################



##### Re-immerge #########################################

if [ $if_reimmerge == 'yes' ]
then


   # Gegrid TP maps
   rm -rf TP.vel.image.regrid.miriad
   regrid in=$name_tp'.image.miriad' tin=combined.clean \
          out=TP.vel.image.regrid.miriad \
          project=sin

   rm -rf combined.clean.reimmerge
   immerge in=combined.clean,TP.vel.image.regrid.miriad factor=1.0 \
		   out=combined.clean.reimmerge

   rm -rf combined.clean.reimmerge.fits
   fits in=combined.clean.reimmerge op=xyout out=combined.clean.reimmerge.fits

fi

##########################################################
