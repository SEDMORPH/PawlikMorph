
Function mpaw_sdsscutout, imgname, stampname, ra, dec, stampsize

    ;; Read in fits file
    img = mrdfits(imgname,/fscale)
    data = mrdfits(imgname,0,hdr)
    
    ;; These are important because some images have their
    ;; coordinates the wrong way round.
    xcoord = sxpar(hdr,'CTYPE1')
    ycoord = sxpar(hdr,'CTYPE2')
    
    ;; World coordinate system
    ;; -  here is the 2x2 matrix used for transformation between
    ;;   (RA,Dec) and (x,y)
    ;;    - CD1_1 - RA degrees per column pixel
    ;;    - CD1_2 - RA degrees per row pixel
    ;;    - CD2_1 - Dec degrees per column pixel
    ;;    - CD2_2 - Dec degrees per row pixel
    wcs = fltarr(4)
    wcs[0] = sxpar(hdr,'CD1_1')
    wcs[1] = sxpar(hdr,'CD1_2')
    wcs[2] = sxpar(hdr,'CD2_1')
    wcs[3] = sxpar(hdr,'CD2_2')

    ra_ref = sxpar(hdr,'CRVAL1')
    dec_ref = sxpar(hdr,'CRVAL2')

    x_ref = sxpar(hdr,'CRPIX1')
    y_ref = sxpar(hdr,'CRPIX2')

    getrot, hdr, angle
    angle = - angle
    
    check = finite(angle)
    If check eq 0 then angle = 0.0
    check = strnumber(angle)

    If xcoord eq 'DEC--TAN' then begin

       ra_ref_temp = dec_ref
       dec_ref_temp = ra_ref
   
       ra_ref = ra_ref_temp
       dec_ref = dec_ref_temp

       wcstemp0 = wcs[2]
       wcstemp1 = wcs[3]
       wcstemp2 = wcs[0]
       wcstemp3 = wcs[1]

       wcs[0] = wcstemp0
       wcs[1] = wcstemp1
       wcs[2] = wcstemp2
       wcs[3] = wcstemp3

    Endif
    
    ;; Find the central pixel's coordinates (fiducial)
    cenpix = mpaw_cenpix(ra, dec, ra_ref, dec_ref, x_ref, y_ref, wcs)
    
    ;; Rotate the image arount the objects centre
    ;; - remeber to set /pivot keyword !!
    img_rot = rot(img, 360.-angle, 1.0, cenpix[0], cenpix[1], /pivot)

    ;; - cut out stamps
    imgsize = size(img_rot)

    deltas = intarr(5)
    deltas[0] = stampsize/2
    deltas[1] = imgsize[1] - cenpix[0] - 1
    deltas[2] = cenpix[0] - 1
    deltas[3] = imgsize[2] - cenpix[1] - 1
    deltas[4] = cenpix[1] - 1

    delta = min(deltas)
    
    x_min = cenpix[0] - delta
    x_max = cenpix[0] + delta
    y_min = cenpix[1] - delta
    y_max = cenpix[1] + delta
    
    stamp = img_rot[x_min:x_max,y_min:y_max]
    
    writefits, stampname, stamp, hdr 
  
End