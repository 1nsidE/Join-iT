;Join-iT 0.1( pre alpha ) (c) Ins!dE

;Started: 04.2009( mm.yyyy )
;First release:**.**.****
;Contact: insiiide@gmail.com
;--------------------------------------------------------------------------------
;Join-iT is a program that join different files into one executable file,pack and
;then depend on configuration unpack and run them, its a mix of joiner and archivator

;P.S. Sorry for my English

;P.P.S.
;I call listview,that holds all items 'fileList' and
;radiobuttons on the right of the window I call "optionButton's" 

include Join-iT.Inc
include settDlg.asm
include jtSett.asm

.code
start:
	mov hInstance,sizeof INITCOMMONCONTROLSEX
	mov hMain,ICC_WIN95_CLASSES
	invoke InitCommonControlsEx,addr hInstance
	   
	invoke GetModuleHandle,0
	mov hInstance,eax
	
	invoke DialogBoxParam,eax,IDD_MAINDLG,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;dialog func,mostly need for compare mess. and call other func's
DlgProc proc hwnd : HWND,msg : UINT,wParam : WPARAM,lParam : LPARAM
	mov eax,msg

	cmp eax,WM_INITDIALOG	;this is message Comparator3000 ;)
	 jz @wminit
	cmp eax,WM_COMMAND
	 jz @wmcommand
	cmp eax,WM_NOTIFY
	 jz @wmnotify
	cmp eax,WM_CLOSE
	 jz @wmclose
 	cmp eax,WM_DROPFILES
	 jz @wmdropfiles
	 		
	ret_false:
	xor eax,eax
	ret
;--------------------------------------------------------------------------------
	
@wminit:
	push hwnd
	pop hMain 
	
	invoke InitDlg
	test eax,eax
	 jnz ret_true
	 jmp ret_false

@wmcommand:
	mov eax,wParam
	
	cmp eax,IDM_ADDFILE
	 jnz @F
	invoke AddFile
	 jmp ret_true
@@:
	cmp eax,IDM_ADDFOLDER
	 jnz @F
	invoke AddFolder
	 jmp ret_true
@@:
	cmp eax,IDM_REMFILE
	 jnz @F
	invoke RemFile
	 jmp ret_true

@@:
	cmp eax,IDM_CLRFILE
	 jnz @F
	invoke ClrFileList
	 jmp ret_true
@@:
	cmp eax,IDM_RENAME
	 jnz @F
	invoke EditItemText	
	 jmp ret_true
@@:
	cmp eax,IDC_EXTRACT  
	 jb @F				
	cmp eax,IDC_MISC
	 ja @F  			
	invoke SetVisibleChecks,eax ;if ( eax >= IDC_EXTRACT ) && ( eax <= IDC_MISC )
	 jmp ret_true
@@:
	cmp eax,IDC_1
	 jb ret_false
@@:
	cmp eax,IDC_5
	 ja ret_false 
 	invoke SetFlags,eax
 	jmp ret_true 

@wmnotify:
	mov edx,lParam
	mov eax,[ edx ].NMHDR.hwndFrom
	
	cmp eax,hFileList
	 jz fileList		;filelist notify
	cmp eax,hToolT
	 jz toolT		;toolbar tooltip
	cmp eax,hToolB
	 jz toolB		;toolbar
	 
	 jmp ret_false

@wmdropfiles:
	invoke StartDrop,wParam
	 jmp ret_true
	
fileList:
	mov eax,[ edx ].NMHDR.code
	
	cmp eax,NM_RCLICK
	 jz fl_popup
 	cmp eax,LVN_KEYDOWN
 	 jz fl_keydown
 	cmp eax,LVN_ITEMCHANGED
 	 jz fl_select
 	
 	jmp ret_false
 	
fl_popup:
 	invoke PopUp
 	 jmp ret_true 
 
fl_keydown:
 	cmp [ edx ].NMLVKEYDOWN.wVKey,VK_DELETE
 	 jnz @F
 	invoke RemFile
 	 jmp ret_true 
@@:
	cmp [ edx ].NMLVKEYDOWN.wVKey,VK_F2
	 jnz ret_false
	invoke EditItemText
	 jmp ret_true
fl_select:
	invoke LoadChecks ;when user select some item
	 jmp ret_true
	
toolT:
	mov eax,[ edx ].NMHDR.code
	cmp eax,TTN_NEEDTEXT
	 jnz ret_false
	invoke ShowToolTip,lParam
	 jmp ret_true

toolB:
	mov eax,lParam
	cmp [ eax ].NMHDR.code,NM_CLICK
	 jnz ret_false
	invoke ToolBarClick,eax
	 jmp ret_true

@wmclose:
	invoke Destructor
	invoke EndDialog,hMain,0
;--------------------------------------------------------------------------------
ret_true:
xor eax,eax
inc eax
ret
DlgProc endp

;initialize dialog controls and get handles of controls
InitDlg proc uses ebx
LOCAL sfi :SHFILEINFO
	
	invoke GetDlgItem,hMain,IDC_FILELIST	;fileList
	mov hFileList,eax
	invoke GetDlgItem,hMain,IDC_STBAR	;status bar
	mov hStBar,eax
	invoke GetDlgItem,hMain,IDC_PRBAR
	
	mov sfi.hIcon,100
	mov sfi.iIcon,-1
	invoke SendMessage,hStBar,SB_SETPARTS,2,addr sfi
	invoke UpdateStBar
	
	invoke InitTlb	 ;initialize toolbar
	invoke InitList	 ;initialize listview

	invoke LoadIcon,hInstance,2
	mov hIcon,eax
	
	invoke SendMessage,hToolB,TB_GETTOOLTIPS,0,0 ;toolbat tooltip
	mov hToolT,eax
	
	invoke LoadMenu,hInstance,IDR_POPUP	;load menu from resources
	invoke GetSubMenu,eax,0			;get submenu for popUp
	mov hMenu,eax
	
	;get system imagelist
	invoke SHGetFileInfo,offset szC,NULL,addr sfi,sizeof SHFILEINFO,SHGFI_SMALLICON or SHGFI_SYSICONINDEX
	invoke SendMessage,hFileList,LVM_SETIMAGELIST,LVSIL_SMALL,eax
	
	invoke InitMemory
	test eax,eax
	 jnz @F
	xor eax,eax
	ret
@@:	
	mov pMem,eax
	mov pLastMem,eax
	invoke GetDlgItem,hMain,IDC_CUSTDIR
	invoke SetWindowLong,eax,GWL_WNDPROC,addr CustDirProc
	mov pCustProc,eax
	
	invoke GetProcessHeap
	mov hHeap,eax
;--------------------------------------------------------------------------------
	
	invoke CheckDlgButton,hMain,IDC_EXTRACT,BST_CHECKED ;check
	invoke SetVisibleChecks,IDC_EXTRACT					;update

	xor eax,eax
	ret
InitDlg endp

;initialize listview
InitList proc
LOCAL lvc : LVCOLUMN
LOCAL lvi : LVITEM

    mov lvc.imask,LVCF_TEXT or LVCF_WIDTH
	mov lvc.lx,230
	mov lvc.pszText,offset szNameCol
	invoke SendMessage,hFileList,LVM_INSERTCOLUMN,0,addr lvc
	or lvc.imask,LVCF_FMT
	mov lvc.fmt,LVCFMT_LEFT
	mov lvc.lx,100
	mov lvc.pszText,offset szSizeCol
	invoke SendMessage,hFileList,LVM_INSERTCOLUMN,1,addr lvc
	invoke SendMessage,hFileList,LVM_SETEXTENDEDLISTVIEWSTYLE,0,LVS_EX_FULLROWSELECT
ret
InitList endp

;show popUp when rclick on fileList
PopUp proc uses eax
LOCAL pt : POINT

	invoke SendMessage,hFileList,LVM_GETITEMCOUNT,0,0
	test eax,eax
	 jnz @F
	invoke EnableMenuItem,hMenu,IDM_CLRFILE,MF_DISABLED or MF_GRAYED
	
@@:
	invoke GetSelectedItem
	inc eax
	 jnz @F
	invoke EnableMenuItem,hMenu,IDM_REMFILE,MF_DISABLED or MF_GRAYED
	invoke EnableMenuItem,hMenu,IDM_RENAME,MF_DISABLED or MF_GRAYED	
@@:
	invoke GetCursorPos,addr pt
	invoke TrackPopupMenu,hMenu,TPM_LEFTALIGN,pt.x,pt.y,0,hMain,NULL

	invoke EnableMenuItem,hMenu,IDM_REMFILE,MF_ENABLED
	invoke EnableMenuItem,hMenu,IDM_CLRFILE,MF_ENABLED
	invoke EnableMenuItem,hMenu,IDM_RENAME,MF_ENABLED
	
go_end:
ret
PopUp endp

;show open dialog and return 1 if all ok,0 else
FileOpen proc ptFilter :DWORD,ptFileName :DWORD,nMemSize :DWORD,hwnd :DWORD,uFlags :DWORD
LOCAL ofn :OPENFILENAME
	
	invoke RtlZeroMemory,addr ofn,sizeof OPENFILENAME
	
	mov ofn.lStructSize,sizeof OPENFILENAME
	movm ofn.hwndOwner,hwnd
	movm ofn.hInstance,hInstance
	movm ofn.lpstrFilter,ptFilter
	movm ofn.lpstrFile,ptFileName
	movm ofn.nMaxFile,nMemSize
	movm ofn.Flags,uFlags
	
	invoke GetOpenFileName,addr ofn

ret
FileOpen endp

;call other func's for add file
AddFile proc uses ecx
LOCAL pszBuff :DWORD
LOCAL nSlashPos :DWORD
LOCAL pszNext :DWORD

	invoke MemAlloc,40000h
	;int 3
@@:
	mov pszBuff,eax
	invoke FileOpen,addr szFileFilter,pszBuff,40000h,hMain,OFN_HIDEREADONLY or OFN_FILEMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
	;invoke CommDlgExtendedError
	test eax,eax
	 jz @F
	;int 3
	invoke IsFolder,pszBuff ;is multiply files selected( 1 - Yes,0 - No )
	test eax,eax
	 jz one_file
	invoke CreateThread,NULL,2048,AddFiles,pszBuff,NULL,NULL	
	 jmp @F
	
one_file:	
	invoke AddToList,pszBuff
	invoke MemFree,pszBuff	
	invoke UpdateStBar
@@:

ret
AddFile endp

;Adds multiplue files asynchornously
AddFiles proc pszBuff :DWORD
LOCAL nSlashPos :DWORD
LOCAL pszNext :DWORD	
	;int 3
	
	invoke DisableGui,TRUE
	invoke lstrlen,pszBuff
	mov nSlashPos,eax
	
	mov ecx,pszBuff							
	add ecx,eax					;get slash pos
 	cmp byte ptr [ ecx - 1 ],'\';check on root di
 	 jnz @@1
	
	invoke FixSlash,pszBuff		
	dec nSlashPos
	inc pszBuff
	 jmp @@2
	
@@1: 	
 	mov byte ptr [ ecx ],'\' 	;put slash instead of NULL

@@2:
	inc ecx
	mov pszNext,ecx 	;pszNext contains adress of next file
	invoke lstrlen,pszNext
	inc eax
	add pszNext,eax
	
@@3:	
	invoke AddToList,pszBuff ;first file
	invoke UpdateStBar
	
	mov eax,pszBuff
	add eax,nSlashPos
	inc eax
	mov byte ptr [ eax ],00h ;null after after slash for next file 
	
	mov eax,pszNext			
	cmp byte ptr [ eax ],00h	;check on extra null at the end of the string
	 jz @F
	
	invoke lstrlen,pszNext	;get offset of the next file name
	inc eax
	push eax				;save offset
	
	invoke lstrcat,pszBuff,pszNext
	
	pop eax					;restore offset
	add pszNext,eax			;add offset to the pointer( now in pszNext address of the next file )
	 jmp @@3
@@:
	invoke MemFree,pszBuff
	invoke DisableGui,FALSE
	
	xor eax,eax
	ret					
AddFiles endp

;show folder browse dialog
AddFolder proc
LOCAL bri : BROWSEINFO
	
	invoke MemAlloc,MAX_PATH
	push eax 
	
	movm bri.hwndOwner,hMain
	mov bri.pidlRoot,NULL
	mov bri.pszDisplayName,NULL
	mov bri.lpszTitle,NULL
	mov bri.ulFlags,NULL
	mov bri.lpfn,NULL
	mov bri.lParam,NULL
	mov bri.iImage,NULL
	invoke SHBrowseForFolder,addr bri
	test eax,eax
	 jz @F
	pop ecx
	mov bri.hwndOwner,ecx
	invoke SHGetPathFromIDList,eax,ecx
	
	invoke AddToList,bri.hwndOwner
	invoke MemFree,bri.hwndOwner
	
	invoke UpdateStBar
@@:
ret
AddFolder endp

;Add dropped files
AddDropedFiles proc hDrop :DWORD
LOCAL nCount :DWORD 
LOCAL pszFileName :DWORD
	mov ebx,DragQueryFile
	
	push NULL
	push NULL
	push -1
	push hDrop
	call ebx
	
	dec eax		;make 0 based
	mov nCount,eax
@@:
	push NULL
	push NULL
	push nCount
	push hDrop
	call ebx ;DragQueryFile
	
	inc eax	        ;for 0
	push eax	;save
	
	invoke MemAlloc,eax	;alloc mem for file name
	mov pszFileName,eax
	
		pop eax			;restore	
	
	push eax
	push pszFileName
	push nCount
	push hDrop
	call ebx ;DragQueryFile

	invoke AddToList,pszFileName	;add file to listview
	invoke MemFree,pszFileName	;free filename mem
	invoke UpdateStBar
	dec nCount
	 jns @B		;while >= 0
	
	
	
	xor eax,eax
ret
AddDropedFiles endp

;save item info
AddToMem proc uses edi esi eax nSize :DWORD,pszName :DWORD
LOCAL fi : FILEINFO

	mov fi.uFlags,DF_FLAGS 		;set item flags to default
	movm fi.uFileSize,nSize 	;file size in bytes
	;int 3
	mov fi.pszCustDir,offset szCustDir
	invoke lstrlen,pszName
	inc eax
	push eax
	;int 3
	invoke MemAlloc,eax ;alloc memory for file name
    mov fi.pszName,eax
;copy name
;-----------------------------------------------------------------------------
	mov edi,eax
	mov esi,pszName

	pop ecx
	mov eax,ecx
	shr ecx,2
	rep movsd ;copy by dword's ,for speed

	mov ecx,eax
	and ecx,3
	rep movsb ;copy end 
;-----------------------------------------------------------------------------
	invoke IsFolder,pszName
	test eax,eax
	 jz @F
	or fi.uFlags,JTH_FOLDER
@@:
	mov eax,nSize
	test eax,eax
	 jnz @F
	or fi.uFlags,JTH_ZEROLEN
	dec fi.uFileSize ;set file size to -1
@@:
	mov edi,pLastMem
	mov ecx,pCurrent
	add ecx,DF_LIMIT
	cmp edi,ecx
	 jnz @F

;------------------------------------------------------------------------------
;if currrent region is ended
	push pCurrent
	invoke InitMemory
	pop ecx
	mov [ ecx + DF_LIMIT ].MEM.pNextMem,eax ;next region
	mov [ eax + DF_LIMIT ].MEM.pPrevMem,ecx ;prev region 
	mov pLastMem,eax
	mov edi,eax
;-------------------------------------------------------------------------------
@@:
	cdq
	lea esi,fi		
	mov ecx,sizeof FILEINFO / 4
	rep movsd		

;--------------------------------------------------------------------------------
	add pLastMem,sizeof FILEINFO	
	
	xor ecx,ecx
	inc ecx
ret
AddToMem endp

;add's item to fileList
AddToList proc uses ebx pszItemName :DWORD
LOCAL sfi :SHFILEINFO ;aka LVITEM ;)
	
	;because SHFILEINFO > LVITEM and because i need it only for SHGetFileInfo api
	;i use SHFILEINFO as LVITEM 
;--------------------------------------------------------------------------------

	invoke SHGetFileInfo,pszItemName,NULL,addr sfi,sizeof SHFILEINFO,SHGFI_SYSICONINDEX or SHGFI_SMALLICON
	
	lea ebx,sfi
	
	movm [ ebx.LVITEM.iImage ],[ ebx.SHFILEINFO.iIcon ] ;icon ,SHFILEINFO.szDisplayName + 20
	
	mov [ ebx.LVITEM.imask ],LVIF_TEXT or LVIF_IMAGE ;style
	movm [ ebx.LVITEM.iItem ],unp.nFileCount ;item number
	mov [ ebx.LVITEM.iSubItem ],0
	
	mov eax,pszItemName
	cmp byte ptr [ eax + 3h ],0h ;if root dir. like 'C:\'
         jz @F
	
	invoke GetNameFromPath,eax
@@:	
	mov [ ebx.LVITEM.pszText ],eax ;SHFILEINFO.szDisplayName + 12
	invoke SendMessage,hFileList,LVM_INSERTITEM,0,addr sfi
;--------------------------------------------------------------------------------
	
	invoke IsFolder,pszItemName
	test eax,eax
	 jz @F 
	mov [ ebx.LVITEM.pszText ],offset szFolder
	inc [ ebx.LVITEM.iSubItem ]
	
	invoke AddToMem,-1,pszItemName
	test ecx,ecx
	 jnz @@@
	invoke FormatError,offset szFileError,[ ebx.LVITEM.pszText ]
	invoke SendMessage,hFileList,LVM_DELETEITEM,unp.nFileCount,0
	xor eax,eax
	ret
;--------------------------------------------------------------------------------
@@:
	invoke GetFileSize_my,pszItemName
	inc eax								;check on -1( if error )	
	 jnz @F
	invoke SendMessage,hFileList,LVM_DELETEITEM,unp.nFileCount,0 ;delete if error
	xor eax,eax
	ret

@@:
	dec eax ;restore eax
	invoke AddToMem,eax,pszItemName ;add to memory( return value in ecx )
	test ecx,ecx
	 jnz @F
	invoke FormatError,offset szFileError,[ ebx.LVITEM.pszText ]
	invoke SendMessage,hFileList,LVM_DELETEITEM,unp.nFileCount,0
	xor eax,eax
	ret
	
@@:     
        add unp.nAllSize,eax
        
        shr eax,10	;divide by 1024( bytes -> kilobytes )
	 jnz @F 	;if filesize < 1kb
	inc eax         ;make it 1 kb
;--------------------------------------------------------------------------------
@@:
	invoke wsprintf,addr [ ebx.LVITEM.lParam ],addr szFlags,eax ;filesize into string( %lu ) 
	
	lea eax,[ ebx.LVITEM.lParam ] ;SHFILEINFO.szDisplayName + 24
	mov [ ebx.LVITEM.pszText ],eax
	
	inc [ ebx.LVITEM.iSubItem ]
@@@:    invoke SendMessage,hFileList,LVM_SETITEM,0,addr sfi ;add column
	
	inc unp.nFileCount ;added new file
	
	mov eax,pCurrent
	inc dword ptr [ eax + DF_LIMIT ].MEM.nCount
	
	xor eax,eax
	inc eax
ret
AddToList endp

;removes file form fileList and form memory
RemFile proc uses ebx ecx
	
@@:
	invoke GetSelectedItem
	inc eax		;last item
	 jz @F
	
	dec eax		;restoring eax
	push eax
	invoke SendMessage,hFileList,LVM_DELETEITEM,eax,0
	
	pop eax
        invoke GetFromMem,eax
        mov ebx,eax
        
        test [ ebx.FILEINFO.uFlags ],JTH_FOLDER or JTH_ZEROLEN
         jnz @2
        mov ecx,[ eax.FILEINFO.uFileSize ]
        sub unp.nAllSize, ecx
@2:
        invoke MemFree,[ ebx.FILEINFO.pszName ]
        test [ ebx.FILEINFO.uFlags ],JT_CUSTDIR
         jz @1
        invoke MemFree,[ ebx.FILEINFO.pszCustDir ]
@1:        
	dec unp.nFileCount
	 jmp @B
@@:
	invoke UpdateStBar
	invoke LoadChecks
ret
RemFile endp

;removes all items in fileList
ClrFileList proc uses eax edi esi ebx
	
	mov eax,unp.nFileCount
	test eax,eax
	 jnz @F
	ret
;--------------------------------------------------------------------------------
@@:
	mov edi,offset MemFree
    mov ebx,pMem
	lea esi,[ ebx + DF_LIMIT ]
@@:
	push [ ebx.FILEINFO.pszName ]
	call edi ;MemFree
	
	test dword ptr[ ebx ],JT_CUSTDIR
	 jz @1
	
	push [ ebx.FILEINFO.pszCustDir ]
	call edi ;MemFree
@1:        
        add ebx,sizeof FILEINFO
        
        dec unp.nFileCount
         jz @F
        
        cmp ebx,esi
         jnz @B
        mov ebx,[ ebx.MEM.pNextMem ]
               
        sub esi,DF_LIMIT
        invoke VirtualFree,esi,0,MEM_RELEASE
        
        mov esi,ebx
        add esi,DF_LIMIT
         jmp @B
;--------------------------------------------------------------------------------
@@:
;free last mem. region
        sub esi,DF_LIMIT
        invoke VirtualFree,esi,NULL,MEM_RELEASE
	
;now alloc new mem. region :)
        invoke InitMemory
        mov pLastMem,eax
	
	invoke SendMessage,hFileList,LVM_DELETEALLITEMS,0,0
	
	mov unp.nAllSize,0
	invoke UpdateStBar
	invoke ClearCheckButtons
	invoke EnableDlgChecks,FALSE
ret
ClrFileList endp

;initialize toolbar
InitTlb proc uses ecx
LOCAL tbb :TBBUTTON
	
	invoke CreateWindowEx,
	0,\
	offset szToolbarClass,\
	NULL,\
	WS_CHILD or WS_VISIBLE or TBSTYLE_FLAT or TBSTYLE_TOOLTIPS or TBSTYLE_WRAPABLE,\
	0,\
	0,\
	0,\
	0,\
	hMain,\
	NULL,\
	hInstance,\
	NULL
	
	mov hToolB,eax
	
	invoke SendMessage,eax,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	
	invoke ImageList_LoadImage,hInstance,ID_TOOLB,32,0,CLR_DEFAULT,IMAGE_BITMAP,LR_CREATEDIBSECTION
	invoke SendMessage,hToolB,TB_SETIMAGELIST,0,eax
	
	xor ecx,ecx
	xor eax,eax
@@:
	push ecx
	push eax
	
	mov tbb.iBitmap,eax
	mov tbb.idCommand,eax
	add tbb.idCommand,IDT_JOIN
	mov tbb.fsState,TBSTATE_ENABLED
	mov tbb.fsStyle,TBSTYLE_BUTTON
	mov tbb.dwData,0
	mov tbb.iString,NULL

	cmp ecx,1
	 jz @@1
	cmp ecx,4
	 jz @@1
	cmp ecx,7
	 jz @@1
	cmp ecx,10
	 jnz @@2 
@@1: 
	or tbb.fsStyle,BTNS_SEP
	mov tbb.iBitmap,6
	pop eax
	dec eax
	push eax
@@2:
	invoke SendMessage,hToolB,TB_INSERTBUTTON,ecx,addr tbb
	pop eax
	inc eax
	
	pop ecx
	inc ecx
	cmp ecx,12
	 jnz @B
ret
InitTlb endp

;updates information in status bar 
UpdateStBar proc
LOCAL szString[ 24 ] :BYTE
	
	invoke wsprintf,addr szString,offset szStCount,unp.nFileCount
	invoke SendMessage,hStBar,SB_SETTEXT,0,addr szString
        
        mov eax,unp.nAllSize
        shr eax,20
	
	invoke wsprintf,addr szString,offset szStFileSize,eax
	invoke SendMessage,hStBar,SB_SETTEXT,1,addr szString
	
ret
UpdateStBar endp

;show toolTip on toolbar buttons
ShowToolTip proc uses edx lParam:DWORD
	mov edx,lParam
	mov eax,[ edx ].NMHDR.idFrom
	
	cmp eax,IDT_JOIN
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szJoinBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret
	
@@:
	cmp eax,IDT_ADDFILE
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szAddBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret
@@:
	cmp eax,IDT_ADDFOLDER
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szAddFolderBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret
@@:
	cmp eax,IDT_REMFILE
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szDelBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret

@@:
	cmp eax,IDT_CLRFILE
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szClrBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret

@@:
	cmp eax,IDT_SETTINGS
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szSettBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret

@@:
	cmp eax,IDT_JOINSETT
	 jnz @F
	mov [ edx ].NMTTDISPINFO.lpszText,offset szJoinSett 
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret
@@:	
	mov [ edx ].NMTTDISPINFO.lpszText,offset szAbtBut
	mov [ edx ].NMTTDISPINFO.hInst,NULL
	ret
	
ShowToolTip endp

;get file name from path
GetNameFromPath proc uses edi pszName:DWORD
	
	invoke lstrlen,pszName
	mov ecx,eax
	
	mov edi,pszName
	add edi,ecx		;go to the end of string 
	mov al,'\'		;search for slash
	std			;form end to the begin ( DF = 1 )
	repnz scasb		;search for slash
	cld			;restore DF ( = 0 )
	mov eax,edi
	add eax,2		;correct pointer

ret
GetNameFromPath endp

;allocates specified size of memory and return pointer to it
MemAlloc proc nSize :DWORD
	
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,nSize
	test eax,eax
	 jnz @F
	invoke GetFromMem,unp.nFileCount
	mov eax,[ eax.FILEINFO.pszName ]
	push eax
	invoke HeapReAlloc,hHeap,HEAP_ZERO_MEMORY or HEAP_REALLOC_IN_PLACE_ONLY	,eax,100h
	pop eax
	invoke lstrlen,[ eax.FILEINFO.pszName ]
	add eax,[ eax.FILEINFO.pszName ]	
@@:
ret
MemAlloc endp

;free memory allocated by MemAlloc
MemFree proc hMemory :DWORD

    invoke HeapFree,hHeap,NULL,hMemory
@@:	
ret
MemFree endp

;manage toolbar clicks
ToolBarClick proc nmMouse :DWORD
	
	mov eax,nmMouse
	mov eax,[ eax ].NMMOUSE.dwItemSpec
	
	cmp eax,IDT_JOIN
	 jz join
	cmp eax,IDT_ADDFILE
	 jz add_file
	cmp eax,IDT_ADDFOLDER
	 jz add_folder
	cmp eax,IDT_REMFILE
	 jz remFile
	cmp eax,IDT_CLRFILE
	 jz clrFile
	cmp eax,IDT_JOINSETT
	 jz join_sett
	cmp eax,IDT_SETTINGS
	 jz settings
	cmp eax,IDT_ABOUT
	 jz about
	 
	 ret
join:
        invoke CreateThread,NULL,1000h,addr JoinFiles,NULL,NULL,NULL
       	ret
	
add_file:
	invoke AddFile
	ret
add_folder:
	invoke AddFolder
	ret
remFile:
	invoke RemFile
	ret

clrFile:
	invoke ClrFileList
	ret
join_sett:
	invoke DialogBoxParam,hInstance,IDD_JOINSETT,hMain,addr JoinSettDlgProc,NULL
	ret
	
settings:
	invoke DialogBoxParam,hInstance,IDD_SETTDLG,hMain,addr SettDlgProc,NULL
	ret
	
about:
	invoke MessageBox,hMain,offset szAbout,offset szCap,MB_ICONINFORMATION
	ret

ToolBarClick endp

;retrieves specified file size,return 0 if fault
GetFileSize_my proc pszFile :DWORD
LOCAL hFile :DWORD	

	xor eax,eax
	invoke CreateFile,pszFile,GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,eax,OPEN_EXISTING,eax,eax
	inc eax
	 jnz @F
	invoke GetNameFromPath,pszFile 
	invoke FormatError,offset szFileError,eax
	ret

@@:	
	dec eax
	mov hFile,eax
	invoke GetFileSize,eax,NULL
	push eax
	invoke CloseHandle,hFile
	pop eax
	
ret
GetFileSize_my endp

;set checkboxes depend on items flags
LoadChecks proc uses ebx

	invoke SendMessage,hFileList,LVM_GETSELECTEDCOUNT,0,0
	dec eax 
	 jz @F
	invoke ClearCheckButtons
	invoke EnableDlgChecks,FALSE
	ret
@@:
	invoke GetSelectedItem
	inc eax
	 jnz @F
	pop eax
	invoke EnableDlgChecks,FALSE
	invoke ClearCheckButtons
	ret
@@:
	;int 3
	lea ebx,[ eax -1 ] ;get selected item num
	
	invoke EnableDlgChecks,TRUE
	invoke ClearCheckButtons
	invoke GetSelectedOption

	cmp eax,IDC_EXTRACT
	 jnz @F
	invoke SetExractChecks,ebx
	ret
@@:
	cmp eax,IDC_FILEATTR
	 jnz @F
	invoke SetFileAttrChecks,ebx
	ret
@@:
	invoke SetMiscCheks,ebx	
ret
LoadChecks endp

;set checkboxes for 'extract options'
SetExractChecks proc uses ebx ecx edi nItem:DWORD

	invoke GetFromMem,nItem
	mov ebx,[ eax ]
	
	invoke SetDlgItemText,hMain,IDC_CUSTDIR,[eax.FILEINFO.pszCustDir]
	
	invoke EnableDlgChecks,TRUE
	mov ecx,IDC_1 - 1
		
	mov edi,CheckDlgButton
@@:
	cmp ecx,IDC_5 ;end of checkboxes
	 jz @F		  
	inc ecx		;next checkbox
	shl ebx,1	;now bit in cf flag
	 jnc @B		;is flag set 

	push ecx
	;int 3
	push BST_CHECKED ;check checkbox
	push ecx
	push hMain
	call edi ;CheckDlgButton
	
	pop ecx	
	 jmp @B
@@:
ret
SetExractChecks endp

;set checkboxes for 'file attributes option'
SetFileAttrChecks proc uses ecx ebx edi nItem:DWORD
	
	invoke GetFromMem,nItem
	mov ebx,[eax]
	
	test ebx,JT_SFA
	 jz @F
	invoke ClearCheckButtons
	invoke CheckDlgButton,hMain,IDC_1,BST_CHECKED
	invoke EnableDlgChecks,FALSE
	invoke GetDlgItem,hMain,IDC_1
	invoke EnableWindow,eax,TRUE
	ret
@@:
	shl ebx,5
	invoke EnableDlgChecks,TRUE
	
	mov ecx,IDC_1 - 1
	mov edi,CheckDlgButton
@@:
	cmp ecx,IDC_5 ;end of checkboxes
	 jz @F		  
	inc ecx		;next checkbox
	shl ebx,1	;now bit in cf flag
	 jnc @B		;is flag set 

	push ecx
	
	push BST_CHECKED
	push ecx
	push hMain
	call edi ;CheckDlgButton
	
	pop ecx
	 jmp @B
@@:
ret
SetFileAttrChecks endp

;set checkboxes for 'misc options'
SetMiscCheks proc uses ebx nItem :DWORD
	
	invoke ClearCheckButtons
	
	invoke GetFromMem,nItem
	mov ebx,[ eax.FILEINFO.uFlags ]
	
	test ebx,JT_ONLUNPACK
	 jz @f 
	invoke GetDlgItem,hMain,IDC_3
	invoke EnableWindow,eax,FALSE
	invoke GetDlgItem,hMain,IDC_4
	invoke EnableWindow,eax,FALSE
	invoke CheckDlgButton,hMain,IDC_1,BST_CHECKED
	 jmp @1
@@:
	test ebx,JT_WUT
	 jz @f

	invoke CheckDlgButton,hMain,IDC_4,BST_CHECKED
@@:
	test ebx,JT_DAE
	 jz @1
	invoke CheckDlgButton,hMain,IDC_3,BST_CHECKED
@1:
	test ebx,JT_RDL
	 jz @F
	invoke CheckDlgButton,hMain,IDC_5,BST_CHECKED
@@:
	test ebx,JT_WTA
	 jz @F
	invoke CheckDlgButton,hMain,IDC_2,BST_CHECKED
@@:
	ret
SetMiscCheks endp

;return 1 if folder else 0
IsFolder proc pszFileName :DWORD

	invoke GetFileAttributes,pszFileName
	test eax,10h
	 jz @F 
	xor eax,eax
	inc eax
	ret

@@:
	xor eax,eax
	ret
IsFolder endp

;set's visible items depend on selected optionButton
SetVisibleChecks proc uses ebx nGroup :DWORD
	
	mov eax,nGroup
	mov ebx,SetDlgItemText
	
	cmp eax,IDC_EXTRACT
	 jz @@1
	cmp eax,IDC_FILEATTR
	 jz @@2
	cmp eax,IDC_MISC
	 jz @@3
	
	ret
;not best but simple	
@@1:
	push offset szWinDir
	push IDC_1
	push hMain
	call ebx
	
	push offset szSysDir
	push IDC_2
	push hMain
	call ebx
	
	push offset szTempDir
	push IDC_3
	push hMain
	call ebx
	
	push offset szRunDir
	push IDC_4
	push hMain
	call ebx
	
	invoke GetDlgItem,hMain,IDC_CUSTDIR
	invoke ShowWindow,eax,SW_SHOW
	invoke GetDlgItem,hMain,IDC_5
	invoke ShowWindow,eax,SW_HIDE
	 jmp @F

@@2:
	push offset szSFA
	push IDC_1
	push hMain
	call ebx
	
	push offset szSysFile
	push IDC_2
	push hMain
	call ebx
	
	push offset szHiddenFile
	push IDC_3
	push hMain
	call ebx

	push offset szArcFile
	push IDC_4
	push hMain
	call ebx
	
	push offset szReadOnly
	push IDC_5
	push hMain
	call ebx
	
	invoke GetDlgItem,hMain,IDC_CUSTDIR
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hMain,IDC_5
	invoke ShowWindow,eax,SW_SHOW
	 jmp @F

@@3:
	push offset szOnlUnp
	push IDC_1
	push hMain
	call ebx
	
	push offset szWTA
	push IDC_2
	push hMain
	call ebx
	
	push offset szDAE
	push IDC_3
	push hMain
	call ebx

	push offset szWUT
	push IDC_4
	push hMain
	call ebx

	push offset szRegDLL
	push IDC_5
	push hMain
	call ebx
	
	invoke GetDlgItem,hMain,IDC_CUSTDIR
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hMain,IDC_5
	invoke ShowWindow,eax,SW_SHOW 
@@:	
	invoke LoadChecks
ret
SetVisibleChecks endp

;disable or enable dlg items depend on have user select item or not( TRUE - enable,FALSE - disable )
EnableDlgChecks proc uses eax edi ecx ebx bEnable :DWORD

	mov eax,IDC_1
	mov ebx,EnableWindow
	mov edi,GetDlgItem
@@:
	push eax
	
	push eax
	push hMain
	call edi ;GetDlgItem
	
	push bEnable
	push eax
	call ebx ;EnableWindow
	
	pop eax
	inc eax
	cmp eax,IDC_CUSTDIR + 1
	 jnz @B
	
	dec bEnable
	 jz @F
	invoke GetDlgItem,hMain,IDC_CUSTDIR
	invoke SetWindowText,eax,NULL
@@:
ret
EnableDlgChecks endp

;retrieve selected optionButton ID
GetSelectedOption proc uses ecx 
LOCAL nStartItem :DWORD	
	
	mov nStartItem,IDC_EXTRACT - 1
@@:
	inc nStartItem
	invoke IsDlgButtonChecked,hMain,nStartItem
	test eax,eax
	 jz @B
	
	mov eax,nStartItem
	
ret
GetSelectedOption endp

;retrieves specified item info from memory
GetFromMem proc uses ecx nItemIndex :DWORD
	
	mov eax,nItemIndex
	mov ecx,pMem
@@:
	sub eax,MAX_FILE
	 js @F
	mov ecx,[ ecx + DF_LIMIT ].MEM.pNextMem
	 jmp @B

@@:
	add eax,MAX_FILE
	shl eax,4
	add eax,ecx	
ret
GetFromMem endp

;initialize memory for items info's
InitMemory proc
	invoke VirtualAlloc,NULL,DF_MEMSIZE,MEM_COMMIT or MEM_RESERVE or MEM_TOP_DOWN,PAGE_READWRITE
	test eax,eax
	 jnz @F
	invoke MessageBox,hMain,offset szMemError,offset szError,MB_ICONERROR
	xor eax,eax
	ret
@@:	
	mov pCurrent,eax
ret
InitMemory  endp

;free's all memory allocated while running
Destructor proc uses ebx

	mov eax,pMem
@@:
	mov ebx,[ eax + DF_LIMIT ].MEM.pNextMem
	invoke VirtualFree,eax,0,MEM_RELEASE
	test ebx,ebx
	 jz @F
	mov eax,ebx
	 jmp @B
@@:	
	invoke ImageList_Destroy,hImgLst
ret
Destructor endp

;clears check buttons i.e all buttons will be unchecked
ClearCheckButtons proc uses ebx edi
	
	mov edi,IDC_1
	mov ebx,CheckDlgButton 
@@: 
	push BST_UNCHECKED
	push edi
	push hMain
	call ebx
	
	inc edi
	cmp edi,IDC_5 + 1 
	 jnz @B
	
ret
ClearCheckButtons endp

;move path name to the files strings
FixSlash proc uses ecx pszString :DWORD
	
	mov eax,pszString
	
	mov dl,byte ptr[ eax ]
	mov bl,[ eax + 1 ]
@@:	
	mov [ eax + 1 ],dl
	
	test bl,bl
	 jz @F
	
	inc eax
	mov dl,bl
	mov bl,[ eax + 1 ]
	 jmp @B
@@:
ret
FixSlash endp

;set item's flags
SetFlags proc uses ecx ebx nCheckID :DWORD
	;rewrite its horrible
    invoke GetSelectedOption ;get selected option
	mov ecx,eax
	
	mov eax,JT_SFA ;by default
	
	cmp ecx,IDC_FILEATTR
	 jz @@1
	cmp ecx,IDC_EXTRACT
	 jnz @@2
	mov eax,JT_WINDIR
	jmp @@1
@@2:	
	mov eax,JT_ONLUNPACK
@@1:
	mov ecx,nCheckID
	sub ecx,IDC_1   ;get checkbox number( example: 1005 -> 5 )
	shr eax,cl     ;bit_pos( x ) = CHECK_ID >> x;
	
	push eax ;save bit pos.
	
	invoke GetSelectedItem
	invoke GetFromMem,eax
	mov ebx,eax        ;save pointer to item flags
	
	invoke IsDlgButtonChecked,hMain,nCheckID ;check or uncheck bit?
	pop ecx
	test eax,eax
	 jz @F ;uncheck
	or [ ebx ],ecx
	 jmp @@3
@@:        
    xor [ ebx ],ecx
@@3:
	invoke GetSelectedOption ;its horrible,but simple :),maked only for disabling other checks when sfa is selected
	push eax
	invoke GetSelectedItem
	pop ecx
	invoke LoadChecks
ret
SetFlags endp

;join differnet files onto one .exe file
JoinFiles proc
ret
JoinFiles endp

;show message box with formatted error message 
FormatError proc uses ebx pszStr1 :DWORD,pszStr2 :DWORD
	
	invoke lstrlen,pszStr1
	mov ebx,eax
	
	cmp pszStr2,NULL
	 jz @F
	invoke lstrlen,pszStr2
	add ebx,eax
@@:
	invoke MemAlloc,ebx
	mov ebx,eax
	invoke wsprintf,eax,pszStr1,pszStr2
	invoke MessageBox,hMain,ebx,offset szError,MB_ICONERROR
	invoke MemFree,ebx
	
ret
FormatError endp

;set new window proc. for filelist item edit control
EditItemText proc
LOCAL lvi :LVITEM
	
	invoke MemAlloc,MAX_PATH
	mov lvi.iIndent,eax
	
	invoke GetSelectedItem
	invoke SendMessage,hFileList,LVM_EDITLABEL,eax,0
	invoke SetWindowLong,eax,GWL_WNDPROC,addr LabelEditProc
	mov pLabelProc,eax
	
ret
EditItemText endp

;subclassed filelist item( rename ) edit window proc.
LabelEditProc proc hwnd :DWORD,msg :DWORD,wParam :DWORD,lParam :DWORD
LOCAL lvi :LVITEM
	
	cmp msg,WM_KEYDOWN
	 jnz @F
	cmp wParam,VK_RETURN
	 jnz @F
	invoke MemAlloc,MAX_PATH
	mov lvi.iIndent,eax
	
	invoke GetWindowText,hwnd,eax,MAX_PATH
	invoke GetSelectedItem
	push eax
	mov ecx,eax
	
	mov lvi.iSubItem,0
	movm lvi.pszText,lvi.iIndent
	invoke SendMessage,hFileList,LVM_SETITEMTEXT,ecx,addr lvi
	
	invoke MemFree,lvi.iIndent
	
	pop eax
	invoke GetFromMem,eax
	mov ecx,JTH_NAMECHANGED
	or [ eax ],ecx
@@:
	invoke CallWindowProc,pLabelProc,hwnd,msg,wParam,lParam
ret
LabelEditProc endp

;subclassed edit control proc in options part
CustDirProc proc uses ebx ecx hwnd :DWORD,msg :DWORD,wParam :DWORD,lParam :DWORD
	;TODO :done this func! ;maybe its done...

	cmp msg ,WM_LBUTTONDOWN
	 jz @@1
	cmp msg,WM_KEYDOWN
	 jz @@@
	cmp wParam,VK_RETURN
	 jnz @@@
	;int 3
@@1:
	invoke MemAlloc,MAX_PATH
	mov ebx,eax

	;int 3
	invoke GetWindowText,hwnd,ebx,MAX_PATH
	invoke lstrcmp,ebx,offset szCustDir
	test eax,eax
	 jnz @F
	invoke SetWindowText,hwnd,NULL
	jmp @@@
@@:
	invoke GetSelectedItem
	invoke GetFromMem,eax
	push eax
	
	mov eax, [eax.FILEINFO.pszCustDir]
	cmp eax,offset szCustDir
	 jz @F
	invoke MemFree,[ eax.FILEINFO.pszCustDir ]
@@:
	pop eax
	mov [ eax.FILEINFO.pszCustDir ],ebx
	or [ eax.FILEINFO.uFlags ],JT_CUSTDIR
@@@:
	invoke CallWindowProc,pCustProc,hwnd,msg,wParam,lParam
ret
CustDirProc endp

;returns currently selected in the fileList item index
GetSelectedItem proc
	invoke SendMessage,hFileList,LVM_GETNEXTITEM,-1,LVNI_SELECTED
ret
GetSelectedItem endp

;convert float value to ascii string
FloatToAscii proc nFloat :DWORD
        
        
ret
FloatToAscii endp

StartDrop proc hDrop :DWORD
	invoke CreateThread,NULL,2048,DropFiles,hDrop,NULL,NULL	
ret

StartDrop endp

DropFiles proc hDrop :DWORD
	
	invoke DisableGui,TRUE
	invoke AddDropedFiles,hDrop
	invoke DisableGui,FALSE
	xor eax,eax	
ret
DropFiles endp

DisableGui proc bDisable : DWORD
	mov eax, bDisable
	not eax
	sub eax,0FFFFFFFEh
	
	invoke EnableWindow,hFileList,eax
	invoke EnableWindow,hToolB,eax
	invoke EnableDlgChecks,eax
	
	test eax, eax
	 jnz load_checks
	invoke ClearCheckButtons
	 jmp @F
load_checks:
	invoke LoadChecks
@@:
	ret
DisableGui endp

end start
