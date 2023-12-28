import os


#### Define variables #################################

ms_list = {
            'uid___A002_Xad93f4_X2f03.ms.split.cal',
            'uid___A002_Xaee04e_X2599.ms.split.cal',
            'uid___A002_Xaee04e_X2987.ms.split.cal',
            'uid___A002_Xaee04e_X2dc3.ms.split.cal',
            'uid___A002_Xb52d1b_X2341.ms.split.cal',
            'uid___A002_Xb54d65_X2e35.ms.split.cal',
            'uid___A002_Xb54d65_X3230.ms.split.cal',
            'uid___A002_Xb58564_Xcf.ms.split.cal',
            'uid___A002_Xb5a3ad_X1f3.ms.split.cal',
            'uid___A002_Xb5a3ad_X659.ms.split.cal',
            'uid___A002_Xb5a3ad_Xa3d.ms.split.cal',
            'uid___A002_Xb5aa7c_X3b08.ms.split.cal',
            'uid___A002_Xb5aa7c_X431a.ms.split.cal',
            'uid___A002_Xb5ee5a_Xa20.ms.split.cal',
            'uid___A002_Xb66ea7_X9c01.ms.split.cal',
            'uid___A002_Xb7a3f8_X9d67.ms.split.cal'

          }
#######################################################



#### Split tha data ###################################

for ms in ms_list:

    outputvis = ms + '.split'
    os.system('rm -rf '+ outputvis )
    split(
          vis = ms , 
          datacolumn = 'data',
          field = 'Sgr_A_star',
          outputvis = outputvis

         )


#######################################################


