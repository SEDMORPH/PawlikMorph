;+
; NAME:
;  run_quickanalysis
;
; PURPOSE:
;	For quicker analysis - computes the binary map of galaxy pixels and calculates the shape asymmetry only. For full analysis use run_imganalysis.pro
;
; CALLING SEQUENCE:
;
;	run_quickanalysis, dir, sample
;
;       INPUT: 
;       - dir - path to the working directory (string)
;       - sample - sample to be analysed (string)
;     
;       OUTPUT:
;       - Pixel maps saved in `output/*.fits' - each map in a separate FITS file;
;       - Shape asymmetry values saved in 'output/*_quickanalysis_out.csv' 
;            
;       KEYWORD PARAMETERS:
;       
;       - NOPIXELMAP: Set if binary pixel map already created
;       - NOSKYBGR: Set if the infput images already sky-subtracted
;       - NOIMGCLEAN: Set if images already cleaned (of nearby sources external to the pixel map)
;       - SAVEPIXELMAP: Set to save binary pixel maps in FITS files
;       - SAVECLEANIMG: Set to save the clean images in FITS files
;            
;       DEPENDENCIES: 
;            
;       - mpaw_distarr.pro
;       - mpaw_subdistarr.pro
;       - mpaw_skybgr.pro
;       - mpaw_cleanimg.pro
;            
;       - mpaw_pixelmap.pro
;       - mpaw_pixelmapfrac.pro
;       - mpaw_pixeloutline.pro
;              
;       - mpaw_makeaperpixmaps.pro
;       - mpaw_aperpixmap.pro
;       - mpaw_apercentre.pro
;            
;       - mpaw_minApix.pro
;       - mpaw_A.pro
;    
;  MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, July 2017, (short version of the image anlysis code from August 2016)
;   Last modified by: ...
;-

PRO RUN_QUICKANALYSIS, dir, sample, nopixelmap=nopixelmap, noskybgr=noskybgr, noimgclean=noimgclean, savepixelmap=savepixelmap, savecleanimg=savecleanimg


    ;;------------------------------------------------------------------
    ;; Input
    ;;------------------------------------------------------------------

    If n_elements(dir) eq 0 then begin
       print, 'ERROR: Path to working directory unspecified!'
       stop 
    Endif
    
    dir_in = dir+sample+'/data/'
    dir_out = dir+sample+'/output/'    
    If file_test(dir_out) eq 0 then spawn, 'mkdir '+ dir_out    
    
    imgs = file_search(dir_in+'*.fits',count=numimgs) 
     
    ;;------------------------------------------------------------------
    ;; Output
    ;;------------------------------------------------------------------
      
    ;; Data structure for output
    struct = {id:0L, imgname:'', imgsize:0, imgmin:0.0, imgmax:0.0, skybgr:0.0, skybgrerr:0.0, skybgrflag:0.0, rmax:0.0, apixx:0, apixy:0, As:0.0, time:0.0 }
    hdr_out = ['id','imgname','imgsize','imgmin','imgmax','skybgr','skybgrerr','skybgrflag','rmax','apixx', 'apixy','As','time']
    out = replicate(struct,numimgs)
    outfile = 'quickanalysis_out'
 
    ;;------------------------------------------------------------------
    ;; Analysis 
    ;;------------------------------------------------------------------
 
    For i = 0, numimgs-1 do begin
          
         imgpath = imgs[i]
         name = strsplit(imgpath,dir_in,/extract,/regex)
         name = strcompress(name,/remove)   
                  
         img = mrdfits(imgpath) 
         
         imgsize = size(img)
         
         If imgsize[1] ne imgsize[2] then begin
             
             print, 'ERROR: Incorect image dimensions. Input image must be a square.'
             stop
             
         Endif else begin
             
             npix = imgsize[1]
         
             If npix/3 ne float(npix)/3. then begin
                 print, 'ERROR: Incorect image dimensions. Image dimensions must be equal odd integers divisible by 3.'
                 stop
             Endif else begin
         
                 img = img - 1000 ;; Software bias (SDSS images only)
                 imgmin = min(img)
                 imgmax = max(img)
        
                 ;; Compute distance array
                 cenpix = fltarr(2)
                 cenpix[0] = npix/2 + 1
                 cenpix[1] = npix/2 + 1
                 distarr = mpaw_distarr(npix, npix, cenpix)
         
                 ;; Esimate sky background
                 skybgr = mpaw_skybgr(img)  
               
                 ;; Object detection: compute/read binary pixel map  
                 If not(keyword_set(nopixelmap)) then begin            
                     thresh = skybgr[0] + 1.*skybgr[1]
                     pixmap = mpaw_pixelmap(img, thresh)       
                     If keyword_set(savepixelmap) then begin
                         writefits, dir_out+'pixelmap_'+name, pixmap  
                     Endif
                 Endif else begin
                     pixmap = mrdfits(dir_out+'pixelmap_'+name,/fscale)
                 Endelse
                 
                 
                 ;; - Maximum radius from pixel map
                 objectpix = where(pixmap eq 1)
                 objectdist = distarr[objectpix]        
                 rmax = max(objectdist)
       
                 ;; -------------------------------
                 ;; Calculating the shape asymmetry
                          
                 ;; - Image preparetion: subtract sky background
                 If not(keyword_set(noskybgr)) then img = img - skybgr[0]        
                 ;; - Image preparation: clean images of nearby sources (external to the pixel map)
                 If not(keyword_set(noimgclean)) then begin
                     img = mpaw_cleanimg(img,pixmap)
                     If keyword_set(savecleanimg) then begin
                         writefits, dir_out+'clean_'+name, img
                     Endif
                 Endif
                 ;; - Compute pixel map for aperture at r_max
                 aperpixmap = mpaw_aperpixmap(npix,r_max,9,0.1)
                 ;; - Coumpute minimum asymmetry centroid
                 apix = mpaw_minApix(img,pixmap,aperpixmap)
                 ;; - Compute the shape asymmetry
                 angle = 180.
                 As = mpaw_A(pixmap,pixmap,aperpixmap,apix,rmax,angle)
               
                 time = systime(1)-time_start
                 
                 ;; Save output
                 out(i).id = i+1
                 out(i).imgname = name
                 out(i).imgsize = npix
                 out(i).imgmin = imgmin
                 out(i).imgmax = imgmax
                 out(i).skybgr = skybgr[0]
                 out(i).skybgrerr = skybgr[1]
                 out(i).skybgrflag = skybgr[2]
                 out(i).rmax = rmax
                 out(i).apixx = apix[0]
                 out(i).apixy = apix[1]
                 out(i).As = As
                 out(i).time = time
                
             Endelse ;; Image simensions check 2
         
         Endelse ;; Image dimensions check 1
         
        
     Endfor

    

END