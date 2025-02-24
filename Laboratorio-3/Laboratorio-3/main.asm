/*
*	Laboratorio-3.asm*
*	Creado: 2/17/2025 5:16:06 PM
*	Autor: Edvin Paiz
*	Descripción: El prelab 3 consiste en un sumador usando interrupciones
*/
/*---------------------------------------------------------------------------------------------------*/
.include "M328PDEF.inc"

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
	CALL	INIT_TMR0	// Se inicia el timer 0 (es el timer que usaré)

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
	// Se configura PORTD como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16	// Se configura el puerto D como salida
	OUT		DDRC, R16	// Se configura el puerto C como salida
	LDI		R16, 0x00
	OUT		PORTD, R16	
	OUT		PORTC, R16	// Se configuran los pines para estar inicialmente apagados


	// Se configura PORTB como entrada con pull-up habilitado
	LDI		R16, 0x0C
	OUT		DDRB, R16	// Se configura el puerto B como entrada y pb2-pb3 como salida
	LDI		R16, 0xFF
	OUT		PORTB, R16	// Se configuran los pines con pull-up activado
	SBI		PORTB, PB3	// Se configura pb2 inicialmente encendido y pb3 inicialmente apagado

	LDI		R17, 0x00	// Variable para guardar estado de contador de reloj
	LDI		R18, 0x00	// Variable para guardar estado de Leds
	LDI		R19, 0xFF	// Variable para guardar estado de botones
	LDI		R20, 0x00	// Variable para guardar contador 1
	LDI		R21, 0x00	// Variable para guardar contador 2
	LDI		R22, 0x00	// Variable para guardar contador 3
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

TR1:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R20		// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTB, PB2
	SBI		PORTB, PB3	// Se habilitan los transistores para sacar solamente el valor a un disp
	LDI		R23, 0x01	// Se cambia el valor de R23 para que cambie de estado para el siguiente siclo.
	RETI

TR2:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z+
	SBI		PORTB, PB2
	CBI		PORTB, PB3	// Se habilitan los transistores para sacar solamente el valor a un disp
	LDI		R23, 0x00	// Se cambia el valor de R23 para que cambie de estado para el siguiente siclo.
	RETI

SUMA: 
	INC		R20
	CPI		R20, 0x0A	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_10S	// Si llega a 10s, reinicia las unidades y le suma uno a las decenas
	LPM		R16, Z
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI
OVERFLOW_10S:
	LDI		R20, 0x00	// Si hay overflow, hacemos reset al registro R20
	INC		R22
	CPI		R22, 0x06
	BREQ	OVERFLOW_60S	// Si llega a 60s, reinicia las decenas y unidades.
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI
OVERFLOW_60S:
	LDI		R20, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	LDI		R17, 0		// Se reinicia el contador para el timer
	RETI

PBREAD:
	// Esta es la medida antirebote utilizando el Timer0
	IN		R16, TIFR0	// Se lee la bandera del registro de interrupción
	SBRS	R16, TOV0	// Se verifica que la bandera de overflow está encendida
	RJMP	PBREAD		// Si está apagada la bandera, regresa al inicio del loop (MAIN)
	SBI		TIFR0, TOV0	// Si está encendida la bandera, salta a apagarla
	LDI		R16, 158
	OUT		TCNT0, R16	// Se vuelve a cargar un valor inicial a Timer0 
	IN		R16, PINB	// Se guarda el estado de PORTB en R16
	CP		R16, R19
	BREQ	NOT_EQ		// Compara el estado anterior y el estado actual y verifica si son iguales
	MOV		R19, R16	// Si son iguales guarda el estado de los botones
	SBIS	PINB, PB0
	RJMP	SUMA_C2		// En caso que se presione pb0: Suma, no: Salta
	SBIS	PINB, PB1
	RJMP	RESTA		// En caso que se presione pb1: Resta, no: Salta
	RETI

NOT_EQ:
	RETI				// Si el estado es igual entonces sale de la sub-rutina

SUMA_C2:
	INC		R21
	CPI		R21, 0x10	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_C2	// Si hay overflow, reinicia el sumador
	OUT		PORTC, R21	// Sacamos el valor guardado en R21 a PORTC
	RETI
OVERFLOW_C2:
	LDI		R21, 0x00	// Si hay overflow, hacemos reset al registro R20
	OUT		PORTC, R21	// Sacamos el valor guardado en R21 a PORTC
	RETI

RESTA:
	DEC		R21
	CPI		R21, 0xFF	// Le restamos 1 a R20 y comparamos si hay underflow
	BREQ	UNDERFLOW	// Si hay underflow, setea el sumador
	OUT		PORTC, R21	// Sacamos el valor guardado en r21 a PORTC
	RETI
UNDERFLOW:
	LDI		R21, 0x0F	// Si hay underflow, dejamos en reset al registro R21
	OUT		PORTC, R21	// Sacamos el valor guardado en R21 a PORTC
	RETI