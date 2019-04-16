PRO mpaw_makeimglist

;; Read input - presumeabley with ID numbers

    sample = 'CANDLESPSB/PSB-F160W/'
    dir = '/Users/Milena/Documents/St_Andrews/Projects/SEDMorph/Samples/'
    infile = dir+sample+'id_psb.csv'
    
    readcol, infile, candlesid, udsid, skipline=1, format = 'I,I'
    id = candlesid
    
    corename = '.f160w.fits'
    
    openw, 1, dir+sample+'/data/imglist.txt'
    
    numgals = n_elements(id)
    For i = 0, numgals-1 do begin
        name = strcompress(string(id[i]),/remove)+corename
        printf, 1, name
    Endfor
    
    close, 1
    
END