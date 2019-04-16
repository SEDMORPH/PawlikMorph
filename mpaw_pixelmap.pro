Function mpaw_pixelmap, img, thresh

  
    imgsize = size(img)
    
    ;; ----------- CHECK 1 ------------- ;;
    ;; Check if stamp is a square
    If imgsize[1] ne imgsize[2] then begin
        print, 'ERROR! MPAW_PIXELMAP: Input image must be a square.'
        objmask = 0.*img
    Endif else begin  
        
        npix = imgsize[1]
        cenpix = fltarr(2)
        cenpix[0] = npix/2 + 1
        cenpix[1] = npix/2 + 1
    
        ;; ------------ CHECK 2 ------------- ;;
        ;; Check if size of stamp appropriate for analysis using 3x3 pixel cells
        If float(npix)/3. ne npix/3 then begin
            print, 'ERROR! MPAW_PIXELMAP: Image size not suitable for 3x3 analysis.'
            objmask = 0. * img
        Endif else begin
            
            ;cenpix = fltarr(2)
            ;cenpix[0] = npix/2 + 1
            ;cenpix[1] = npix/2 + 1
                  
            ;; ------------ CHECK 3 ------------- ;;
            ;; Check if central pixel bright enough
            If img[cenpix[0],cenpix[1]] lt thresh then begin
                print, 'ERROR! MPAW_PIXELMAP: Central pixel too faint.'
                objmask = 0 * img
            Endif else begin
                
                ;; ----------------------------------------------- ;;
                ;; --------------- BEGIN DETECTION --------------- ;;
                
                ;dist = mpaw_distarr(npix,npix,cenpix)
                
                imgarea = npix*npix
                
                cellsize = [3,3]
                cellarea = cellsize[0]*cellsize[1]  
                
                numcells = imgarea/cellarea
                  
                centralcell = fltarr(2)
                centralcell[0] = long(sqrt(numcells)/2) + 1
                centralcell[1] = long(sqrt(numcells)/2) + 1

                x_min = 0
                x_max = cellsize[0]-1
                y_min = 0
                y_max = cellsize[1]-1
                
                cellstruc = {num:0L, xcoord:0L, ycoord:0L, xmin:0L, xmax:0L, ymin:0L, ymax:0L, array:fltarr(cellarea), mean:0.0}
                cell = replicate(cellstruc, numcells)

                cellmask_sum = intarr(numcells)
                
                k = 0
                x = 0
                y = 0
                
                While k lt numcells do begin

                    my_cell = img[x_min:x_max,y_min:y_max]
                    
                  ;  cellmask = sourcemask[x_min:x_max,y_min:y_max]
                  ;  cellmask_sum[k] = total(cellmask)

                    mean = total(my_cell)/n_elements(my_cell)

                    cell[k].array = my_cell
                    cell[k].mean = mean
                    cell[k].xmin = x_min
                    cell[k].xmax = x_max
                    cell[k].ymin = y_min
                    cell[k].ymax = y_max
                    cell[k].xcoord = x
                    cell[k].ycoord = y
                    cell[k].num = k

                    x_min = x_min + cellsize[0]
                    x_max = x_max + cellsize[0]

                    x = x + 1

                    If (y_max gt imgsize[2]) then break

                    If (x_max gt imgsize[1]) then begin

                        x_min = 0
                        x_max = cellsize[0]-1
                        y_min = y_min + cellsize[1]
                        y_max = y_max + cellsize[1]

                        x = 0
                        y = y + 1

                    Endif

                    k = k + 1  

                Endwhile
                
                ;; Find the central cell and get all the parameters
                For k = 0, numcells-1 do begin

                    If (cell[k].xcoord eq centralcell[0] and cell[k].ycoord eq centralcell[1]) then begin

                        ccArray = cell[k].array
                        ccMean = cell[k].mean
                        ccX = cell[k].xcoord
                        ccY = cell[k].ycoord
                        ccXmin = cell[k].xmin
                        ccXmax = cell[k].xmax
                        ccYmin = cell[k].ymin
                        ccYmax = cell[k].ymax

                    Endif

                Endfor
                
                ;; Object mask is not coarse grained (same number of
                ;; pixels as the stamp).
                ;; Set all pixels within the central cell to 1.
                objmask = 0 * img
                objmask[ccXmin:ccXmax, ccYmin:ccYmax] = 1.
                
                ;; Define the displacement vectors
                ;; (1 unit corresponds to 1 cell)
                vector_x = [-1,0,1,-1,0,1,-1,0,1]
                vector_y = [-1,-1,-1,0,0,0,1,1,1]
                
                ;; Check all surrounding cells (go out in progressively
                ;; larger loops)
                For m = 0, 8 do begin

                    neighbour_x = centralcell[0] + vector_x[m]
                    neighbour_y = centralcell[1] + vector_y[m]

                    For n = 0, numcells-1 do begin

                        If (cell[n].xcoord eq neighbour_x and cell[n].ycoord eq neighbour_y) then begin
                            cellval = cell[n].mean
                            cellxmin = cell[n].xmin
                            cellxmax = cell[n].xmax
                            cellymin = cell[n].ymin
                            cellymax = cell[n].ymax

                           ; cellmasksum = cellmask_sum[n]
                            
                        Endif

                    Endfor

                  ;  If (cellval gt thresh) and (cellmasksum eq 0) then objmask[cellxmin:cellxmax,cellymin:cellymax] = 1.
                    If (cellval gt thresh) then objmask[cellxmin:cellxmax,cellymin:cellymax] = 1.
                Endfor
                
                boxsize =1l
                x = 1l
                y = 0l
                dx = 0l
                dy = 1l

                x_limit = long(sqrt(numCells)/2)+1
                y_limit = long(sqrt(numCells)/2)+1

                step = 1
                
                While (x lt x_limit and x gt (-1*x_limit) and y lt y_limit and y gt -1*(y_limit) ) do begin

                    currentcell_x = centralcell[0] + x
                    currentcell_y = centralcell[1] + y

                    For n = 0, numcells-1 do begin

                        If (cell[n].xcoord eq currentcell_x and cell[n].ycoord eq currentcell_y) then begin                     
                            cellval = cell[n].mean
                            cellxmin = cell[n].xmin
                            cellxmax = cell[n].xmax
                            cellymin = cell[n].ymin
                            cellymax = cell[n].ymax

                          ;  cellmasksum = cellmask_sum[n]
                        Endif

                    Endfor

                   ; If (cellval gt thresh) and (cellmasksum eq 0) then begin
                    If (cellval gt thresh) then begin
                        
                        meanmask = fltarr(9)

                        For m = 0, 8 do begin

                            neighbour_x = currentcell_x + vector_x[m]
                            neighbour_y = currentcell_y + vector_y[m]

                            For n = 0, numcells-1 do begin

                                If (cell[n].xcoord eq neighbour_x and cell[n].ycoord eq neighbour_y) then begin
                                    neighbourxmin = cell[n].xmin
                                    neighbourxmax = cell[n].xmax
                                    neighbourymin = cell[n].ymin
                                    neighbourymax = cell[n].ymax

                                Endif

                            Endfor

                            neighbourmask = objmask[neighbourxmin:neighbourxmax, neighbourymin:neighbourymax]
                            meanmask[m] = total(neighbourmask)/n_elements(neighbourmask)
                        Endfor

                        mask = where(meanmask eq 1.)

                        If (mask[0] ge 0) then objmask[cellxmin:cellxmax, cellymin:cellymax] = 1.

                    Endif


                    If (dx eq 0 and dy eq 1 and x eq boxsize and y eq 0) then begin

                        x = x + 1
                        boxsize = boxsize + 1

                    Endif

                    If (x+dx) gt boxsize then begin
                        dx = 0
                        dy = 1
                    Endif else if (y+dy) gt boxsize then begin
                        dx = -1
                        dy = 0
                    Endif else if (x+dx) lt (-1.*boxSize) then begin
                        dx = 0
                        dy = -1
                    Endif else if (y+dy) lt (-1.*boxSize) then begin
                        dx = 1
                        dy = 0
                    Endif
         
                    x = x + dx
                    y = y + dy

                    step = step + 1

                Endwhile
             
            ;; close check 3
            Endelse
         ;; close check 2
         Endelse
     ;; close check 1
     Endelse
    
     return, objmask
    
End