Function mpaw_minmpix, img, objmask

    imgsize = size(img)
    npix = imgsize[1]
 
    objind = where(objmask eq 1)
    
    If objind[0] ne -1 then begin
     
    objind_2d = array_indices(objmask,objind)
     
    tempmask = 0. * objmask
    tempmask[objind] = img[objind]
     
    ;; Sort pixels by flux (brightest to faintest)
    sortedind = reverse(sort(tempmask))
    
    ;; Keep track of their position in 2d-space
    sortedind_2d = array_indices(objmask,sortedind)
    
    ;; Assign flux values to each pixel
    sorted_mask = tempmask[sortedind]
   
    Ipix = fltarr(n_elements(tempmask))
    For ii = 0, n_elements(tempmask)-1 do begin
        Ipix[ii] = sorted_mask[ii]
    Endfor

    Itotal = total(Ipix)
    ii = 0
    Isum = 0
    count = 0
    While ii lt n_elements(tempmask) do begin
        If Ipix[ii] gt 0 then begin
            count = count + 1
            Isum = Isum + Ipix[ii]
        Endif
        If Isum ge 0.3*Itotal then ii = n_elements(tempmask)
        ii = ii + 1
    Endwhile
    
    ii = 0
    jj = 0
    regionpix = fltarr(count)
    regionpix_x = fltarr(count)
    regionpix_y = fltarr(count)
    
    Isum = 0
    
    While ii lt n_elements(tempmask) do begin
        If Ipix[ii] gt 0 then begin
            
            regionpix[jj] = sortedind[ii]
            regionpix_2d = array_indices(tempmask,sortedind[ii])
            regionpix_x[jj] = regionpix_2d[0]
            regionpix_y[jj] = regionpix_2d[1]
          
            Isum = Isum + Ipix[ii]
            jj = jj + 1
        Endif
        If Isum ge 0.3*Itotal then ii = n_elements(tempmask)
        ii = ii + 1
    Endwhile
    
    ;; Calculate Mtotal
    
    Mtotal = fltarr(n_elements(regionpix))
    
    For i = 0, n_elements(regionpix)-1 do begin
        
        curpix_x = regionpix_x[i]
        curpix_y = regionpix_y[i]
        
        dist = mpaw_distarr(npix,npix,[curpix_x,curpix_y])
        sorted_dist = dist[sortedind]
    
        Mpix = fltarr(n_elements(tempmask))
        Ipix = fltarr(n_elements(tempmask))

        For ii = 0, n_elements(tempmask)-1 do begin
            Ipix[ii] = sorted_mask[ii]
            Mpix[ii] = Ipix[ii]*(sorted_dist[ii]*sorted_dist[ii])
        Endfor
    
        Mtotal[i] = total(Mpix)
        
    Endfor
    
    Mtotal_min = min(Mtotal,sub)
    
    centroid_ind = regionpix[sub]
    centroid = array_indices(img,centroid_ind)
    
Endif else begin
    centroid = [0,0]
Endelse

    return, centroid

End