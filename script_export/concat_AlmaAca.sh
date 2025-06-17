#!/bin/bash

if_fitsin='yes'
if_uvaver='yes'

spw=$(seq 0 1 3)

dir_data='../fits/'
# 12m information
vis_12m=$(seq 0 1 3)
head_12m='ALMA12m'
fields_12m=$(seq 0 1 3)

# 7m information
vis_7m=$(seq 0 1 15)
head_7m='ACA7m'
fields_7m=$(seq 1 1 4)


declare -A restfreq
restfreq[0]=217.238530
restfreq[1]=215.700000
restfreq[2]=230.900000
restfreq[3]=232.694912


# 1. load FITS visibility to Miriad format

if [ $if_fitsin	== 'yes' ]
then
  for spw_ID in $spw
  do

    # 7m
    for field_ID in $fields_7m
    do
      for vis_ID in $vis_7m
      do  
          infile=$head_7m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
          rm -rf $infile'.miriad'
          fits in=$dir_data$infile'.fits' op='uvin' out=$infile'.miriad'
      done
    done

    #12m
    for field_ID in $fields_12m
    do
      for vis_ID in $vis_12m
      do  
          infile=$head_12m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
          rm -rf $infile'.miriad'
          fits in=$dir_data$infile'.fits' op='uvin' out=$infile'.miriad'
      done
    done

  done
fi




# 2. use the Miriad-uvaver task to concatenate the velocity-regridded Miriad visibilities
if [ $if_uvaver == 'yes' ]
then
  for spw_ID in $spw
  do

    # 7m
    for field_ID in $fields_7m
    do
      
      declare -a visarr_7m
      visarr_7m=()

      for vis_ID in $vis_7m
      do
        infile=$head_7m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
	visarr_7m+=("$infile.miriad")
      done


      # concatenate files
      outfile=$head_7m'_spw'$spw_ID'_'$field_ID'.miriad'

      if [ -e $outfile ]; then
        rm -rf $outfile
      fi

#      echo ${visarr_7m[*]}

      uvaver vis=${visarr_7m[*]} options='nocal,nopass,nopol' out=$outfile

#      cp -r $outfile ../../combine_all_chan/"all_combine$spw_ID"/

    done



    # 12m
    for field_ID in $fields_12m
    do

      declare -a visarr_12m
      visarr_12m=()

      for vis_ID in $vis_12m
      do
        infile=$head_12m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
	visarr_12m+=("$infile.miriad")
      done



      # concatenate files 
      outfile=$head_12m'_spw'$spw_ID'_'$field_ID'.miriad'

      if [ -e $outfile ]; then
        rm -rf $outfile
      fi
      
#      echo ${visarr_12m[*]}

      uvaver vis=${visarr_12m[*]} options='nocal,nopass,nopol' out=$outfile

#      cp -r $outfile ../../combine_all_chan/"all_combine$spw_ID"/

    done


  done

fi
