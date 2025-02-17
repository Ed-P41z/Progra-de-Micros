/*
*	PreLab-3.asm
*
*	Creado: 2/16/2025 6:49:23 PM
*	Autor: Edvin Paiz
*	Descripción: El prelab 3 consiste en un sumador usando interrupciones
*/

.include "M328PDEF.inc"

.cseg
.org	0x0000

// Se configura la pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

SETUP:
	// Se realiza la configuración del prescaler
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se habilita el cambio del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz
	CALL	INIT_TMR0	// Se inicia el timer 0 (es el timer que usaré)

	// Desabilitar el serial
	LDI R16, 0x00
	STS UCSR0B, R16

	// Se configuran pines de entrada y salida (DDRx, PORTx, PINx)
	// Se configura PORTC como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRC, R16	// Se configura el puerto C como salida
	LDI		R16, 0x00
	OUT		PORTD, R16	
	OUT		PORTC, R16	// Se configuran los pines para estar inicialmente apagados

	LDI		R17, 0x00	// Variable para guardar estado de contador de reloj
	LDI		R18, 0x00	// Variable para guardar estado de Leds

	// Se configura PORTB como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRB, R16	// Se configura el puerto B como entrada y un bit como salida
	SBI		DDRB, PB5
	LDI		R16, 0xFF
	OUT		PORTB, R16	// Se configuran los pines con pull-up activado
	CBI		PORTB, PB5	// El bit está inicialmente apagado

	LDI		R20, 0x00	// Variable para guardar estado de Leds contador

// Loop infinito
MAIN:
	

