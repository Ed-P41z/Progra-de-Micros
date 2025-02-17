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

.org	0x0006
	JMP		PBREAD		//Sub-rutina de interrupción cuando se presiones los botones


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
	STS		PCICR, R16
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)
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
	OUT		DDRB, R16	// Se configura el puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16	// Se configuran los pines con pull-up activado

	LDI		R17, 0xFF	// Variable para guardar estado de los botones
	LDI		R20, 0x00	// Variable para guardar estado de Leds contador
	
	SEI					// Habilitamos las interrupciones globales nuevamente

// Loop infinito
MAIN:
	INC R19
 	RJMP MAIN	// Para mantener entretenido el main loop

// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1 << CS02) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 1024
	LDI		R16, 158
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

// Sub-rutina de interrupcion

PBREAD:
	// Esta es la medida antirebote utilizando el Timer0
	IN		R16, TIFR0	// Se lee la bandera del registro de interrupción
	SBRS	R16, TOV0	// Se verifica que la bandera de overflow está encendida
	RJMP	PBREAD		// Si está apagada la bandera, regresa al inicio del loop (MAIN)
	SBI		TIFR0, TOV0	// Si está encendida la bandera, salta a apagarla
	LDI		R16, 158
	OUT		TCNT0, R16	// Se vuelve a cargar un valor inicial a Timer0 
	IN		R16, PINB	// Se guarda el estado de PORTB en R16
	CP		R16, R17
	BREQ	NOT_EQ		// Compara el estado anterior y el estado actual y verifica si son iguales
	MOV		R17, R16	// Si son iguales guarda el estado de los botones
	SBIS	PINB, PB0
	RJMP	SUMA		// En caso que se presione pb0: Suma, no: Salta
	SBIS	PINB, PB1
	RJMP	RESTA		// En caso que se presione pb1: Resta, no: Salta
	RETI

NOT_EQ:
	RETI				// Si el estado es igual entonces sale de la sub-rutina

SUMA:
	INC		R20
	CPI		R20, 0x10	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW	// Si hay overflow, reinicia el sumador
	OUT		PORTC, R20	// Sacamos el valor guardado en R20 a PORTD
	RETI
OVERFLOW:
	LDI		R20, 0x00	// Si hay overflow, hacemos reset al registro R20
	OUT		PORTC, R20	// Sacamos el valor guardado en R20 a PORTD
	RETI

RESTA:
	DEC		R20
	CPI		R20, 0xFF	// Le restamos 1 a R20 y comparamos si hay underflow
	BREQ	UNDERFLOW	// Si hay underflow, setea el sumador
	OUT		PORTC, R20	// Sacamos el valor guardado en r20 a PORTD
	RETI
UNDERFLOW:
	LDI		R20, 0x0F	// Si hay underflow, dejamos en reset al registro R20
	OUT		PORTC, R20	// Sacamos el valor guardado en R20 a PORTD
	RETI


