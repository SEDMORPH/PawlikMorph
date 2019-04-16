;; Clean image of non-overlappng sources (outside of the object's pixel map)

Function mpaw_cleanimg, img, pixmap

    imgsize = size(img)
    npix = imgsize[1]
    imgclean = img
    
    ;; Dilate pixel map 
    element = replicate(1,9,9)
    map = dilate(pixmap,element)
    
    skyind = where(map ne 1)
   
    If n_elements(skyind) gt 10 then begin
        
        ;;  --- Find a threshold for defining sky pixels ---
        meansky = mean(img[skyind])
        mediansky = median(img[skyind])
        
        If meansky le mediansky then begin
            thresh = meansky 
        Endif else begin
            
            sigmasky = sqrt( total( (img[skyind] - meansky)^2 ) / (float(n_elements(img[skyind]))) )
      
            mode_old = 3.*mediansky - 2.*meansky
            mode_new = 0.0
            w = 0
            clipsteps = n_elements(img)
                
            While w lt clipsteps do begin

                skyind = where(abs(img[skyind]-meansky) lt 3.*sigmasky)
                meansky = mean(img[skyind])
                mediansky = median(img[skyind])
                sigmasky = sqrt( total( (img[skyind] - meansky)^2 ) / (float(n_elements(img[skyind]))) )
      
                mode_new = 3.*mediansky - 2.*meansky
                mode_diff = abs(mode_old - mode_new)
                
                If mode_diff lt 0.01 then begin  
                    modesky = mode_new
                    w = clipsteps
                Endif else begin 
                    w = w + 1
                Endelse
                
                mode_old = mode_new
                
            Endwhile
            
            thresh = modesky 
            
        Endelse
        
        ;; --- Mask out sources with random sky pixels ---
        
        skypix = where(pixmap ne 1 and img gt thresh)
        
        skypixels = img[skypix]
        allpixels = skypixels
        
        If n_elements(skypixels) ge n_elements(img) then begin
            print, 'ERROR: No sources detected! Check image and pixel map.'
        Endif else begin
            pixfrac = float(n_elements(img))/float(n_elements(skypixels))
            ;; If whole number:
            If pixfrac eq float(round(pixfrac)) then begin
                For p = 1, long(pixfrac)-1 do begin
                    allpixels = [allpixels,skypixels]
                Endfor
            Endif else begin
                wholefrac = float(round(pixfrac))
                ;restfrac = (pixfrac - wholefrac)
                ;restnum = long(restfrac*n_elements(skypixels))
                For p = 1, long(pixfrac)-1 do begin
                    allpixels = [allpixels,skypixels]
                Endfor
                diff = n_elements(img)-n_elements(allpixels)
                allpixels = [allpixels,skypixels[0:diff-1]]
            Endelse
        Endelse
   
    allpixels = shuffle(allpixels)
  
    skyimg = make_array(npix,npix,/integer,value=1) * allpixels
    imgclean[where(pixmap ne 1 and img ge thresh)] =  skyimg[where(pixmap ne 1 and img ge thresh)]
        
    Endif   

    return, imgclean
    

End