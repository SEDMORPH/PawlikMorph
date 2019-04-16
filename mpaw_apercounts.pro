Function mpaw_apercounts, aperpix, photpar, err=err

    apersize = size(aperpix)
    numpix = apersize[1]
    aperarea = float(numpix);*(1./(2.5))^2.
          
    apercounts = total(aperpix) / aperarea
    
   ; print, 'total aperpix',  total(aperpix)
    
    If keyword_set(err) then $
        ; If SDSS header values used for background estimate: skyerr = bgr[1]*1d8*flux20*(0.396^2.)
        apercounts_err = sqrt( (total(aperpix)+photpar.skybgr*float(numpix))/photpar.gain +float(numpix)*(photpar.darkvar+photpar.skybgrerr)  )/aperarea $
            else if not(keyword_set(err)) then $
                apercounts_err = apercounts*0 - 99
        
    return, [apercounts, apercounts_err]

       
End