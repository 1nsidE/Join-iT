include jtSett.inc
.code
JoinSettDlgProc proc hwnd :DWORD,msg :DWORD,wParam :DWORD,lParam :DWORD
	
	mov eax,msg
	
	cmp eax,WM_INITDIALOG
	 jz @wm_init
	cmp eax,WM_COMMAND
	 jz @wm_command
	cmp eax,WM_CLOSE
	 jz @wm_close

ret_false:	
	xor eax,eax
	ret
	
@wm_init:
	invoke InitJSett,hwnd
	ret
	
@wm_command:
	mov eax,wParam
	
	cmp eax,IDC_JCANCEL
	 jnz @F
	invoke EndDialog,hwnd,0
	 jmp ret_true
@@:	
	jmp ret_false
	
@wm_close:
	invoke EndDialog,hwnd,0
	 jmp ret_true

ret_true:
	xor eax,eax
	inc eax
ret
JoinSettDlgProc endp

InitJSett proc hwnd :DWORD

	invoke SetDlgItemText,hwnd,IDC_OUTFILE,offset szJoined
	xor eax,eax	
ret

InitJSett endp


