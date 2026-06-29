; Hello World Assembly Test Program (v1.0, January 27 2020)
; Written by Ian Seyler
;
; BareMetal compile:
; nasm hello.asm -o hello.app
;
; This simple test program outputs the string in hello_message
; 1) Load the string address into the `RSI` register. The `LEA` instruction is used here. `MOV` could also be used via `mov rsi, hello_message`
; 2) Load the number of characters to output into the `RCX` register. `ECX` is used since a `MOV` to it will clear the high 32-bits
; 3) Call the kernel function to output characters. It depends on the string address in `RSI` and the number of characters to output in `RCX`
; 4) Return to the OS/CLI

[BITS 64]
DEFAULT ABS

%INCLUDE "libBareMetal.asm"

start:					; Start of program label
	lea rsi, [rel menu] ; Load RSI with the relative memory address of string, lea ocupa menos y da menos errores que mov
	mov ecx, menu.len ;variable constante numero de caracteres, Output 
	call [b_output]			; Print the string that RSI points to

    xor bl, bl ; inicializamos bl para borrar la opcion anterior

; NO muestra otro caracter en pantalla que no sean los indicados
sondeo_polling_teclado:
    call [b_input]

    ;********* early exit / guard clause ********
    test al, al ; si no ha habido entrada de teclado al=0. Mejor que cmp al, 0. Ahorra ciclos de reloj
    jz sondeo_polling_teclado 

    cmp al, 0x1C ; es Intro? NO scancode 0x0D (Ascii)
    je ejecuta_opcion

    cmp al, 0x0E			; Backspace / retroceso
	je ui_input_backspace
    ;***** fin early exit / guard clause ******

    ;***** confirmacion visual caracter ****** 
    mov [rel caracter_introducido], al
    lea rsi, [rel caracter_introducido]
    mov ecx, 1 ; 1 SOLO caracter
    call [b_output]
    ;*** fin confirmacion visual caracter ****

    ;or al, 00100000b		; convierte a minuscula, SOLO para q

    cmp al, "1"
    je guarda_opcion ;NO mov bl, al. Hay que volver (jmp) a sondeo_polling_teclado
    
    cmp al, "2"
    je guarda_opcion

    ;***** mayus / minus ******
    cmp al, "Q"
    je guarda_opcion
    cmp al, "q"
    je guarda_opcion
    ;*** fin mayus / minus ****

    

    jmp sondeo_polling_teclado ;NO start

;************** borra caracter **************
ui_input_backspace:
    test bl, bl               ; ¿Había alguna opción seleccionada en BL?
    jz sondeo_polling_teclado ; Si BL ya es 0 (está al principio), no hace nada

    xor bl, bl                ; Reseteamos BL a 0 (borramos la opción elegida)

    ; --- BORRADO VISUAL EXACTO (Copiado de BareMetal) ---
    mov al, 0x03              ; Código para mover el cursor un espacio hacia atrás
    call output_char

    mov al, ' '               ; Código para pintar un espacio en blanco encima de la letra
    call output_char

    mov al, 0x03              ; Código para volver a mover el cursor hacia atrás
    call output_char

    jmp sondeo_polling_teclado ; Volvemos a esperar que el usuario pulse otra tecla

; -----------------------------------------------------------------------------
; output_char -- Displays a char
;  IN:	AL  = char to display
; OUT:	All registers preserved
output_char:
	push rsi
	push rcx

	mov [tchar], al
	mov rsi, tchar
	mov ecx, 1
	call [b_output]

	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------
;*************** fin borra caracter ***************

guarda_opcion: ;caracter
    mov bl, al ; al -> bl

    jmp sondeo_polling_teclado ;NO start

ejecuta_opcion: ; caracter guardado
    cmp bl, "1" ;cmp [rel caracter_introducido], "1" es mas caro
    je opcion
    
    cmp bl, "2"
    je opcion1

    ;***** sal *****
    cmp bl, "Q"
    je sal ; NO ret
    cmp bl, "q"
    je sal ; NO ret
    ;*** fin sal ****

    ;*** mensaje error *** 
    lea rsi, [rel error]
    mov ecx, error.len
    call [b_output]
    ;** fin mensaje error **

    jmp start ;NO sondeo_polling_teclado

;********** Opciones *********
opcion:
    lea rsi, [rel msg] 
    mov ecx, msg.len
    call [b_output]
    
    jmp start ;NO sondeo_polling_teclado

opcion1:
    lea rsi, [rel msg1] 
    mov ecx, msg1.len
    call [b_output]

    jmp start ;NO sondeo_polling_teclado

sal:
    ret				; Return to OS

menu: db "Menu", 10, "----", 10, "1. Opcion 1", 10, "2. Opcion 2", 10, "q. Salir", 10, "> ", 0 ; 10 es salto de linea, 0 es caracter nulo (fin)
.len: equ $ -menu -1 ; t compilacion, Resta la posición actual menos el inicio del mensaje

msg:  db 10, "Opcion 1", 10, 0
.len: equ $ -msg  -1 ; quitamos caracter nulo espacio inicial siguiente linea

msg1: db 10, "Opcion 2", 10, 0
.len: equ $ -msg1 -1 

caracter_introducido: db 0

tchar: db 0                   ; Variable necesaria para que output_char funcione

error: db 10, "E: opcion no disponible", 10, 0 
.len: equ $ -error -1 
