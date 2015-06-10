.code

SettDlgProc proc hwnd :DWORD,msg :DWORD, wParam :DWORD,lParam :DWORD
	
	mov eax,msg
	
	cmp eax,WM_INITDIALOG
	 jz @wm_initdialog
	cmp eax,WM_COMMAND
	 jz @wm_command
	cmp eax,WM_CLOSE
	 jz @wm_close

ret_false:
	xor eax,eax
	ret

@wm_initdialog:
	invoke LoadUnpackFlags,hwnd 
	invoke GetDlgItem,hwnd,IDC_ICONPIC
	invoke SendMessage,eax,STM_SETICON,hIcon,0	
	 jmp  ret_true

@wm_command:
	mov eax,wParam
	 
	cmp eax,IDC_CANCEL
	 jnz @F
	invoke EndDialog,hwnd,0
	jmp ret_true
@@:	
	cmp eax,IDC_SAVE
	 jnz @F
	invoke SetUnpackFlags,hwnd
	invoke EndDialog,hwnd,0
	 jmp ret_true
@@:
	cmp eax,IDC_ICONBUT
	 jnz ret_false
	invoke MemAlloc,MAX_PATH
	push eax
	invoke FileOpen,offset szIconFilter,eax,MAX_PATH,hwnd,OFN_HIDEREADONLY or OFN_FILEMUSTEXIST or OFN_EXPLORER
	test eax,eax
	 jnz @F
	pop eax
	invoke MemFree,eax
	jmp ret_true
@@:	 
	pop eax
	invoke SetIcon,eax,hwnd
	invoke MemFree,eax
	 jmp ret_true
	
@wm_close:
	invoke EndDialog,hwnd,0
	jmp ret_true

ret_true:
	xor eax,eax
	inc eax
ret
SettDlgProc endp

SetUnpackFlags proc uses ebx ecx edi esi hwnd :DWORD
	mov ebx,IsDlgButtonChecked
	mov esi,IDC_GUIUNP
	mov edi,JTS_GUIUNP
	
@@L:
	;int 3
	push esi
	push hwnd
	call ebx ;IsDlgButtonChecked
	
	inc esi
	cmp esi,IDC_SELFREM + 1 
	 ja @@@
	
	test eax,eax
	 jz @F
	or unp.uFlags,edi
	shr edi,1
	 jmp @@L
@@:	;uncheck
	mov eax,edi
	not eax
	and unp.uFlags,eax
	shr edi,1
	 jmp @@L
@@@:
ret
SetUnpackFlags endp

LoadUnpackFlags proc uses ebx ecx edi esi hwnd :DWORD
	mov esi,unp.uFlags
	mov edi,IDC_GUIUNP - 1
	mov ebx,CheckDlgButton
@@:
	inc edi
	cmp edi,IDC_SELFREM
	 ja @@@
	
	shl esi,1
	 jnc @B
	push BST_CHECKED
	push edi
	push hwnd
	call ebx
	 jmp @B
@@@:
ret
LoadUnpackFlags endp

SetIcon  proc uses eax ptFileName :DWORD,hwnd :DWORD

	invoke ExtractIcon,hInstance,ptFileName,0
	test eax,eax
	 jnz @F
	invoke GetNameFromPath,ptFileName
	invoke FormatError,offset szNoIconError,eax
	ret
@@: 
	mov hIcon,eax
	invoke GetDlgItem,hwnd,IDC_ICONPIC
	invoke SendMessage,eax,STM_SETICON,hIcon,0
	
ret
SetIcon endp
