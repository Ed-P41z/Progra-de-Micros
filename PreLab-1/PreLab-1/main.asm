/*
*	PreLab-1.asm
*
*	Creado: 2/2/2025 7:02:46 PM
*	Autor: Edvin Paiz
*	Descripción: El prelab 1 consiste en un sumador con antirebotes integrado
*/
.include "M328PDEF.inc"

.cseg
.org 0x0000

// Se configura la pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

// Se configura el MCU
SETUP:
	// Se configuran pines de entrada y salida (DDRx, PORTx, PINx)
	// Se configura PORTD como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRD, R16	// Se configura el puerto D como entrada
	LDI		R16, 0xFF
	LDI		PORTD, R16 // Se configuran los pines con pull-up activado

	// Se configura PORTB como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRB, R16 // Se configura el puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16 // Se configuran los pines para estar inicialmente apagados

	LDI		R17, 0xFF // Variable para guardar estado de botones



