Function mpaw_cenpix, ra, dec, ra_ref, dec_ref, x_ref, y_ref, wcs

    wcs0 = wcs[0]
    wcs1 = wcs[1]
    wcs2 = wcs[2]
    wcs3 = wcs[3]
    
    ;; - get difference in RA and Dec
    delta_ra = (ra - ra_ref)*cos(dec*(4.*atan(1.)/180.))
    delta_dec = dec - dec_ref

    ;; - convert to difference in pixels
    dt = 1./(wcs0*wcs3 - wcs2*wcs1)
    delta_x = dt*(delta_ra*wcs3 - delta_dec*wcs1)
    delta_y = dt*(delta_dec*wcs0 - delta_ra*wcs2)

    ;; - add to the central pixel
    x = x_ref + delta_x
    y = y_ref + delta_y
    
    cenpix = fltarr(2)
    
    cenpix[0] = x
    cenpix[1] = y
    
    return, cenpix
    
End