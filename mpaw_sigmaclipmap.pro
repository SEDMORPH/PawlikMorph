Function mpaw_sigmaclipmap, data, pixmap, n

    tolerance = 1.
    While tolerance gt 0.1 do begin
      
        sig = stdev(data[where(pixmap eq 1)])
        med = median(data[where(pixmap eq 1)]) 
              
        data[where(data gt med+n*sig or data lt med-n*sig)] = -999. 
        pixmap[where(data gt med+n*sig or data lt med-n*sig)] = 0
                
        signew = stdev(data[where(pixmap eq 1)])
        tolerance = (sig - signew) / signew      
         
    Endwhile
    
    return, data
    
End