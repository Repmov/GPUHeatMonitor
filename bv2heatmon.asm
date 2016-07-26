

.586
.model          flat,stdcall
option          casemap:none

      include \MASM32\INCLUDE\windows.inc
      include \MASM32\INCLUDE\masm32.inc
      include \MASM32\INCLUDE\gdi32.inc
      include \MASM32\INCLUDE\user32.inc
      include \MASM32\INCLUDE\kernel32.inc
      include \MASM32\INCLUDE\Comctl32.inc
      include \MASM32\INCLUDE\comdlg32.inc
      include \MASM32\INCLUDE\shell32.inc
      include \MASM32\include\advapi32.inc
      include \masm32\include\winmm.inc
      include bv2_nvapi.INC


      includelib \MASM32\LIB\masm32.lib
      includelib \MASM32\LIB\gdi32.lib
      includelib \MASM32\LIB\user32.lib
      includelib \MASM32\LIB\kernel32.lib
      includelib \MASM32\LIB\Comctl32.lib
      includelib \MASM32\LIB\comdlg32.lib
      includelib \MASM32\LIB\shell32.lib
      includelib  \MASM32\lib\advapi32.lib
      includelib \masm32\lib\winmm.lib
      includelib nvapi.lib


      ;macros taken from the masm package macros
      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      return MACRO arg
        mov eax, arg
        ret
      ENDM


      RGB macro red,green,blue 
        xor eax,eax 
        mov ah,blue 
        shl eax,8 
        mov ah,green 
        mov al,red 
      endm 


      WinMain         PROTO :DWORD,:DWORD,:DWORD,:DWORD
      MakeRegion      PROTO :DWORD, :DWORD, :DWORD
      BmpButton2      PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
      AsciiToDw       PROTO :DWORD
      dwtoa2          PROTO :DWORD,:DWORD
      getGPUTemp      PROTO :DWORD,:DWORD
      DrawUpdate      PROTO  :DWORD


.CONST

      BitmapID        equ 2000
      PictureW        equ 250
      PictureH        equ 154

      WM_SHELLNOTIFY equ WM_USER+5 
      IDI_TRAY equ 0 
      IDM_RESTORE equ 1000 
      IDM_EXIT2 equ 1010 
      
      DISPLAY_GRAPH_WIDTH equ 225
      
      
.DATA

      ClassName       db "bv2heatmon",0
      DisplayName     db "BV2 Thermal Monitor",0  

      ButtonClassName db "button",0
      ButtonText      db "Click Me!",0

      RestoreString   db "Restore",0
      
      ExitString      db "Exit",0
      FontName        db "Ariblk.ttf",0   ;TODO later imbed it
      
      ErrorHeader     db "Error",0
      NoInitString    db "No NVidia GPU's found or error on initialization. Closing Down...",0
      
      Temp1RootString  db "GPU 0: %lu",0
      Temp2RootString  db "GPU 0: %lu",13,10,"GPU 1: %lu",0
      
      range           dd 120    ;TODO move to equ
      ysize           dd 56      ;TODO move to equ

      errorstring     db 1000 dup (0)
      BufferString    db 100 dup (0)
     
      gpuTemps1       dd 0
      gpuTemps2       dd 0
      
      paintCriticalSection CRITICAL_SECTION <>
      
      physicalGPUCount dd 0
      physicalGPUs    dd 8 dup (0)
      tempReading dd 0
      

.DATA?

      hFontT          dd ?

      TextBack1       dd ?
      TextBack2       dd ?
      graphBack       dd ?

      hInstance       dd ?
      hBitmap         dd ?
      ThreadID1       dd ?
      xpos            dd ?
      ypos            dd ?
      XBut            dd ?
      MinBut          dd ?
      TWND            dd ?
      hPopupMenu      dd ?

      note            NOTIFYICONDATA <> 
      pt              POINT       <?>
      
      NvStatus        dd ?
      
      ;assume max of 2 gpu's - irrespective of sample time our bitmap is only 225 wide
      tempHistory     dd 2*DISPLAY_GRAPH_WIDTH dup (?)

      gpuColour1      dd ?
      gpuColour2      dd ?
  

.CODE

  include savebackregion.asm
  include transparent.asm
  include bmpbuttons.asm


start:
        invoke GetModuleHandle, NULL
        mov    hInstance,eax
         
        invoke NvAPI_Initialize
        mov NvStatus,eax
        cmp eax,NVAPI_OK
        jnz initFailure
         
        invoke NvAPI_EnumPhysicalGPUs,addr physicalGPUs, addr physicalGPUCount
        mov NvStatus,eax
        cmp eax,NVAPI_OK
        jnz initFailure
        
        ;mov physicalGPUCount,1   ;for testing
        cmp physicalGPUCount,0
        jz noGPUs

      ;  invoke dwtoa,physicalGPUCount,addr errorstring
      ;  invoke MessageBox,0,addr errorstring,addr errorstring,MB_OK
                
        invoke WinMain, hInstance,NULL,NULL, SW_SHOWDEFAULT
        
        jmp skipfail
        
noGPUs:    
initFailure:    
        ;invoke NvAPI_GetErrorMessage,NvStatus, addr errorstring
        ;invoke MessageBox,0,addr errorstring,addr Text,MB_OK
        invoke MessageBox,0,addr NoInitString,addr ErrorHeader,MB_OK
skipfail:  
        invoke ExitProcess,eax
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
        
        
getGPUTemp proc gpuNumber:DWORD,lpTemp:DWORD

        LOCAL ThermalSettings:NV_GPU_THERMAL_SETTINGS 
        
        push ebx
        push edi
        push esi
        
        mov esi,lpTemp
        mov dword ptr [esi],-1
        
        lea edi,ThermalSettings
        mov ecx,sizeof(NV_GPU_THERMAL_SETTINGS)
        xor eax,eax
        rep stosb

        mov eax,sizeof(NV_GPU_THERMAL_SETTINGS)
        mov ebx,1
        shl ebx,16
        or eax,ebx
  
        mov ThermalSettings.version,eax 
        mov ThermalSettings.count,NVAPI_MAX_THERMAL_SENSORS_PER_GPU 
        mov ThermalSettings.sensor[0].controller,NVAPI_THERMAL_CONTROLLER_UNKNOWN
        mov ThermalSettings.sensor[0].target,NVAPI_THERMAL_TARGET_GPU
        lea ebx,physicalGPUs
        mov eax,gpuNumber
        mov edi,dword ptr [ebx+eax*4]
        invoke NvAPI_GPU_GetThermalSettings,edi,NVAPI_THERMAL_TARGET_ALL,addr ThermalSettings
        cmp eax,NVAPI_OK
        jnz failTempReading
        
        mov ebx,ThermalSettings.sensor[0].currentTemp
        mov dword ptr [esi],ebx
        
failTempReading:  
        pop esi      
        pop edi 
        pop ebx
        
        ret

getGPUTemp endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
        

WinMain proc hInst:DWORD,hPrevInst:DWORD,CmdLine:DWORD,CmdShow:DWORD

        LOCAL wc:WNDCLASSEX
        LOCAL msg:MSG
        LOCAL hwnd:HWND
                
        mov     wc.cbSize,SIZEOF WNDCLASSEX
        mov     wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
        mov     wc.lpfnWndProc, OFFSET WndProc
        mov     wc.cbClsExtra,NULL
        mov     wc.cbWndExtra,NULL
        push    hInstance
        pop     wc.hInstance     
        mov     wc.hbrBackground,NULL
        mov     wc.lpszMenuName,NULL
        mov     wc.lpszClassName,OFFSET ClassName
        invoke  LoadCursor,NULL,IDC_CROSS
        mov     wc.hCursor,eax

        invoke LoadIcon,hInstance,500    ; icon ID
        mov wc.hIcon, eax
        invoke LoadIcon,hInstance,501
        mov     wc.hIconSm,eax

        invoke  RegisterClassEx, addr wc
        
        invoke  GetSystemMetrics,SM_CXSCREEN
        ;shr     eax,1
        sub     eax,PictureW;/2
        mov xpos,eax
        push    eax

        invoke  GetSystemMetrics,SM_CYSCREEN
        ;shr     eax,1
        sub     eax,PictureH+PictureH/2;/2
        mov ypos,eax
        pop     ebx        
        
        INVOKE  CreateWindowEx,NULL,ADDR ClassName,ADDR ClassName,\
                WS_POPUP,ebx,eax,PictureW,PictureH,NULL,
                NULL,hInst,NULL
        mov     hwnd,eax
        mov TWND,eax

        invoke  ShowWindow, hwnd,SW_SHOWNORMAL
        invoke  UpdateWindow, hwnd

_Start:
        invoke  GetMessage,ADDR msg,NULL,0,0
        test    eax, eax
        jz      _Exit
        invoke  TranslateMessage,ADDR msg
        invoke  DispatchMessage,ADDR msg
        jmp     _Start
_Exit:
        mov     eax,msg.wParam
        ret
        
WinMain ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


WndProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

      LOCAL ps:PAINTSTRUCT
      LOCAL hdc:HDC
      LOCAL hMemDC:HDC
      LOCAL rect:RECT
      LOCAL	MousePos:POINT

      .IF     uMsg == WM_CREATE
      
          invoke InitializeCriticalSection,addr paintCriticalSection
          invoke CreateFont,-12,0,0,0,400,0,0,0,ANSI_CHARSET,\ 
                              OUT_TT_ONLY_PRECIS, CLIP_DEFAULT_PRECIS,\ 
                              PROOF_QUALITY,DEFAULT_PITCH or FF_DONTCARE ,\ 
                              ADDR FontName 
          mov hFontT, eax
                          
          RGB 255,0,0
          mov gpuColour1,eax
          RGB 0,0,255
          mov gpuColour2,eax

          invoke  LoadBitmap,hInstance,BitmapID
          mov     hBitmap,eax        
          invoke  GetWindowDC,hWnd
          mov     hdc,eax
          invoke  CreateCompatibleDC,NULL
          mov     hMemDC,eax
          invoke  SelectObject,hMemDC,hBitmap

          ;save the areas under the 'text' boxes
          invoke SaveBackRegion,hMemDC,171,24,60,18
          mov TextBack1,eax
          invoke SaveBackRegion,hMemDC,171,46,60,18
          mov TextBack2,eax
          
          invoke SaveBackRegion,hMemDC,12,88,DISPLAY_GRAPH_WIDTH,56
          mov graphBack,eax

          invoke  GetClientRect,hWnd,ADDR rect
          invoke  MakeRegion,hMemDC,rect.right,rect.bottom                
          invoke  SetWindowRgn,hWnd,eax,TRUE                               
          invoke  ReleaseDC,hWnd,hdc               
          invoke  DeleteDC,hMemDC

          ;the x button
          invoke BmpButton2,hWnd,220,5,2005,2006,502
          mov XBut,eax

          ;the min button
          invoke BmpButton2,hWnd,207,8,2011,2012,504
          mov MinBut,eax

          ;;;;;;;;;;;;;;;system tray icon
          invoke CreatePopupMenu 
          mov hPopupMenu,eax 
          invoke AppendMenu,hPopupMenu,MF_STRING,IDM_RESTORE,addr RestoreString 
          invoke AppendMenu,hPopupMenu,MF_STRING,IDM_EXIT2,addr ExitString 

          mov note.cbSize,sizeof NOTIFYICONDATA 
          push hWnd 
          pop note.hwnd
          mov note.uID,IDI_TRAY
          mov note.uFlags,NIF_ICON+NIF_MESSAGE+NIF_TIP 
          mov note.uCallbackMessage,WM_SHELLNOTIFY 
          invoke LoadIcon,hInstance,500 

          mov note.hIcon,eax 
          invoke lstrcpy,addr note.szTip,addr BufferString  
          invoke ShowWindow,hWnd,SW_HIDE 
          invoke Shell_NotifyIcon,NIM_ADD,addr note  

          ;start the update thread 
          mov eax, OFFSET UpdateThread
          invoke CreateThread,NULL,NULL,eax,
                                hWnd ,0,ADDR ThreadID1
          invoke CloseHandle,eax


      .ELSEIF uMsg == WM_PAINT
      
          invoke InvalidateRect,hWnd,NULL,FALSE 
          invoke  GetClientRect,hWnd,addr rect
          invoke  BeginPaint,hWnd,addr ps
          mov     hdc,eax        
          invoke  CreateCompatibleDC,NULL
          mov     hMemDC,eax
          invoke  SelectObject,hMemDC,hBitmap
          invoke  BitBlt,hdc,0,0,rect.right,rect.bottom,hMemDC,0,0,SRCCOPY        
        
          invoke DrawUpdate,hWnd
 
          invoke  DeleteDC,hMemDC        
          invoke  EndPaint,hWnd,addr ps   
                                  
        
      .ELSEIF uMsg == WM_COMMAND
         
          mov     eax,wParam

          .if wParam==IDM_RESTORE 
              invoke ShowWindow,hWnd,SW_RESTORE 
          .endif
          .if wParam==IDM_EXIT2
              invoke Shell_NotifyIcon,NIM_DELETE,addr note 
              invoke DestroyWindow,hWnd 
          .endif     

          .if ax == 502    ;close button

              invoke Shell_NotifyIcon,NIM_DELETE,addr note
              invoke  SendMessage,hWnd,WM_DESTROY,NULL,NULL
              ret

          .elseif ax== 504     ;minimize button
              invoke ShowWindow,hWnd,SW_MINIMIZE
              return 0
     
          .endif


          .elseif uMsg == WM_SIZE
            .if wParam==SIZE_MINIMIZED 
                invoke ShowWindow,hWnd,SW_HIDE 
            .endif 

          .elseif uMsg==WM_SHELLNOTIFY 
            .if wParam==IDI_TRAY 
              .if lParam==WM_RBUTTONDOWN 
                invoke GetCursorPos,addr pt 
                invoke SetForegroundWindow,hWnd 
                invoke TrackPopupMenu,hPopupMenu,TPM_RIGHTALIGN,pt.x,pt.y,NULL,hWnd,NULL 
                invoke PostMessage,hWnd,WM_NULL,0,0 
              .elseif lParam==WM_LBUTTONDBLCLK 
                invoke SendMessage,hWnd,WM_COMMAND,IDM_RESTORE,0 
              .endif 
          .endif 

                
      .ELSEIF uMsg == WM_DESTROY
          invoke  DeleteObject,hBitmap
          invoke  PostQuitMessage,NULL
          xor     eax,eax
          ret

      .ELSEIF uMsg==WM_NCHITTEST  
	       ; This handler is a little trick to make moving the window easy.
	       ; First get mouse position in client coordinates:
	       mov		eax, lParam
	       mov		ecx, eax
	       shr		ecx, 16		; ecx = Y
	       and		eax, 0ffffh	; eax = X
	       mov		MousePos.x, eax
	       mov		MousePos.y, ecx
         invoke	ScreenToClient, hWnd, ADDR MousePos
	
        ;check if x and y fall within caption bar....
         mov eax,22   ; 22 
         cmp MousePos.y,eax
         jge nocaptionhit
 	      ; If not, return HTCAPTION, which will make windows think you are clicking on
	       ; the  window caption (and thus moving the window)
	       mov		eax, HTCAPTION	

nocaptionhit:

        ret
        
      .ENDIF
          invoke  DefWindowProc,hWnd,uMsg,wParam,lParam            
          ret

WndProc endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MakeRegion      PROC USES ESI EDI EBX _hdc:HDC, _wdt:DWORD, _hgt:DWORD

        LOCAL flag: DWORD
        LOCAL frun: DWORD
        LOCAL d_dc: DWORD
        LOCAL f_dc: DWORD
        LOCAL oldx: DWORD
        LOCAL tcol: DWORD                

        mov     flag,FALSE
        mov     frun,TRUE
        mov     oldx,0
        xor     edi,edi
        xor     esi,esi

        invoke  GetPixel,_hdc,0,0
        mov     tcol,eax              
        
_xloop: invoke  GetPixel,_hdc,edi,esi

        cmp     eax,tcol
        jz      _letsgo

        cmp     edi,_wdt
        jnz     _foundone
        
 _letsgo:  
        cmp     flag,TRUE           
        jnz     _nextone
        
        mov     flag,FALSE        
        mov     eax,esi
        inc     eax
        invoke  CreateRectRgn,ebx,esi,edi,eax
        mov     d_dc,eax

        cmp     frun,TRUE       
        jnz     _nofrun
        mov     frun,FALSE
        push    d_dc
        pop     f_dc
        jmp     _nextone

_nofrun:
        invoke  CombineRgn,f_dc,f_dc,d_dc,RGN_OR
        invoke  DeleteObject,d_dc          
        jmp     _nextone
          
_foundone:
        cmp     flag,FALSE
        jnz     _nextone
        mov     flag,TRUE
        mov     ebx,edi

_nextone:
        inc     edi
        cmp     edi,_wdt
        jbe     _xloop
        
        xor     edi,edi       
        inc     esi
        cmp     esi,_hgt
        jb      _xloop
        
_exit:  mov     eax,f_dc      
        ret

MakeRegion ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawUpdate proc hWnd:DWORD

        LOCAL hdc:DWORD
        LOCAL hFontT2:DWORD
        LOCAL TotalTempChar:DWORD
        LOCAL TotalTempSize:DWORD
        LOCAL tempValue:DWORD

        invoke EnterCriticalSection,addr paintCriticalSection
        
        invoke  GetWindowDC,hWnd
        mov hdc,eax

        RGB 255,255,255
        push eax
        push eax
        invoke TransparentBitBlt,hdc,TextBack1,171,24,eax
        pop eax
        invoke TransparentBitBlt,hdc,TextBack2,171,46,eax
        pop eax
        invoke TransparentBitBlt,hdc,graphBack,12,88,eax
          
        mov ecx,DISPLAY_GRAPH_WIDTH-2
        mov eax,11+1
        mov ebx,0
        lea esi,tempHistory
nextpixel:          
        push ecx
        push eax
        push ebx
        add eax,ebx
        push eax
        mov edx,dword ptr [esi+ebx*4]     ;56 pixels so need to adjust range 0-120 to 56
        cmp edx,0
        jz skipplot1
          
        mov tempValue,edx  
        finit
        fild tempValue
        fild range
        fdiv 
        fild ysize
        fmul 
        fistp tempValue
          
        fwait
        mov edx,88+56-1
        sub edx,tempValue
          
        invoke SetPixel,hdc,eax,edx,gpuColour1
skipplot1:
        pop eax
        pop ebx
        pop eax
        pop ecx
        inc ebx
        loop nextpixel      
                    
          
        cmp physicalGPUCount,1
        jz onlyoneGPUPlot
          
          
        mov ecx,DISPLAY_GRAPH_WIDTH-2
        mov eax,11+1
        mov ebx,0
        lea esi,tempHistory
        add esi,DISPLAY_GRAPH_WIDTH*4
nextpixel2:          
        push ecx
        push eax
        push ebx
        add eax,ebx
        push eax
        
        mov edx,dword ptr [esi+ebx*4]     ;56 pixels so need to adjust range 0-120 to 56
        cmp edx,0
        jz skipplot2
          
        mov tempValue,edx  
        finit
        fild tempValue
        fild range
        fdiv 
        fild ysize
        fmul 
        fistp tempValue
          
        fwait
        mov edx,88+56-1
        sub edx,tempValue
          
        invoke SetPixel,hdc,eax,edx,gpuColour2
skipplot2:
        pop eax
        pop ebx
        pop eax
        pop ecx
        inc ebx
        loop nextpixel2  
              
onlyoneGPUPlot:

        invoke SelectObject, hdc, hFontT
        mov hFontT2,eax    

        invoke dwtoa,gpuTemps1,addr errorstring
        invoke lstrlen,addr errorstring
        mov ebx,eax
        invoke GetTextExtentPoint32,hdc,addr errorstring,ebx,addr TotalTempSize

        invoke SetTextColor,hdc,gpuColour1

        invoke SetBkMode,hdc,TRANSPARENT

        mov eax,179+40-2
        sub eax,TotalTempSize
        Invoke TextOut,hdc,eax,28-3,addr errorstring,2
      
        cmp physicalGPUCount,1
        jz onlyoneGPUText
        
        invoke dwtoa,gpuTemps2,addr errorstring
        invoke lstrlen,addr errorstring
        mov ebx,eax
        invoke GetTextExtentPoint32,hdc,addr errorstring,ebx,addr TotalTempSize

        invoke SetTextColor,hdc,gpuColour2;eax

        invoke SetBkMode,hdc,TRANSPARENT

        mov eax,179+40-2
        sub eax,TotalTempSize
        Invoke TextOut,hdc,eax,28+20-1,addr errorstring,2
     
onlyoneGPUText:   
        invoke SelectObject, hdc, hFontT2
        invoke SetBkMode,hdc,OPAQUE
          
        invoke  ReleaseDC,TWND,hdc
        
        invoke LeaveCriticalSection,addr paintCriticalSection
        
        ret
        
DrawUpdate endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateThread proc hWnd:DWORD


beginagain:
        ;shuffle our tempHistory down and get the new readings
        lea esi,tempHistory
        mov ecx,DISPLAY_GRAPH_WIDTH-2
        dec ecx
        mov ebx,0
          ;TODO change to repmov
nextVal:  
        mov eax,dword ptr [esi+ebx+4]
        mov dword ptr [esi+ebx],eax
        add ebx,4
        loop nextVal
  
        invoke getGPUTemp,0,addr tempReading
        cmp eax,NVAPI_OK
        jnz readingFail
        mov eax,tempReading 
        jmp readingOK
readingFail:
        mov eax,0
readingOK:
        mov gpuTemps1,eax
        mov dword ptr [esi+ebx],eax

        cmp physicalGPUCount,1
        jz onlyoneGPU

        ;shuffle our tempHistory down and get the new readings
        lea esi,tempHistory
         add esi,DISPLAY_GRAPH_WIDTH*4
        mov ecx,DISPLAY_GRAPH_WIDTH-2
        dec ecx
        mov ebx,0
        ;TODO change to repmov
nextVal2:  
        mov eax,dword ptr [esi+ebx+4]
        mov dword ptr [esi+ebx],eax
        add ebx,4
        loop nextVal2

        invoke getGPUTemp,1,addr tempReading
        cmp eax,NVAPI_OK
        jnz readingFail2
        mov eax,tempReading 
        jmp readingOK2
readingFail2:
        mov eax,0
readingOK2:
        mov gpuTemps2,eax
        mov dword ptr [esi+ebx],eax
          
onlyoneGPU:
        invoke DrawUpdate,hWnd


        ;TODO group the cmp's together
        cmp physicalGPUCount,1
        jz onlyoneGPUToolTip
        invoke	wsprintf,addr BufferString,addr Temp2RootString,gpuTemps1,gpuTemps2
        jmp skiponlyoneGPUToolTip
onlyoneGPUToolTip:
        invoke	wsprintf,addr BufferString,addr Temp1RootString,gpuTemps1
skiponlyoneGPUToolTip:          
        invoke lstrcpy,addr note.szTip,addr BufferString ;AppName 
        invoke Shell_NotifyIcon,NIM_MODIFY,addr note  


moveon:
        invoke Sleep,500     ;TODO read from config file
        jmp beginagain

        ret
        
UpdateThread endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


AsciiToDw proc uses edx esi,lpAscii:DWORD

  ;this procedure comes from the masm includes

	mov		esi,lpAscii
	xor		eax,eax
	xor		edx,edx
  @@:
	mov		dl,[esi]
	sub		dl,'0'
	jb		@f
	cmp		dl,10
	jnb		@f
	lea		eax,[eax*4+eax]		;Multiply by 5
	lea		eax,[eax*2+edx]		;Multiply by 2 and add digit in edx
	inc		esi
	jmp		@b
  @@:
	ret

AsciiToDw endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


dwtoa2 proc public uses esi edi dwValue:DWORD, lpBuffer:DWORD
;;;;;;;;;;;;;;;;
    ; -----------------------------------------
    ; This procedure was written by Tim Roberts
    ; -----------------------------------------
    ; Modified slightly by Farrier to return a '0' when dwValue = 0
    ; -------------------------------------------------------------
    ; convert DWORD to ascii string
    ; dwValue is value to be converted
    ; lpBuffer is the address of the receiving buffer
    ; EXAMPLE:
    ; invoke dwtoa,edx,addr buffer
    ;
    ; Uses: eax, ecx, edx.
    ; -------------------------------------------------------------

    mov eax, dwValue
    mov edi, [lpBuffer]
    .if (eax == 0)
        mov byte ptr [edi], '0'
        inc edi
        mov byte ptr [edi], 0
        ret
    .endif
    ; Is the value negative?
    .if (sdword ptr eax < 0)
      mov byte ptr [edi], '-'   ;store a minus sign
      inc edi
      neg eax                   ;and invert the value
    .endif
    mov esi, edi                ;save pointer to first digit
    mov ecx, 10
    .while (eax > 0)            ;while there is more to convert...
      xor edx, edx
      div ecx                   ;put next digit in edx
      add dl, '0'               ;convert to ASCII
      mov [edi], dl             ;store it
      inc edi
    .endw
    mov byte ptr [edi], 0       ;terminate the string
    ; We now have all the digits, but in reverse order.
    .while (esi < edi)
      dec edi
      mov al, [esi]
      mov ah, [edi]
      mov [edi], al
      mov [esi], ah
      inc esi
    .endw
    ret
    
dwtoa2 endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


end start
