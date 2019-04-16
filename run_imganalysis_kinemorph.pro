;+
; NAME:
;  run_imganalysis_kinemorph
;
; PURPOSE:
;	Computes a range of structural and morphological parameters for the maps of galaxy kinematics 
;
; CALLING SEQUENCE:
;
;	run_imganalysis_kinem, sample, [imgname]
;            
; MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, August 2016, based on an older version from March 2014. 
;	
;-

PRO RUN_IMGANALYSIS_KINEMORPH, sample, imgname
        
    ;;------------------------------------------------------------------
    ;; Directories
    ;;------------------------------------------------------------------
    dir = '/Users/Milena/Documents/St_Andrews/Projects/PSBKinematics/'+sample
    dir_in = dir+'/'
    dir_out = dir+'/output/'
    If file_test(dir_out) eq 0 then spawn, 'mkdir '+ dir_out  
    
    ;;------------------------------------------------------------------
    ;; Maps
    ;;------------------------------------------------------------------
    If n_elements(imgname) eq 0 then begin
        imgs = file_search(dir_in+'residmap_*.fits',count=numimgs) 
    Endif else begin
        numimgs = 1
    Endelse
       
    ;;------------------------------------------------------------------
    ;; Output set up 
    ;;------------------------------------------------------------------
    ;; Data structure for storing structural parameters
    struct = {id:0L,bpixx:0,bpixy:0,apixx:0,apixy:0,mpixx:0,mpixy:0,rmax:0.0,A:0.0,As:0.0,As90:0.0,S3:0.0,S4:0.0,S5:0.0,S6:0.0,S7:0.0,S8:0.0,S9:0.0,S10:0.0,w3:0.0,w4:0.0,w5:0.0,w6:0.0,w7:0.0,w8:0.0,w9:0.0,w10:0.0,G:0.0,M20:0.0}
    hdr_out = ['id','bpixx','bpixy','apixx','apixy','mpixx','mpixy','rmax','A','As','As90','S3','S4','S5','S6','S7','S8','S9','S10','w3','w4','w5','w6','w7','w8','w9','w10','G','M20']
    out = replicate(struct,numimgs)
    outfile = sample+'_structpar'
      
    ;; Data structure for storing image information
    struct = {id:0L,imgname:'',imgsize:0}
    hdr_out1 = ['id','imgname','imgsize']
    out1 = replicate(struct,numimgs)
    outfile1 = sample+'_imginfo' 
       
    ;;------------------------------------------------------------------
    ;; Analysis 
    ;;------------------------------------------------------------------
   
    For i = 0, numimgs-1 do begin
        
        out(i).id = i+1
        out1(i).id = i+1
        ;; --------------------
        ;; Reading imaging data
        If n_elements(imgname) eq 0 then begin
            imgpath = imgs[i]
            name = strsplit(imgpath,dir_in,/extract,/regex)
            name = strcompress(name,/remove)
        Endif else begin
            name = imgname
            imgpath = dir_in+imgname
        Endelse
        out1(i).imgname = name
        
        img = mrdfits(imgpath,/fscale) 
        imgsize = size(img)
        npix = imgsize[1]
        cenpix = fltarr(2)
        cenpix[0] = npix/2 + 1
        cenpix[1] = npix/2 + 1
        distarr = mpaw_distarr(npix, npix, cenpix)
        
        ;; --------------------
        ;; Binary pixel map
        pixmap = img*0
        pixmap[where(img ne -99.)] = 1
        
        ;; -------------------------------
        ;; - Maximum radius from pixel map
        objectpix = where(pixmap eq 1)
        objectdist = distarr[objectpix]        
        r_max = max(objectdist)
        
        ;; ---------------------
        ;; - Set background to 0
        img[where(pixmap ne 1)] = 0.
        ;; - Scale the image
       ; If min(img) lt 0. then begin
    ;        img[where(pixmap eq 1)] = img[where(pixmap eq 1)] + abs(min(img)) + 1.
    ;    Endif
        
        ;; -------------
        ;; - Asymmetries
        ;A = mpaw_A_kinem(img,pixmap,cenpix,r_max,180.,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove),/shape)
        ;As = mpaw_A_kinem(pixmap,pixmap,cenpix,r_max,180.,/shape)
        
        ;; ----------
        ;; Clumpiness
        width = r_max/3.
        w3 = width
        S3 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
        
        width = r_max/4.
        w4 = width
        S4 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
      
        width = r_max/5.
        w5 = width
        S5 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
      
        width = r_max/6.
        w6 = width
        S6 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
      
        width = r_max/7.
        w7 = width
        S7 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
      
        width = r_max/8.
        w8 = width
        S8 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
    
        width = r_max/9.
        w9 = width
        S9 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
    
        width = r_max/10.
        w10 = width
        S10 = mpaw_S_kinem(img,pixmap,width,dir_in,strcompress(strsplit(name,'.fits',/extract,/regex),/remove))
    
        ;; ----------
        ;; Gini index
        G = mpaw_G(abs(img),pixmap)
        
        ;; --------------
        ;; M20 statistics
        ;M20 = mpaw_M20(abs(img),pixmap)
          
        out1(i).imgname = name
        out1(i).imgsize = npix
        
        ;out(i).A = A
        ;out(i).As = As
        out(i).S3 = S3
        out(i).S4 = S4
        out(i).S5 = S5
        out(i).S6 = S6
        out(i).S7 = S7
        out(i).S8 = S8
        out(i).S9 = S9
        out(i).S10 = S10
        out(i).w3 = w3
        out(i).w4 = w4
        out(i).w5 = w5
        out(i).w6 = w6
        out(i).w7 = w7
        out(i).w7 = w8
        out(i).w7 = w9
        out(i).w7 = w10
        out(i).G = G
        ;out(i).M20 = M20
      
        write_csv, dir_out+outfile+'.csv', out,  header=hdr_out
        write_csv, dir_out+outfile1+'.csv', out1, header=hdr_out1
    Endfor
 
End
