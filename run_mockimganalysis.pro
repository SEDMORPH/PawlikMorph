;+
; NAME:
;  run_mockimganalysis
;
; PURPOSE:
;	Carries out mock image analysis, including measurements of a range of structural and morphological parameters. 
;  
; MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, August 2016, based on an older version from March 2014. 
;	
;-


PRO RUN_MOCKIMGANALYSIS, simulation, orientation, filter, singleimg=singleimg, convertunits=convertunits,aperpixmap=aperpixmap,nopixelmap=nopixelmap,savepixelmap=savepixelmap

    ;;------------------------------------------------------------------
    ;; Directories
    ;;------------------------------------------------------------------
    dir = '/Users/Milena/Documents/St_Andrews/Projects/SEDMorph/Simulations/GADGET3/RERUN/'
    dir_in = dir+simulation+'/imgs_'+filter+'/orien_'+orientation+'/'  
    dir_out = dir+simulation+'/output/'    
    If file_test(dir_out) eq 0 then spawn, 'mkdir '+ dir_out    
       
    imagesize = 147
    
    ;;------------------------------------------------------------------
    ;; Images
    ;;------------------------------------------------------------------  
    If not(keyword_set(singleimg)) then begin
            imgs = file_search(dir_in+'sdssimage_z0.040_tauv1.0_mu0.3_*.fits',count=numimgs)
    Endif else begin
        ;; Finish!
    Endelse
    
    ;; -----------------------------------------------------------------
    ;; Photometric parameters
    ;; -----------------------------------------------------------------
    
    exptime = 53.907456
 
    If filter eq 'u' then f = 0
    If filter eq 'g' then f = 1
    If filter eq 'r' then f = 2
    If filter eq 'i' then f = 3
    If filter eq 'z' then f = 4
    
    aa = [ -24.1270,  -24.5128,  -24.1073,  -23.6936,   -21.9465]
    kk = [ 0.506005, 0.181950,  0.103586,  0.0628950,  0.0557740]
    air = [ 1.19020,1.19027, 1.19027, 1.19022,1.19022]
    gain = [1.6,3.995,4.725,4.885,4.775]  
    darkvar = [9.30250,1.44000,1.00000, 5.76000, 1.00000 ]
 
    psf_s12g = [1.44527,1.36313,1.21196,1.114143,1.20288] ;; in pixels
    psf_s22g = [3.1865,3.06772,2.82102,2.75094,3.09981] ;; in pixels
    psf_ratio =[0.081989,0.081099,0.06811,0.059653,0.054539]
    psf_width = [1.54254,1.44980,1.31878,1.25789,1.29391]/0.396 ;; originally in arcsec

    b = [1.4,0.9,1.2,1.8,7.4]*10d^(-10)

    sky=[24.3,23.9,23.0,22.4,21.2]

    sky = (2*b)*sinh(-sky*(alog(10)/2.5)-alog(b))
    sky = exptime*sky*10d^(-0.4*(aa+kk*air)) 

    skysig = [6.23701d-12,2.58936d-12,4.04300d-12,6.71002d-12,2.55825d-11] ;- maggies/arcsec^2
    skysig = exptime*skysig*10d^(-0.4*(aa+kk*air)) 

    
    ;;------------------------------------------------------------------
    ;; Generate aperture pixel maps
    ;;------------------------------------------------------------------
    ;; --- Binary aperture maps for compuattion of light profiles --- 
    ;; - Quicker if pre-prepared and saved as fits: 
    If keyword_set(aperpixmap) then begin
        If n_elements(imgname) eq 0 then begin
            imgs = file_search(dir_in+'sdssimage_z0.040_tauv1.0_mu0.3_*.fits',count=numimgs)
            imagesize = 0
            For i = 0, n_elements(imgs)-1 do begin
                im = mrdfits(imgs[i])
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
    
     
    ;;------------------------------------------------------------------
    ;; Output set up 
    ;;------------------------------------------------------------------

    ;; Data structure for storing structural parameters
    struct = {id:0L,bpixx:0,bpixy:0,apixx:0,apixy:0,mpixx:0,mpixy:0,rmax:0.0,r20:0.0,r50:0.0,r80:0.0,r90:0.0,C2080:0.0,C5090:0.0,A:0.0,A_bgr:0.0,As:0.0,As90:0.0,S:0.0,S_bgr:0.0,G:0.0,M20:0.0,mag:0.0,mag_err:0.0,sb0:0.0,sb0_err:0.0,reff:0.0,reff_err:0.0,n:0.0,n_err:0.0}
    hdr_out = ['id','bpixx','bpixy','apixx','apixy','mpixx','mpixy','rmax','r20','r50','r80','r90','C2080','C5090','A','A_bgr','As','As90','S','S_bgr','G','M20','mag','mag_err','sb0','sb0_err','reff','reff_err','n','n_err']
    out = replicate(struct,numimgs)
    outfile = simulation+'_structpar_'+filter+'_'+orientation

    ;; Data structure for storing radial profiles
    struct = {id:0L,nprof:0,prof:fltarr(imagesize/2),proferr:fltarr(imagesize/2)}
    out1 = replicate(struct,numimgs)
    outfile1 = simulation+'_sbprof_'+filter+'_'+orientation

    ;; Data structure for storing image information
    struct = {id:0L,imgname:'',imgsize:0,imgmin:0.0,imgmax:0.0,skybgr:0.0,skybgrerr:0.0,skybgrflag:0,time:0.0}
    hdr_out2 = ['id','imgname','imgsize','imgmin','imgmax','skybgr','skybgrerr','skybgrflag','time']
    out2 = replicate(struct,numimgs)
    outfile2 = simulation+'_imginfo_'+filter+'_'+orientation
    
    
    ;;------------------------------------------------------------------
    ;; Analysis 
    ;;------------------------------------------------------------------
   ; numimgs = 150
    
     For i = 0, numimgs-1 do begin
         
         tic 

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
            
                If keyword_set(convertunits) then begin
                    
                    Img_jansky = img
                    ;; Convert to counts (mock images from simulations in janskys)
                    ;; - Need positive flux for the unit conversion
                    diff_jansky = 1e-03
                    img_jansky = img_jansky + diff_jansky
    
                    img_mag = -2.5*alog10(img_jansky/3631.)
                    img_ff0 = (2*b[f])*sinh(-img_mag*(alog(10)/2.5)-alog(b[f]))
                    img_counts = exptime*img_ff0*10d^(-0.4*(aa+kk*air)[f]) 
           
                    print, min(img_jansky), max(img_jansky)
                    print, min(img_mag), max(img_mag)
                    print, min(img_ff0), max(img_ff0)
                    print, min(img_counts), max(img_counts)
       
                    ;; Take away the previously added flux (now in counts)
                    diff_mag = -2.5*alog10(diff_jansky/3631.)
                    diff_ff0 = (2*b[f])*sinh(-diff_mag*(alog(10)/2.5)-alog(b[f]))
                    diff_counts = exptime*diff_ff0*10d^(-0.4*(aa+kk*air)[f])             
                    img_counts = img_counts-diff_counts
    
                    print, min(img_counts), max(img_counts)
   
                    img = img_counts 
                    img[where(finite(img) lt 1)] = 0.0

                    writefits, dir_in+'imgcounts_'+name, img
            
                Endif
           
                out2(i).imgmin = min(img)
                out2(i).imgmax = max(img)
    
                imgsize = size(img)
                npix = imgsize[1]
                cenpix = fltarr(2)
                cenpix[0] = npix/2 + 1
                cenpix[1] = npix/2 + 1
                distarr = mpaw_distarr(npix, npix, cenpix)
    
               
                ;; -----------------------------------------------------
                ;; Estimate background level + standard deviation 
                ;; (needed to define the threshold for object detection)               
                skybgr = mpaw_skybgr(img)  
            
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
    
                If finite(r_max) ne 1 then r_max = 0.0
                ;; ------------------------------------------
                ;; Structural and morphological measurements:
    
                ;; --- Centroids ---
                ;; Compute pixel map for aperture at r_max
                aperpixmap = mpaw_aperpixmap(npix,r_max,9,0.1)
                ;aperpixmap = mpaw_aperpixmap(npix,cenpix,r_max,99,0.01)
    
                bpix = mpaw_maxIpix(img,pixmap)
                apix = mpaw_minApix(img,pixmap,aperpixmap)
                mpix = mpaw_minMpix(img,pixmap)
       
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
           
           
                photpar = {skybgr:0.0,skybgrerr:0.0,exptime:0.0,airmass:0.0,aa:0.0,kk:0.0,gain:0.0,darkvar:0.0,b:0.0,flux20:0.0}
                photpar.skybgr = skybgr[0]
                photpar.skybgrerr = skybgr[1]
                photpar.exptime = exptime
                ;photpar.airmass = airmass
                photpar.aa = aa[f]
                photpar.kk = kk[f]
                photpar.gain = gain[f]
                photpar.darkvar = darkvar[f]
                photpar.b = b[f]
                result = mpaw_sbprof(img,aperpixmap,bpix,r_aper,photpar,/err,/cog) 
           
                rad = result.rad
                prof = result.prof
                proferr = result.proferr
     
                ;; --- Concentration indices (see Bershady et al. 2000) 
                C2080 = mpaw_C(rad[0],rad[2])
                C5090 = mpaw_C(rad[1],rad[3])
    
                ;; --- Asymmetry (see Conselice et al. 2000)
                angle = 180.
                result = mpaw_a(img,pixmap,aperpixmap,apix,rmax,angle,/noisecorrect)
                A = result[0]
                Abgr = result[1]
    
                ;; --- Shape asymmetry ---
                As = mpaw_a(pixmap,pixmap,aperpixmap,apix,rmax,angle)
                As90 = mpaw_a(pixmap,pixmap,aperpixmap,apix,rmax,90.)
    
           
                ;; --- Clumpiness (see) ---
                If rad[0] gt 0.0 then begin
                    width = (rcut = rad[0])
                    aperpixmapcut = mpaw_aperpixmap(npix,rcut,9,0.1)
            
                    aperpixmapcut = mpaw_apercentre(aperpixmapcut,bpix)
                    result = mpaw_s(img,pixmap,aperpixmap,width,aperpixmapcut,/noisecorrect,/sout)
                    S = result[0]
                    Sbgr = result[1]
                Endif else begin
                    S = -99.
                    Sbgr = -99.
                Endelse
    
                ;; --- Gini index ---
                G = mpaw_G(img,pixmap)
      
                ;; --- Momemnt of light ---
                M20 = mpaw_M20(img,pixmap)
      
                ;; - Total magnitudes within pixel map
                result = mpaw_mag(img,pixmap,photpar)
                mag = result[0]
                magerr = result[1]
        
                print, prof[0]
                
                ;; - Seric fits to the radial profiles
                If prof[0] gt 0.0 then begin
                    guess = [prof[0]/5.,1.,2.5,psf_s12g[f],psf_s22g[f],psf_ratio[f]]
                    par = mpaw_fitsersic(R,guess,prof,proferr,cov,err)
                Endif else begin
                    par = [-99.,-99.,-99.]
                    err = [-99.,-99.,-99.]
                Endelse
    
                time = toc()
   
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
     
                write_csv, dir_out+outfile+'.csv', out, header=hdr_out
                write_csv, dir_out+outfile2+'.csv', out2, header=hdr_out2
   
                save, out, filename=dir_out+outfile+'.sav'
                save, out1, filename=dir_out+outfile1+'.sav'
                save, out2, filename=dir_out+outfile2+'.sav'
           
            
            Endif

        Endfor
    
    END