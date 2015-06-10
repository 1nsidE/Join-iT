 ;start
.486
.model flat,stdcall
option casemap : none

include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include comdlg32.inc
include shell32.inc
include gdi32.inc

;lib's
includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib shell32.lib
includelib gdi32.lib

;proto's
DlgProc			PROTO :DWORD,:DWORD,:DWORD,:DWORD
IconDlg 		PROTO :DWORD,:DWORD,:DWORD,:DWORD
FileOpen		PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
AddToMem		PROTO :DWORD,:DWORD
EnableDlgChecks		PROTO :DWORD
GetNameFromPath		PROTO :DWORD
LoadChecks			PROTO 
EditItemText		PROTO
GetSelectedItem		PROTO
CustDirProc			PROTO :DWORD,:DWORD,:DWORD,:DWORD
SetCheckButtons		PROTO :DWORD,:DWORD
IsFolder			PROTO :DWORD
ClearCheckButtons	PROTO
SetUnpackFlags 		PROTO :DWORD
LoadUnpackFlags		PROTO :DWORD
SetIcon				PROTO :DWORD,:DWORD
JoinFiles			PROTO
FloatToAscii        PROTO :DWORD
ShowToolTip 		PROTO :DWORD
MemAlloc			PROTO :DWORD
MemFree				PROTO :DWORD
AddToList			PROTO :DWORD
AddDropedFiles		PROTO :DWORD
StartDrop			PROTO :DWORD
DropFiles			PROTO :DWORD
ToolBarClick		PROTO :DWORD
GetFileSize_my		PROTO :DWORD
SetVisibleChecks	PROTO :DWORD
SetExractChecks		PROTO :DWORD
SetFileAttrChecks	PROTO :DWORD
SetMiscCheks		PROTO :DWORD
SetFlags			PROTO :DWORD
GetSelectedOption	PROTO
GetFromMem			PROTO :DWORD
UpdateStBar			PROTO
InitMemory			PROTO
Destructor			PROTO
FixSlash			PROTO :DWORD
IconButClick		PROTO
InitDlg				PROTO
InitList			PROTO
InitTlb				PROTO
AddFile				PROTO
LabelEditProc		PROTO :DWORD,:DWORD,:DWORD,:DWORD
AddFolder			PROTO
RemFile				PROTO
ClrFileList    		PROTO
PopUp 				PROTO 
FormatError			PROTO :DWORD,:DWORD
AddFiles			PROTO :DWORD
DisableGui			PROTO :DWORD


;--------------------------------------------------------------------------------
;names for handling resources

IDD_MAINDLG		equ 100
 IDC_FILELIST 	equ 1001
 IDC_PROPLIST 	equ 1002
 IDC_OUTLST 	equ 1003
 IDC_PRBAR		equ 1004
 IDC_STBAR		equ 1005
 IDC_EXTRACT	equ 1006
 IDC_FILEATTR	equ 1007
 IDC_MISC		equ 1008 
 
 IDC_1			equ 1009
 IDC_2			equ 1010
 IDC_3			equ 1011
 IDC_4			equ 1012
 IDC_5			equ 1013
 IDC_CUSTDIR	equ 1014
 
IDD_SETTDLG		equ 103
 IDC_GUIUNP		equ 3001
 IDC_UFN		equ 3002
 IDC_CRC		equ 3003
 IDC_CRYPT		equ 3004
 IDC_PACK		equ 3005
 IDC_SELFREM	equ 3006
 IDC_SAVE		equ 3007
 IDC_CANCEL		equ 3008

IDD_JOINSETT	equ 101
 IDC_TRAY		equ 2011
 IDC_SHELL		equ 2012
 IDC_LOG		equ 2016
 IDC_LOGBUT		equ 2017
 IDC_JCANCEL	equ 2009
 IDC_JSAVE		equ 2005
 IDC_ICONPIC	equ 3010
 IDC_ICONBUT	equ 3011	
 
IDR_POPUP       equ 300
 IDM_ADDFILE	equ 3002
 IDM_ADDFOLDER	equ 3006
 IDM_ADDPATH	equ 3004
 IDM_REMFILE	equ 3003
 IDM_CLRFILE	equ 3005
 IDM_RENAME		equ 3008

IDC_TOOLB		equ 400
 IDT_JOIN       equ 4001
 IDT_ADDFILE	equ 4002
 IDT_ADDFOLDER	equ 4003
 IDT_REMFILE	equ 4004
 IDT_CLRFILE 	equ 4005
 IDT_JOINSETT	equ 4006
 IDT_SETTINGS	equ 4007
 IDT_ABOUT		equ 4008

IDD_ICONDLG		equ 102

IDC_ICONLIST	equ 5001
IDC_LOGO		equ 5004
IDB_LOGO		equ 602

ID_TOOLB		equ 600
ID_LOADER		equ 111
DATA            equ 987
LOADER_SIZE     equ 1536

DF_FLAGS 	equ JT_WINDIR or JT_SFA or JT_ONLUNPACK
DF_MEMSIZE	equ 10000h
MAX_FILE	equ ( DF_MEMSIZE - 10h ) / ( sizeof FILEINFO )
DF_LIMIT	equ DF_MEMSIZE - 10h

;--------------------------------------------------------------------------------
;item's flags

JT_WINDIR	equ 80000000h
JT_SYSDIR	equ 40000000h
JT_TEMPDIR	equ 20000000h
JT_EXECDIR	equ 10000000h
JT_CUSTDIR	equ 08000000h

JT_SFA			equ 04000000h
JT_SYSFILE		equ 02000000h
JT_HIDDENFILE	equ 01000000h
JT_ARCFILE		equ 00800000h
JT_RONLYFILE	equ 00400000h

JT_ONLUNPACK	equ 00200000h
JT_WTA			equ 00100000h
JT_DAE			equ 00080000h
JT_WUT			equ 00040000h
JT_RDL			equ 00020000h

JTH_FOLDER	equ 00010000h
JTH_ZEROLEN	equ 00008000h
JTH_NAMECHANGED	equ 00004000h
JTH_REMOVED		equ 00002000h 

JTS_GUIUNP	equ JT_WINDIR
JTS_UFN		equ JT_SYSDIR
JTS_CRC		equ JT_TEMPDIR
JTS_CRYPT	equ JT_EXECDIR
JTS_PACK	equ JT_CUSTDIR
JTS_SELFREM	equ JT_SFA	


movm macro m1,m2
	push m2
	pop m1
endm

;struct that save info about files,... needed for loader
FILEINFO struct 
        uFlags		dd ? ;flags like extract path,file attributes,etc...
        uFileSize	dd ? ;file size in bytes
        pszName		dd ? ;pointer to the item path
        pszCustDir	dd ? ;pointer to the custom directory
FILEINFO ends

UNPACKINFO struct
        nFileCount	dd ? ;all files count
        nAllSize	dd ? ;all files size
        uFlags		dd ? ;flags like pack,CRC check,...
UNPACKINFO ends

MEM struct
	nCount    dd ? ;files count in current mem. region 
	pNextMem  dd ? ;next mem region
	pPrevMem  dd ? ;prev. mem region
MEM ends

;global var's,strings...
.data
szFileFilter	db 'All Files( *.* )',0,'*.*',0,0
szIconFilter	db '*.ico,*.exe,*.dll',0,'*.ico;*.exe;*.dll',0,0
szNameCol		db 'Name',0
szSizeCol		db 'Size',0

szJoinBut 		db 'Join Files',0
szAddBut		db 'Add Files',0
szAddFolderBut	db 'Add Folder',0
szDelBut		db 'Remove files',0
szClrBut		db 'Clear',0
szJoinSett		db 'Join-iT Settings',0
szSettBut		db 'Settings',0
szAbtBut		db 'About',0
szFlags			db '%lu Kb',0

szFileError		db 'Cannot open %s',0
szMemError		db 'Error while allocating memory',0
szNoIconError	db 'No icons in the %s',0
szNoFileError   db 'Add some files first !!!',0
szError			db 'Error',0
szStCount		db 'Items count: %lu',0
szStFileSize	db 'Overall size: %lu Mb',0
szBrowseDir		db 'Please Select Folder',0
szC				db 'C:\',0
szFind			db '\*',0
szReBarClass	db 'ReBarWindow32',0
szToolbarClass	db 'ToolbarWindow32',0
szFolder		db 'Folder',0

szWinDir	db 'Windows Directory',0
szSysDir	db 'System Directory',0
szTempDir	db 'Temp Directory',0
szRunDir	db 'Execute directory',0
szCustDir	db 'Custom Directory',0

szSFA			db 'Save File Attributes',0
szSysFile		db 'System File',0
szHiddenFile	db 'Hidden File',0
szArcFile		db 'Archive File',0
szReadOnly		db 'Read-Only File',0

szOnlUnp	db 'Only Unpack',0
szWTA		db 'Write To Autorun',0
szDAE		db 'Delete After Execution',0
szWUT		db 'Wait Until Terminated',0
szRegDLL	db 'Register DLL( OCX )',0   

szCap		db 'About Join-iT',0
szAbout		db 'Join-iT 0.01( pre-alpha )',0Dh,
		 '---------------------------------------',0Dh,
		 'Author: InsidE',0Dh,
		 'Release Date: ##.##.####',0Dh,
		 'Contact: insiiide@gmail.com',0

szJoined	db 'joined.exe',0
szControls  db 'comctl32.dll',0

;--------------------------------------------------------------------------------
unp		UNPACKINFO< 0,0,JTS_PACK or JTS_CRYPT or JTS_GUIUNP >

.data?
hInstance	dd ? ;no comment
hMain		dd ? ;main window handle
hFileList	dd ? ;fileList handle 
hPrBar      dd ? ;ProgressBar handle
hToolB		dd ? ;toolbar handle
hMenu		dd ? ;menu handle
hIcon		dd ? ;loader icon handle
hImgLst		dd ? ;toolbar imagelist
hToolT		dd ? ;toolbar tooltip handle 
hStBar		dd ? ;status bar handle
pMem		dd ? ;pointer to the first memory region that contain info about files  
pLastMem	dd ? ;pointer to the next position in the current region 
pCurrent	dd ? ;pointer to the current memory region
hHeap		dd ? ;handle of process heap
pLabelProc	dd ? ;pointer to the fileList item( rename ) edit control original func. 
pCustProc	dd ? ;pointer to the origial function of Custom Dir. edit control 

