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

	
// Loop infinito
MAIN:
	IN		R16, TIFR0	// Se lee la bandera del registro de interrupción
	SBRS	R16, TOV0	// Se verifica que la bandera de overflow está encendida
	RJMP	MAIN		// Si está apagada la bandera, regresa al inicio del loop
	SBI		TIFR0, TOV0	// Si está encendida la bandera, salta a apagarla
	LDI		R16, 100
	OUT		TCNT0, R16	// Se vuelve a cargar un valor inicial a Timer0
	INC		R17
	CPI		R17, 10		// Se compara con 10 para verificar si pasaron 10ms
	BRNE	MAIN		// Si no han pasado 10ms regresa a MAIN
	CLR		R17			// Si ya pasaron 10ms limpia el registro del contador de reloj
	INC		R18
	CPI		R18, 0x10	
	BREQ	OVERFLOW	// Se suma 1 a R18 y verifica si hay overflow
	OUT		PORTD, R18
	RJMP	MAIN		// Si no hay overflow imprime el valor y regresa a MAIN

// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

OVERFLOW:
	LDI		R18, 0x00	
	OUT		PORTD, R18	// Si hay overflow resetea el contador e imprime el valor
	RJMP	MAIN