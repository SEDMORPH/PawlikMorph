;+
; NAME:
;  run_imganalysis
;
; PURPOSE:
;	Carries out image analysis, including measurements of a range of structural and morphological parameters.
;
;
; CALLING SEQUENCE:
;
;	run_imganalysis, dir, sample, [imgname]
;            
;       INPUT: 
;       dir: a string - path to the working directory
;       sample: a string name of the sample to be analysed
;  
;       OPTIONAL INPUT:
;       imgname : can specifiy to analyse a single image, instead of whole sample
;      
;       OUTPUT:
;       The order in the output catalog '*_structpar.csv' matches that in the list of images ('*_imginfo.csv')
;            
;	
; KEYWORD PARAMETERS:
;       
;       SDSSHDR: For SDSS images - set if header values available (need for calculating the magnitude, Sersic index)
;       LARGEIMG: Set if larger images available - for bgr estimation
;            
;       APERPIXMAP: Set to create binary maps of aperture pixels 
;            - required for computation of surface-brightness profiles;
;            - time consuming so best to do only once if possible;
;            ** Set image size in pixels - line 109 (want the pixel map to macth the maximum size of images to be analysed);         
;       NOSKYBGR: Set if the infput images already sky-subtracted
;       NOPIXELMAP: Set if binary pixel map already created
;       NOIMGCLEAN: Set if image already cleaned (of nearby sources **external** to the pixel map)
;            
;       ASPROFILE: Set to compute shape asymmetry profiles - time consuming
;       AOUT: Set to compute outer asymmetries
;       GFRAC: Set to compute fractional Gini parameters
;            
;       FITSCLEANIMG: Optional output - images cleared of point sources     
;       FITSPIXELMAP: Optional output - binary pixel map in a fits file 
;      
; EXAMPLES:
;        run_imganalysis, 'path', 'TESTSAMPLE_1', /imglist, /aperpixmap, /savepixelmap, /savecleanimg, /sdsscutout, /sdsshdr
;        run_imganalysis, 'path', 'TESTSAMPLE_2', /imglist, /aperpixmap, /savepixelmap, /savecleanimg
;
; DEPENDENCIES: 
;            
;       - mpaw_distarr.pro
;       - mpaw_subdistarr.pro
;       - mpaw_skybgr.pro
;            
;       - mpaw_pixelmap.pro
;       - mpaw_pixelmapfrac.pro
;       - mpaw_pixeloutline.pro
;              
;       - mpaw_makeaperpixmaps.pro
;       - mpaw_aperpixmap.pro
;       - mpaw_apercentre.pro
;            
;       - mpaw_maxipix.pro
;       - mpaw_minapix.pro
;       - mpaw_minmpix.pro
;            
;       - mpaw_c.pro  
;       - mpaw_a.pro
;       - mpaw_s.pro
;       - mpaw_g.pro
;       - mpaw_m20.pro
;       - mpaw_asprof.pro
;            
;       - mpaw_apercounts.pro   
;       - mpaw_mag.pro  
;       - mpaw_sbprof.pro 
;       - mpaw_growthcurve.pro
;       - mpaw_sersicfunction.pro
;       - mpaw_fitsersic.pro
;       
; NOTES: 
;   The function asprof.pro is currently slow and still needs some testing.
;  
; MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, August 2016, based on an older version from March 2014. 
;   Last modified by: Milena Pawlik, March 2018
;-

PRO run_imganalysis, dir, sample, imgname, imglist=imglist, sdsscutout=sdsscutout, sdsshdr=sdsshdr, largeimg=largeimg, noskybgr=noskybgr, noimgclean=noimgclean, aperpixmap=aperpixmap, nopixelmap=nopixelmap, asprofile=asprofile, aout=aout, gfrac=gfrac, savepixelmap=savepixelmap, savecleanimg=savecleanimg, sav=sav
    
    ;;------------------------------------------------------------------
    ;; Directories
    ;;------------------------------------------------------------------
    ;dir = '/Users/Milena/Documents/St_Andrews/Projects/SEDMorph/Samples/'
    If n_elements(dir) eq 0 then begin
       print, 'ERROR: Path to working directory unspecified!'
       stop 
    Endif
    
    dir_in = dir+sample+'/data/'
    dir_out = dir+sample+'/output/'
    dir_aper = dir+sample+'/aperpixmaps/'  
    If file_test(dir_out) eq 0 then spawn, 'mkdir '+ dir_out    
       
    ;; --- Specify image size in pixels ---
    ;; - Images need to be square with size being a multiple of 3 pixels
    ;; - One size for all images preferred
    ;; - If sizes vary, enter the size of the largest image
    ;;   or trim prior to the analysis (preferred) using [];
    imagesize = 141 ;; pixels
    
    ;; --- Specify the object detection thresholds for shape asymmetry profiles ---
    nsig = [1.,2.,3.,5.,10.]
    nsig_str = ['1sig','2sig','3sig','5sig','10sig']
 
    ;filters = ['u','g','r','i','z']
    filters=['r']
    
    ;;------------------------------------------------------------------
    ;; Generate aperture pixel maps
    ;;------------------------------------------------------------------
    ;; --- Binary aperture maps for compuation of light profiles --- 
    ;; - Quicker if pre-prepared and saved as fits: 
    If keyword_set(aperpixmap) then begin
        If n_elements(imgname) eq 0 then begin
            If not(keyword_set(imglist)) then imgs = file_search(dir_in+'*.fits',count=numimgs)
            If keyword_set(imglist) then readcol, dir_in+'imglist.txt', imgs , format='A'
 
            imagesize = 0
            For i = 0, n_elements(imgs)-1 do begin
               If not(keyword_set(imglist)) then im = mrdfits(imgs[i])
               If keyword_set(imglist) then im = mrdfits(dir_in+imgs[i])
                imsize = size(im)
                If imsize[1] eq imsize[2] then begin
                    imagesizenew = imsize[1]
                    If imagesizenew gt imagesize then imagesize = imagesizenew
                Endif else begin
                    print, 'ERROR: Incorrect image dimensions. Use run_imageprep to trim.'
                    stop
                Endelse
            Endfor
            print, 'size', imagesize
        Endif else begin
            If n_elememnts(imgsize) eq 0 then begin
                print, 'ERROR: Specify image size for creating aperture pixel map.'
                stop
            Endif
        Endelse
        mpaw_makeaperpixmaps, imagesize, /silent
    Endif
    
    For f = 0, n_elements(filters)-1 do begin
        ;;------------------------------------------------------------------
        ;; Images
        ;;------------------------------------------------------------------
        If n_elements(imgname) eq 0 then begin
            
            If keyword_set(sdsscutout) then begin
                
                ;; If no list provided search for files
                If not(keyword_set(imglist)) then begin
                    imgs = file_search(dir_in+'sdsscutout*_'+filters[f]+'band.fits',count=numimgs)
                    If keyword_set(largeimg) then limgs = file_search(dir_in+'sdsslcutout*_'+filters[f]+'band.fits',count=numlimgs)
                Endif else if keyword_set(imglist) then begin
                    ;; --- Image list ---
                    If file_test(dir_in+'imglist.txt') ne 0 then begin
                        readcol, dir_in+'imglist.txt', imgs , format='A'
                        numimgs = n_elements(imgs)
                    Endif else begin
                        print, 'ERROR! File not found: imglist.txt'
                        stop
                    Endelse
                    
                     If keyword_set(largeimg) then begin
                         If file_test(dir_in+'limglist.txt') ne 0 then begin
                             readcol, dir_in+'limglist.txt', limgs , format='A'
                         Endif else begin
                             print, 'ERROR! File not found: limglist.txt'
                             stop
                         Endelse
                     Endif
                Endif
    
            Endif else if not(keyword_set(sdsscutout)) then begin
                ;; If no list provided search for files, otherwise read from the list to preserve order
                If not(keyword_set(imglist)) then begin
                    imgs = file_search(dir_in+'*.fits',count=numimgs) 
                    
                Endif else if keyword_set(imglist) then begin
                    
                    If file_test(dir_in+'imglist.txt') ne 0 then begin
                        readcol, dir_in+'imglist.txt', imgs , format='A'
                        numimgs = n_elements(imgs)
                    Endif else begin
                        print, 'ERROR! File not found: imglist.txt'
                        stop
                    Endelse
                Endif
        
            Endif
            
        Endif else numimgs = 1
        
        ;;------------------------------------------------------------------
        ;; Output set up 
        ;;------------------------------------------------------------------

        ;; Data structure for storing structural parameters
        struct = {id:0L,bpixx:0,bpixy:0,apixx:0,apixy:0,mpixx:0,mpixy:0,rmax:0.0,r20:0.0,r50:0.0,r80:0.0,r90:0.0,C2080:0.0,C5090:0.0,A:0.0,A_bgr:0.0,As:0.0,As90:0.0,S:0.0,S_bgr:0.0,G:0.0,M20:0.0,mag:0.0,mag_err:0.0,sb0:0.0,sb0_err:0.0,reff:0.0,reff_err:0.0,n:0.0,n_err:0.0}
        hdr_out = ['id','bpixx','bpixy','apixx','apixy','mpixx','mpixy','rmax','r20','r50','r80','r90','C2080','C5090','A','A_bgr','As','As90','S','S_bgr','G','M20','mag','mag_err','sb0','sb0_err','reff','reff_err','n','n_err']
        out = replicate(struct,numimgs)
        ;outfile = 'structpar_'+filters[f]+'band
        outfile = 'structpar'
    
        ;; Data structure for storing radial profiles
        struct = {id:0L,nprof:0,prof:fltarr(imagesize/2),proferr:fltarr(imagesize/2)}
        out1 = replicate(struct,numimgs)
        ;outfile1 = 'sbprof_'+filters[f]+'band
        outfile1 = 'sbprof'
    
        ;; Data structure for storing image information
        struct = {id:0L,imgname:'',imgsize:0,imgmin:0.0,imgmax:0.0,skybgr:0.0,skybgrerr:0.0,skybgrflag:0,time:0.0}
        hdr_out2 = ['id','imgname','imgsize','imgmin','imgmax','skybgr','skybgrerr','skybgrflag','time']
        out2 = replicate(struct,numimgs)
        ;outfile2 = 'imginfo_'+filters[f]+'band
        outfile2 = 'imginfo'
    
        ;; Data structure for storing additional parameters: outer asymmetries, fractional Gini indices
        struct = {id:0L, Ao20:0.0, Ao50:0.0, Ao80:0.0, Ao90:0.0, G20:0.0, G50:0.0, G80:0.0, G90:0.0}
        out3 = replicate(struct,numimgs)
        ;outfile3 = 'extrapar_'+filters[f]+'band
        outfile3 = 'extrapar'
    
        ;; Data structure for storing the shape asymmetry profiles
        struct = {id:0L, As:fltarr(n_elements(nsig)), As90:fltarr(n_elements(nsig))}
        out4 = replicate(struct,numimgs)
        ;outfile4 = 'asprof_'+filters[f]+'band
        outfile4 = 'asprof'
        
        ;;------------------------------------------------------------------
        ;; Analysis 
        ;;------------------------------------------------------------------
        flag = replicate(1,numimgs) ;; added by Yanmei Chen, Jan 2019

        For i = 0, numimgs-1 do begin
            ;tic 
            time_start = systime(1)
  
                out(i).id = i+1
                out1(i).id = i+1
                out2(i).id = i+1
        
                ;; --------------------
                ;; Reading imaging data
                If n_elements(imgname) eq 0 then begin
                    If keyword_set(imglist) then begin
                        name = imgs[i]
                        imgpath = dir_in+name
                        If keyword_set(largeimg) then limgpath = dir_in+limgs[i]
                    Endif else if not(keyword_set(imglist)) then begin
                        imgpath = imgs[i]
                        If keyword_set(largeimg) then limgpath = limgs[i]
                        name = strsplit(imgpath,dir_in,/extract,/regex)
                        name = strcompress(name,/remove)
                    Endif
                Endif else begin
                    name = imgname
                    imgpath = dir_in+imgname
                Endelse
  
                out2(i).imgname = name
        
                ;; Sometimes need to set /fscale to read images properly - not sure why...
                ;img = mrdfits(imgpath,/fscale) - 1000   
                ;If keyword_set(largeimg) then limg = mrdfits(limgs[i],/fscale) - 1000
                print, imgpath
                
                If file_test(imgpath) ne 0 then begin
                    
                img = mrdfits(imgpath)     
                If keyword_set(largeimg) then limg = mrdfits(limgpath)
                If keyword_set(softbias) then begin
                    img = img - 1000       
                    If keyword_set(largeimg) then limg = limg - 1000
                Endif 
                
                out2(i).imgmin = min(img)
                out2(i).imgmax = max(img)
        
                imgsize = size(img)
                if imgsize[1] ne 141 then begin       ;; Flag added by Yanmei Chen, Jan 2019
                   flag[i] = -99
                   continue
                endif
                
                npix = imgsize[1]
                cenpix = fltarr(2)
                cenpix[0] = npix/2 + 1
                cenpix[1] = npix/2 + 1
                distarr = mpaw_distarr(npix, npix, cenpix)
        
                ;;---------------------------------------------------------
                ;; For SDSS - read in data from image header, if available)
                If keyword_set(sdsshdr) then begin
            
                    data = mrdfits(imgpath,0,hdr)
            
                    ;; Read in header parameters
                    bzero = sxpar(hdr,'BZERO')
                    bscale = sxpar(hdr,'BSCALE')
                    softbias = sxpar(hdr,'SOFTBIAS')     
                    sky = sxpar(hdr,'SKY')
                    skyerr = sxpar(hdr,'SKYERR')
                    ;skybgr_err = sxpar(hdr,'SKYSIG')
                    exptime = sxpar(hdr,'EXPTIME')
                    airmass = sxpar(hdr,'AIRMASS')
                    aa = sxpar(hdr,'PHT_AA')
                    kk = sxpar(hdr,'PHT_KK')
                    gain = sxpar(hdr,'GAIN')
                    darkvar = sxpar(hdr,'DARK_VAR')
                    b = sxpar(hdr,'PHT_B')
                    flux20 = sxpar(hdr,'FLUX20')

                    psf_s12g = sxpar(hdr,'PSFS12G')
                    psf_s22g = sxpar(hdr,'PSFS22G') 
            
                    psf_ratio = sxpar(hdr,'PSF_B_2G')       
                    psf_wid = sxpar(hdr,'PSFWID')
    
                Endif
         
                ;; -----------------------------------------------------
                ;; Estimate background level + standard deviation 
                ;; (needed to define the threshold for object detection)        
                If keyword_set(largeimg) then tempimg = limg else tempimg = img         
                skybgr = mpaw_skybgr(tempimg)  
                
                ;; -----------------------------------------------
                ;; Object detection: compute/read binary pixel map  
                If not(keyword_set(nopixelmap)) then begin
            
                    thresh = skybgr[0] + 1.*skybgr[1]
                    pixmap = mpaw_pixelmap(img, thresh)       
                    ;; Write in a fits file
                    If keyword_set(savepixelmap) then begin
                        writefits, dir_out+'pixelmap_'+name, pixmap  
                    Endif
            
                Endif else begin
                    pixmap = mrdfits(dir_out+'pixelmap_'+name,/fscale)
                Endelse
           
                ;; - Maximum radius from pixel map
                objectpix = where(pixmap eq 1)
                objectdist = distarr[objectpix]        
                r_max = max(objectdist)
       
                ;; ------------------------------------------
                ;; Image preparation (optional):  
        
                ;; - Subtract sky background
                If not(keyword_set(noskybgr)) then img = img - skybgr[0]
        
                ;; - Clean images of nearby sources (external to the pixel map)
                If not(keyword_set(noimgclean)) then begin
                    img = mpaw_cleanimg(img,pixmap)
                    If keyword_set(savecleanimg) then begin
                        writefits, dir_out+'clean_'+name, img
                    Endif
                Endif
        
                ;; ------------------------------------------
                ;; Structural and morphological measurements:
        
                ;; --- Centroids ---
                ;; Compute pixel map for aperture at r_max
                aperpixmap = mpaw_aperpixmap(npix,r_max,9,0.1)
                ;aperpixmap = mpaw_aperpixmap(npix,cenpix,r_max,99,0.01)
        
                bpix = mpaw_maxipix(img,pixmap)
                apix = mpaw_minapix(img,pixmap,aperpixmap)
                mpix = mpaw_minmpix(img,pixmap)
           
                ;; --- Radial profiles and growth curve radii ---        
                r_aper = findgen(npix/2)+1. 
                numaper = n_elements(r_aper)
                rind = numaper-1        
                For rr = 0, numaper-2 do begin
                    If r_max gt r_aper[rr] and r_max le r_aper[rr+1] then rind = rr
                Endfor
                rind = rind-1
                r_aper = r_aper[0:rind]
                nprof = rind-1
                r = r_aper-1.        
                numaper = n_elements(r_aper)     
                numannuli = n_elements(r)        
                If keyword_set(sdsshdr) then begin
                    photpar = {skybgr:0.0,skybgrerr:0.0,exptime:0.0,airmass:0.0,aa:0.0,kk:0.0,gain:0.0,darkvar:0.0,b:0.0,flux20:0.0}
                    photpar.skybgr = skybgr[0]
                    photpar.skybgrerr = skybgr[1]
                    photpar.exptime = exptime
                    photpar.airmass = airmass
                    photpar.aa = aa
                    photpar.kk = kk
                    photpar.gain = gain
                    photpar.darkvar = darkvar
                    photpar.b = b  
                    photpar.flux20 = flux20     
                    result = mpaw_sbprof(img,dir_aper,aperpixmap,bpix,r_aper,photpar,/err,/cog) 
                Endif else if not(keyword_set(sdsshdr)) then begin
                    result = mpaw_sbprof(img,dir_aper,aperpixmap,bpix,r_aper,/cog)
                Endif 
        
                rad = result.rad
                prof = result.prof
                proferr = result.proferr
         
                ;; --- Concentration indices (see Bershady et al. 2000) 
                C2080 = mpaw_c(rad[0],rad[2])
                C5090 = mpaw_c(rad[1],rad[3])
        
                ;; --- Asymmetry (see Conselice et al. 2000)
                angle = 180.
                result = mpaw_a(img,pixmap,aperpixmap,apix,rmax,angle,/noisecorrect)
                A = result[0]
                Abgr = result[1]
        
                ;; --- Shape asymmetry ---
                As = mpaw_a(pixmap,pixmap,aperpixmap,apix,rmax,angle)
                As90 = mpaw_a(pixmap,pixmap,aperpixmap,apix,rmax,90.)
        
                ;; --- Outer asymmetry ---
                If keyword_set(aout) then begin
                    For i = 0, n_elements(rad)-1 do begin
                        aperpixmapcut = mpaw_aperpixmap(img,rad[i],9,0.1)
                        aperpixmapcut = mpaw_apercentre(aperpixmapcut,bpix)
                        Ao = mpaw_a(img,pixmap,aperpixmap,apix,rmax,angle,aperpixmapcut,/noisecorrect,/aout)
                        If i eq 0 then Ao20 = Ao[0]
                        If i eq 1 then Ao50 = Ao[0]
                        If i eq 2 then Ao80 = Ao[0]
                        If i eq 3 then Ao90 = Ao[0]  
                        If i eq 0 then Ao20_bgr = Ao[1]
                        If i eq 1 then Ao50_bgr = Ao[1]
                        If i eq 2 then Ao80_bgr = Ao[1]
                        If i eq 3 then Ao90_bgr = Ao[1]              
                    Endfor
                Endif
        
                ;; --- Shape asymmetry profile ---
                If keyword_set(asprofile) then begin
                    ;; - Choose thresholds for object detection (multiple of standard deviation above the background)
                    nsig = [1.,2.,3.,5.,10.]
                    thresholds = skybgr[0] + nsig*skybgr[1]
                    ;; - Compute the asymmetries           
                    paths = dir_out+'pixmap_'+nsig_str+'_'+name
                    asymmetries = mpaw_asprof(img,apix,thresholds,paths)            
                Endif
        
                ;; --- Clumpiness ---
                If rad[0] gt 0.0 then begin
                    width = (rcut = rad[0])
                    aperpixmapcut = mpaw_aperpixmap(npix,rcut,9,0.1)
                
                    aperpixmapcut = mpaw_apercentre(aperpixmapcut,bpix)
                    result = mpaw_s(img,pixmap,aperpixmap,width,aperpixmapcut,/noisecorrect,/sout)
                    S = result[0]
                    Sbgr = result[1]
                    if Sbgr eq -99 then flag[i] = -199         ;; flag added by Yanmei Chen, Jan 2019
                Endif else begin
                    S = -99.
                    Sbgr = -99.
                Endelse
        
                ;; --- Gini index ---
                G = mpaw_g(img,pixmap)
        
                ;; --- `Fractional' Gini indices ---
                If keyword_set(gfrac) then begin
                    For i = 0, n_elements(rad)-1 do begin
                        outpixmap20 = mpaw_pixelmapfrac(img,pixmap,0.2)
                        inpixmap20 = pixmap - outpixmap20
                
                        outpixmap50 = mpaw_pixelmapfrac(img,pixmap,0.5)
                        inpixmap50 = pixmap - outpixmap50
                
                        outpixmap80 = mpaw_pixelmapfrac(img,pixmap,0.8)
                        inpixmap80 = pixmap - outpixmap80
                
                        outpixmap90 = mpaw_pixelmapfrac(img,pixmap,0.9)
                        inpixmap90 = pixmap - outpixmap90
    
                        G20 = mpaw_g(img,inpixmap20)
                        G50 = mpaw_g(img,inpixmap50)
                        G80 = mpaw_g(img,inpixmap80)
                        G90 = mpaw_g(img,inpixmap90)
        
                    Endfor
                Endif
        
                ;; --- Momemnt of light ---
                M20 = mpaw_m20(img,pixmap)
          
                ;; *** If photometric calibration parameters known ***
                If keyword_set(sdsshdr) then begin
            
                    ;; - Total magnitudes within pixel map
                    result = mpaw_mag(img,pixmap,photpar)
                    mag = result[0]
                    magerr = result[1]
            
                    print, prof[0]
                    
                    ;; - Seric fits to the radial profiles
                    If prof[0] gt 0.0 then begin
                        guess = [prof[0]/5.,1.,2.5,psf_s12g,psf_s22g,psf_ratio]
                        par = mpaw_fitsersic(R,guess,prof,proferr,cov,err)
                    Endif else begin
                        par = [-99.,-99.,-99.]
                        err = [-99.,-99.,-99.]
                    Endelse
        
                Endif 
                
                time = systime(1)-time_start
       
                ;; ---------------------------------------
                ;; --- Save parameters in output files ---
    
                out(i).bpixx = bpix[0]
                out(i).bpixy = bpix[1]
                out(i).apixx = apix[0]
                out(i).apixy = apix[1]
                out(i).mpixx = mpix[0]
                out(i).mpixy = mpix[1]    
                out(i).rmax = r_max      
                out(i).r20 = rad[0]
                out(i).r50 = rad[1]
                out(i).r80 = rad[2]
                out(i).r90 = rad[3]              
                out(i).C2080 = C2080
                out(i).C5090 = C5090
                out(i).A = A
                out(i).A_bgr = Abgr
                out(i).As = As
                out(i).As90 = As90
                out(i).S = S
                out(i).S_bgr = Sbgr
                out(i).G = G
                out(i).M20 = M20       
                If keyword_set(sdsshdr) then begin
                    out(i).mag = mag 
                    out(i).mag_err = magerr           
                    out(i).sb0 = par[0]
                    out(i).sb0_err = err[0]
                    out(i).reff = par[1]
                    out(i).reff_err = err[1]
                    out(i).n = par[2]
                    out(i).n_err = err[2]
                Endif else begin
                    out(i).mag = (out(i).mag_err = -99.)
                    out(i).sb0 = (out(i).sb0_err = -99.)
                    out(i).reff = (out(i).reff_err = -99.)
                    out(i).n = (out(i).n_err = -99.)
                Endelse       
                ;; -----------------------------------
       
                out1(i).nprof = numannuli     
                out1(i).prof([0:numannuli-1]) = prof
                out1(i).proferr([0:numannuli-1]) = proferr       
                ;; -----------------------------------
        
                out2(i).id = i+1
                out2(i).imgname = name
                out2(i).imgsize = npix
                out2(i).skybgr = skybgr[0]
                out2(i).skybgrerr = skybgr[1]
                out2(i).skybgrflag = skybgr[2]  
                out2(i).time = time     
                ;; -----------------------------------
       
                If keyword_set(aout) or keyword_set(gfrac) then out3(i).id = i+1       
                If keyword_set(aout) then begin
                    out3(i).Ao20 = Ao20
                    out3(i).Ao20_bgr = Ao20_bgr
                    out3(i).Ao50 = Ao50
                    out3(i).Ao50_bgr = Ao50_bgr
                    out3(i).Ao80 = Ao80
                    out3(i).Ao80_bgr = Ao80_bgr
                    out3(i).Ao90 = Ao90
                    out3(i).Ao90_bgr = Ao90_bgr
                Endif       
                If keyword_set(gfrac) then begin
                    out3(i).G20 = G20
                    out3(i).G50 = G50
                    out3(i).G80 = G80
                    out3(i).G90 = G90
                Endif
                ;; -----------------------------------
       
                write_csv, dir_out+outfile+'.csv', out, header=hdr_out
                write_csv, dir_out+outfile2+'.csv', out2, header=hdr_out2
       
                save, out, filename=dir_out+outfile+'_test.sav'
                save, out1, filename=dir_out+outfile1+'_test.sav'
                save, out2, filename=dir_out+outfile2+'_test.sav'
                If keyword_set(aout) or keyword_set(gfrac) then save, out3, filename=dir_out+outfile3+'.sav'
                If keyword_set(asprofile)then save, out4, filename=dir_out+outfile4+'.sav'
                
            Endif
            
             Endfor
        
        ;; output flag : added by Yanmei Chen, Jan 2019
        mwrfits, flag, dir_out+'warning_flags_'+filters[f]+'band.fits',/create
  
        Endfor ;; SDSS filters

    
    END
