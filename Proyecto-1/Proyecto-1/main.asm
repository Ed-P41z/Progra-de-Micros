/*
*	Proyecto-1.asm
*	Creado: 2/24/2025 4:48:35 PM
*	Autor: Edvin Paiz
*	Descripción: El proyecto 1 consiste en hacer un reloj digital con varias funciones
*/
/*---------------------------------------------------------------------------------------------------*/

.include "M328PDEF.inc"

.cseg
.org	0x0000
	JMP		SETUP

.org	PCI0addr
	JMP		PBREAD		//Sub-rutina de interrupción cuando se presionen los botones

.org	OVF0addr
	JMP		TMR0_OV		//Sub-rutina de interrupción cuando hay overflow en el timer0

.org	OVF2addr
	JMP		TMR0_1V		//Sub-rutina de interrupción cuando hay overflow en el timer0

/*---------------------------------------------------------------------------------------------------*/
SETUP:
	// Se apagan las interrupciones globales
	CLI

	// Lista de valores para mostrar números en el display
	Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
	//				 0		1	 2	   3	 4	   5	 6	   7	 8	   9
	//Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
	//				 0		1	 2	   3	 4	   5	 6	   7	 8	   9

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
	CALL	INIT_TMR0	// Se inicia el timer 0
	CALL	INIT_TMR1	// Se inicia el timer 1
	CALL	INIT_TMR2	// Se inicia el timer 2

	// Desabilitar el serial
	LDI R16, 0x00
	STS UCSR0B, R16

	// Se habilitan las interrupciones de Timer0
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16

	// Se habilitan las interrupciones de Pin Change 0
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)
	STS		PCMSK0, R16

	// Se configuran pines de entrada y salida (DDRx, PORTx, PINx)
	// Se configura PORTD y PORTC como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16	// Se configura el puerto D como salida
	OUT		DDRC, R16	// Se configura el puerto C como salida
	LDI		R16, 0x00
	OUT		PORTD, R16	
	OUT		PORTC, R16	// Se configuran los pines para estar inicialmente apagados


	// Se configura PORTB como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRB, R16	// Se configura el puerto B como entrada y pb2-pb5 como salida
	LDI		R16, 0xFF
	OUT		PORTB, R16	// Se configuran los pines con pull-up activado

	LDI		R17, 0x00	// Variable para guardar estado de contador de reloj TMR0
	LDI		R18, 0x00	// Variable para guardar estado de Leds
	LDI		R19, 0xFF	// Variable para guardar estado de botones
	LDI		R20, 0x00	// Variable para guardar contador 1 (UM)
	LDI		R21, 0x00	// Variable para guardar contador 2	(DM)
	LDI		R22, 0x00	// Variable para guardar contador 3 (UH)
	LDI		R24, 0x00	// Variable para guardar contador 4	(DH)
	LDI		R25, 0x00	// Variable para guardar contador 5	(UD)
	LDI		R26, 0x00	// Variable para guardar contador 6	(DD)
	LDI		R27, 0x00	// Variable para guardar contador 7	(UMS)
	LDI		R28, 0x00	// Variable para guardar contador 8	(DMS)
	LDI		R23, 0x00	// Variable parar guardar estado transistores
	LDI		R29, 0x00	// Variable para guardar modo actual

	CALL	INICIAR_DISP// Se inicia el display donde se mostrará el contador
	
	SEI					// Habilitamos las interrupciones globales nuevamente

/*---------------------------------------------------------------------------------------------------*/
MAIN:
 	RJMP MAIN	// Para mantener entretenido el main loop

/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1 << CS01) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 64
	LDI		R16, 178
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

INIT_TMR1:
	LDI		R16, (1 << CS01) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 64
	LDI		R16, 178
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

INIT_TMR2:
	LDI		R16, (1 << CS01) | (1 << CS00)
	LDI		R16, 178
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

INICIAR_DISP:	// Se modifica la dirección a la que apunta Z a la primera de la lista
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	LPM		R16, Z		// Se carga el valor guardado en la primera dirección
	OUT		PORTD, R16	// Se saca a PORTD el primer valor al que apunta Z
	RET

/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina de interrupcion
// Sub-rutina de interrupcion para mostrar displays
TMR0_OV:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	SBI		TIFR0, TOV0	// Si está encendida la bandera de overflow, salta a apagarla
	LDI		R16, 178
	OUT		TCNT0, R16	// Se vuelve a cargar un valor inicial a Timer0 
	CPI		R23, 0x00	
	BREQ	TR1			// Se verifica el estado de R23 y se salta a TR1 si es 0x00
	CPI		R23, 0x01
	BREQ	TR2			// Se verifica el estado de R23 y se salta a TR2 si es 0x01
	CPI		R23, 0x02
	BREQ	TR3			// Se verifica el estado de R23 y se salta a TR3 si es 0x02
	CPI		R23, 0x03
	BREQ	TR4			// Se verifica el estado de R23 y se salta a TR4 si es 0x03

TR1:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R20		// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	LDI		R23, 0x01	// Se cambia el valor de R23 para que cambie de estado para el siguiente siclo.
	RJMP	RETURN_T0

TR2:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTC, PC0
	SBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	LDI		R23, 0x02	// Se cambia el valor de R23 para que cambie de estado para el siguiente siclo.
	RJMP	RETURN_T0

TR3:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	SBI		PORTC, PC2
	CBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	LDI		R23, 0x03	// Se cambia el valor de R23 para que cambie de estado para el siguiente siclo.
	RJMP	RETURN_T0

TR4:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	SBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	LDI		R23, 0x00	// Se cambia el valor de R23 para que cambie de estado para el siguiente siclo.
	RJMP	RETURN_T0

RETURN_T0:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

// Sub-rutina de interrupcion para suma de tiempo de reloj
TIMER_1V:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

SUMA: 
	INC		R20
	CPI		R20, 0x0A	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_10M	// Si llega a 10M, reinicia las unidades y le suma uno a las decenas
	LPM		R16, Z
	LDI		R17, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_10M:
	LDI		R20, 0x00	// Se reinicia el contador completo
	INC		R21
	CPI		R21, 0x06
	BREQ	OVERFLOW_60M
	LDI		R17, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_60M:
	LDI		R20, 0x00
	LDI		R21, 0x00	// Se reinicia el contador completo
	INC		R22
	CPI		R24, 0x02
	BREQ	OVERFLOW_24H
	CPI		R22, 0x0A
	BREQ	OVERFLOW_10H
	LDI		R17, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_10H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R24
	CPI		R24, 0x02
	BREQ	OVERFLOW_20H
	LDI		R17, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_20H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R24
	CPI		R24, 0x06
	BREQ	OVERFLOW_24H
	LDI		R17, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_24H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	
	LDI		R24, 0x00	// Se reinicia el contador completo
	BREQ	OVERFLOW_10D
	LDI		R17, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_10D:


RETURN_T1:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

// Sub-rutina de interrupcion para detectar botones
PBREAD:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	IN		R16, PINB	// Se guarda el estado de PORTB en R16
	SBIS	PINB, PB0
	RJMP	SUMA_C2		// En caso que se presione pb0: Suma, no: Salta
	SBIS	PINB, PB1
	RJMP	RESTA		// En caso que se presione pb1: Resta, no: Salta
	RJMP	RETURN_PB

SUMA_C2:
	INC		R29
	CPI		R29, 0x10	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_C2	// Si hay overflow, reinicia el sumador
	RJMP	RETURN_PB
OVERFLOW_C2:
	LDI		R29, 0x00	// Si hay overflow, hacemos reset al registro R20
	OUT		PORTC, R29	// Sacamos el valor guardado en R21 a PORTC
	RJMP	RETURN_PB

RESTA:
	DEC		R29
	CPI		R29, 0xFF	// Le restamos 1 a R20 y comparamos si hay underflow
	BREQ	UNDERFLOW	// Si hay underflow, setea el sumador
	RJMP	RETURN_PB
UNDERFLOW:
	LDI		R29, 0x0F	// Si hay underflow, dejamos en reset al registro R21
	RJMP	RETURN_PB

RETURN_PB:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI