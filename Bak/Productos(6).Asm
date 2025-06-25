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
	szBuscando   db "Buscando", 0





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

    ; Abrir el archivo en modo lectura
    invoke CreateFileA, addr archivoNombre, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov hArchivo, eax
    .if hArchivo != INVALID_HANDLE_VALUE
        .while TRUE
            invoke RtlZeroMemory, addr bufferLectura, sizeof bufferLectura
            invoke ReadFile, hArchivo, addr bufferLectura, sizeof bufferLectura, addr nBytesEscritos, NULL
            .break .if eax == 0 || nBytesEscritos == 0

            mov esi, offset bufferLectura

        buscar_linea:
            mov edi, esi

        buscar_fin_linea:
            cmp byte ptr [edi], 13 ; fin de línea CR
            je fin_linea_buscar
            cmp byte ptr [edi], 0  ; fin de buffer
            je fin_todo_buscar
            inc edi
            jmp buscar_fin_linea

        fin_linea_buscar:
            mov byte ptr [edi], 0 ; cortar línea para tratar como cadena

            ; Buscar el guion '-' para separar el nombre
            mov esi, offset bufferLectura
            mov edi, esi

        buscar_guion:
            cmp byte ptr [edi], '-'
            je encontrado_guion
            cmp byte ptr [edi], 0
            je no_encontrado_guion
            inc edi
            jmp buscar_guion

        encontrado_guion:
            ; Cortar cadena en el espacio antes del guion
            ; Asumiendo que formato es "Nombre - Bs.7 - Stock: 10"
            ; Aquí retrocedemos 1 para eliminar espacio antes del guion
            mov byte ptr [edi - 1], 0

            ; Ahora la cadena bufferLectura termina justo después del nombre

            ; Comparar con varNombre

            invoke lstrlen, addr varNombre
            mov ecx, eax
            mov esi, offset bufferLectura
            mov edi, offset varNombre
            push ecx
            repe cmpsb
            pop ecx
            .if ZERO?
                ; coincidencia encontrada
                invoke MessageBox, hWin, offset bufferLectura, addr szTest, MB_OK
                jmp cerrar_archivo_buscar
            .endif

            jmp siguiente_linea

        no_encontrado_guion:
            ; No encontró guion, ignorar línea o comparar toda
            jmp siguiente_linea

        siguiente_linea:
            ; Saltar a siguiente línea dentro del buffer
            add edi, 2 ; saltar CR LF
            mov esi, edi
            jmp buscar_linea

        fin_todo_buscar:
        .endw

        cerrar_archivo_buscar:
        invoke CloseHandle, hArchivo
    .else
        invoke MessageBox, hWin, addr szErrorArchivo, addr szTituloError, MB_OK
    .endif






                cerrar_archivo:
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