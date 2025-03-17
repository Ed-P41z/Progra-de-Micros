;
; EjemploTimer0.asm
;
; Created: 2/5/2025 5:32:00 PM
; Author : edvin
;

.include "M328PDEF.inc"
.cseg
.org	0x0000
.def	counter = R20

/******************************/
// Configuración de pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16
/******************************/
// Configuración MCU
SETUP:
	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPE)
	STS		CLKPR, 16
	LDI		R16, (1 << CLKPC2)
	STS		CLKPR, R16

	CALL	INIT_TMR0

	SBI		DDRB, 5
	CBI		PORT, 5

	LDI		R16, 0x00
	STS		UCSR0B, R16

	LDI		COUNTER, 0x00

MAIN:
	IN		R16, TIFR0
	SBRS	R16, TOV0
	RJMP	MAIN_LOOP
	SBI		TIFR0, TOV0
	LDI		R16, 100
	OUT		TCNT0, R16
	INC		COUNTER
	CPI		COUNTER, 50
	BRNE	MAIN_LOOP
	CLR		COUNTER
	SBI		PINB, PB5
	RJMP	MAIN_LOOP


INIT_TMR0:
	LDI		R16, (1<<1) | (1<<CS00)
	OUT		TCCR0B, R16
	LDI		R16, 100
	OUT		TCNT0, R16
	RET
