;+
; NAME:
;  run_mockimgprep
;
; PURPOSE:
;	Carries out mock image analysis, including measurements of a range of structural and morphological parameters. 
;  
; MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, August 2016, based on an older version from March 2014. 
;	
;-

PRO RUN_MOCKIMGPREP, simulation, orientation, filter, singleimg=singleimg, trim=trim

    ;;------------------------------------------------------------------
    ;; Directories
    ;;------------------------------------------------------------------
    dir = '/Users/Milena/Documents/St_Andrews/Projects/SEDMorph/Simulations/GADGET3/RERUN/'
    dir_in = dir+simulation+'/imgs_'+filter+'/orien_'+orientation+'/'  
    dir_out = dir_in   
       
    ;;------------------------------------------------------------------
    ;; Images
    ;;------------------------------------------------------------------  
    If not(keyword_set(singleimg)) then begin
        imgs = file_search(dir_in+'sdssimage_z0.040_tauv1.0_mu0.3_*.fits',count=numimgs)
    Endif else begin
        ;; Finish!
    Endelse
       
    ;; ------------------------------------------
    ;; --- Check size and adjust if necessary ---
    If keyword_set(trim) then begin
     
        For i = 0, n_elements(imgs)-1 do begin
           
            mpaw_sdsstrim, imgs[i] , imgs[i]
           
        Endfor
        
    Endif

END



