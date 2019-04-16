;; Optional: coordsfile - object coordinated for centering; of none specified and /centre keyword set, the image is centred on the brightest pixel instead;

PRO mpaw_sdsstrim, imgname, newimgname, coords, centre=centre

    img = mrdfits(imgname,/fscale)
    data = mrdfits(imgname,0,hdr)
    
    imgsize = size(img)
    npix = lonarr(2)
    npix[0] = imgsize[1]
    npix[1] = imgsize[2]
    cenpix = lonarr(2)
    cenpix[0] = npix[0]/2 + 1
    cenpix[1] = npix[1]/2 + 1
    
    print, 'SIZE',imgsize
        
    ;; --- Check image size ---
    If not(keyword_set(centre)) then begin
        If npix[0] eq npix[1] and float(npix[0]/3) eq float(npix[0]/3.) then begin
            print, 'Input image size correct - proceeding without trimming...
            writefits, newimgname, img, hdr
            return
        Endif else begin
            
            ;; - Find the maximum size possible for a square image, given the position of the central pixel
            deltas = intarr(5)
            deltas[0] = npix[0]
            deltas[1] = npix[0] - cenpix[0] - 1
            deltas[2] = npix[0] - deltas[1] - 1
            deltas[3] = npix[1] - cenpix[1] - 1
            deltas[4] = npix[1] - deltas[3] - 1
            delta = min(deltas)
            maxsize = delta*2+1
    
            ;; - Make sure that the image can be divided into 3x3 cells (crutial for analysis)
            delta = (maxsize-3)/2
            While float(delta/3) ne float(delta)/3. do begin  
                delta = delta - 1
            Endwhile
            ;newsize = delta*2+3
    
            x_min = cenpix[0] - delta -1
            x_max = cenpix[0] + delta +1
            y_min = cenpix[1] - delta -1
            y_max = cenpix[1] + delta +1
        
            print, 'image size'
            print, imgsize[1], imgsize[2], cenpix
            print, x_min,x_max,y_min,y_max
    
            img = img[x_min:x_max,y_min:y_max]
    
            writefits, newimgname, img, hdr
        
            
            
        Endelse
        
    Endif else if keyword_set(centre) then begin
                
        
            ;; Centre on the object coordinates if provided; 
            ;; otherwise use the maximum-intensity pixel
            If n_elements(coords) eq 2 then begin
                cenpix = coords 
            Endif else begin
                bright = max(img,ind) 
                brightpix = array_indices(img,ind)
                cenpix = brightpix
            Endelse  
       
    
        ;; - Find the maximum size possible for a square image, given the position of the central pixel
        deltas = intarr(5)
        deltas[0] = npix[0]
        deltas[1] = npix[0] - cenpix[0] - 1
        deltas[2] = npix[0] - deltas[1] - 1
        deltas[3] = npix[1] - cenpix[1] - 1
        deltas[4] = npix[1] - deltas[3] - 1
        delta = min(deltas)
        maxsize = delta*2+1
    
        ;; - Make sure that the image can be divided into 3x3 cells (crutial for analysis)
        delta = (maxsize-3)/2
        While float(delta/3) ne float(delta)/3. do begin  
            delta = delta - 1
        Endwhile
        ;newsize = delta*2+3
    
        x_min = cenpix[0] - delta -1
        x_max = cenpix[0] + delta +1
        y_min = cenpix[1] - delta -1
        y_max = cenpix[1] + delta +1
        
        print, 'image size'
        print, imgsize[1], imgsize[2], cenpix
        print, x_min,x_max,y_min,y_max
    
        img = img[x_min:x_max,y_min:y_max]
    
        writefits, newimgname, img, hdr
        
    Endif
        
           
End