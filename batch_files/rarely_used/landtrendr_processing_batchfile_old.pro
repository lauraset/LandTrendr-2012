retall
;this batch file controls all of the landtrendr preprocessing steps

;---please state the landsat path/row ID and path to the data as described following each variable---
ppprrr = '047030' ; ex. '046026' -MUST BE PPP (path) and RRR (row), three digits for both path and row, use zero if needed ex: '0PP0RR'
path = 'F:\047030\'; ex. 'F:\046026\' -MAKE SURE THERE IS A "\" AT THE END, must point to a drive path, even if on a server 

;---please select the preprocessing options to run
;SELECT A MODE TO RUN THE PREPREPROCESSING PROCEDURES.
;procedure groups are 
;1 = process procedure group 1 (VCT and image prep)
;2 = process procedure group 2 (create a radiometric reference image)
;3 = process procedure group 3 (image normalization and cloudmask fixing)
;4 = process procedure group 4 (create tc images and timesync image lists)
;5 = process procedure group 5 (run segmention in evaluation mode)
;6 = process procedure group 6 (create segmention outputs)
;7 = manual mode
preprocessing_mode  = 7 

resume_segmentation = 0
                          
;MANUAL PRE-PROCESSING PROCEDURES - 
;!NOTE! if using mode 1,2,3,4,5,6 above then don't do anything here
;if using the manual option, select the processes to run
;1=do this, 0=don't do this, or as described
;-----------PROCESS GROUP 1-----------
vct_convert_glovis  = 0  ;unpackage glovis files for use in VCT
screen_images       = 0  ;use 0 if you don't want to screen any images, use 1 if you do (recommended)
prep_dem            = 0  ;!prepare a DEM for use in VCT
prep_nlcd           = 0  ;!prepare a landcover map for use in VCT
run_vct_for_masks   = 0  ;have VCT make a landcover mask
lt_convert_glovis   = 0  ;!unpackage glovis files for use in LandTrendr
vct_to_lt_masks     = 0  ;!convert the VCT landcover mask to LandTrendr "cloudmasks"
;-----------PROCESS GROUP 2-----------
create_ref_image    = 0  ;!create either a COST ref img or a from MODIS ref img
;-----------PROCESS GROUP 3-----------
fix_cloudmasks      = 0  ;!create cloudmask if VCT did not make one and fix specific cloudmasks as needed (need to define the date below) 
run_madcal          = 0  ;!normalized all images to a radiometric reference image
;-----------PROCESS GROUP 4-----------
create_tc           = 0  ;creates tasseled cap transformations from the normalized images
create_ts_img_list  = 0  ;creates TimeSync image lists
;-----------PROCESS GROUP 5-----------
segmentation_eval   = 0  ;runs landtrendr in evaluation mode
;-----------PROCESS GROUP 6-----------
segmentation        = 0  ;creates segmentation outputs
fit_to_vertices     = 0  ;use 1 to run bgw, 2 to run b5,b4,b3, 3 to run both
label_segs          = 0  ;extracts specific segment types
filter_labels       = 0  ;applys mmu spatial filtering and performs patch aggregation on labeled outputs 
dist_rec_snapshots  = 0  ;create disturbance and recovery slice outputs
dark_seg_outputs    = 0  ;creates an output used to make a forest-nonforest mask
;-----------MISC----------------------    
make_image_info     = 0  ;!create an image info file
make_composites     = 0  ;creates yearly image composites from normalized images
fix_hdrs            = 0  ;fixes hdr's that reference the upperleft corner of a pixel (1.0) instead of the center (1.5)
repop_img_info      = 0  ;0=do nothing, 1=repopulate all fields 2=do not repop normalized imgs 3=repop only cloudmasks
print_img_info      =[0] ;0=do nothing, 1=print image file, 2=print cloudmask, 3=print tc file, 4=print usearea file or [1,3,4] or [1,4]
convert_hdrs        = 0  ;converts "flat" headers to envi style headers; 1=convert headers (no overwrite), 2=convert headers (overwrite)
delete_lt_dates     = 0  ;!deletes every instance of a given date (define the date below)
add_years_to_hdr    = 0  ;adds the year of the bands to the fitted output headers (.hdr)

;-----------------------------------------------------------------------------------------------------------------
;#################################################################################################################
;CREATE_REF_IMAGE
;if using auto dark object picker, then use 0, if using manual selected values
;  enter values for bands 1-5 and 7 (6 in the LT stack) example: [32,14,8,4,1,1]
   dark_object_vals = [0] ;example: [32,14,8,4,1,1]
   ls_madcal_ref_img = 0 ;if using auto ref picker use 0, else use full path to a image you select (best option)

;#################################################################################################################
;RUN_MADCAL
;FIX_CLOUDMASKS
  ;if you're running all dates use 0 else follow instructions following the variable
  fix_only_these = [0] ;[<year><julian day>] ex: [2001215] or multiple ex. [2001215,1998198] as numbers not strings(no "")

;#################################################################################################################
;DELETE_LT_DATES
  ;if you want to delete every trace of a date list them here
  deletedate = [0]  ;[<year><julian day>] ex: [2001215] or multiple ex. [2001215,1998198] as numbers not strings(no "")

;#################################################################################################################
;-----------------------------------------------------------------------------------------------------------------
;|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
;---------DONE WITH DYNAMIC INPUTS--------
;|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
;-----------------------------------------------------------------------------------------------------------------
;#################################################################################################################


;---------STATIC INPUTS-------------
;PROJECTION
  ;either specify the full path to a file that is in the desired projection or enter "default" (include quotations)
  ;which will use the native from-GLOVIS projection.  To make a "proj_ref_file" follow these instructions:
  ;in arcmap... toolbox > data management > raster > raster dataset > create raster data set
  ;example inputs:
  ;output location: *\ppprrr\study_area\
  ;raster dataset name with extension: proj_ref_image.img (best to use .img or .tif)
  ;pixel type: 8_bit_unsigned (best to use because it produces smallest file size)
  ;spatial reference for raster: use the dialog to select a projection
  ;number of bands: 1 (best to use because it produces the smallest file size)
  proj_ref_file = "T:\Groups\Spacers-Annex\Scenes\ppprrr\study_area\prof_ref_file_albers.img"

;RADIOMETRIC NORMALIZATION REFERENCE SOURCE 
  ;how do you want to radiometrically normalize the image set?
  ;1 = use a modis image to normalize all images directly
  ;2 = use a landsat radiometric reference image to normalize all images
  ;3 = use a ledaps image to normalize all images directly 
  norm_method = 3

;RADIOMETRIC NORMALIZATION METHOD
  ;if the the above "RADIOMETRIC NORMALIZATION REFERENCE SOURCE " variable is set to 2 how do you want to...
  ;create the landsat radiometric reference image?
  ;1 = apply COST to a landsat reference image
  ;2 = use a MODIS NBAR image to normalize a landsat reference image
  ;3 = use an intersecting landsat image to use as the radiometric reference image !!!(need to specify the variable "radiometric_ref_img")!!! 
  ;4 = use a LEDAPS processed image (note that this requires preparation that is described in the documentation)
  madcal_ref_img = 4  
  radiometric_ref_img = 0 ;give path to a landsat image that you want to use as the radiometric reference image
  
;PREP_DEM
  input_dem = 0 ;give the full path if using your own DEM, else us 0 to have the program download SRTM DEM's

;PREP_NLCD
  nlcdimg = "T:\Groups\Spacers-Annex\Scenes\gis_data\NLCD2001_landcover_v2_2-13-11\nlcd2001_landcover_v2_2-13-11_padded.img" ;full path to land cover map

;VCT_TO_LT_MASKS
  water_off = 1  ;0=water WILL be included in the "cloudmask" - 1=water will NOT be included in the "cloudmask"
  snow_off = 0  ;0=snow WILL be included in the "cloudmask" - 1=snow will NOT be included in the "cloudmask"
  ;VCT creates a LOT of files that we do not use in LT, the delete_files keyword deletes all image files not used in LT
  delete_files = 1  ;use 1 to delete the unused files, use 0 to retain the files ***FYI the extra files are about 70gb***

;CREATE_REF_IMAGE
   ;if either option 1 from RADIOMETRIC NORMALIZATION REFERENCE SOURCE or option 2...
   ;from the RADIOMETRIC NORMALIZATION METHOD section...
   ;is selected then you must specify the full path to the MODIS NBAR image...
   ;else use 0.  target day and year refer to the year and day of the MODIS image...
   ;all three of these variables are ignored it the options do not apply to MODIS
   modis_img_path = "T:\Groups\Spacers-Annex\Scenes\gis_data\modis\mnbar5_2002209_oregon_lam_s16bit_padded.bsq" 
   target_day = 0      
   target_year = 2002  

;SEGMENTATION PARAMETER PATH
  segparamstxt = "T:\Groups\Spacers-Annex\Scenes\ppprrr\outputs\nbr_segmentation_parameters.txt" ;give full path to the segmentation parameter .txt file
  label_parameters_txt = "T:\Groups\Spacers-Annex\Scenes\ppprrr\outputs\nbr_label_parameters.txt" ;give full path to the label parameter .txt file
  class_code_txt = "T:\Groups\Spacers-Annex\Scenes\ppprrr\outputs\nbr_label_codes.txt" ;give full path to the class code .txt file
;--------------------------------------------------------------------------------------------------------------

run_params = {ppprrr:ppprrr,$
   path:path,$
   vct_convert_glovis:vct_convert_glovis,$
   prep_dem:prep_dem,$
   input_dem:input_dem,$
   prep_nlcd:prep_nlcd,$
   nlcdimg:nlcdimg,$
   run_vct_for_masks:run_vct_for_masks,$
   lt_convert_glovis:lt_convert_glovis,$
   water_off:water_off,$
   snow_off:snow_off,$
   delete_files:delete_files,$
   proj_ref_file:proj_ref_file,$
   vct_to_lt_masks:vct_to_lt_masks,$
   create_ref_image:create_ref_image,$
   make_image_info:make_image_info,$
   run_madcal:run_madcal,$
   create_tc:create_tc,$
   dark_object_vals:dark_object_vals,$
   ls_madcal_ref_img:ls_madcal_ref_img,$
   fix_cloudmasks:fix_cloudmasks,$
   fix_hdrs:fix_hdrs,$
   create_ts_img_list:create_ts_img_list,$
   print_img_info:print_img_info,$
   repop_img_info:repop_img_info,$
   convert_hdrs:convert_hdrs,$
   fix_only_these:fix_only_these,$
   make_composites:make_composites,$
   preprocessing_mode:preprocessing_mode,$
   madcal_ref_img:madcal_ref_img,$
   delete_lt_dates:delete_lt_dates,$
   deletedate:deletedate,$
   norm_method:norm_method,$
   target_day:target_day,$
   target_year:target_year,$
   modis_img_path:modis_img_path,$
   ;is_update:is_update,$
   segmentation_eval:segmentation_eval,$
   segmentation:segmentation,$
   resume:resume_segmentation,$
   label_segs:label_segs,$
   filter_labels:filter_labels,$
   dist_rec_snapshots:dist_rec_snapshots,$
   dark_seg_outputs:dark_seg_outputs,$
   screen_images:screen_images,$
   segparamstxt:segparamstxt,$
   label_parameters_txt:label_parameters_txt,$
   class_code_txt:class_code_txt,$
   fit_to_vertices:fit_to_vertices,$
   add_years_to_hdr:add_years_to_hdr,$
   radiometric_ref_img:radiometric_ref_img}
   
.run tbcd_v2   
landtrendr_preprocessor, run_params

