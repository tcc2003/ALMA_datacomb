# GCDprogress
This is a file to record the progress of doing the project, which is about the abundance of Deuterium in the Galactic Center.

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

