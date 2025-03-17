;
; Antirebote.asm
;
; Created: 29/1/2025 5:25:07 PM
; Author : Edvin Paiz
;
// Encabezado
.include "M328PDEF.inc"

.cseg
.org	0x0000

// Configurar la pila
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH(RAMEND)
OUT SPH, R16

// Configurar el MCU
SETUP:
	// Configurar pines de entrada y salida (DDRx, PORTx, PINx)
	// PORTD como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRD, R16	// Setear puerto D como entrada
	LDI		R16, 0xFF
	OUT		PORTD, R16	// Habilitar pull-ups en puerto D

	// PORTB como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRB, R16	// Setear puerto B como salida
	LDI		R16, 0x01
	OUT		PORTB, R16	// Encender primer bit de puerto B

	LDI		R17, 0xFF	// Variable para guardar estado de botones
// Loop infinito
MAIN:
	IN		R16, PIND	//Guardando el estado de PORTD en R16
	SBRC	R16, 2
	RJMP	MAIN
	CP		R17, R16	// 0xFF 0xFB
	BREQ	MAIN
	MOV		R17, R16	// 0xFB -> R17
	SBI		PINB, 0
	RJMP	MAIN

// Sub-rutina (no de interrupción)

// Rutinas de interrupción