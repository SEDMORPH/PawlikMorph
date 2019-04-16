;; Display images

PRO mpaw_displayfits, sample, params=params

    dir = '/Users/Milena/Documents/St_Andrews/Projects/SEDMorph/Samples/'
    
    filename = dir+sample+'/images.ps'
    set_plot, 'ps'
    device, xsize=8, ysize=10, yoffset=0.5, xoffset=0.3, /inches, filename=filename
    !P.Multi = [0,4,6]              ; [junk,rows,columns]
    !x.omargin=[0,0]                ;overall around plot[left,right]
    !y.omargin=[0,0] 
    
    blank = [0,0,0]#[0,0,0] 
   
    readcol, dir+sample+'/data/imglist.txt', names, format='A'  
    numimgs = n_elements(names)
    
    If keyword_set(params) then begin
        
        struct = {id:0L,bpixx:0,bpixy:0,apixx:0,apixy:0,mpixx:0,mpixy:0,rmax:0.0,r20:0.0,r50:0.0,r80:0.0,r90:0.0,C2080:0.0,C5090:0.0,A:0.0,A_bgr:0.0,As:0.0,As90:0.0,S:0.0,S_bgr:0.0,G:0.0,M20:0.0,mag:0.0,mag_err:0.0,sb0:0.0,sb0_err:0.0,reff:0.0,reff_err:0.0,n:0.0,n_err:0.0}
        data = replicate(struct,numimgs)
        hdr = ''
        openr, 1, dir+sample+'/output/structpar_rband.csv'
        readf, 1, hdr
        readf, 1, data
        close, 1
        
    Endif
 
    For i = 0, numimgs-1 do begin
        
        id_str = strcompress(string(i+1),/remove)
        If keyword_set(params) then A_str = strcompress(string(sigfig(data(i).As,2)),/remove)
        
        If file_test(dir+sample+'/original/'+names[i]) then begin 
            
            origimg = mrdfits(dir+sample+'/original/'+names[i],/fscale)
            img = mrdfits(dir+sample+'/data/'+names[i],/fscale)
            cleanimg = mrdfits(dir+sample+'/output/clean_'+names[i],/fscale)
            pixmap = mrdfits(dir+sample+'/output/pixelmap_'+names[i],/fscale)
   
            TVimage, hist_equal(origimg), MultiMargin=[1,1,1,1]
            TVimage, hist_equal(img), MultiMargin=[1,1,1,1]
            TVimage, hist_equal(cleanimg), MultiMargin=[1,1,1,1]
            If total(pixmap) gt 0 then $
                TVimage, hist_equal(pixmap), MultiMargin=[1,1,1,1] $
                    else TVimage, pixmap, MultiMargin=[1,1,1,1]
            xyouts, 9,1,id_str,color=fsc_color('white'),charsize=0.8,align=0.
            If keyword_set(params) then xyouts, 7,9,'As='+A_str,color=fsc_color('white'),charsize=0.8,align=0.
             
            ;; BAd objects?
            If keyword_set(params) then begin
                If (data(i).M20 ge -1.0 and data(i).G ge 0.5) or (data(i).M20 ge -0.75) then xyouts, 2,2,'CONTAMINATED',color=fsc_color('red'),charsize=0.8,align=0.
            Endif
            
        Endif else begin
             TVimage, blank, MultiMargin=[1,1,1,1]
             TVimage, blank, MultiMargin=[1,1,1,1]
             TVimage, blank, MultiMargin=[1,1,1,1]
             TVimage, blank, MultiMargin=[1,1,1,1]
             xyouts, 9,1,id_str,color=fsc_color('white'),charsize=0.8,align=0.
        Endelse
    
    
    Endfor
    
    !P.Multi =0
    device, /close
    
End