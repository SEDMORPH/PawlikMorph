Function mpaw_distarr, npixx, npixy, cenpix

    x1 = findgen(npixx) - cenpix[0]
    x2 = x1*0. + 1.
    
    y1 = findgen(npixy) - cenpix[1]
    y2 = y1*0. + 1. 
    
    pixx = x1#y2
    pixy = x2#y1
    
    dist = sqrt(pixx^2 + pixy^2)
    
    return, dist
    
End