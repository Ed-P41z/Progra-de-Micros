/*
*	PreLab-2.asm
*
*	Creado: 2/7/2025 5:05:45 PM
*	Autor: Edvin Paiz
*	Descripción: El prelab 2 consiste en un sumador usando timer
*/
.include "M328PDEF.inc"

.cseg
.org 0x0000

SETUP:
	// Se realiza la configuración del prescaler
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se habilita el cambio del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz
	CALL	INIT_TMR0	// Se inicia el timer 0 (es el timer que usaré

	// Se configuran pines de entrada y salida (DDRx, PORTx, PINx)
	// Se configura PORTD como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16	// Se configura el puerto D como salida
	LDI		R16, 0x00
	OUT		PORTD, R16	// Se configuran los pines para estar inicialmente apagados

	LDI		R17, 0x00	// Variable para guardar estado de contador de reloj
	LDI		R18, 0x00	// Variable para guardar estado de Leds
