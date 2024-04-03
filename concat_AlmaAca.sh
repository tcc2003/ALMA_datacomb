#!/bin/bash

if_fitsin='yes'
if_uvaver='yes'

spw=$(seq 0 1 0)

# 12m information
vis_12m=$(seq 0 1 3)
head_12m='ALMA12m'
fields_12m=$(seq 1 1 1)

# 7m information
vis_7m=$(seq 0 1 15)
head_7m='ACA7m'
fields_7m=$(seq 1 1 4)


declare -A restfreq
restfreq[0]=217.238530
restfreq[1]=215.700000
restfreq[2]=223.900000
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
          fits in=$infile'.fits' op='uvin' out=$infile'.miriad'
      done
    done

    #12m
    for field_ID in $fields_12m
    do
      for vis_ID in $vis_12m
      do  
          infile=$head_12m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
          rm -rf $infile'.miriad'
          fits in=$infile'.fits' op='uvin' out=$infile'.miriad'
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
      allvis_7m=''
      for vis_ID in $vis_7m
      do
        infile=$head_7m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
        allvis_7m+=$infile'.miriad,'
      done
    done

    # 12m
    for field_ID in $fields_12m
    do
      allvis_12m=''
      for vis_ID in $vis_12m
      do
        infile=$head_12m'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
        allvis_12m+=$infile'.miriad,'
      done
    done

  done


  allvis_7m=${allvis_7m::-1}
  allvis_12m=${allvis_12m::-1}


  echo $allvis_12m


  # concatenate files
  for spw_ID in $spw
  do
    # 7m
    for field_ID in $fields_7m
    do  
      outfile=$head_7m'_spw'$spw_ID'_'$field_ID'.miriad'
      
      if [ -e $outfile ]; then
      	rm -rf $outfile
      fi

      uvaver vis=$allvis_7m options='nocal,nopass,nopol' out=$outfile

    done

    # 12m
    for field_ID in $fields_12m
    do
      outfile=$head_12m'_spw'$spw_ID'_'$field_ID'.miriad'

      if [ -e $outfile ]; then
        rm -rf $outfile
      fi

      uvaver vis=$allvis_12m options='nocal,nopass,nopol' out=$outfile

    done

  done



fi
