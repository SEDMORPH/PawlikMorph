Function mpaw_g, img, pixmap

    imgsize = size(img)
    npix= imgsize[1]
    
    tempmask = img*0
    objind = where(pixmap eq 1)
    
    If objind[0] ne -1 then begin
        obj = img[objind]
        objsize = size(obj)
        tempmask[objind] = img[objind]
    
        numpix = objsize[1]
        meanpix = total(obj) / numpix
    
        sorted_objind = sort(obj)
        sorted_obj = obj[sorted_objind]
       
        factor = 1./(abs(meanpix)*(numpix*(numpix-1.)))
    
        terms = fltarr(numpix)

        print, numpix, n_elements(obj), n_elements(sorted_obj)
        For ii = 0, numpix-1 do begin
            terms[ii] = (2.*ii - numpix - 1.) * abs(sorted_obj[ii])
        Endfor  
            
        G = factor * total(terms)
    Endif else begin
        G = -99.
    Endelse
     
    return, G
End

