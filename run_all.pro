;; Image preparation/analysis warrper 

PRO RUN_ALL, mockimgs=mockimgs

    If not(keyword_set(mockimgs)) then begin
        
        path = '/Users/Milena/Documents/St_Andrews/Projects/MaNGA/'
        samples = ['MaNGA_SDSS']

        For i = 0, n_elements(samples)-1 do begin
            sample = samples[i]
           ; run_imgprep, path, sample, /sdss, /cutout
            run_imganalysis, path, sample, /imglist, /sdsscutout, /sdsshdr, /largeimg, /savecleanimg, /savepixelmap
        Endfor
        
    Endif else begin
        
        ;filters = ['u','g','r','i','z']
        filters = ['r']
        orientations = ['0','1','2','3','4','5','6']
        
        For f = 0, n_elements(filters)-1 do begin
        
            For o = 0, n_elements(orientations)-1 do begin
                
               ; If (f eq 0 and o eq 0) then run_mockimganalysis, '2xSc_13',  orientations[o], filters[f], $
               ;  /convertunits, /aperpixmap, /savepixelmap
                 
               ; If (f ne 0 or o ne 0) then run_mockimganalysis, '2xSc_13',  orientations[o],filters[f], $
                ;  /convertunits, /savepixelmap
               run_mockimgprep, 'Sc_Scp3_13',orientations[o], filters[f], /trim
               run_mockimganalysis, 'Sc_Scp3_13',  orientations[o], filters[f], /convertunits, /aperpixmap, /savepixelmap
                 
            Endfor
            
        Endfor
  
        
    Endelse

END