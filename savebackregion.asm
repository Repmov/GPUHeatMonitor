;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveBackRegion proc  ODC:DWORD,TopX:DWORD,TopY:DWORD,BWidth:DWORD,BHeight:DWORD

LOCAL dcMem:DWORD
LOCAL BMMem2:DWORD
LOCAL BMemOld:DWORD

   ;saves a region from the specified DC into a bitmap
   ; and returns the handle for the bitmap

    invoke CreateCompatibleDC,ODC
    mov dcMem,eax

    invoke CreateCompatibleBitmap,ODC,BWidth,BHeight
    mov BMMem2,eax
    
    invoke SelectObject,dcMem,BMMem2
    mov BMemOld,eax

    ;now bitblt into the new dc
    invoke BitBlt,dcMem,0,0,BWidth,BHeight,ODC,TopX,TopY,SRCCOPY


    ;delete the dc and return the handle to the bitmap
 
   invoke SelectObject,dcMem,BMemOld
   invoke DeleteDC,dcMem 


   mov eax,BMMem2


  ret

SaveBackRegion endp
