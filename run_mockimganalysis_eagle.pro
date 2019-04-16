;; Mock image analysis - specifically for EAGLE data
;; - Read in data from James - mock images of EAGLE galaxies 
;; - Prepare for analysis: add effects of noise and convolve with a PSF
;; - Conver to SDSS units (counts) and analyse (get As and C)

;; KEYWORDS

;; /NOISE -  add noise (set to match the SDSS data)
;; /PSF - convolve with a PSF (set to match the SDSS data)
;; /SAVEIMGS - save the post-processed images (with effects of noise/psf)

;; /UNITS - convert to counts

;; /APERPIXMAP - set only if:
;;              1) running for the first time; 
;;              2) running on larger images than previously. 
;;              This creates pixelmaps for a number of concentric circular 
;;              apertures and saves them in .fits files.




PRO RUN_MOCKIMGANALYSIS_EAGLE, GALAXYID, FILTER, DUST=DUST, NOISE=NOISE, PSF=PSF, UNITS=UNITS, TRIM=TRIM, APERPIXMAPS=APERPIXMAPS, PLOTIMGS=PLOTIMGS

dir = '/Users/Milena/Documents/St_Andrews/Projects/EAGLEPSB/FromJames/'
If not(keyword_set(dust)) then filename = dir+'PSB_skirtstacks_nodust.hdf5' $
    else filename = dir+'PSB_skirtstacks_dust.hdf5'

galaxyid_str = strcompress(string(galaxyid),/remove)

dir_out = dir+'Galaxy_'+galaxyid_str+'/'
If file_test(dir_out) eq 0 then spawn, 'mkdir '+ dir_out    

;h5_list, filename
;group       /galaxy_17473041             
;dataset     /galaxy_17473041/g_stack     H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_17473041/i_stack     H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_17473041/r_stack     H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_17473041/zs          H5T_FLOAT [68]
;group       /galaxy_19955964             
;dataset     /galaxy_19955964/g_stack     H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_19955964/i_stack     H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_19955964/r_stack     H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_19955964/zs          H5T_FLOAT [68]
;group       /galaxy_8154303              
;dataset     /galaxy_8154303/g_stack      H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_8154303/i_stack      H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_8154303/r_stack      H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_8154303/zs           H5T_FLOAT [68]
;group       /galaxy_9052811              
;dataset     /galaxy_9052811/g_stack      H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_9052811/i_stack      H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_9052811/r_stack      H5T_FLOAT [68, 256, 256]
;dataset     /galaxy_9052811/zs           H5T_FLOAT [68]

file = H5F_OPEN(filename)  
  
imgarray =  H5D_READ(H5D_OPEN(file, 'galaxy_'+galaxyid_str+'/'+filter+'_stack'))
zarray = H5D_READ(H5D_OPEN(file, 'galaxy_'+galaxyid_str+'/zs'))
numz = n_elements(zarray)

;; -----------------------------------------------
;; Set structure for storing output parameters
;struct = {id:0L,bpixx:0,bpixy:0,apixx:0,apixy:0,mpixx:0,mpixy:0,rmax:0.0,r20:0.0,r50:0.0,r80:0.0,r90:0.0,C2080:0.0,C5090:0.0,A:0.0,A_bgr:0.0,As:0.0,As90:0.0,S:0.0,S_bgr:0.0,G:0.0,M20:0.0,mag:0.0,mag_err:0.0,sb0:0.0,sb0_err:0.0,reff:0.0,reff_err:0.0,n:0.0,n_err:0.0}
;hdr_out = ['id','bpixx','bpixy','apixx','apixy','mpixx','mpixy','rmax','r20','r50','r80','r90','C2080','C5090','A','A_bgr','As','As90','S','S_bgr','G','M20','mag','mag_err','sb0','sb0_err','reff','reff_err','n','n_err']

struct = {id:0L,bpixx:0,bpixy:0,apixx:0,apixy:0,r20:0.0,r50:0.0,r80:0.0,r90:0.0,rmax:0.0,C:0.0,As:0.0,As90:0.0}    
hdr = ['zsnap','bpixx','bpixy','apixx','apixy','r20','r50','r80','r90','rmax','C','As','As90']
out = replicate(struct,numz)
If not(keyword_set(dust)) then $
    outfile = 'sdssmockimgRT_nodust_eagle'+galaxyid_str+'_structure_'+filter+'band.csv' $
        else outfile = 'sdssmockimgRT_dust_eagle'+galaxyid_str+'_structure_'+filter+'band.csv'
;; -----------------
;;-- SDSS parameters
;;-- filters
filters = ['u','g','r','i','z']

;;-- CCD pixel size in arcsec
pixel_size = 0.396

;;-- Values from SDSS to construct a 2-gaussian psf (median of values for 500000 SDSS fields)
psf_s12g = [1.44527,1.36313,1.21196,1.114143,1.20288] ;; in pixels
psf_s22g = [3.1865,3.06772,2.82102,2.75094,3.09981] ;; in pixels
psf_ratio =[0.081989,0.081099,0.06811,0.059653,0.054539]
psf_width = [1.54254,1.44980,1.31878,1.25789,1.29391]/pixel_size ;; originally in arcsec

;;-- Values for photometric calibration
b = [1.4,0.9,1.2,1.8,7.4]*10d^(-10)
;;- in seconds:
exptime = 53.907456
;;- in magnitudes, converted from SDSS skyerr:
skysig = [0.0047951106042681858, 0.0015403498079674194, 0.00098253076542588599, 0.00088190450872838123, 0.0010950415323111404]

;;- median SDSS values (from Jairo)
; - sky level [nanomaggy -> jansky -> mag]
sky = [1.20542,1.67145,3.99916,7.07624,20.7627]
sky_mag = -2.5*alog10(sky*(3.631*10d^(-6))/3631.)
sky_mag = sky_mag +2.5*alog10(1/pixel_size^2)    ;; per pixel

aa = [ -24.1270,  -24.5128,  -24.1073,  -23.6936,   -21.9465]
kk = [ 0.506005, 0.181950,  0.103586,  0.0628950,  0.0557740]
air = [ 1.19020,1.19027, 1.19027, 1.19022,1.19022]
gain = [1.6,3.995,4.725,4.885,4.775]
darkvar = [9.30250,1.44000,1.00000, 5.76000, 1.00000 ]



;;------------------------------------------------------------------
;; Generate aperture pixel maps
;;------------------------------------------------------------------
;; --- Binary aperture maps for compuattion of light profiles --- 
;; - Quicker if pre-prepared and saved as fits:
If keyword_set(aperpixmaps) then begin    
   ; allsizes = intarr(numz)
;    For z = 0, numz-1 do begin
;       img = reform(imgarray[z,*,*])  
;       imgsize = size(img)
;       allsizes[z] = imgsize[1]       
;    Endfor  
;    print, max(allsizes)
    mpaw_makeaperpixmaps, 249, /silent
Endif


If keyword_set(plotimgs) then begin    
    If not(keyword_set(dust)) then filename=dir_out+'eagle'+galaxyid_str+'_sdssmockimgsRT_nodust.ps' $
        else filename=dir_out+'eagle'+galaxyid_str+'_sdssmockimgsRT_dust.ps'
    set_plot, 'ps'
    device, filename=filename, xsize=8, ysize=10, yoffset=0.5, xoffset=0.3, /inches
    !P.Multi = [0,5,7]   
Endif

For z = 0, numz-1 do begin
    
    tic 
    
    snap = strcompress(string(z+1),/remove)
    If (z+1) lt 10 then snap = '0'+snap
    If not(keyword_set(dust)) then $
        imgname = dir_out+'sdssmockimgRT_nodust_eagle'+galaxyid_str+'_snap'+snap+'_'+filter+'band' $
            else imgname = dir_out+'sdssmockimgRT_dust_eagle'+galaxyid_str+'_snap'+snap+'_'+filter+'band' 
      
    
    ;; Extract image from data file
    img_jansky = reform(imgarray[z,*,*])   
    img = img_jansky
    
    zsnap = zarray[z]
    zsnap_str = strcompress(string(zsnap),/remove)    
    
    index = where(filters eq filter)
    
    ;; - temporary fix to change array[1] into a scalar... 
    ;; (reform() does not seem to work!)
    b_val = min(b[index])
    aa_val = min(aa[index])
    kk_val = min(kk[index])
    air_val = min(air[index])
    gain_val = min(gain[index])
    darkvar_val = min(darkvar[index])
    skySig_val = min(skySig[index])
    sky_val = min(sky_mag[index])
    
    ;; ----------------------------------------------------------
    ;;                     IMAGE PREPARATION
    ;; ----------------------------------------------------------
    
    ;; -----------------         
    ;; Convolve with PSF
    If keyword_set(psf) then begin
       
        kernel1 = gaussian_function(replicate(psf_s12g[index],2),width=psf_width[index],maximum=1.0)
        kernel1 = kernel1/total(kernel1)
        kernel2 = gaussian_function(replicate(psf_s22g[index],2),width=psf_width[index],maximum=psf_ratio[index])
        kernel2 = kernel2/total(kernel2)
        kernel = (kernel1+kernel2)/total(kernel1+kernel2)

        img_jansky_psf = convol(img_jansky,kernel)
        
        img = img_jansky_psf
    Endif
        
    ;; ---------
    ;; Add noise
    If keyword_set(noise) then begin
        
       index = where(filters eq filter)
        
        ;; - convert to mag
        img_mag = -2.5*alog10(img_jansky/3631.)
        ;; - add sdss zeropoint offsets 
        If filter eq 'u' then img_mag = img_mag+0.04           
        If filter eq 'z' then img_mag = img_mag-0.02
        ;; - convert to counts/pixel; force to be >= zero  
        img_ff0 = (2*b_val)* sinh(-img_mag*(alog(10)/2.5) - alog(b_val) )
        img_counts = exptime*img_ff0*10d^(-0.4*(aa_val+kk_val*air_val)) > 0      
        ;; - convert sky level to counts
        sky_ff0 = (2*b_val)*sinh(-sky_val*(alog(10)/2.5)-alog(b_val))
        sky_counts = exptime*sky_ff0*10d^(-0.4*(aa_val+kk_val*air_val)) > 0          
        ;; - build the sigma image        
        sigma_counts = sqrt((img_counts+sky_counts)/gain_val+1*(darkvar_val+skySig_val))        
        dim1 = (size(img_counts,/dim))[0]
        dim2 = (size(img_counts,/dim))[0]
        noise_counts = randomn(seed,dim1,dim2) * sigma_counts ;Gaussian random noise with sigma = error in counts (noise) 
        noise_ff0 = (noise_counts/exptime) * 10d^(0.4*(aa_val+kk_val*air_val))
        noise_jansky = 3631.*noise_ff0 ; error in flux : S = 3631*f/f0
        ;; - add noise
        img_jansky_psf_noise = img_jansky_psf + noise_jansky
        
        img = img_jansky_psf_noise

    Endif
         
    ;writefits, imgname+'_raw.fits', img_jansky
    ;writefits, imgname+'_psf.fits', img_jansky_psf
    ;writefits, imgname+'_noise.fits', img_jansky_psf_noise
    
    ;; -----------------------
    ;; Convert units to counts
    If keyword_set(units) then begin
            
        img_mag = -2.5*alog10(img/3631.)
        img_ff0 = (2*b_val)*sinh(-img_mag*(alog(10)/2.5)-alog(b_val))
        img_counts = exptime*img_ff0*10d^(-0.4*(aa_val+kk_val*air_val)) > 0
        
        img = img_counts 
        img[where(finite(img) lt 1)] = 0.0

    Endif
    
   
    ;; --------------------------------
    ;; Check size and trim if necessary
    If keyword_set(trim) then begin
    
       
        imgsize = size(img)
        npix = lonarr(2)
        npix[0] = imgsize[1]
        npix[1] = imgsize[2]
        cenpix = lonarr(2)
        cenpix[0] = npix[0]/2 + 1
        cenpix[1] = npix[1]/2 + 1
       
        ;; --- Check image size ---
        If not(keyword_set(centre)) then begin
            If npix[0] eq npix[1] and float(npix[0]/3) eq float(npix[0]/3.) then begin
                print, 'Input image size correct - proceeding without trimming...
                writefits, newimgname, img, hdr
                return
            Endif else begin
        
                ;; - Find the maximum size possible for a square image, given the position of the central pixel
                deltas = intarr(5)
                deltas[0] = npix[0]
                deltas[1] = npix[0] - cenpix[0] - 1
                deltas[2] = npix[0] - deltas[1] - 1
                deltas[3] = npix[1] - cenpix[1] - 1
                deltas[4] = npix[1] - deltas[3] - 1
                delta = min(deltas)
                maxsize = delta*2+1

                ;; - Make sure that the image can be divided into 3x3 cells (crutial for analysis)
                delta = (maxsize-3)/2
                While float(delta/3) ne float(delta)/3. do begin  
                    delta = delta - 1
                Endwhile
                ;newsize = delta*2+3

                x_min = cenpix[0] - delta -1
                x_max = cenpix[0] + delta +1
                y_min = cenpix[1] - delta -1
                y_max = cenpix[1] + delta +1
    
              ;  print, 'image size'
              ;  print, imgsize[1], imgsize[2], cenpix
              ;  print, x_min,x_max,y_min,y_max

                img = img[x_min:x_max,y_min:y_max]
            
            Endelse
        Endif
    
    Endif
    
    
    ;; --------------------
    ;; Save processed image
    writefits, imgname+'_processed.fits', img
    
    ;; ----------------------------------------------------------
    ;;                    DISPLAY IMGES IN A FILE
    ;; ----------------------------------------------------------
    
    If keyword_set(plotimgs) then begin
        TVimage, img, MultiMargin=[1,1,1,1]
        xyouts,1,9,'z: '+zsnap_str, color=fsc_color('white'),charsize=0.8,align=0.
    Endif

    ;; ----------------------------------------------------------
    ;;                           ANALYSIS
    ;; ----------------------------------------------------------
    
    out(z).id = z+1
    ;out(z).eagleid = galaxyid
    
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
    thresh = skybgr[0] + 1.*skybgr[1]
    pixmap = mpaw_pixelmap(img, thresh)       
    ;; Write in a fits file
    writefits, imgname+'_pixelmap.fits', pixmap  
        
    ;pixmap = mrdfits(imgname+'_pixelmap.fits')
        
      
    print, imgname
    
    ;; - Maximum radius from pixel map
    objectpix = where(pixmap eq 1)
    objectdist = distarr[objectpix]        
    r_max = max(objectdist)
     
    If finite(r_max) ne 1 then r_max = 0.0
    
    ;; --- Centroids ---
    ;; Compute pixel map for aperture at r_max
    aperpixmap = mpaw_aperpixmap(npix,r_max,9,0.1)
    ;aperpixmap = mpaw_aperpixmap(npix,cenpix,r_max,99,0.01)

    bpix = mpaw_maxIpix(img,pixmap)
    
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
    photpar.aa = aa_val
    photpar.kk = kk_val
    photpar.gain = gain_val
    photpar.darkvar = darkvar_val
    photpar.b = b_val
           
    result = mpaw_sbprof(img,aperpixmap,bpix,r_aper,photpar,/err,/cog) 
    rad = result.rad
    
    prof = result.prof
        
    ;; --- Concentration indices (see Bershady et al. 2000) 
    C2080 = mpaw_C(rad[0],rad[2])
               
    out(z).bpixx = bpix[0]
    out(z).bpixy = bpix[1]
    out(z).r20 = rad[0]
    out(z).r50 = rad[1]
    out(z).r80 = rad[2]
    out(z).r90 = rad[3]   
    out(z).rmax = r_max 
    out(z).C = C2080
     
    apix = mpaw_minApix(img,pixmap,aperpixmap)
    ;; --- Shape asymmetry ---
    As = mpaw_a(pixmap,pixmap,aperpixmap,apix,rmax,180.)
    As90 = mpaw_a(pixmap,pixmap,aperpixmap,apix,rmax,90.)
    
    out(z).apixx = apix[0]
    out(z).apixy = apix[1]   
    out(z).As = As
    out(z).As90 = As90
           
    write_csv, dir_out+outfile, out, header=hdr
    
    print, 'C', C2080
    print, 'As', As
        
    print, 'Snaphsot ', z+1, ' done!. Total number of snapshots: ', numz
    print, '(imgsize:', imgsize, ')'
    
    time = toc()
    print, 'Analysis time: ', time
    
    print, '****************'
Endfor

If keyword_set(plotimgs) then begin
    !P.Multi = 0
    device, /close 
Endif


END