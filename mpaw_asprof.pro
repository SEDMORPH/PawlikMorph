Function mpaw_asprof, img, centroid, thresh, paths, getpixmaps=getpixmaps

    outpar = {As:fltarr(n_elements(thresh)), As90:fltarr(n_elements(thresh))}

    ;; - For each threshold:
    For i = n_elements(thresh)-1 do begin
        
        ;; - Get the pixel map 
        If keyword_set(getpixmaps) then begin
            pixmap = mpaw_pixmap(img,thresh[i])
            writefits, paths[i], pixmap
        Endif else begin
            pixmap = mrdfits(paths[i],/fscale)
        Endelse
        
        ;; --- Measure the shape asymmetries: ---
        ;; - 180 deg rotation
        pixmapRot = rot(pixmap,180.,1.0,centroid[0],centroid[1],/pivot)
        pixmapResid = abs(pixmap - pixmapRot)
        As = total(pixmapResid) / (2.*total(abs(pixmap)))
        ;; - 90 deg rotation 
        pixmapRot = rot(pixmap,90.,1.0,centroid[0],centroid[1],/pivot)
        pixmapResid = abs(pixmap - pixmapRot)
        As90 = total(pixmapResid) / (2.*total(abs(pixmap)))
        
        outpar.As[i] = As
        outpar.As90[i] = As90
    Endfor

    return, outpar
End