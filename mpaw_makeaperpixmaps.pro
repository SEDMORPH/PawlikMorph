PRO mpaw_makeaperpixmaps, npix, annuli=annuli, silent=silent

    cenpix = npix/2 + 1    
    r_aper = findgen(cenpix)+1.
    
    numaper = n_elements(r_aper)
    numannul = numaper-1
    
    struct = {map:fltarr(npix,npix)}
    aper = replicate(struct, numaper)
    
    For i = 0, numaper-1 do begin
     
        aperpixmap = mpaw_aperpixmap(npix,r_aper[i],9,0.1)
       ; aperpixmap = mpaw_aperpixmap(npix,[cenpix,cenpix],r_aper[i],9,0.1)
        ;aperpixmap = mpaw_aperpixmap(npix,cenpix,r_max,99,0.01)
        
        If not(keyword_set(silent)) then begin
            
            pix = where(aperpixmap eq 1)
            If n_elements(pix) eq 1 then begin
                If pix eq -1 then print, 'No pixels included in the aperture pixel map'
                If pix ne -1 then print, ' Number of pixels: ', 1
            Endif else begin
                print, 'Number of pixels: ', n_elements(pix)
            Endelse
        
        Endif
        
        writefits, 'aperpixmaps/aperture'+strcompress(string(i),/remove)+'.fits', aperpixmap
        aper(i).map = aperpixmap
        
    Endfor
    
    If keyword_set(annuli) then begin        
       
        For i = 0, numannul-1 do begin
        
            annul_id = i + 1
            annulpixmap = aper(i+1).map - aper(i).map 
      
            If not(keyword_set(silent)) then begin
            
                pix = where(annulpixmap eq 1)
                If n_elements(pix) eq 1 then begin
                    If pix eq -1 then print, 'No pixels included in the annulus pixel map'
                    If pix ne -1 then print, ' Number of pixels in the annulus: ', 1
                Endif else begin
                    print, 'Number of pixels in the annulus: ', n_elements(pix)
                Endelse
        
            Endif
               
            writefits, 'apertures/annulus'+strcompress(string(i),/remove)+'.fits', annulpixmap
                
       
        Endfor    
    Endif
    
End