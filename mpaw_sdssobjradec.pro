Function mpaw_readinfile, infile, numpar
    
    hdr = ''
    numobj = file_lines(infile)-1
    params = fltarr(numpar,numobj)
    
    openr, 1, infile
    readf, 1, hdr
    readf, 1, params
    close, 1
      
    return, params

End