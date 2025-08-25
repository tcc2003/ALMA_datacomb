#!/bin/bash

if_fitsin='yes'
if_uvredo='yes'
if_uvaver='yes'

vis_IDs=$(seq 0 1 15)
filehead='ACA7m'
spw=$(seq 0 1 0)
field=$(seq 1 1 1)
#line_parameter='velocity,1532,-1230,1.57,1.57'
linepara_test='velocity,2,83.67,1.57,1.57'
restfreq[0]=217.238530
restfreq[1]=215.700000
restfreq[2]=223.900000
restfreq[3]=232.694912


# 1. load FITS visibility to Miriad format

if [ $if_fitsin	== 'yes' ]
then
  for spw_ID in $spw
  do
    for field_ID in $field
    do
      for vis_ID in $vis_IDs
      do  
          infile=$filehead'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
          rm -rf $infile'.miriad'
          fits in=$infile'.fits' op='uvin' out=$infile'.miriad'
      done
    done
  done
fi


# 2. use Miriad-uvredo to perform velocity regridding
if [ $if_uvredo == 'yes' ]
then
 for spw_ID in $spw
  do
    for field_ID in $field
    do

      for vis_ID in $vis_IDs
      do
  
        # remove output file if exist
        infile=$filehead'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
        rm -rf $infile'_uvputhd.miriad'
        rm -rf $infile'_uvredo.miriad'
  
        # include restfrequency in the header
        uvputhd vis=$infile'.miriad' hdvar='restfreq' type='d' \
		varval=${restfreq[$spw_ID]} \
		out=$infile'_uvputhd.miriad'
  
        # syntax of the line parameter: nchan, start, width, step
        uvredo vis=$infile'_uvputhd.miriad' out=$infile'_uvredo.miriad' \
       	       stokes='ii' options='velocity' velocity='lsr' \
  	       line=$linepara_test
        rm -rf $infile'_uvputhd.miriad'
  
        # use the Miriad-uvspec task to check the regrided velocity, for example
        #uvspec vis='ACA7m_vis1_spw0_1_uvredo.miriad' device=/xw options=nobase,avall nxy=1,1 axis=vel,amp
  
      done
    done
  done

fi


# 3. use the Miriad-uvaver task to concatenate the velocity-regridded Miriad visibilities
if [ $if_uvaver == 'yes' ]
then
  for spw_ID in $spw
  do
    for field_ID in $field
    do
      vis=''
      for vis_ID in $vis_IDs
      do
        infile=$filehead'_vis'$vis_ID'_spw'$spw_ID'_'$field_ID
        vis+=$infile'_uvredo.miriad,'
      done
    done
  done

  vis=${vis::-1}

  # concatenate files
  for spw_ID in $spw
  do
    for field_ID in $field
    do  
      outfile=$filehead'_spw'$spw_ID'_'$field_ID'.miriad'
      rm -rf $outfile
      uvaver vis=$vis options='nocal,nopass,nopol' out=$outfile
    done
  done
 
fi
