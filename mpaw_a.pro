;; Compute the asymmetry parameter 

;; Optionam arguments: -apermaskcut (if /aout set)

Function mpaw_a, img, pixelmap, apermask, centroid, rmax, angle, apermaskcut, noisecorrect=noisecorrect, aout=aout

    cenpix_x = centroid[0]
    cenpix_y = centroid[1]
    
    imgRot = rot(img,angle,1.0,cenpix_x,cenpix_y,/pivot)
    imgResid = abs(img - imgRot)

    If keyword_set(aout) then $
        netmask = apermask-apermaskcut $
            else netmask = apermask
    
    regionind = where(netmask eq 1)
    region = img[regionind]
    regionResid = imgResid[regionind]
    
    A = total(regionResid) / (2.*total(abs(region)))
    
    netmask = netmask*0
    
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
        
                bgrimgRot = rot(bgrimg,180.,1.0,cenpix_x,cenpix_y,/pivot)
                bgrimgResid = abs(bgrimg - bgrimgRot)
           
                bgrregionResid = bgrimgResid[regionind]
             
                Abgr=total(bgrregionResid)/(2.*total(abs(region)))
           
                A = A - Abgr
           
            Endif else begin                
                Abgr = -99
            Endelse
       
        Endif else begin
            Abgr = -99
        Endelse
   
        return, [A, Abgr] 
   
   Endif else begin
       
        return, A
        
   Endelse
   
End
    
    