    ;; A function to centre the aperture mask on a specific pixel (using pre-prepared masks)
        
        Function mpaw_apercentre, apermask, pix
             
            imgsize = size(apermask)
            npix = imgsize[1]
    
            cenpix = fltarr(2)
            cenpix[0] = npix/2 + 1
            cenpix[1] = npix/2 + 1
               
            del = pix - cenpix
            
            ;; Create a new mask
            x = findgen(npix)
            y = findgen(npix)
            mask = x#y * 0
            
            ind = where(apermask eq 1)
            
            For i = 0, n_elements(ind)-1 do begin
                ind2d = array_indices(mask,ind[i])
                If (ind2d[0]+del[0]) le npix-1 and (ind2d[1]+del[1]) le npix-1 then mask[ind2d[0]+del[0],ind2d[1]+del[1]] = 1
            Endfor
          
            return, mask
            
        End