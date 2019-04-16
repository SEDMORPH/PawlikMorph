;; Use with mpfitfun.pro

Function mpaw_sersicfunction, X, P

  ;; ---------------------------- ;;
  ;; ------ Radii sampling ------ ;;
  R = X  
  R_temp = 0.0
  For j = 0, n_elements(R)-2 do begin
      Rmin = R[j]
      Rmax = R[j+1]
      Rj = interpolate([Rmin,Rmax],(1./9.)*findgen(10))
      Rj = Rj[1:n_elements(R1)-1]
      R_temp = [R_temp,Rj]
  Endfor
  
  ;; ---------------------------- ;;
  ;; ------ Sersic profile ------ ;;
  sb_eff = P[0]
  R_eff = P[1]
  n = P[2]
  sig1 = P[3]
  sig2 = P[4]
  ratio = P[5]
  
  ;; -- For magnitudes
  ;sb_m = sb_0 - 2.5*alog10(exp(-(R/alpha)^(1/n)))
  
  ;; -- For linear flux measures
  ;sb = sb_0*exp(-(R/alpha)^(1/n))
  b = (1.9992*n)-0.3271
  sb = sb_eff*exp(  -b*( (R_temp/R_eff)^(1./n)  -1. )   )
  ;sb_n = sb/total(sb)
  
  ;; --------------------------- ;;
  ;; ---- Convolve with PSF ---- ;;
  gauspar = fltarr(4)
  gauspar[0] = 1.0 ;; Max y-value
  gauspar[1] = 0.0 ;; Mean x-value (centre)
  gauspar[2] = sig1;; Sigma
  gauspar[3] = 0.0;; Offset
  psf1 = gaussian(R_temp,gauspar)
  psf1 = psf1/total(psf1)
  gauspar = fltarr(4)
  gauspar[0] = ratio ;; Max y-value
  gauspar[1] = 0.0 ;; Mean x-value (centre)
  gauspar[2] = sig2;; Sigma
  gauspar[3] = 0.0;; Offset
  psf2 = gaussian(R_temp,gauspar)
  psf2 = psf2/total(psf2)
  psf = (psf1+psf2)/total(psf1+psf2)
  
  R_sym = [-reverse(R_temp[1:n_elements(R_temp)-1]),R_temp]
  psf_sym = [reverse(psf[1:n_elements(psf)-1]),psf]
  sb_sym = [reverse(sb[1:n_elements(sb)-1]),sb]
 
  sb_psf = convol(sb_sym,psf_sym,/edge_truncate,center=1)
  sb_psf = sb_psf[n_elements(sb):n_elements(sb_psf)-1]  
  ;sb_psf = sb_psf*total(sb)
  
  ;; ----------------------------- ;;
  ;; - Back to original sampling - ;;
  ind = intarr(n_elements(R))
  For i = 0, n_elements(R)-1 do begin
      ind[i] = where(R_temp eq R[i])
  Endfor
  sb_fit = sb_psf[ind]
    
  return, sb_fit

End