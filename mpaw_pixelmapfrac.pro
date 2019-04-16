Function mpaw_pixelmapfrac, img, pixelmap, frac

          newimg = img
          
          imgsize = size(img)
          npix = imgsize[1]
          cenpix = fltarr(2)
          cenpix[0] = npix_x/2 + 1
          cenpix[1] = npix_y/2 + 1
      
          dist = my_distarr(npix,npix,cenpix)
          
          imgarea = npix*npix
          
          cellsize = [3,3]
          cellarea = cellsize[0]*cellsize[1]  
          
          numcells = imgarea/cellarea

          x_min = 0
          x_max = cellsize[0]-1
          y_min = 0
          y_max = cellsize[1]-1
         
          k = 0
          x = 0
          y = 0
          
          
          cellstruc = {num:0L, xcoord:0L, ycoord:0L, xmin:0L, xmax:0L, ymin:0L, ymax:0L, array:fltarr(cellarea), mean:0.0}
          cell = replicate(cellstruc, numcells)
          
          
          cellcount = 0
          While k lt numcells do begin

              my_cell = img[x_min:x_max,y_min:y_max]
              meanflux = total(my_cell)/n_elements(my_cell)
              
              cell[k].array = my_cell
              cell[k].mean = meanflux
              cell[k].xmin = x_min
              cell[k].xmax = x_max
              cell[k].ymin = y_min
              cell[k].ymax = y_max
              cell[k].xcoord = x
              cell[k].ycoord = y
              cell[k].num = k
              newimg[x_min:x_max,y_min:y_max] = meanflux

              If total(mask[x_min:x_max,y_min:y_max]) eq 9 then begin
                  cellcount = cellcount + 1
              Endif
              
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
          

          ;; Old method (choose low-surface brightness pixels directly)
          ;lowsbind = where(newimg lt thresh)
          ;match, objind, lowsbind, objind_sub, lowsbind_sub
          ;outskirtsind = objind[objind_sub]
          ;outskirtmask = img*0
          ;outskirtmask[outskirtsind] = 1
          
          ;; New method (choose the brightes pixels first and then take away from the total mask)
          
          ;; Find all cells belonging to the object
          m = 0
          k = 0
          objcellind = intarr(numcells)
          While k lt numcells do begin
              cellind = k
              If total(mask[cell[k].xmin:cell[k].xmax,cell[k].ymin:cell[k].ymax]) eq 9 then begin
                  objcellind[m] = cellind
                  m = m + 1
              Endif
              k = k + 1
          Endwhile
          objcellind = objcellind[0:m-1]
          
          objcell = cell[objcellind]
          
          ind_sort = reverse(sort(objcell.mean))
          objcellind_sort = objcellind[ind_sort]
          objcell_sort = objcell[ind_sort]
          
          Itotal = total(objcell.mean)
          Icell = fltarr(n_elements(objcell))
          Icell_ind = fltarr(n_elements(objcell))
          
          For ii = 0, n_elements(objcell)-1 do begin
              Icell[ii] = objcell_sort[ii].mean
              Icell_ind[ii] = objcellind_sort[ii]
          Endfor
          
          ii = 0
          Isum = 0
          While ii lt n_elements(objcell) do begin
              If Icell[ii] gt 0 then begin
                  Isum = Isum + Icell[ii]
              Endif
              If Isum ge frac*Itotal then begin
                  count = ii
                  ii = n_elements(objcell)
              Endif
              ii = ii + 1
          Endwhile
          
          brightcell_ind = objcellind_sort[0:count]
          
          brightmask = 0*mask
          
          For ii = 0, count do begin
              
              ind = brightcell_ind[ii]
              brightmask[cell[ind].xmin:cell[ind].xmax,cell[ind].ymin:cell[ind].ymax] = 1
              
          Endfor
          
         ; element = replicate(1,3,3)
         ; tempmask1 = dilate(brightmask,element)
         ; tempmask2 = dilate(tempmask1,element)
         ; tempmask3 = dilate(tempmask2,element)
         ; dilatedmask = dilate(tempmask2,element)
          
          outskirtmask = mask - brightmask
          
     
          
         Endelse
      Endelse
  
    return, outskirtmask

End