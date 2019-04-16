Function mpaw_mag, img, pixmap, photpar, aperpixmap, aper=aper

    If not(keyword_set(aper)) then $
        pix = img[where(pixmap eq 1)] $
            else pix = img[where(aperpixmap eq 1)]
    
    numpix = n_elements(pix)
    
    counts = total(pix)
    f_over_f0 = counts / (1d8*photpar.flux20)
    mag = -(2.5/alog(10.))*(asinh((f_over_f0)/(2.*photpar.b))+alog(photpar.b))  
    
    countserr = sqrt(((counts+photpar.skybgr)/photpar.gain)+float(numpix)*(photpar.darkvar+photpar.skybgrerr)) 
    mag_err = (2.5/alog(10))*(countserr/photpar.exptime)*(1./(2.*photpar.b))*10.^(0.4*(photpar.aa+photpar.kk*photpar.airmass)) / sqrt(1+(f_over_f0/(2*photpar.b))^2)
  
    return, [mag, mag_err]
End