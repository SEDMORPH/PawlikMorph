Function mpaw_growthcurve, img, maxaper, npix, cenpix, centroid, radii, photpar, err=err

    numaper = n_elements(radii)
    aper_prof = fltarr(numaper)
    
    ;; Calculate mean flux within the maximum radius
    ind = where(maxaper eq 1)
    pix = img[ind]
   ; flux = my_flux(pix,bgr,exptime,airmass,aa,kk,gain,darkvar,b,flux20)
    If keyword_set(err) then flux = mpaw_apercounts(pix,photpar,/err)
    If not(keyword_set(err)) then flux = mpaw_apercounts(pix)
  
    ;; To get the total flux need to multiply the mean flux by the aperture area
    apersize = size(pix)
    numpix = long(apersize[1])
    aperarea = numpix*(1./(2.5))^2.
    tot_flux = flux[0] * aperarea
    
    ;; Calculate (cummulative) surface brightness profile
    For ii = 0, numaper-1 do begin
       
        ;; Mean flux
        aper_id = ii + 1
        aper_rad = radii[ii]
        ;aper_mask = my_aper([npix_x,npix_y], cenpix, aper_rad, nsubpix)
        temp_mask = mrdfits('ap'+strcompress(string(ii),/remove)+'.fits',/fscale)
        If npix_x lt 141 then begin
            del = (141 - npix_x)/2
            temp_mask = temp_mask[del-1:npix_x-del-1,del-1:npix_y-del-1]
        Endif
        aper_mask = my_apercentre(temp_mask,cenpix)
        aper_ind = where(aper_mask eq 1)
        aper_pix = img[aper_ind]
        ;aper_flux = my_flux(aper_pix,bgr,exptime,airmass,aa,kk,gain,darkvar,b,flux20)
        aper_flux = my_flux_counts(aper_pix,bgr,exptime,gain,darkvar,flux20)
        ;; Cummulative profile
        apersize = size(aper_pix)
        numpix = long(apersize[1])
        aperarea = numpix*(1./(2.5))^2.
        
        aper_prof[ii] = aper_flux[0] * aperarea
        
    Endfor

    ;; Interpolate
    radii_interp = (findgen((round(max(radii))-round(min(radii)))*1000)+1)/1000.+ min(radii)
    aper_prof_interp = interpol(aper_prof, radii, radii_interp)

   ; print, 'radii', radii_interp
   ; print, 'prof', aper_prof_interp
    
   ; print, 'total flux', tot_flux
    
    radii_interp_size = size(radii_interp)
    numradii = radii_interp_size[1]
    
    ;; Sum up flux until reaches certain fraction of total flux
    
    totflux = tot_flux
    oldflux = 0
    
    r20 = ( r50 = ( r80 = ( r90 = 0.0)))
    For ii = 0, numradii-1 do begin
        
        newflux = aper_prof_interp[ii]
        
        If (oldflux lt 0.2*totflux and newflux gt 0.2*totflux) then r20 = radii_interp[ii]
        If (oldflux lt 0.5*totflux and newflux gt 0.5*totflux) then r50 = radii_interp[ii]
        If (oldflux lt 0.8*totflux and newflux gt 0.8*totflux) then r80 = radii_interp[ii]
        If (oldflux lt 0.9*totflux and newflux gt 0.9*totflux) then r90 = radii_interp[ii]
        
        oldflux = newflux
        
    Endfor

    rad = [r20, r50, r80, r90]
    
    return, rad
    
End 