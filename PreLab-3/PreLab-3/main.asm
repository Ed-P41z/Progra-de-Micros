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
	JMP		SETUP

.org	PCINT0
	JMP		PBREAD//SUBRUTINA SUMA O RESTA


SETUP:
	// Se apagan las interrupciones globales
	CLI

	// Se configura la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16
	
	// Se realiza la configuración del prescaler
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se habilita el cambio del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz
	CALL	INIT_TMR0	// Se inicia el timer 0 (es el timer que usaré)

	// Desabilitar el serial
	LDI R16, 0x00
	STS UCSR0B, R16

	// Se habilitan las interrupciones de Pin Change 0
	LDI		R16, (1 << PCIE0)
	STS		PCMSK0, R16

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
	
	SEI					// Habilitamos las interrupciones globales nuevamente

// Loop infinito
MAIN:
	INC R19
	RJMP MAIN

// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1 << CS02) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER 0 a 64
	LDI		R16, 158
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

// Sub-rutina de interrupcion

PBREAD:
	



