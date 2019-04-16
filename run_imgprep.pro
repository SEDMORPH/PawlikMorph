;+
; NAME:
;  run_imgprep
;
; PURPOSE:
;	Carries out image preparation
;
;
; CALLING SEQUENCE:
;
;	run_imgprep, dir, sample, [imgname]
;            
;       INPUT:
;       dir: a string - path to the working directory 
;       sample: a string pointing to the sample to be analysed
;  
;       OPTIONAL INPUT:
;       - IMGNAME: can specifiy to analyse a single image, instead of whole sample;
;       - CUTOUTSIZE: need to be a multiple of 3 pixels (important for computation of binary pixel maps);
;                     - recommended sizes: 141 pixels (~1 arcmin), 231 pixels (~1.5 arcmin), 303 pixels (~2 arcmin);
;                     - default sizes are 141 (for analysis) and 231 (larger image for sky level estimation):
;       - FILTERS: array of strings, e.g. ['g','r','i'], if not specified thaen all 5 filters assumed
;       
;       OUTPUT:
;     
; KEYWORD PARAMETERS:
;      
;       
; EXAMPLES:
;       run_imgprep, 'path', 'TESTSAMPLE_1', /sdss, /cutout
;       run_imgprep, 'path', 'TESTSAMPLE_2', /trim
;
;
; DEPENDENCIES: 
;      
;
; NOTES: 
;
;  
; MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, August 2016, based on an older version from March 2014. 
;	Last modified by: Milena Pawlik, June 2017
;-

PRO run_imgprep, dir, sample, imgname, sdss=sdss, cutout=cutout, trim=trim, centre=centre, flagsources=flagsources
    
    ;;------------------------------------------------------------------
    ;; Directories
    ;;------------------------------------------------------------------
    ;dir = '/Users/Milena/Documents/St_Andrews/Projects/SEDMorph/Samples/'
    dir_in = dir+sample+'/data/'
    
    If n_elements(dir) eq 0 then begin
       print, 'ERROR: Path to working directory unspecified!'
       stop 
    Endif
    
    dir_out = dir+sample+'/data/'    
    If file_test(dir_out) eq 0 then spawn, 'mkdir '+ dir_out  
      
       
    ;;------------------------------------------------------------------  
    ;;  --- OPTIONAL: FOR SDSS IMAGES ONLY ---
    ;;------------------------------------------------------------------  

    
    ;;  --- Cut out postage stamps from SDSS fields ---
    If keyword_set(cutout) then begin
        If not(keyword_set(sdss)) then begin
            print, 'ERROR: Cut out option avalilable only for sdss imaging (for now).'
            stop
        Endif else begin
            
            ;; - OPTIONAL: Input file with sdss image parameters:
            ;;              - to match object coordinates with the right field
            ;;              - includes: RA, DEC, RUN, RERUN, CAMCOL, FIELD, OBJ ?
    
            infile = dir_in+'imgparams.csv'
            numpar = 7 ;; number of parameters in the input file

            outfile = dir+sample+'/data/imgradec.csv'
            outfile_1 = dir+sample+'/data/imglist.txt'
            outfile_2 = dir+sample+'/data/limglist.txt'
 
            
            ;; --- SDSS filters ---
           ; filters = ['u','g','r','i','z']
            filters = ['r']
            
            ;; --- Default cutout size --- 
            cutoutsize = [141,231]
            ;cutoutsize = [183,231]
 
            ;; - Rename the images from the SDSS database
            If n_elements(imgname) eq 0 then begin
                fields = file_search(dir_in+'drC*',count=numfields) 
            
                For i = 0, numfields-1 do begin
                    pathname = fields[i]
                    imgname = strsplit(pathname,dir_in,/extract,/regex)
                    imgname = strcompress(imgname,/remove)
                    newname = mpaw_sdssrenamefits(imgname)
                  
                    If file_test(dir_in+newname) eq 1 then file_delete, dir_in+newname
                    file_move, dir_in+imgname, dir_in+newname
                Endfor
            Endif else begin
                newname = mpaw_sdssrenamefits(imgname)
                If file_test(dir_in+newname) eq 1 then file_delete, dir_in+newname
                file_move, dir_in+imgname, dir_in+newname
            Endelse
            
            
            ;; - Prepare square cut-outs centered on the object coordinates
            If file_test(infile) eq 0 then begin
                print, 'ERROR: Object coordinates not found.'
                stop
            Endif else begin
                ;; - Create output directory
                ;If file_test(dir_out+'cutouts') eq 0 then spawn, 'mkdir '+ dir_out+'cutouts'   
               
                ;; - Read in object coordinates and image parameters
                numobj = file_lines(infile)-1
                params = mpaw_readinfile(infile,numpar,numobj)
                ;; Ra, Dec are the first two parameters
                coords = fltarr(2,numobj)
                coords(0,*) = params(0,*)
                coords(1,*) = params(1,*)
                ;; Build image name
                params_str = string(long(params))
                params_str = strcompress(params_str,/remove) 
                corenames = strarr(numobj)    
                For i = 0, numobj-1 do begin
                    corenames[i] = 'SDSS_'+params_str[2,i]+'_'+params_str[3,i]+'_'+params_str[4,i]+'_'+params_str[5,i]
                Endfor
                
                hdr_out =  ['ra','dec','cutoutname','sdssimgname']
                struct = {ra:0.0,dec:0.0,cutoutname:'',imgname:''}
                out = replicate(struct,numobj)
                
                lcutoutnames = strarr(numobj)
                
                For f = 0, n_elements(filters)-1 do begin
                    
                    For i = 0, numobj-1 do begin
                        
                     ;   If i ne 46 and f ne 0 then begin
                        
                        ra = coords(0,i)
                        dec = coords(1,i) 
                          
                        ra_str =  string(ra, FORMAT='(F6.2)')
                        If dec lt 0 then dec_str = string(dec, FORMAT='(F6.2)') $
                            else dec_str = '+'+string(dec, FORMAT='(F5.2)')
    
                        ra_str = strcompress(ra_str,/remove)
                        dec_str = strcompress(dec_str,/remove)
                        
                        
                        imgname = dir_in+corenames[i]+'_'+filters[f]+'.fits'
                        cutoutname = dir_out+'sdsscutout_'+ra_str+dec_str+'_'+filters[f]+'band.fits'
                        lcutoutname = dir_out+'sdsslcutout_'+ra_str+dec_str+'_'+filters[f]+'band.fits'
                        
                        ;; Cut-out for analysis
                        print, i, imgname
                  
                        
                        cutout = mpaw_sdsscutout(imgname, cutoutname, ra, dec, cutoutsize[0])
                        ;; Larger cut-out for sky level estimation
                        lcutout = mpaw_sdsscutout(imgname, lcutoutname, ra, dec, cutoutsize[1])
                        
                       out(i).ra = ra
                       out(i).dec = dec
                       out(i).cutoutname = 'sdsscutout_'+ra_str+dec_str+'_'+filters[f]+'band.fits'
                       out(i).imgname = corenames[i]+'_'+filters[f]+'.fits'
                       
                       lcutoutnames[i]= 'sdsslcutout_'+ra_str+dec_str+'_'+filters[f]+'band.fits'
                      
                       print, f
                       
                    ;    Endif
                    
                    Endfor
                    
                Endfor
                
                write_csv, outfile, out, header=hdr_out
                
                writecol, outfile_1, out.cutoutname, fmt='(A)'
                writecol, outfile_2, lcutoutnames, fmt='(A)'
                
            Endelse
        Endelse
    Endif
    
    ;;------------------------------------------------------------------  
    ;;                 --- For pre-prepared cutouts ---
    ;;------------------------------------------------------------------ 
    
    If keyword_set(centre) and not(keyword_set(trim)) then begin
        print, 'ERROR: Centering must be followed by adjusting the image size. Set keyword /trim to proceed. '
        stop
    Endif else begin
  
        ;; ------------------------------------------
        ;; --- Check size and adjust if necessary ---
        If keyword_set(trim) then begin
        
            If n_elements(imgname) eq 0 then $
                imgs = file_search(dir_in+'*.fits',count=numimgs) else numimgs = 1
        
            print, numimgs
            
            For i = 0, numimgs-1 do begin
                If n_elements(imgname) eq 0 then begin
           
                    path = imgs[i]
                    name = strsplit(path,dir_in,/extract,/regex)
                    name = strcompress(name,/remove)
                Endif else begin
                    name = imgname
                    path = dir_in+name
                Endelse
                
                ;; Adjusted cutouts retain the input name but are moved to a new directory
                ;newimgname = strsplit(pathname,dir_in,/extract,/regex)
                ;newimgname = strcompress(newimgname,/remove)
                ;newimgname = dir_out+newimgname
                newpath = dir_out+name
            
                ;; -------------------------------------
                ;; ----- Optional: image centering -----
                If keyword_set(centre) then begin     
                    ;; Optional - read in coordinates and re-centre image;
                    ;; otherwise, if coordinates not specified, centre on the brightest pixel 
                    If keyword_set(centrecoords) then begin
                        num = file_lines(coordsfile)-1
                        If num ne numimgs then begin
                            print, 'ERROR: Check the list of coordinates: number of objets does not match the number of images!'
                            stop
                        Endif else begin
                            head = ''
                            coordsall = fltarr(2,num)
                            openr, 1, coordsfile
                            readf, 1, head
                            readf, 1, coordsall
                            close, 1 
                            coords = [coordsall(0,i),coordsall(1,i)]
                        Endelse
                    Endif else if not(keyword_set(centrecoords)) then begin
                        
                        coords = 0
                    Endif
                    mpaw_sdsstrim, path, newpath, coords, /centre
                Endif else if not(keyword_set(centre)) then begin ;; End image centering 
                    ;; -------------------------------------
            
                    print, '***'
                    print, name
                    ;; ---- FINISH!! 
                     mpaw_sdsstrim, path, newpath 
                Endif
    
            Endfor ;; Close object loop
        Endif
    Endelse
    
        ;; ---------------------------------------------------------------------
        ;; ---  For SDSS images: check for potentially contaminating sources ---
        ;; ---------------------------------------------------------------------
    
    End

