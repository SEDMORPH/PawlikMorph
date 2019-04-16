;+
; NAME:
;        SHUFFLE
;
; PURPOSE:
;        This function returns the uniformly-shuffled elements of an array.
;
; CATEGORY:
;        Math.
;
; CALLING SEQUENCE:
;
;        Result = SHUFFLE( A [, Num])
;
; INPUTS:
;        A:        Array containing the elements to shuffle (e.g. INDGEN(100))
;
; OPTIONAL INPUTS:
;        Num:      Number of shuffled elements to return. Must be < N_ELEMENTS(A)+1
;
; OPTIONAL INPUT KEYWORD PARAMETERS:
;        SEED:     Number used to seed the random number generator, RANDOMU.
;
; OUTPUTS:
;        Returns the Num shuffled elements of the A array.
;
; OPTIONAL OUTPUT KEYWORD PARAMETERS:
;
;        INDICES:  Array of indices pointing to the shuffled elements of A.
;
; EXAMPLE:
;        Pick 10 unique random integers between the numbers 1..100:
;
;        i = INDGEN(100)
;        j = SHUFFLE(i,10)
;
; MODIFICATION HISTORY:
;        Written by:    Han Wen, January 1997.
;-

function SHUFFLE, A, Num, INDICES=Indices, SEED=Seed

         NP   = N_PARAMS()
         N    = N_ELEMENTS(A)
         if (N eq 0) then message, $
              'Must be called with 1-2 parameters: A [,Num]'
         if (NP eq 1) then Num = N

         r         = RANDOMU(Seed, N)
         Indices   = SORT(r)
         return, A(Indices(0:Num-1))
end