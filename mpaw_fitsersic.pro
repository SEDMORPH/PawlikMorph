;; ----------------------------------------------------------------------------------- ;;
;;        Fit a sersic function into object's surface-brightness (1D) profile          ;;
;; ----------------------------------------------------------------------------------- ;;
;; Optional input: weights (need to set keyword /weight)

Function mpaw_fitsersic, R, guess, prof, proferr, cov, err, weights, weight=weight
    
    parinfo = replicate({value:0.0,fixed:0,limited:[0,0],limits:[0.0,0.0]},6)
    parinfo[*].value = guess
    
    ;; Constrain the effective surface brightness
    parinfo[0].limited = [1,1]
    parinfo[0].limits = [1.,10000.]
    ;; Constrain the effective radius
    parinfo[1].limited = [1,1]
    parinfo[1].limits = [1.0,100.0]
    ;; Constrain the sersic index
    parinfo[2].limited = [1,1]
    parinfo[2].limits = [0.5,6.0]
  
    ;; Keep sigma1 fixed
    parinfo[3].fixed = 1 
    ;; Keep sigma2 fixed
    parinfo[4].fixed = 1 
    ;; Keep ratio fixed
    parinfo[5].fixed = 1 
    
    ;; Weights
    If not(keyword_set(weight)) then begin
        weights = 1./proferr^2.
        ind = where(finite(weights) eq 0 or weights lt 0)
        If ind[0] ne -1 then weights[ind]=0.0
    Endif
        
    bestParams = mpfitfun('mpaw_sersicfunction', R, prof, proferr, guess, yfit=yfit, weights=weights, /nan, parinfo=parinfo ,perr=err, covar=cov)
  
    return, bestParams
    
End
