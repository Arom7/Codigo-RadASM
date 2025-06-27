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
    szErrorArchivo  db "No se pudo abrir el archivo", 0
	szTituloError   db "Error", 0
	szNoEncontrado db "Producto no encontrado", 0
	szAviso        db "Aviso", 0
	szTextoIngresado db "Texto que ingresaste", 0
	szLineaLeida db "Línea leída", 0
	szBuscando   db "Buscando", 
	totalPagar     dd 0
	bufferPrecio   db 16 dup(0)
	bufferTotal    db 32 dup(0)
	

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
		 invoke CreateFileA, addr archivoNombre, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov hArchivo, eax
        .if hArchivo != INVALID_HANDLE_VALUE
            .while TRUE
                invoke RtlZeroMemory, addr bufferLectura, sizeof bufferLectura
                invoke ReadFile, hArchivo, addr bufferLectura, sizeof bufferLectura, addr nBytesEscritos, NULL
                .break .if eax == 0 || nBytesEscritos == 0

                mov esi, offset bufferLectura

				repetir_linea:
				    mov edi, esi
				
				buscar_fin:
				    cmp byte ptr [edi], 13
				    je fin_linea
				    cmp byte ptr [edi], 0
				    je fin_todo
				    inc edi
				    jmp buscar_fin
				
				fin_linea:
				    mov byte ptr [edi], 0
				    invoke SendDlgItemMessage, hWin, IDC_LISTA, LB_ADDSTRING, 0, esi
				    add edi, 2
				    mov esi, edi
				    jmp repetir_linea
				
				fin_todo:
				    .endw
				    invoke CloseHandle, hArchivo
        .endif
	.elseif eax==WM_COMMAND
		mov eax, wParam
		and eax, 0FFFFh
		.if ax == IDC_REGISTRAR 
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
			
			
			.elseif ax == IDC_BUSCAR

    			; Leer el nombre que el usuario quiere buscar
    			invoke GetDlgItemText, hWin, IDC_BUSCAR_NOMBRE, addr varNombre, sizeof varNombre

    			; Abrir archivo
    			invoke CreateFileA, addr archivoNombre, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    			mov hArchivo, eax
    			.if hArchivo != INVALID_HANDLE_VALUE
        			.while TRUE
            			; Leer línea por línea
            			invoke RtlZeroMemory, addr bufferLectura, sizeof bufferLectura
            			invoke ReadFile, hArchivo, addr bufferLectura, sizeof bufferLectura, addr nBytesEscritos, NULL
            			.break .if eax == 0 || nBytesEscritos == 0

            			mov esi, offset bufferLectura

        			buscar_linea:
            			mov edi, esi

        			buscar_fin_linea:
            			cmp byte ptr [edi], 13
            			je cortar_linea
            			cmp byte ptr [edi], 0
            			je fin_todo_buscar
            			inc edi
            			jmp buscar_fin_linea

        			cortar_linea:
            			mov byte ptr [edi], 0 ; termina línea
            			; Extraer nombre antes del " - "
            			mov ebx, esi
        			buscar_guion:
            			cmp byte ptr [ebx], '-'
            			je cortar_nombre
            			cmp byte ptr [ebx], 0
            			je continuar
            			inc ebx
            			jmp buscar_guion

        			cortar_nombre:
            			mov byte ptr [ebx - 1], 0 ; termina nombre antes del guion

            			; Comparar nombre extraído con varNombre
            			invoke lstrcmpiA, esi, addr varNombre
            			.if eax == 0
                			; Coincidencia, mostrar línea completa
                			; (ponemos el guion de nuevo para ver la línea completa)
                			mov byte ptr [ebx - 1], ' '
                			invoke MessageBox, hWin, esi, addr szTest, MB_OK
                			jmp cerrar_archivo_buscar
            			.endif

        			continuar:
            			add edi, 2
            			mov esi, edi
            			jmp buscar_linea

        			fin_todo_buscar:
        			.endw

        			; No se encontró
        			invoke MessageBox, hWin, addr szNoEncontrado, addr szAviso, MB_OK

        			cerrar_archivo_buscar:
        			invoke CloseHandle, hArchivo
    			.else
        			invoke MessageBox, hWin, addr szErrorArchivo, addr szTituloError, MB_OK
    			.endif
		
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