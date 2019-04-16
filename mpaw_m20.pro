Function mpaw_m20, img, pixmap
    
    imgsize = size(img)  
    npix = imgsize[1]   
    cenpix = fltarr(2)
    cenpix[0] = npix/2 + 1
    cenpix[1] = npix/2 + 1
    dist = mpaw_distarr(npix,npix,cenpix)
    
    tempmap = img * 0
        
    objind = where(pixmap eq 1)
    tempmap[objind] = img[objind]
      
    sorted_ind = reverse(sort(tempmap))
    sorted_map = tempmap[sorted_ind]
    sorted_dist = dist[sorted_ind]
    
    numpix = n_elements(tempmap)
    
    Mpix = fltarr(numpix)
    Ipix = fltarr(numpix)
    
    For ii = 0, numpix-1 do begin
        Ipix[ii] = sorted_map[ii]
        Mpix[ii] = Ipix[ii]*(sorted_dist[ii]*sorted_dist[ii])
    Endfor
    Mtotal = total(Mpix)
    Itotal = total(Ipix)
    ii = 0
    Msum = 0
    Isum = 0
    While ii lt numpix do begin
        If Ipix[ii] gt 0 then begin
            Isum = Isum + Ipix[ii]
            Msum = Msum + Mpix[ii]
        Endif
        If Isum ge 0.2*Itotal then ii = numpix
        ii = ii + 1
    Endwhile
    
    M20 = alog10(Msum/Mtotal)
      
    return, M20
    
End
    