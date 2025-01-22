/*
* EjemploClase22Enero2025.asm
*
* Created: 1/22/2025 5:16:58 PM
* Author : Pedro Castillo
*/
.include "M328PDEF.inc"		//Include definitions specific to ATMega328P
/***************************************************/

START:

SETUP:
	/******** PIN CONFIGURATION ********/
	LDI		R16, 0xFF
	OUT		PORTD, R16
	OUT		PORTB, R16

MAIN_LOOP:
	DEC		R16
	RJMP	MAIN_LOOP