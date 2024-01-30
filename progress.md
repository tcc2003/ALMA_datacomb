# GCDprogress
This is a file to record the progress of doing the project, which is about the abundance of Deuterium in the Galactic Center.
### 2024.Jan.30
The error message
```
linmos: CVS Revision 1.5, 2013/07/20 04:39:18 UTC

WARNING: Setting RMS to 1.0 for all images.
Processing image ACA7m.acamodel.regrid.temp
### Fatal Error [linmos]:  Bad parameter for gaussian beam
```
is due to the mistake of datatype in setting the header of pbtype.
Approach
Modify ```pb="gaus('$pbfwhm_7m')"``` to ```pb="gaus($pbfwhm_7m)"```, so does the 12m array.

### 2024.Jan.25
Select the certain high-emission channels in the task by specify "line" in task "invert" to the convenience and speed of the following execution. The way to check the high-emission channel is use "imview" in casa655. By following its spectra, I chose the high_emission part by specify its velocity.

### 2024.Jan.24
Approach (to resolve the error in "invert")
1. In **exportfits_7m.py**, I replace the task "split" with "mstransform" in CASA version 6.5.5.
2. Execute an individual calibrated data with field 1 and spw 0 step by step, and I finally do the task "invert" in the MIRIAD software package sucessfully.
3. Run the script **exportfits_7m.py**, **concat_7m.py** and **combineAlmaAca.sh** seperately to identify where the error is occurring.
4. I confirm that the error is related to task "split".


### 2024.Jan.18
After trying to do the task "invert", I got the error message.
```
invert: CVS Revision 1.12, 2012/05/25 12:53:15 UTC

### Informational [invert]:  Using uniform weighting with robust unset is not recommended
Reading the visibility data ...
Making cubes with 1532 planes
Visibilities accepted: 0
### Warning [invert]:  Visibilities rejected: 52852
### Fatal Error [invert]:  No visibilities to map
```

### 2024.Jan.11
After executing step 0,1 ,I am not sure how to appropriately set the value of certain parameters in ACA imaging (like "cutoff","niters","region").

### 2023.Dec.28
1. In order to differentiate the script of imaging and the subsequent analysis,I rename the directory. In addition, I add the script for analyzing the final spectra.
2. Complete the rough structure of ***combine_AlmaAca.sh*** script.
 


### 2023.Nov.28-29
Write a script to perform velocity regridding and concatenate the velocity-regridded visibilities.
After testing this script with field 0, the converting Miriad file is unable to open.
```
fits: CVS Revision 1.24, 2013/03/14 17:33:00 UTC

### Fatal Error [fits]:  Error opening ACA7m_vis0_spw0_0.miriad, in UVOPEN(new): File exists
```
After checking the originated data in CASA, I find that the field 0 is not target source but calibrator. In addition, I try to revise the range of field of ***exportuvfits_failed.sh***.




### 2023.Nov.21
1. As converting ACA FITS to Miriad by Miriad-fits task, I see the error message
   
    ```
    fits: CVS Revision 1.24, 2013/03/14 17:33:00 UTC

    ### Fatal Error [fits]:  Serious inconsistency in file size
    ``` 
   This is caused by different central frequency on each visibility due to Doppler effect.
 
2. Approach
    1. Change the way to export the ACA CASA ms.
      - Export individual ACA CASA .ms files without running cvel and concat.
        (The script with cvel and concat is ***exportfits_failed.py***)
      - Write a BASH for-loop to read individual FITS visibilities using the Miriad-fits task.
      - Use the Miriad-uvredo task to perform velocity regridding (may need to think about changing restfreq, etc)
      - Use the Miriad-uvaver task to concatenate the velociy-regridded Miriad visibilities.
      - For some details, see issuse **Error converting ACA CASA ms to Miriad files**
    2. Revise the combine_mosaic.sh script. Directly use the velocity-regridded Miriad visibilities without loading from FITS.

