**************************************************************
Some notes on the image analysis code - IDL

Written by: Milena Pawlik, September 2016
Last edited: June 2017
**************************************************************

The code can be used on a single image or a set of many images. As it was written specifically for SDSS data it contains many options to use only when dealing with SDSS imaging but other data sets can be analysed as well (although this needs some polishing). It can be run on either real or mock images - separate procedures provided.

Requires the following IDL routines (included):
- shuffle.pro
- writecol.pro.

This README is also available in rich text, which is slightly easier to read. 

1. Input
------
The required input is in the form of FITS files.

For SDSS data, given the object coordinates, small images can be cut out of the SDSS imaging fields. Alternatively, this option could be skipped if cut-outs already available. For any other data, the required input should be in the form of cut-outs centred roughly on the `central pixel’ of the object of interest (precise centring and image trimming options are available).

2. Directories
-----------
The path to the input directory is specified as an input parameter. The input directory, e.g. ‘TESTSAMPLE’ , should contain a subdirectory ‘data’  with all images for the analysis. The `output’ directory is created automatically within the parent directory.  

3. Running the code
----------------
The analysis is done in two steps: 1) preparation of the cut-outs, during which the image size is checked and adjusted if necessary, with an option of defining the image centre; 2) analysis of the resulting cut-outs. 

	3.1 For pre-prepared cutouts (any data)

		3.1.1 Preparing images for analysis 
	
		run_imgprep, ‘path’, ‘TESTSAMPLE’, /trim 
		- This will check the size of each image in the ‘TESTSAMPLE/data’ directory and trim it if necessary - the desired size is a square with an odd number of pixels, divisible by 3, on each side, centred on the objects position pixel. Note that the input image is overwritten by the trimmed one!

		3.1.2  Running the analysis
		
		run_imganalysis, ‘path/’, ‘TESTSAMPLE’ , /aperpixmap - if run for the first time (or if want to analyse images larger than previously)
		run_imganalysis, ‘path/’, ‘TESTSAMPLE’ 
	
		When run for the first time, a keyword /aperpixmap must be set. This will create circular pixel maps and save for future use to speed up the analysis. It is not recommended to keep the keyword set for subsequent runs as it is a time consuming step.
Use also if images larger than previously are being analysed for the first time (because the size of the circular pixel maps must be at least as large as the largest image to be analysed).

		Other optional tasks:
		/imglist -  set if particular order of images being analysed is preferred; the order should be specified in ‘TESTSAMPLE/data/imglist.txt’  (list of image names); if not set, the code will analyse *all* images within the parent directory in an alphabetical order;
		/savepixelmap - save the pixel maps in *.fits files;
                 /savecleanimg - save the `clean’ images in *.fits files;
		/noskybgr - if images already sky background-subtracted, set to skip this step during the analysis;
		/noimgclean - skip the image cleaning step (by default, the code cleans the images from nearby point sources that don’t overlap with the object of interest);
		/nopixelmap - use preprepared object pixel maps if available (e.g. from a previous run); saves time.


	3.2 For large SDSS images

	Use if imaging fields + SDSS image parameters available (need a file imgparams.csv with RA, DEC, RUN, RERUN, CAMCOL, FIELD). In this case, additionally to the standard analysis, the photometric information from the SDSS FITS header are used to measure additional parameters, such as total magnitude, Sersic index. 

		3.2.1 Preparing images for analysis 

		run_imgprep, ‘path/’, ‘TESTSAMPLE’, /sdss, /cutout
		- This will cut out small images centred on the objects of interest and store the object coordinates in a file imgradec.csv, and the list of image names in imglist.csv. Optionally, larger cutouts can also be created for the purpose of estimating the sky background more reliably (set /largeimg keyword).

		3.2.2 Running the analysis

		run_imganalysis, ‘path/’, ‘TESTSAMPLE’, /sdsscutout, /sdsshdr 
		
		Optional tasks as in 2.1.2.
		Additionally:
		/largeimg - set if large images available for background estimation (if cut out during run_imgprep step)
    
		

4. Output files
-----------
The output from the standard analysis includes a range of structural and morphological parameters. For detailed description see Pawlik et al. 2016 and the references therein.
Image information is stored in imginfo_* files and the output parameters are saved in structpar_* files.

	imginfo_*

	id - ID number, signifying the order in which the images were analysed;
	imgname - the name of the image FITS file;
	imgsize - image size [pixels];
	imgmin, imgmax  - minimum/maximum pixel value in the image;
	skybgr - sky background estimate [counts/pixel]
	skybgrerr - standard deviation in the sky background [counts/pixel]
	skybgrflag - flag pointing to unreliable measurement of the sky background if set to 1;
	time - total analysis time;

	structpar_*

	id -  ID number, signifying the order in which the images were analysed (same as in imginfo_*);
	bpixx, bpixy - [x,y] position of the brightest pixel;
	apixx, apixy - [x,y] position yielding minimum value of the rotational light-weighted asymmetry parameter;
	mpixx, mpixy - [x,y] position yielding minimum value of the second order moment of light;
	rmax - the `maximum’ radius of the galaxy, defined as the distance between the furthest pixel in the object’s pixel map, with respect to the central brightest pixel;
	r20 - curve of growth radii defining a circular aperture that contains 20% of the total flux;
	r50 - curve of growth radii defining a circular aperture that contains 50% of the total flux;
	r80 - curve of growth radii defining a circular aperture that contains 80% of the total flux;
	r90 - curve of growth radii defining a circular aperture that contains 90% of the total flux;
	C2080 - the concentration index defined by the logarithmic ratio of  r20 and r80;
	C5090 - the concentration index defined by the logarithmic ratio of  r50 and r90;
	A - the asymmetry of light under image rotation about 180 degrees around [apixx,apixy] (background corrected);
         A_bgr - the `background’ asymmetry associated with A;
        As  - the shape asymmetry under image rotation about 180 degrees around [apixx,apixy];
	As90  - the shape asymmetry under image rotation about 90 degrees around [apixx,apixy];
	S - the `clumpiness’ of the light distribution (background corrected);
	S_bgr - the `background’ clumpiness associated with S;
	G - the Gini index;
	M20 - the second-order moment of the brightest 20% of the total light;

	mag - total magnitude within the boundaries of the pixel map;
	mag_err - the error associated with mag;
	sb0 - Sersic model’s best-fit parameter: the central surface brightness;
	sb0_err - error associated with sb0;
	reff - Sersic model’s best-fit parameter: the effective radius;
	reff_err - error associated with reff;
	n - Sersic model’s best-fit parameter: the Sersic index;
	n_err - error associated with n;

	warning_flags_*

	This fits array contains any flags raised during the processing. Unless you understand what you are doing DO NOT USE RESULTS WHERE FLAG != 1


	
	
