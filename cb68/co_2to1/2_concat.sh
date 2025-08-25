#!/bin/bash
if_fitsin='yes'
if_uvaver='yes'

molecule='co_2to1'

dir_data='./'

# 7m information
visnum_7m=$(seq 0 1 1)
head_7m='aca7m'
fields_7m=$(seq 0 1 12)

restfreq='230.538GHz'

# 1. load FITS visibility to Miriad format
if [ $if_fitsin	== 'yes' ]
then
  # 7m
  for field_ID in $fields_7m
  do
    for vis_ID in $visnum_7m
    do
      infile=$head_7m'_vis'$vis_ID'_'$molecule'_'$field_ID
      rm -rf $infile'.miriad'

      fits in=$dir_data$infile'.fits' op='uvin' out=$infile'.miriad'
    done
  done

fi


# 2. convert polarization and concatenate the velocity-regridded Miriad visibilities
if [ $if_uvaver == 'yes' ]
then

    # 7m
    for field_ID in $fields_7m
    do
      
      declare -a visarr_7m
      visarr_7m=()

      for vis_ID in $visnum_7m
      do
        infile=$head_7m'_vis'$vis_ID'_'$molecule'_'$field_ID
	    visarr_7m+=("$infile.miriad")
      done

      #echo ${visarr_7m[*]}

      # concatenate files
      outfile=$head_7m'_'$molecule'_'$field_ID'.miriad'
      rm -rf $outfile

      uvaver vis=${visarr_7m[*]} options='nocal,nopass,nopol' \
	         stokes=i out=$outfile

#      cp -r $outfile ../../combine/

    done

fi
