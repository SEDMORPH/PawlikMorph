Function mpaw_sbprof, img, maxaper, centroid, radii, photpar, err=err, cog=cog
  
    imgsize = size(img)
    npix = imgsize[1]
    cenpix = fltarr(2)
    cenpix[0] = npix/2 + 1
    cenpix[1] = npix/2 + 1
    
    ;; --- Calculate flux within the maximum radius ---
    ;; - Mean flux
    ind = where(maxaper eq 1)
    pix = img[ind]
    If keyword_set(err) then flux = mpaw_apercounts(pix,photpar,/err)
    If not(keyword_set(err)) then flux = mpaw_apercounts(pix)  
    ;; - Convert to total flux
    apersize = size(pix)
    numpix = long(apersize[1])
    ;aperarea = numpix*(1./(2.5))^2.
    aperarea = numpix   
    tot_flux = flux[0] * float(aperarea)
    
    ;; --- Calculate radial profiles and cumulative profiles ---
    numaper = n_elements(radii)
    numannul = numaper - 1
  
    aper_prof = fltarr(numaper)
    annul_prof = fltarr(numannul)
    annul_prof_err = fltarr(numannul)

    struct = {mask:fltarr(npix,npix)}
    aper = replicate(struct, numaper)
    
    For ii = 0, numaper-1 do begin
        
        aper_id = ii + 1
        aper_rad = radii[ii]
        tempmaskfile = 'aperpixmaps/aperture'+strcompress(string(ii),/remove)+'.fits'
        If file_test(tempmaskfile) eq 1 then begin
            tempmask = mrdfits(tempmaskfile,/fscale,/silent)
        Endif else if file_test(tempmaskfile) eq 0 then begin
            print, 'ERROR! MPAW_SBPROFCOUNTS: Aperture pixel map not found. Rerun with keyword /aperpixmap.'
            stop
        Endif
                        
        masksize = size(tempmask)
        If npix gt masksize[1] then begin
            print, npix, masksize[1]
            print, 'ERROR! MPAW_SBPROFCOUNTS: Incorrect size of aperture pixel map! Rerun with keyword /aperpixmap.'
            stop
        Endif else if npix lt masksize[1] then begin
             print, npix, masksize[1]
            print, 'WARNING! MPAW_SBPROFCOUNTS: Aperture pixel map too large! Trimming ...'
            
            ;; *** Temporary fix ***
            ;; Any pixel map should be a squre with *odd* number of pixels per side but just in case ...
            If float(masksize[1])/2. eq masksize[1]/2 then del = (masksize[1] - npix)
            If float(masksize[1])/2. ne masksize[1]/2 then del = (masksize[1] - npix)/2 
                   
            tempmask = tempmask[del:masksize[1]-del-1,del:masksize[1]-del-1]
              
        Endif
          
        apermask = mpaw_apercentre(tempmask,centroid)
          
        ;; --- Get aperture flux ---               
        aper_ind = where(apermask eq 1)
        aper_pix = img[aper_ind]        
        If keyword_set(err) then aper_flux = mpaw_apercounts(aper_pix,photpar,/err)
        If not(keyword_set(err)) then aper_flux = mpaw_apercounts(aper_pix)
            
        ;; --- Innermost aperture ---
        If ii eq 0 then begin      
            aper0_prof = aper_flux[0]
            aper0_prof_err = aper_flux[1]
        Endif
        
         
        ;; --- Cumulative profile ---
        apersize = size(aper_pix)
        numpix = long(apersize[1])
       ; aperarea = numpix*(1./(2.5))^2.
        aperarea = numpix
        aper_prof[ii] = aper_flux[0]*float(aperarea)
        
        ;; --- Save aperture masks in a structure ---
        ;help, apermask
        aper(ii).mask = apermask
        
                
    Endfor

    ;; --- Get flux in the surounding annuli up to r_max ---
    For ii = 0, numannul-1 do begin
        
        annul_id = ii + 1
        annulmask = aper(ii+1).mask - aper(ii).mask  
      
        annul_ind = where(annulmask eq 1)
        annul_pix = img[annul_ind]
        If keyword_set(err) then annul_flux = mpaw_apercounts(annul_pix,photpar,/err)
        If not(keyword_set(err)) then annul_flux = mpaw_apercounts(annul_pix)
        annul_prof[ii] = annul_flux[0]
        annul_prof_err[ii] = annul_flux[1]
        
        
        ;print, 'Annulus ', ii, annul_prof[ii]
    Endfor
    
    ;cgplot, radii, aper_prof
    
   ; print, aper_prof
;    stop
    
    ;; --- Get growth curve radii ---
    If not(keyword_set(cog)) then begin
        r20 = (r50 = (r80 = (r90 = 0.0)))
    Endif else begin
        ;; Interpolate
        radii_interp = (findgen((round(max(radii))-round(min(radii)))*1000)+1)/1000.+ min(radii)
        aper_prof_interp = interpol(aper_prof, radii, radii_interp)
    
        radii_interp_size = size(radii_interp)
        numradii = radii_interp_size[1]
    
        ;; Sum up flux until reaches certain fraction of total flux    
        totflux = tot_flux
        oldflux = 0    
        r20 = ( r50 = ( r80 = ( r90 = -99)))
        For ii = 0, numradii-1 do begin
        
            newflux = aper_prof_interp[ii]
            
          ;  print, newflux, totflux
            
            If (oldflux lt 0.2*totflux and newflux gt 0.2*totflux) then r20 = radii_interp[ii]
            If (oldflux lt 0.5*totflux and newflux gt 0.5*totflux) then r50 = radii_interp[ii]
            If (oldflux lt 0.8*totflux and newflux gt 0.8*totflux) then r80 = radii_interp[ii]
            If (oldflux lt 0.9*totflux and newflux gt 0.9*totflux) then r90 = radii_interp[ii]
        
            oldflux = newflux
        
        Endfor

    Endelse
    
    
    ;; Output 
    output = {rad:fltarr(4),prof:fltarr(numaper),proferr:fltarr(numaper)}
    
    output.rad = [r20,r50,r80,r90]
    output.prof = [aper0_prof, annul_prof]
    output.proferr = [aper0_prof_err, annul_prof_err]    
    
    aper = 0
    
    return, output
    
End