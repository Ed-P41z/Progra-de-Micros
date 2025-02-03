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
	OUT		PORTD, R16	// Se configuran los pines con pull-up activado

	// Se configura PORTB como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRB, R16	// Se configura el puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16	// Se configuran los pines para estar inicialmente apagados

	LDI		R17, 0xFF	// Variable para guardar estado de botones

// Loop infinito
MAIN:
	IN		R16, PIND	// Se guarda el estado de PORTD en R16
	CP		R17, R16	// Compara el estado anterior con el estado actual del pb1
	BREQ	MAIN		// Si es el mismo estado repite los dos pasos anteriores
	CALL	DELAY
	IN		R16, PIND	// Lee nuevamente R16 para ver si no fue un error de lectura
	CP		R17, R16
	BREQ	MAIN		// Si fue un erro de lectura regresa a MAIN
	MOV		R17, R16	// Guardamos el valor de la lectura anterior en R17


// Sub-rutina (no de interrupcion)
DELAY: // Se realiza un delay como medida antirrebote
	LDI		R18, 0xFF
	LDI		R19, 0x04	// Cargamos los valores necesarios a dos registros
SUB_DELAY:
	DEC		R18
	CPI		R18, 0		
	BRNE	SUB_DELAY	// Se resta 1 a R18 hasta que llegue a 0 y ignora el BRNE
	DEC		R19
	CPI		R19, 0		// Se resta 1 a R19 hasta que llegue a 0	
	RET					// Al llegar R19 a 0 regresa a MAIN: CALL

