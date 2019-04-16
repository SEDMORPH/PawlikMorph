;; Function for distance array sampling


Function mpaw_subdistarr, npix, nsubpix, cenpix

    xneg = findgen((npix/2)*nsubpix)/nsubpix - cenpix[0]
    xpos = reverse(-xneg)
    zeroes = fltarr(nsubpix)
    x1 = [xneg,zeroes,xpos]
   ; x1 = findgen(npix_x*nsubpix-)/nsubpix - cenpix[0]
    x2 = x1*0. + 1.
    
    yneg = findgen((npix/2)*nsubpix)/nsubpix - cenpix[1]
    ypos = reverse(-yneg)
    zeroes = fltarr(nsubpix)
    y1 = [yneg,zeroes,ypos]
   ; y1 = findgen(npix_y*nsubpix-)/nsubpix - cenpix[1]
    y2 = y1*0. + 1.
      
    subpix_x = temporary(x1)#temporary(y2)
    subpix_y = temporary(x2)#temporary(y1)
    
    subdist = sqrt(temporary(subpix_x)^2 + temporary(subpix_y)^2)
    
    ;; Set all unnecessary arrays to zero
   
    
    return, subdist
    
End
