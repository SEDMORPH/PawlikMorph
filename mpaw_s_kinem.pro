;+
; NAME:
;  mpaw_S_kinem
;
; PURPOSE:
;	Computes the measure of clumpines for a pixel map 
;
; CALLING SEQUENCE:
;
;	result = mpaw_S_kinem(img,pixelmap,width)
;            
; OPTIONAL INPUT:
;            
;   Set keyword /print and specify dir and name for optional output:       
;   dir - path to the output directory
;   name - name of the output file (smoothed image + residuals)
;            
; MODIFICATION HISTORY:
;
; 	Written by:	Milena Pawlik, August 2016, based on an older version from March 2014. 
;	
;-

Function mpaw_s_kinem, img, pixelmap, width, dir, name, print=print
     
    imgSmooth = filter_image(img,smooth=width)
    imgResid = abs(img - imgSmooth)      
       
    regionind = where(pixelmap eq 1)      
    region = img[regionind]
    regionSmooth = imgSmooth[regionind]
    regionResid = imgResid[regionind]
    
   ; S = total(regionSmooth) / total(region)
    
    S = total(abs(regionResid)) / total(abs(region))
    
    If keyword_set(print) then begin
        imgSmooth[where(pixelmap ne 1)] = 0
        imgResid[where(pixelmap ne 1)] = 0
        writefits, dir+name+'_scaled.fits', img
        writefits, dir+name+'_smooth.fits', imgSmooth
        writefits, dir+name+'_smoothresid.fits', imgResid
    Endif
    
    return, S

End