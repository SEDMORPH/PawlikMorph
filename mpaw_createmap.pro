Function mpaw_createmap, infile, infile_pos, sigmaclip=sigmaclip

    readcol, infile, xbin, ybin, velbin, velkin, velcirc, resid, comment='#'
    readcol, infile_pos, x, y, comment='#'

    ;; Choose data 
    data = resid
   
    ;; This function maps the values from the binned to unbinned coordinates (out - values for unbinned coordinates)
    display_bins, xbin, ybin, data, x, y, out
    ;; For displaying:
    ;display_pixels, x, y, out
  
    ;; Round to two decimal places
    x = round(x*100)/100.0
    y = round(y*100)/100.0
    ;; Scale numbers to a range (0,n_elements(sqrt(x))-1)
    xnew = (float(sqrt(n_elements(x))-1) -0.0) * (x-min(x)) / (max(x)-min(x)) + 0.0
    ;xnew = reverse(xnew) 
    ynew = (float(sqrt(n_elements(y))-1) -0.0) * (y-min(y)) / (max(y)-min(y)) + 0.0
    ;ynew = reverse(ynew)

    out[where(out gt 1e+08)] = -999.
   
    ;; Make image array
    arr = fltarr(  long(sqrt(n_elements(xnew))),long(sqrt(n_elements(ynew)))  )
    
    For i = 0, long(sqrt(n_elements(ynew)))-1 do begin
        
        For j = 0, long(sqrt(n_elements(xnew)))-1 do begin
        
            pixelvalue = out[where(long(xnew) eq i and long(ynew) eq j)]
            
            arr[i,j] = pixelvalue
            
        Endfor
        
    Endfor
  
    If keyword_set(sigmaclip) then begin
        map = arr
        map[where(arr ne -999.)] = 1
        map[where(arr eq -999.)] = 0
        arr = mpaw_sigmaclipmap(arr,map,5.)
    Endif
    
    return, arr
    
End