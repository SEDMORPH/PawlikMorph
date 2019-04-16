;; ----------------------------------------------------------------------- ;;
;; A function to determine aperture pixels (through pixel samping) knowing ;;
;;           the aperture radius and the number of subpixels.              ;;


Function mpaw_aperpixmap, npix, rad, nsubpix, frac
    
        npix = long(npix)
        ;imgsize = size(img)
        ;npix = imgsize[1]
        
        cenpix = fltarr(2)
        cenpix[0] = npix/2 + 1
        cenpix[1] = npix/2 + 1
        
        mask = 0 * (lindgen(npix)#lindgen(npix))
        submask = 0 * (lindgen(npix*nsubpix)#lindgen(npix*nsubpix))
          
        submasksize = size(submask)
             
        ;; Create distance array
        dist = mpaw_distarr(npix,npix,cenpix)
        
        ;; Create subdistance array
        subdist = mpaw_subdistarr(npix,nsubpix,cenpix)
    
      ;; Assign subpixels and their distances to the correct pixels 

        ;; Pixel coordinates:
        x_coord = 0
        y_coord = 0

        ;; Subpixel coordinates:
        x_min = 0
        y_min = 0
        x_max = nsubpix - 1
        y_max = nsubpix - 1

        pixelstr = {ind:0L, coord:fltarr(2), subpixels:fltarr(nsubpix,nsubpix)}
 
        pixel = replicate(pixelstr,npix*npix)
                
        i = 0L
        While i lt npix*npix do begin
          
            pixel[i].subpixels = subdist[x_min:x_max,y_min:y_max]
            pixel[i].coord = [x_coord,y_coord]
            pixel[i].ind = i
            
            x_coord = x_coord + 1
    
            x_min = x_min + nsubpix
            x_max = x_max + nsubpix
    
            If y_max gt submasksize[2] then break
            If x_max gt submasksize[1] then begin
        
                x_coord = 0
                y_coord = y_coord + 1
        
                x_min = 0
                x_max = nsubpix - 1
                y_min = y_min + nsubpix
                y_max = y_max + nsubpix
        
            Endif
    
            i = i + 1
    
        Endwhile

        For i = 0, (npix*npix)-1 do begin
    
            apersubpix = where(pixel[i].subpixels le rad)
            apersubpix_size = size(apersubpix)
    
            fraction = float(apersubpix_size[1])/((nsubpix*nsubpix))
            ;0.01 recreates the number of pixels within the first 8 SDSS apertures!!
            If fraction ge frac then begin
                mask[pixel(i).ind] = 1
            Endif
    
        Endfor
        
        
        return, mask
        

End