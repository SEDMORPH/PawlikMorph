Function mpaw_readinfile, infile, numparams, numobj, nohdr=nohdr

    If not(keyword_set(nohdr)) then hdr = ''
    params = fltarr(numparams,numobj)
    
    get_lun, lun
    openr, lun, infile
    If not(keyword_set(nohdr)) then readf, lun, hdr
    readf, lun, params
    close, lun
    free_lun, lun
    
    return, params
End