;; Estimates the level of sky background in an image. 
;; 
;; Flag = 1 
;; Indicates unreliable measurement - if the sky region used for the estimate is smaller than 20000 pixels (Simard et al. 2011)

Function mpaw_skybgr, img
    
    imgsize = size(img)
    npix = imgsize[1]
    cenpix = fltarr(2)
    cenpix[0] = npix/2 + 1
    cenpix[1] = npix/2 + 1
    distarr = mpaw_distarr(npix, npix, cenpix)
    
    ;; Estimate the sky background level 
   
    yfit = gauss2dfit(img,coeff)
    fwhm_x = 2*sqrt(2*alog(2))*coeff[2]
    fwhm_y = 2*sqrt(2*alog(2))*coeff[3]
    r_in = 2*max(fwhm_x,fwhm_y)
    
    ;; Define the sky region
    skyind = where(distarr gt r_in)
    skyregion = img[skyind]
    
    ;; Flag the measurement if sky region smaller than 20000 pixels (Simard et al. 2011)
    If n_elements(skyregion) gt 100 then begin
        
        If n_elements(skyregion) gt 20000 then begin
            flag = 0        
        Endif else begin
            flag = 1            
        Endelse
        mean_sky = mean(skyregion)
        median_sky = median(skyregion)
        sigma_sky = sqrt( total( (skyregion - mean_sky)^2 ) / (float(n_elements(skyregion))) )
      
        If mean_sky le median_sky then begin
            ;print, 'Non-crowded region. Using mean value for the sky background estimate:'
            sky = mean_sky
            sky_err = sigma_sky
        Endif    
        
        If mean_sky gt median_sky then begin
           
            ;print, 'Crowded region. Using mode for the sky background estimate.'
            ;print, 'Begin sigma clipping until mode convergence...'
           
            mode_old = 3.*median_sky - 2.*mean_sky
            mode_new = 0.0
            w = 0
            clipsteps = n_elements(skyregion)
                
            While w lt clipsteps do begin

                skyind = where(abs(skyregion-mean_sky) lt 3.*sigma_sky) 
                skyregion = skyregion[skyind] 
                skysize = size(skyregion)
  
                mean_sky = mean(skyregion)
                median_sky = median(skyregion)
                sigma_sky = sqrt( total( (skyregion - mean_sky)^2 ) / (float(n_elements(skyregion))) )            
                mode_new = 3.*median_sky - 2.*mean_sky
                mode_diff = abs(mode_old - mode_new)

                If mode_diff lt 0.01 then begin
                        
                    mode_sky = mode_new
                    ;print, 'Number of iterations in sky estimation', w
                    w = clipsteps

                Endif else begin 
                    w = w + 1
                Endelse

                mode_old = mode_new

            Endwhile

                ;print, 'Sigma clipping finished. Sky background estimate:'
            sky = mode_sky
            sky_err = sigma_sky  
            
        Endif
    
            
    Endif else begin
        sky = -99
        sky_err = -99
        flag = -99           
    Endelse   
      
    return, [sky, sky_err, flag]
   
End