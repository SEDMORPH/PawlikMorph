;; Compute the clumpiness parameter 

;; Optionam arguments: -apermaskcut (if /sout set)


Function mpaw_s, img, pixelmap, apermask, width, apermaskcut, noisecorrect=noisecorrect, sout=sout
        
    imgSmooth = filter_image(img,smooth=width)
    imgResid = abs(img - imgSmooth)      
    img = abs(img)
   
    If keyword_set(sout) then $
        netmask = apermask-apermaskcut $
            else netmask = apermask
          
    regionind = where(netmask eq 1)
    region = img[regionind]
    regionResid = imgResid[regionind]
    
    netmask=netmask*0
   
    S = total(regionResid) / total(region)
    
    If keyword_set(noisecorrect) then begin 
        
        ;; ---------------------------------------------
        ;; Noise correction
        ;; ---------------------------------------------    
        ;; --- Build a `background noise' image ---
        bgrimg = img*0.
        ;; - Determine pixels to be masked out
        element = replicate(1,9,9)
        mask = dilate(pixelmap,element)
        maskind = where(mask eq 1) 
        ;; - Determine background pixels
        bgrind = where(mask ne 1)
        bgrpix = img[bgrind]
    
        If float(n_elements(bgrind)) gt float(n_elements(maskind))/10. then begin
            If n_elements(maskind) gt 1 then begin
                If n_elements(bgrind) ge n_elements(maskind) then begin
                    maskpix = bgrpix[0:n_elements(maskind)-1]
                Endif else begin
                    pixfrac = float(n_elements(maskind))/float(n_elements(bgrind))
                    ;; If whole number:
                    maskpix = bgrpix
                    If pixfrac eq float(round(pixfrac)) then begin
                        For p = 1, long(pixfrac)-1 do begin
                            maskpix = [maskpix,bgrpix]
                        Endfor
                    Endif else begin
                        For p = 1, long(pixfrac)-1 do begin
                            maskpix = [maskpix,bgrpix]
                        Endfor
                        diff = n_elements(maskind)-n_elements(maskpix)
                        maskpix = [maskpix,bgrpix[0:diff-1]]
                    Endelse
                Endelse
        
                bgrimg[bgrind] = bgrpix
                bgrimg[maskind] = maskpix
        
                bgrimgSmooth = filter_image(bgrimg,smooth=width)
                bgrimgResid = abs(bgrimg - bgrimgSmooth)
              
                bgrregionResid = bgrimgResid[regionind]
                Sbgr = total(bgrregionResid) / total(region)
                           
                print, Sbgr
                
                S = S - Sbgr
           
            Endif else begin
                Sbgr = -99
                print, 'WARNING: Number of galaxy pixels is 0!'
                ;stop
            Endelse
       
        Endif else begin
            Sbgr = -99
            print, 'WARNING: Not enough sky pixels'
            ;stop
        Endelse
    
        return, [S, Sbgr]
    
    Endif else begin
    
        return, S
     
    Endelse

End
