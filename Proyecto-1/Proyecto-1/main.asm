/*
*	Proyecto-1.asm
*	Creado: 2/24/2025 4:48:35 PM
*	Autor: Edvin Paiz
*	Descripción: El proyecto 1 consiste en hacer un reloj digital con varias funciones
*/
/*---------------------------------------------------------------------------------------------------*/

include "M328PDEF.inc"

.cseg
.org	0x0000
	JMP		SETUP

.org	0x0006
	JMP		PBREAD		//Sub-rutina de interrupción cuando se presiones los botones

.org	0x0020
	JMP		TMR0_OV		//Sub-rutina de interrupción cuando hay overflow en el timer0

/*---------------------------------------------------------------------------------------------------*/
SETUP:
	// Se apagan las interrupciones globales
	CLI

	// Lista de valores para mostrar números en el display
	Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
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
	LDI		R20, 0x00	// Variable para guardar contador 1 (US)
	LDI		R21, 0x00	// Variable para guardar contador 2	(DS)
	LDI		R22, 0x00	// Variable para guardar contador 3 (UM)
	LDI		R24, 0x00	// Variable para guardar contador 4	(DM)
	LDI		R23, 0x00	// Variable parar guardar estado transistores

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
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 64
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
TMR0_OV:
	SBI		TIFR0, TOV0	// Si está encendida la bandera de overflow, salta a apagarla
	LDI		R16, 178
	OUT		TCNT0, R16	// Se vuelve a cargar un valor inicial a Timer0 
	INC		R17			// Incrementa cada 5ms
	CPI		R17, 200	// Se compara con 200 para verificar si pasó 1 seg
	BRNE	NOT_1S		// Si no ha pasado 1 seg regresa a MAIN
	BREQ	SUMA
	RETI

NOT_1S:
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
	RETI

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
	RETI

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
	RETI

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
	RETI

SUMA: 
	INC		R20
	CPI		R20, 0x3C	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_60S	// Si llega a 60s, reinicia las unidades y le suma uno a las decenas
	LPM		R16, Z
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI
OVERFLOW_60S:
	LDI		R20, 0x00
	LDI		R21, 0x00	// Se reinicia el contador completo
	INC		R22
	CPI		R22, 0x0A
	BREQ	OVERFLOW_10M
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI
OVERFLOW_10M:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R23
	CPI		R23, 0x06
	BREQ	OVERFLOW_60M
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI
OVERFLOW_60M:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R23
	CPI		R23, 0x06
	BREQ	OVERFLOW_10H
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI
OVERFLOW_10H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R23
	CPI		R23, 0x06
	BREQ	OVERFLOW_60M
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI