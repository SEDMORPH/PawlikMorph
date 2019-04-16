Function mpaw_pixeloutline, pixelmap
    
    element = replicate(1,3,3)
    
    e_pixelmap = erode(pixelmap,element)
    
    outline = pixelmap - e_pixelmap
    
    return, outline
    
End