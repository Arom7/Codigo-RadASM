.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Productos.inc
include masm32.inc
includelib masm32.lib 

.data
	varNombre db 50 dup(0)
	varPrecio db 20 dup(0)
	varStock  db 20 dup(0)
	varDescripcion db 100 dup(0)
	bufferLinea   db 100 dup(0)
    szFormato     db "%s - Bs.%s - Stock: %s", 0
    saltoLinea	  db 13,10

	; Datos para realizar testeo
	szTest db "!Click en Registrar",0
	
	; Datos para generar el archivo de texto
	archivoNombre db "productos.txt",0
	nBytesEscritos dd ?
	
	; Datos para la lectura del .txt
	bufferLectura db 128 dup(0)
	hArchivo dd ?
.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov	eax,uMsg
	.if eax==WM_INITDIALOG
		invoke CreateFileA, addr archivoNombre, FILE_APPEND_DATA, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
		mov hArchivo, eax
		.if hArchivo != INVALID_HANDLE_VALUE
			.while TRUE
				invoke RtlZeroMemory, addr bufferLectura, sizeof bufferLectura
				invoke ReadFile, hArchivo, addr bufferLectura, sizeof bufferLectura, addr nBytesEscritos, NULL
				.break .if eax == 0 || nBytesEscritos == 0

				; Recorre el buffer hasta encontrar salto de línea
				mov esi, offset bufferLectura
				mov ecx, nBytesEscritos

				buscar_salto:
					cmp ecx, 0
					je fin_busqueda

					cmp byte ptr [esi], 13
					je encontrado

					inc esi
					dec ecx
					jmp buscar_salto
	
				encontrado:
					mov byte ptr [esi], 0  ; Terminar la línea
	
				fin_busqueda:
					invoke SendDlgItemMessage, hWin, IDC_LISTA, LB_ADDSTRING, 0, addr bufferLectura
			.endw
			invoke CloseHandle, hArchivo
		.endif
	.elseif eax==WM_COMMAND
		mov eax, wParam
		and eax, 0FFFFh
		.if ax == IDC_REGISTRAR 
			; La otra linea era para realizar un test al boton y su funcionamiento
			invoke MessageBox, NULL, addr szTest, addr szTest, MB_OK
			invoke GetDlgItemText, hWin, IDC_NOMBRE, addr varNombre, sizeof varNombre
			invoke GetDlgItemText, hWin, IDC_PRECIO, addr varPrecio, sizeof varPrecio
			invoke GetDlgItemText, hWin, IDC_STOCK, addr varStock, sizeof varStock
			invoke GetDlgItemText, hWin, IDC_DESCRIPCION, addr varDescripcion, sizeof varDescripcion
			
			invoke wsprintf, addr bufferLinea, addr szFormato, addr varNombre, addr varPrecio, addr varStock
			
			invoke SendDlgItemMessage, hWin, IDC_LISTA, LB_ADDSTRING, 0, addr bufferLinea
			
			; Codigo para el registro en un archivo txt
			invoke CreateFileA, addr archivoNombre, GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
			mov ebx, eax
			.if ebx != INVALID_HANDLE_VALUE
				invoke SetFilePointer, ebx, 0, 0, 2
				invoke lstrlen, addr bufferLinea
				mov ecx, eax
				invoke WriteFile, ebx, addr bufferLinea, ecx , addr nBytesEscritos, NULL
				invoke WriteFile, ebx, addr saltoLinea, 2, addr nBytesEscritos, NULL
				
				invoke CloseHandle,ebx
			.endif
			
			invoke MessageBox, hWin, addr bufferLinea, addr szTest, MB_OK
		
		.elseif ax == IDCANCEL
			invoke EndDialog, hWin, 0
		.endif	
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
