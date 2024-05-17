#!/bin/bash

### README -------------------------------------------------
#
# This script is revised from the script "combine_mosaic.sh"
# obtained from https://github.com/baobabyoo/almica
#
#
#
### Flow ---------------------------------------------------
#
#
# 1. Correct headers if necessary
#
# 2. Imaging ACA alone
#
# 3. Apply 12m primary beam
#
# 4. Re-generate ACA visibilities
#
# 5. Joint deconvolution
#
### --------------------------------------------------------


##### Parameters #########################################

# flow control -------------------------------------------
if_setheaders='yes'
if_duplicateACA='yes'
if_acaim='yes'
if_imag12mcheck='yes'
if_aca2almavis='yes'
if_acarewt='yes'
if_duplicateALL='yes'
if_finalim='yes'
if_cleanup='nyes'
if_reimmerge='nyes'
# --------------------------------------------------------


# global information -------------------------------------
linerestfreq='217.10498' # in GHz unit

# set the starting channel and number of channels
ch_start="1"
num_ch="20" #*****

# parameters for aca2almavis
nptsalma=1500
uvmaxalma=5.0 #****

# --------------------------------------------------------

# 12m data information
name_12m='ALMA12m'
fields_12m=$(seq 0 1 3)
pbfwhm_12m='26.2'

# 7m data information
name_7m='ACA7m'
fields_7m=$(seq 1 1 4)
pbfwhm_7m='45.57'


# - - Defining global variables - - - - - - - - - - - - -#
ch='channel,'$num_ch',1,1,1'
chout='channel,'$num_ch',1,1,1'

# ACA imagiing parameter
aca_cell='0.5'
aca_imsize='512,512'
aca_niters='80000'
aca_cutoff='0.025'

# 12m imaging parameter
alma_cutoff='0.015'
alma_niters='100000'
alma_cell='0.3'
alma_imsize='512,512'

# 12m + ACA imaging parameter
tsys_aca='1600.0'
final_cell='0.3'
final_imsize='512,512'
final_cutoff='0.006'
final_niters='3000000'

##########################################################



##### Reset headers to allow Miriad processing ###########

if [ $if_setheaders == 'yes' ]
then

   # 12m data
     for field_id in $fields_12m
     do
        pb="gaus("$pbfwhm_12m")"
	puthd in=$name_12m'_spw'$spw'_'$field_id'.miriad'/restfreq \
	      value=$linerestfreq type=d

	puthd in=$name_12m'_spw'$spw'_'$field_id'.miriad'/telescop \
              value='single' type=a
        puthd in=$name_12m'_spw'$spw'_'$field_id'.miriad'/pbtype \
              value=$pb type=a
     done

   # 7m data
     for field_id in $fields_7m
     do

	pb="gaus("$pbfwhm_7m")"
	puthd in=$name_7m'_spw'$spw'_'$field_id'.miriad'/restfreq \
              value=$linerestfreq type=d
        puthd in=$name_7m'_spw'$spw'_'$field_id'.miriad'/telescop \
	      value='single' type=a
	puthd in=$name_7m'_spw'$spw'_'$field_id'.miriad'/pbtype \
              value=$pb type=a
     done


fi

##########################################################


##### Make a copy of relevant files for imaging ##########
if [ $if_duplicateACA == 'yes' ]
then

   rm -rf intermediate_vis
   mkdir intermediate_vis

   # ACA
   cp -r $name_7m*'.miriad' ./intermediate_vis/

fi
##########################################################



##### Imaging ACA visibilities ###########
if [ $if_acaim == 'yes' ]
then


   rm -rf aca.map
   rm -rf aca.beam
   invert "vis=./intermediate_vis/*" options=systemp,double,mosaic \
	  map=aca.map beam=aca.beam cell=$aca_cell imsize=$aca_imsize robust=2.0

   rm -rf aca.model    
   mossdi map=aca.map beam=aca.beam out=aca.model gain=0.1 \
	  niters=$aca_niters cutoff=$aca_cutoff options=positive

   rm -rf aca.clean
   rm -rf aca.residual
   restor map=aca.map beam=aca.beam model=aca.model \
	  mode=clean out=aca.clean
   restor map=aca.map beam=aca.beam model=aca.model \
          mode=residual out=aca.residual

fi
##########################################################

##### Imaging 12m to check with final image ##############
if [ $if_imag12mcheck == 'yes' ]
then

    rm -rf alma.map
    rm -rf alma.beam

    invert vis=$name_12m'_'*'.miriad' map=alma.map beam=alma.beam robust=2.0 \
           options=systemp,double,mosaic cell=$alma_cell imsize=$alma_imsize

    rm -rf alma.model
    mossdi map=alma.map beam=alma.beam out=alma.model gain='0.1' \
           niters=$alma_niters cutoff=$alma_cutoff

    rm -rf alma.clean
    rm -rf alma.residual
    restor map=alma.map beam=alma.beam model=alma.model \
           mode=clean out=alma.clean
    restor map=alma.map beam=alma.beam model=alma.model \
           mode=residual out=alma.residual


fi
##########################################################



##### Converting ACA image to 12m visibilities ########
if [ $if_aca2almavis == 'yes' ]
then


   rm -rf uv_random.miriad
   uvrandom npts=$nptsalma freq=$linerestfreq inttime=10 uvmax=$uvmaxalma nchan=$num_ch \
            gauss=true out=uv_random.miriad


   for field_id in $fields_12m
   do

	rm -rf single_input.alma_$field_id.temp.miriad
	rm -rf temp.beam
        invert vis=$name_12m'_spw0_'$field_id'.miriad'   \
               imsize=$alma_imsize cell=$alma_cell \
               map=single_input.alma_$field_id.temp.miriad beam=temp.beam 
	#	line=$ch

        # applying ALMA primary beam to ACA clean model
	rm -rf aca.demos
	rm -rf aca.demos1

	if [ $aca_method == 'clean' ]
        then
           demos map=aca.model vis=$name_12m'_spw0_'$field_id'.miriad' out=aca.demos
        else
           demos map=aca.model vis=$name_12m'_spw0_'$field_id'.miriad' out=aca.demos # options=detaper
        fi

	mv aca.demos1 aca.demos

        # regrid ACA maps
        rm -rf single_input.alma_$field_id.regrid.miriad
        regrid in=aca.demos tin=single_input.alma_$field_id.temp.miriad \
               out=single_input.alma_$field_id.regrid.miriad \
               project=sin


	# simulate visibilities
	rm -rf single_input.alma_$field_id.uvmodel.miriad
        uvmodel vis=uv_random.miriad model=single_input.alma_$field_id.regrid.miriad \
		options=replace,imhead "select=uvrange(0,$uvmaxalma)" \
                out=single_input.alma_$field_id.uvmodel.miriad


        rm -rf temp
        uvputhd vis=single_input.alma_$field_id.uvmodel.miriad hdvar='telescop' \
                varval='ALMA' type=a out=temp
        rm -rf single_input.alma_$field_id.uvmodel.miriad
        mv temp single_input.alma_$field_id.uvmodel.miriad

	outname=single_input.alma_$field_id.uvmodel.miriad
        pb="gaus("$pbfwhm_12m")"
        puthd in=$outname/telescop \
              value='single' type=a
        puthd in=$outname/pbtype \
              value=$pb type=a


   done



fi
##########################################################



##### Manually reweight the ACA visibilities ##########
if [ $if_acarewt == 'yes' ]
then

   echo '##### Reweighting ACA visibility assuming Tsys ='$tsys_aca' Kelvin'

   for field_id in $fields_12m
   do

         outname=single_input.alma_$field_id.uvmodel.rewt.miriad
         rm -rf $outname
         uvputhd vis=single_input.alma_$field_id.uvmodel.miriad hdvar=systemp type=r length=1 \
                 varval=$tsys_aca out=$outname
         puthd in=$outname/jyperk value=1.0 type=r

         pb="gaus("$pbfwhm_12m")"
         puthd in=$outname/telescop \
               value='single' type=a
         puthd in=$outname/pbtype \
               value=$pb type=a
	

   done

fi

##########################################################



##### Duplicating all visibilities for imaging ###########
if [ $if_duplicateALL == 'yes' ]
then

   rm -rf final_vis
   mkdir final_vis

   # 12m
   cp -r $name_12m'_'*'.miriad' ./final_vis/

   # ACA
   cp -r single_input.alma_*.uvmodel.rewt.miriad ./final_vis/

fi
##########################################################


##### Final imaging ######################################
if [ $if_finalim == 'yes' ]
then


   rm -rf combined.map
   rm -rf combined.beam
   invert vis=./final_vis/* options=systemp,double,mosaic \
          map=combined.map beam=combined.beam cell=$final_cell imsize=$final_imsize robust=2.0

   rm -rf combined.model
   mossdi map=combined.map beam=combined.beam out=combined.model gain=0.1 \
          niters=$final_niters cutoff=$final_cutoff
   

   rm -rf combined.clean
   rm -rf combined.residual
   restor map=combined.map beam=combined.beam model=combined.model \
          mode=clean out=combined.clean
   restor map=combined.map beam=combined.beam model=combined.model \
          mode=residual out=combined.residual

   rm -rf combined.clean.fits
   fits in=combined.clean op=xyout out=combined.clean.fits
   rm -rf combined.dirty.fits
   fits in=combined.map op=xyout out=combined.dirty.fits
   rm -rf combined.model.fits
   fits in=combined.model op=xyout out=combined.model.fits
   rm -rf combined.residual.fits
   fits in=combined.residual op=xyout out=combined.residual.fits
   rm -rf combined.beam.fits
   fits in=combined.beam op=xyout out=combined.beam.fits

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



   rm -rf combined.clean.reimmerge
   immerge in=combined.clean,TP_12CO.vel.image.regrid.miriad factor=$acatp_conv_f \
	   out=combined.clean.reimmerge

   rm -rf combined.clean.reimmerge.fits
   fits in=combined.clean.reimmerge op=xyout out=combined.clean.reimmerge.fits

fi

##########################################################
