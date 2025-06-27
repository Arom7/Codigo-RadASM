
include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include shell32.inc

includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib shell32.lib

; Librerias nuevas incluidas por si hay error
include masm32.inc
include masm32.lib

DlgProc			PROTO	:HWND,:UINT,:WPARAM,:LPARAM

.const

IDD_DIALOG1			equ 101

IDC_NOMBRE			equ 1003; ID del EditText para el nombre del producto
IDC_PRECIO			equ 1005; ID del EditText del precio del producto
IDC_STOCK			equ 1006; ID del EditText del stock o la cantidad del producto
IDC_DESCRIPCION		equ 1009; ID del EditText de la descripcion del producto
IDC_BOTON_REGISTRAR equ 1010; ID del boton para el registro
IDC_LISTA			equ 1011; ID de la ListBox para mostrar los productos

;#########################################################################

.data?

hInstance			dd ?

;#########################################################################
