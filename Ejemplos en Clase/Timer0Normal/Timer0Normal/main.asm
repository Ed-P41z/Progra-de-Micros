;
; Timer0Normal.asm
;
; Created: 2/12/2025 4:52:47 PM
; Author : edvin
;


.include "M328PDEF.inc"

.cseg
.org	0x0000
	JMP		SETUP

.org	OVF0addr
	JMP		TMR0_ISR

SETUP:
	// Deshabilitar interrupciones globales
	CLI

	// Se configura la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

	// Se cambia el prescaler del uC	
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se habilita el cambio del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz

	// Se habilitan interrupciones del TOV0
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16

	// Configurar pb5 como salida inicialmente apagada
	SBI		DDRB, PB5
	SBI		DDRB, PB0
	CBI		PORTB, PB5
	CBI		PORTB, PB0

	LDI		R20, 0
	SEI

MAIN_LOOP:
	CPI		R20, 50
	BRNE	MAIN_LOOP
	CLR		R20
	SBI		PINB, PB0
	SBI		PINB, PB0
	RJMP	MAIN_LOOP


// Sub-rutinas de no interrupción

// Sub-rutinas de interrupción
TMR0_ISR:
	LDI		R16, 100
	OUT		TCNT0, R16
	INC		R20
	RETI