Function mpaw_sdssrenamefits, name
    
    string = strsplit(name,'drC',/extract,/regex)
 
    string = strsplit(string,'RUN', /extract, /regex)

    string = strjoin(string," ")

    string = strcompress(string,/remove)
   
    string = strsplit(string,'RE', /extract, /regex)

    string = strjoin(string," ")

    string = strcompress(string,/remove)
   
    string = strsplit(string,'CAMCOL', /extract, /regex)

    string = strjoin(string," ")

    string = strcompress(string,/remove)

    string = strsplit(string,'FIELD', /extract, /regex)

    string = strjoin(string," ")

    string = strcompress(string,/remove)

    string = strsplit(string,'FILTER', /extract, /regex)

    string = strjoin(string," ")

    string = strcompress(string,/remove)

    string = strsplit(string,escape='?',/extract)

    string = strsplit(string,escape='&',/extract)
   
    string = repstr(string,'=','_')

    newname = 'SDSS'+string+'.fits'
        
    return, newname
    
    
End