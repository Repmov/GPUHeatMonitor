


;###################################################################################

BmpButnProc2 proc hWin   :DWORD,
                 uMsg   :DWORD,
                 wParam :DWORD,
                 lParam :DWORD

    LOCAL hBmpU  :DWORD
    LOCAL hBmpD  :DWORD
    LOCAL hImage2 :DWORD
    LOCAL hParent:DWORD
    LOCAL ID     :DWORD
    LOCAL ptX    :DWORD
    LOCAL ptY    :DWORD
    LOCAL bWid   :DWORD
    LOCAL bHgt   :DWORD
    LOCAL Rct    :RECT

    .data
    cFlag dd 0      ; a GLOBAL variable for the "clicked" setting
    .code

    .if uMsg == WM_LBUTTONDOWN


        invoke GetWindowLong,hWin,4
        mov hBmpD, eax
        invoke GetWindowLong,hWin,8
        mov hImage2, eax
        invoke SendMessage,hImage2,STM_SETIMAGE,IMAGE_BITMAP,hBmpD
        invoke SetCapture,hWin
        mov cFlag, 1

    .elseif uMsg == WM_LBUTTONUP

        .if cFlag == 0
          ret
        .else
          mov cFlag, 0
        .endif

        invoke GetWindowLong,hWin,0
        mov hBmpU, eax
        invoke GetWindowLong,hWin,8
        mov hImage2, eax
        invoke SendMessage,hImage2,STM_SETIMAGE,IMAGE_BITMAP,hBmpU

        mov eax, lParam
        cwde
        mov ptX, eax
        mov eax, lParam
        rol eax, 16
        cwde
        mov ptY, eax

        invoke GetWindowRect,hWin,ADDR Rct

        mov eax, Rct.right
        mov edx, Rct.left
        sub eax, edx
        mov bWid, eax

        mov eax, Rct.bottom
        mov edx, Rct.top
        sub eax, edx
        mov bHgt, eax

      ; --------------------------------
      ; exclude button releases outside
      ; of the button rectangle from
      ; sending message back to parent
      ; --------------------------------
        cmp ptX, 0
        jle @F
        cmp ptY, 0
        jle @F
        mov eax, bWid
        cmp ptX, eax
        jge @F
        mov eax, bHgt
        cmp ptY, eax
        jge @F

        invoke GetParent,hWin
        mov hParent, eax
        invoke GetDlgCtrlID,hWin
        mov ID, eax
      ;  mov ID,508
        invoke SendMessage,hParent,WM_COMMAND,ID,hWin
         

      @@:

        invoke ReleaseCapture

    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

BmpButnProc2 endp

; ########################################################################

BmpButton2 proc hParent:DWORD,topX:DWORD,topY:DWORD,
                rnum1:DWORD,rnum2:DWORD,ID:DWORD

  ; parameters are,
  ; 1.  Parent handle
  ; 2/3 top X & Y co-ordinates
  ; 4/5 resource ID numbers or identifiers for UP & DOWN bitmaps
  ; 6   ID number for control

    LOCAL hButn11  :DWORD
    LOCAL hImage2  :DWORD
    LOCAL hModule :DWORD
    LOCAL wid     :DWORD
    LOCAL hgt     :DWORD
    LOCAL hBmpU   :DWORD
    LOCAL hBmpD   :DWORD
    LOCAL Rct     :RECT
    LOCAL wc      :WNDCLASSEX


    invoke GetModuleHandle,NULL
    mov hModule, eax

    invoke LoadBitmap,hModule,rnum1
    mov hBmpU, eax
    invoke LoadBitmap,hModule,rnum2
    mov hBmpD, eax


skipskins:

    jmp skipdd
      Bmp_Button_Class db "Bmp_Button_Class",0
    skipdd:

    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNWINDOW
    mov wc.lpfnWndProc,    offset BmpButnProc2
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     16
      push hModule
      pop wc.hInstance
    mov wc.hbrBackground,  COLOR_BTNFACE+1
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  offset Bmp_Button_Class
    mov wc.hIcon,          NULL
      invoke LoadCursor,NULL,IDC_HAND  ;IDC_ARROW
    mov wc.hCursor,        eax
    mov wc.hIconSm,        NULL

    invoke RegisterClassEx, ADDR wc

    invoke CreateWindowEx,WS_EX_TRANSPARENT,
            ADDR Bmp_Button_Class,NULL,
            WS_CHILD or WS_VISIBLE,
            topX,topY,100,100,hParent,ID,
            hModule,NULL

    mov hButn11, eax

    invoke SetWindowLong,hButn11,0,hBmpU
    invoke SetWindowLong,hButn11,4,hBmpD


    jmp skipdd2
    ButnImageClass db "STATIC",0
    skipdd2:

    invoke CreateWindowEx,0,
            ADDR ButnImageClass,NULL,
            WS_CHILD or WS_VISIBLE or SS_BITMAP,
            0,0,0,0,hButn11,ID,
            hModule,NULL

    mov hImage2, eax

    invoke SendMessage,hImage2,STM_SETIMAGE,IMAGE_BITMAP,hBmpU

    invoke GetWindowRect,hImage2,ADDR Rct
    invoke SetWindowLong,hButn11,8,hImage2

    mov eax, Rct.bottom
    mov edx, Rct.top
    sub eax, edx
    mov hgt, eax

    mov eax, Rct.right
    mov edx, Rct.left
    sub eax, edx
    mov wid, eax

    invoke SetWindowPos,hButn11,HWND_TOP,0,0,wid,hgt,SWP_NOMOVE

    invoke ShowWindow,hButn11,SW_SHOW

    mov eax, hButn11

    ret

BmpButton2 endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this button type clicks itself on mousedown - donesnt wait for mouseup


BmpButtonClickProc   proc hWin   :DWORD,
                 uMsg   :DWORD,
                 wParam :DWORD,
                 lParam :DWORD

    LOCAL hBmpU  :DWORD
    LOCAL hBmpD  :DWORD
    LOCAL hImage2 :DWORD
    LOCAL hParent:DWORD
    LOCAL ID     :DWORD
    LOCAL ptX    :DWORD
    LOCAL ptY    :DWORD
    LOCAL bWid   :DWORD
    LOCAL bHgt   :DWORD
    LOCAL Rct    :RECT
    local    TimerID2:DWORD
    

    .data
    cFlag2 dd 0      ; a GLOBAL variable for the "clicked" setting
    message db "got here!",0
    .code

    .if uMsg == WM_LBUTTONDOWN

      cmp MeSpinning,1
      jz skipalreadyspin


      mov MeSpinning,1

        invoke GetWindowLong,hWin,4
        mov hBmpD, eax
        invoke GetWindowLong,hWin,8
        mov hImage2, eax
        invoke SendMessage,hImage2,STM_SETIMAGE,IMAGE_BITMAP,hBmpD

        mov cFlag2, 1

  invoke SetTimer,hWin,NULL,200,NULL
  mov TimerID2,eax



skipalreadyspin:      
       
  .elseif  uMsg == WM_TIMER


  .if cFlag2 == 0
          ret
        .else
          mov cFlag2, 0
        .endif

        invoke GetWindowLong,hWin,0
        mov hBmpU, eax
        invoke GetWindowLong,hWin,8
        mov hImage2, eax

        invoke SendMessage,hImage2,STM_SETIMAGE,IMAGE_BITMAP,hBmpU

        mov eax, lParam
        cwde
        mov ptX, eax
        mov eax, lParam
        rol eax, 16
        cwde
        mov ptY, eax

        invoke GetWindowRect,hWin,ADDR Rct

        mov eax, Rct.right
        mov edx, Rct.left
        sub eax, edx
        mov bWid, eax

        mov eax, Rct.bottom
        mov edx, Rct.top
        sub eax, edx
        mov bHgt, eax

      ; --------------------------------
      ; exclude button releases outside
      ; of the button rectangle from
      ; sending message back to parent
      ; --------------------------------
        cmp ptX, 0
        jle @F
        cmp ptY, 0
        jle @F
        mov eax, bWid
        cmp ptX, eax
        jge @F
        mov eax, bHgt
        cmp ptY, eax
        jge @F

        invoke GetParent,hWin
        mov hParent, eax
        invoke GetDlgCtrlID,hWin
        mov ID, eax

        invoke SendMessage,hParent,WM_COMMAND,ID,hWin
         

      @@:

        invoke ReleaseCapture

         invoke KillTimer,hWin,NULL

   .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

BmpButtonClickProc   endp

; ########################################################################

.data
  MeSpinning dd 0
.code

BmpButtonClick proc hParent:DWORD,topX:DWORD,topY:DWORD,
                rnum1:DWORD,rnum2:DWORD,ID:DWORD

  ; parameters are,
  ; 1.  Parent handle
  ; 2/3 top X & Y co-ordinates
  ; 4/5 resource ID numbers or identifiers for UP & DOWN bitmaps
  ; 6   ID number for control

    LOCAL hButn11  :DWORD
    LOCAL hImage2  :DWORD
    LOCAL hModule :DWORD
    LOCAL wid     :DWORD
    LOCAL hgt     :DWORD
    LOCAL hBmpU   :DWORD
    LOCAL hBmpD   :DWORD
    LOCAL Rct     :RECT
    LOCAL wc      :WNDCLASSEX


    invoke GetModuleHandle,NULL
    mov hModule, eax


    invoke LoadBitmap,hModule,rnum1
    mov hBmpU, eax
    invoke LoadBitmap,hModule,rnum2
    mov hBmpD, eax


skipskins:

    jmp skipdd
      Bmp_Button_Class2 db "BmpC_Button_Class",0
    skipdd:

    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNWINDOW
    mov wc.lpfnWndProc,    offset BmpButtonClickProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     16
      push hModule
      pop wc.hInstance
    mov wc.hbrBackground,  COLOR_BTNFACE+1
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  offset Bmp_Button_Class2
    mov wc.hIcon,          NULL
      invoke LoadCursor,NULL,IDC_HAND ;IDC_ARROW
    mov wc.hCursor,        eax
    mov wc.hIconSm,        NULL

    invoke RegisterClassEx, ADDR wc

    invoke CreateWindowEx,WS_EX_TRANSPARENT,
            ADDR Bmp_Button_Class2,NULL,
            WS_CHILD or WS_VISIBLE,
            topX,topY,100,100,hParent,ID,
            hModule,NULL

    mov hButn11, eax

    invoke SetWindowLong,hButn11,0,hBmpU
    invoke SetWindowLong,hButn11,4,hBmpD


    jmp skipdd2
    ButnImageClass2 db "STATIC",0
    skipdd2:

    invoke CreateWindowEx,0,
            ADDR ButnImageClass2,NULL,
            WS_CHILD or WS_VISIBLE or SS_BITMAP,
            0,0,0,0,hButn11,ID,
            hModule,NULL

    mov hImage2, eax

    invoke SendMessage,hImage2,STM_SETIMAGE,IMAGE_BITMAP,hBmpU

    invoke GetWindowRect,hImage2,ADDR Rct
    invoke SetWindowLong,hButn11,8,hImage2

    mov eax, Rct.bottom
    mov edx, Rct.top
    sub eax, edx
    mov hgt, eax

    mov eax, Rct.right
    mov edx, Rct.left
    sub eax, edx
    mov wid, eax

    invoke SetWindowPos,hButn11,HWND_TOP,0,0,wid,hgt,SWP_NOMOVE

    invoke ShowWindow,hButn11,SW_SHOW

    mov eax, hButn11

    ret

BmpButtonClick endp



