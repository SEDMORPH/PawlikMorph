Function mpaw_a_kinem, img, pixelmap, centroid, rmax, angle, dir, name, shape=shape

    cenpix_x = centroid[0]
    cenpix_y = centroid[1]
    
    imgRot = rot(img,angle,1.0,cenpix_x,cenpix_y,/pivot)
    imgResid = abs(img - imgRot)
    
    If not(keyword_set(shape)) then begin
        ;; Region of interest - only where mask ans maskrot coincide!
        pixelmapRot = rot(pixelmap,angle,1.0,cenpix_x,cenpix_y,/pivot)
        regionind = where(pixelmap+pixelmapRot eq 2)
    Endif else begin
        regionind = where(pixelmap ge 0) ;; Include all
    Endelse
    
    region = img[regionind]
    regionResid = imgResid[regionind]
    
    A = total(regionResid) / (2.*total(abs(region)))
    
    If not(keyword_set(shape)) then begin
        imgRot[where(pixelmap+pixelmapRot ne 2)] = 0
        imgResid[where(pixelmap+pixelmapRot ne 2)] = 0
        writefits, dir+name+'_rot.fits', imgRot
        writefits, dir+name+'_rotresid.fits', imgResid
    Endif
    
    return, A
 
End
    
    