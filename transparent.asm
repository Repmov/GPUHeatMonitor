TransparentBitBlt proto :DWORD,:DWORD,:DWORD,:DWORD,:COLORREF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TransparentBitBlt proc thDC:DWORD,hBit:DWORD,Xpos:DWORD,Ypos:DWORD,cTransparentColor:COLORREF

        LOCAL BM:BITMAP 
        LOCAL bmAndBack:DWORD
        LOCAL bmAndObject:DWORD
        LOCAL bmAndMem:DWORD
        LOCAL bmSave : DWORD
        LOCAL  bmBackOld :DWORD
        LOCAL  bmMemOld :DWORD
        LOCAL bmObjectOld :DWORD
        LOCAL bmSaveOld :DWORD
        LOCAL hdcMem :DWORD
        LOCAL hdcBack :DWORD
        LOCAL hdcObject:DWORD
        LOCAL hdcTemp:DWORD
        LOCAL hdcSave:DWORD
        LOCAL PTSize:POINT
        LOCAL cColor:COLORREF 


        invoke CreateCompatibleDC,thDC
        mov hdcTemp,eax
        invoke SelectObject,hdcTemp, hBit                 ; // Select the bitmap 
        invoke GetObject,hBit, sizeof BM, addr BM

        mov eax,BM.bmWidth
        mov PTSize.x,eax
        mov eax,BM.bmHeight
        mov PTSize.y,eax
        invoke DPtoLP,hdcTemp,addr PTSize,1

        invoke CreateCompatibleDC,thDC
        mov hdcBack,eax
        invoke CreateCompatibleDC,thDC
        mov hdcObject,eax
        invoke CreateCompatibleDC,thDC
        mov hdcMem,eax
        invoke CreateCompatibleDC,thDC
        mov hdcSave,eax

        invoke CreateBitmap,PTSize.x,PTSize.y,1,1,NULL
        mov bmAndBack,eax
        invoke CreateBitmap,PTSize.x,PTSize.y,1,1,NULL
        mov bmAndObject,eax
        invoke CreateCompatibleBitmap,thDC,PTSize.x,PTSize.y
        mov bmAndMem,eax
        invoke CreateCompatibleBitmap,thDC,PTSize.x,PTSize.y
        mov bmSave,eax

        invoke SelectObject,hdcBack,bmAndBack
        mov bmBackOld,eax
        invoke SelectObject,hdcObject,bmAndObject
        mov bmObjectOld,eax
        invoke SelectObject,hdcMem,bmAndMem
        mov bmMemOld,eax
        invoke SelectObject,hdcSave,bmSave
        mov bmSaveOld,eax

        invoke GetMapMode,thDC
        invoke SetMapMode,hdcTemp,eax

        invoke BitBlt,hdcSave,0,0,PTSize.x,PTSize.y,hdcTemp,0,0,SRCCOPY
        invoke SetBkColor,hdcTemp,cTransparentColor
        mov cColor,eax
        invoke BitBlt,hdcObject,0,0,PTSize.x,PTSize.y,hdcTemp,0,0,SRCCOPY
        invoke SetBkColor,hdcTemp,cColor

        invoke BitBlt,hdcBack,0,0,PTSize.x,PTSize.y,hdcObject,0,0,NOTSRCCOPY

        invoke BitBlt,hdcMem,0,0,PTSize.x,PTSize.y,thDC,Xpos,Ypos,SRCCOPY
        invoke BitBlt,hdcMem,0,0,PTSize.x,PTSize.y,hdcObject,0,0,SRCAND
        invoke BitBlt,hdcTemp,0,0,PTSize.x,PTSize.y,hdcBack,0,0,SRCAND
        invoke BitBlt,hdcMem,0,0,PTSize.x,PTSize.y,hdcTemp,0,0,SRCPAINT
        invoke BitBlt,thDC,Xpos,Ypos,PTSize.x,PTSize.y,hdcMem,0,0,SRCCOPY
        invoke BitBlt,hdcTemp,0,0,PTSize.x,PTSize.y,hdcSave,0,0,SRCCOPY

        invoke SelectObject,hdcBack,bmBackOld
        invoke DeleteObject,eax

        invoke SelectObject,hdcObject,bmObjectOld
        invoke DeleteObject,eax

        invoke SelectObject,hdcMem,bmMemOld
        invoke DeleteObject,eax

        invoke SelectObject,hdcSave,bmSaveOld
        invoke DeleteObject,eax

        invoke DeleteDC,hdcMem
        invoke DeleteDC,hdcBack
        invoke DeleteDC,hdcObject
        invoke DeleteDC,hdcSave
        invoke DeleteDC,hdcTemp

        ret

TransparentBitBlt endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


TransparentBitBltPortion proc thDC:DWORD,hBit:DWORD,Xpos:DWORD,Ypos:DWORD,cTransparentColor:COLORREF,dWidth:DWORD,dHeight:DWORD,srcLeft:DWORD,srcTop:DWORD


        LOCAL BM:BITMAP 
        LOCAL bmAndBack:DWORD
        LOCAL bmAndObject:DWORD
        LOCAL bmAndMem:DWORD
        LOCAL bmSave : DWORD
        LOCAL  bmBackOld :DWORD
        LOCAL  bmMemOld :DWORD
        LOCAL bmObjectOld :DWORD
        LOCAL bmSaveOld :DWORD
        LOCAL hdcMem :DWORD
        LOCAL hdcBack :DWORD
        LOCAL hdcObject:DWORD
        LOCAL hdcTemp:DWORD
        LOCAL hdcSave:DWORD
        LOCAL PTSize:POINT
        LOCAL cColor:COLORREF 


        invoke CreateCompatibleDC,thDC
        mov hdcTemp,eax
        invoke SelectObject,hdcTemp, hBit                 ; // Select the bitmap 
        invoke GetObject,hBit, sizeof BM, addr BM

        mov eax,BM.bmWidth
        mov PTSize.x,eax
        mov eax,BM.bmHeight
        mov PTSize.y,eax
        invoke DPtoLP,hdcTemp,addr PTSize,1

        invoke CreateCompatibleDC,thDC
        mov hdcBack,eax
        invoke CreateCompatibleDC,thDC
        mov hdcObject,eax
        invoke CreateCompatibleDC,thDC
        mov hdcMem,eax
        invoke CreateCompatibleDC,thDC
        mov hdcSave,eax

        invoke CreateBitmap,PTSize.x,PTSize.y,1,1,NULL
        mov bmAndBack,eax
        invoke CreateBitmap,PTSize.x,PTSize.y,1,1,NULL
        mov bmAndObject,eax
        invoke CreateCompatibleBitmap,thDC,PTSize.x,PTSize.y
        mov bmAndMem,eax
        invoke CreateCompatibleBitmap,thDC,PTSize.x,PTSize.y
        mov bmSave,eax

        invoke SelectObject,hdcBack,bmAndBack
        mov bmBackOld,eax
        invoke SelectObject,hdcObject,bmAndObject
        mov bmObjectOld,eax
        invoke SelectObject,hdcMem,bmAndMem
        mov bmMemOld,eax
        invoke SelectObject,hdcSave,bmSave
        mov bmSaveOld,eax

        invoke GetMapMode,thDC
        invoke SetMapMode,hdcTemp,eax

        invoke BitBlt,hdcSave,0,0,PTSize.x,PTSize.y,hdcTemp,0,0,SRCCOPY
        invoke SetBkColor,hdcTemp,cTransparentColor
        mov cColor,eax
        invoke BitBlt,hdcObject,0,0,PTSize.x,PTSize.y,hdcTemp,0,0,SRCCOPY
        invoke SetBkColor,hdcTemp,cColor

        invoke BitBlt,hdcBack,0,0,PTSize.x,PTSize.y,hdcObject,0,0,NOTSRCCOPY

        invoke BitBlt,hdcMem,0,0,PTSize.x,PTSize.y,thDC,Xpos,Ypos,SRCCOPY

        invoke BitBlt,hdcMem,0,0,PTSize.x,PTSize.y,hdcObject,srcLeft,srcTop,SRCAND
        invoke BitBlt,hdcTemp,0,0,PTSize.x,PTSize.y,hdcBack,0,0,SRCAND
        invoke BitBlt,hdcMem,0,0,PTSize.x,PTSize.y,hdcTemp,srcLeft,srcTop,SRCPAINT
        invoke BitBlt,thDC,Xpos,Ypos,dWidth,dHeight,hdcMem,0,0,SRCCOPY
        invoke BitBlt,hdcTemp,0,0,PTSize.x,PTSize.y,hdcSave,0,0,SRCCOPY

        invoke SelectObject,hdcBack,bmBackOld
        invoke DeleteObject,eax

        invoke SelectObject,hdcObject,bmObjectOld
        invoke DeleteObject,eax

        invoke SelectObject,hdcMem,bmMemOld
        invoke DeleteObject,eax

        invoke SelectObject,hdcSave,bmSaveOld
        invoke DeleteObject,eax

        invoke DeleteDC,hdcMem
        invoke DeleteDC,hdcBack
        invoke DeleteDC,hdcObject
        invoke DeleteDC,hdcSave
        invoke DeleteDC,hdcTemp

        ret

TransparentBitBltPortion endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
