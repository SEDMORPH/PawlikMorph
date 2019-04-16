;; Plot an image

PRO PLOTIMG, imgname, maskname
    
    dir = '~/Documents/St_Andrews/Projects/SEDMorph/Samples/Bulge_sample'
    ;read_jpeg, dir+imgname, img
    img = mrdfits(dir+imgname)
    mask = mrdfits(dir+maskname)
    
    cgloadct, 2
    
    img = img-5000
    
    ;img[where(mask eq 1)] = 0
    
    set_plot, 'ps'
    device, filename=dir+'img.ps'
    
     ; TVimage, img, MultiMargin = [0.5,0.5,0.5,0.5]
      
    TVimage, hist_equal(img), MultiMargin=[0.5,0.5,0.5,0.5]
  
    device, /close
    
END