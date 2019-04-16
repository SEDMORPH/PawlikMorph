;; Find the minimum asymmetry central pixel within the object pixels:
;; - select a range of candidate centroids - pixels within the brigthest region that comprises 20% of the total flux within the object pixel map;
;; - measure asymmetry of the image under rotation around each of the candidate centroids;
;; - pick a centroid that yields the minimum A value;

;; *** NOTE: This is different from the traditional approach (see e.g. Conselice et al. 2000) where the measurement of A is made for a pre-determined initial centroid and its neighbouring 8 pixels and only if one of the neighbouring pixels yields a lower value than the centroid, the procedure is repeated for that neigbouring pixel. Our approach reduces the chance of being stuck in a local asymmetry minimum (not found by Conselice at al 2000 but perhaps could be the case in more messed up galaxies).

Function mpaw_minapix, img, objmask, apermask
    
    imgsize = size(img)
    npix = imgsize[1]
    cenpix = fltarr(2)
    cenpix[0] = npix/2 + 1
    cenpix[1] = npix/2 + 1
    
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
        If Isum ge 0.2*Itotal then ii = n_elements(tempmask)
        ii = ii + 1
    Endwhile
    
    ii = 0
    jj = 0
    regionpix = fltarr(count)
    regionpix_x = fltarr(count)
    regionpix_y = fltarr(count)
    
    Isum = 0
    
    While ii lt count-1 do begin
        If Ipix[ii] gt 0 then begin
            
            regionpix[jj] = sortedind[ii]
            regionpix_2d = array_indices(tempmask,sortedind[ii])
            regionpix_x[jj] = regionpix_2d[0]
            regionpix_y[jj] = regionpix_2d[1]
          
            Isum = Isum + Ipix[ii]
            jj = jj + 1
        Endif
        If Isum ge 0.2*Itotal then ii = count
        ii = ii + 1
    Endwhile
    
    regionpix_x = regionpix_x[0:count-1]
    regionpix_y = regionpix_y[0:count-1]
    ;; Calculate the asymmetry parameter for each 'bright galaxy pixel' 
    ;; (store all values in an array and keep track of the pixel positions)
    
    A = fltarr(n_elements(regionpix))
    
    For i = 0, n_elements(regionpix)-1 do begin
   
        cenpix_x = regionpix_x[i]
        cenpix_y = regionpix_y[i]
        
        imgRot = rot(img,180.,1.0,cenpix_x,cenpix_y,/pivot)
        imgResid = abs(img - imgRot)
        
        regionmask = mpaw_apercentre(apermask,[cenpix_x,cenpix_y])

        regionind = where(regionmask eq 1)
        region = img[regionind]
        regionResid = imgResid[regionind]
    
        regionmask = regionmask * 0
    
        A[i] = total(regionResid) / (2.*total(abs(region)))
    
    Endfor
    
    A_min = min(A,sub)
    
    centroid_ind = regionpix[sub]
    centroid = array_indices(img,centroid_ind)
    
Endif else begin
    centroid = [0,0]
Endelse
    
    return, centroid
    
    
    
End
