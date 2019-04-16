Function mpaw_c, r_in, r_out
    
    C = 5. * alog10(r_out/r_in)
    c_check = finite(C)
    If c_check eq 0 then C = -99
    
    return, C
    
End
