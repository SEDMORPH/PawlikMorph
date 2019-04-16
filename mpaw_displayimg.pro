;; Display data in one file

;; Example calling sequence: mpaw_displayimg, 'MergerCutouts_iBandNoisy', /img, /cleanimg, /pixmap 


PRO mpaw_displayimg, sample, img=img, cleanimg=cleanimg, pixmap=pixmap

dir = '/Users/Milena/Documents/St_Andrews/Projects/SimFromTim/'
outfile = dir+'/'+sample+'_data.ps'

    If keyword_set(img) and keyword_set(cleanimg) and keyword_set(pixmap) then begin 
        
        dir_img = dir+sample+'/data/'
        dir_cleanimg = dir+sample+'/output/'
        dir_pixmap = dir+sample+'/output/'
    
        imgs = file_search(dir_img+'/*.fits',count=numimg)
        cleanimgs = file_search(dir_cleanimg+'/clean_*.fits',count=numcleanimg)
        pixmaps =  file_search(dir_pixmap+'/pixelmap_*.fits',count=numpixmap)
       
        If numimg ne numcleanimg $
            or numimg ne numpixmap $
                or numpixmap ne numcleanimg then begin
                    print, 'ERROR: Check input data!'
                    print, 'Number of images: ',numimg
                    print, 'Number of clean images: ',numcleanimg
                    print, 'Number of pixel maps: ',numpixmap
                    stop
        Endif else begin
            
            names = strarr(numimg)
            For i = 0, numimg-1 do begin
                names[i] = strcompress(strsplit(imgs[i],dir_img,/extract,/regex),/remove)
            Endfor
            
            set_plot, 'ps'
            device, xsize=6, ysize=10, yoffset=0.5, xoffset=0.3, /inches, filename=outfile
            !P.Multi = [0,3,7]  
             
            For i = 0, numimg-1 do begin
                
                img = mrdfits(imgs[i],/fscale)
                cleanimg = mrdfits(cleanimgs[i],/fscale)
                pixmap = mrdfits(pixmaps[i],/fscale)
                
                TVimage, hist_equal(img), MultiMargin=[1,1,1,1]
                TVimage, hist_equal(cleanimg), MultiMargin=[1,1,1,1]
                If total(pixmap) gt 0 then $
                    TVimage, hist_equal(pixmap), MultiMargin=[1,1,1,1] $
                        else TVimage, pixmap, MultiMargin=[1,1,1,1]
                xyouts, 1,1,names[i],color=fsc_color('white'),charsize=0.8,align=0.
         
            Endfor
            
            !P.Multi =0
            device, /close
            
       
        Endelse
        
        
        
    Endif
    
    
    If keyword_set(img) and keyword_set(pixmap) and not(keyword_set(cleanimg)) then begin 
        
        dir_img = dir+sample+'/data/'
        dir_pixmap = dir+sample+'/output/'
    
        imgs = file_search(dir_img+'/*.fits',count=numimg)
        pixmaps =  file_search(dir_pixmap+'/pixelmap_*.fits',count=numpixmap)
       
        If numimg ne numpixmap then begin
                print, 'ERROR: Check input data!'
                print, 'Number of images: ',numimg
                print, 'Number of pixel maps: ',numpixmap
                stop
        Endif else begin
            
            names = strarr(numimg)
            For i = 0, numimg-1 do begin
                names[i] = strcompress(strsplit(imgs[i],dir_img,/extract,/regex),/remove)
            Endfor
            
            set_plot, 'ps'
            device, xsize=4, ysize=10, yoffset=0.5, xoffset=0.3, /inches, filename=outfile
            !P.Multi = [0,2,7]  
             
            For i = 0, numimg-1 do begin
                
                img = mrdfits(imgs[i],/fscale)
                pixmap = mrdfits(pixmaps[i],/fscale)
                
                TVimage, hist_equal(img), MultiMargin=[1,1,1,1]
                If total(pixmap) gt 0 then $
                    TVimage, hist_equal(pixmap), MultiMargin=[1,1,1,1] $
                        else TVimage, pixmap, MultiMargin=[1,1,1,1]
                xyouts, 1,1,names[i],color=fsc_color('white'),charsize=0.8,align=0.
         
            Endfor
            
            !P.Multi =0
            device, /close
            
       
        Endelse
        
        
        
    Endif
    
    

END