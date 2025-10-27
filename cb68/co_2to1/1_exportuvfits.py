import os

##############################################################
'''
  Exporting Pipeline calibrated CASA MS to FITS files
'''
##### Define variables #######################################

# The CASA MS to export
ms_path_7m = '../../calibrated/7m_13fields/'
all_7m_ms = [               
               os.path.join(ms_path_7m, 'uid___A002_X10a341d_X46df.ms'),
               os.path.join(ms_path_7m, 'uid___A002_X10a341d_X4a19.ms')
            ]


# The fields and spectral windows to export
CO_spwID_7m = '34'
molecule = 'co_2to1'

fields_7m = range(0,13)

# The head of the output FITS file name
head_7m = 'aca7m'

# velocity gridding in the output
vel_start  = '-25.0248km/s' #end : 39 km/s
vel_width  = '0.159km/s'
vel_nchan  = 400

# the certain high-emission channels for test
mode = 'velocity'
outframe = 'LSRK'

# rest frequency (central frequency in spw setup)
restfreq = '230.538GHz'

##############################################################
thesteps = []
step_title = {
              0: 'Output listobs files',
              1: 'Split individual target source fields in to MS files',
              2: 'Continuum subtraction',
			  3: 'Export the observations of each visibility on each field to FITS'
             }

try:
  print ('List of steps to be executed ...', mysteps)
  thesteps = mysteps
except:
  print ('global variable mysteps not set.')

if (thesteps==[]):
  thesteps = range(0,len(step_title))
  print ('Executing all steps: ', thesteps)


##### output listobs file #####################################

mystep = 0
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])


  for vis in all_7m_ms:
    listfile = vis + '.listobs'
#    os.system('rm -rf ' + listfile)
#    listobs(vis = vis, listfile = listfile)

##############################################################



##### Split individual target source fields in to MS files ###

mystep = 1
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  print('########################################\n')
  print('Exporting 7m mosaic fields: ', fields_7m)

  for visID in range(len(all_7m_ms)):
    vis = all_7m_ms[visID]

    for fieldID in fields_7m:
        splitms = head_7m + '_vis' + str(visID) + '_' + molecule + '_' + str(fieldID) + '.ms'
        os.system('rm -rf ' + splitms )

        # split CO 2-1 data
        mstransform(
                     vis = vis, 
                     outputvis  = splitms,
                     field = str(fieldID+3), 
					 spw   = CO_spwID_7m,
                     restfreq = restfreq )
#                     regridms = True,
#					 mode  = mode,
#					 outframe = outframe,
#					 nchan = vel_nchan,
#					 start = vel_start,
#					 width = vel_width
#                   )

#################################################################################

##### Continuum subtraction #####################################################
mystep = 2
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  for visID in range(len(all_7m_ms)):
    vis = all_7m_ms[visID]
	
    for fieldID in fields_7m:
        split_ms = head_7m + '_vis' + str(visID) + '_' + molecule + '_' + str(fieldID) + '.ms'
        
        uvcontsub(
                   vis = split_ms,
				   fitspw = '0:20~120;400~500',
				   want_cont = True
				 )

#################################################################################

##### Export the observations of each visibility on each field to FITS ##########
mystep = 3
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  for visID in range(len(all_7m_ms)):
    vis = all_7m_ms[visID]

    for fieldID in fields_7m:
      filenamehead = head_7m + '_vis' + str(visID) + '_' + molecule + '_' + str(fieldID)
      vis  = filenamehead + '.ms.contsub'
      fits = filenamehead + '.fits'

      os.system('rm -rf ' + fits )
      exportuvfits(
                    vis = vis, 
                    fitsfile = fits,
                    multisource = False, 
					combinespw = False
                  )

###############################################################

