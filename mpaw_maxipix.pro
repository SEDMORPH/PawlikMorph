Function mpaw_maxipix, img, objmask
    
    brightpix = fltarr(2)
              
    fluxmask = objmask * 0
       
    ;; Find pixels belonging to the object
    ;; - 1D indices:
    objind = where(objmask eq 1) 
 
    If objind[0] ne -1 then begin
   
        tempmask = objmask*0.
        tempmask[objind] = img[objind]
    
        ;; Sort pixels by flux (brightest to faintest)
        sortedind = reverse(sort(tempmask))
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
     
        fluxmask[regionpix] = img[regionpix]
        
        max = max(fluxmask, maxind)
        maxpix = array_indices(fluxmask, maxind)
        
        brightpix[0] = maxpix[0] + 1
        brightpix[1] = maxpix[1] + 1
        
    Endif else begin
        brightpix = [0,0]
    Endelse
           
    return, long(brightpix)
    
    fluxmask = 0
    
End
