/*
*	Proyecto-1.asm
*	Creado: 2/24/2025 4:48:35 PM
*	Autor: Edvin Paiz
*	Descripción: El proyecto 1 consiste en hacer un reloj digital con varias funciones
*/
/*---------------------------------------------------------------------------------------------------*/

.include "M328PDEF.inc"

.equ	T0VALUE		= 0x0000
.equ	T1VALUE		= 0x0000
.equ	T2VALUE		= 0x0000
.equ	MODES		= 8
.def	COUNT_T0	= R17	// Registro que guarda el contador de Timer0
.def	LEDMODE		= R18	// Registro que guarda el estado de los LEDS de modo
.def	PBSTATE		= R19	// Registro que guarda el estado de los botones
.def	TRDISP		= R20	// Registro que guarda el estado de los transistores
.def	MODE		= R21	// Registro que guarda el modo actual

.dseg
.org	SRAM_START
UMIN:	.byte	1	// Espacio en RAM para guardar unidades de minutos
DMIN:	.byte	1	// Espacio en RAM para guardar decenas de minutos
UHRS:	.byte	1	// Espacio en RAM para guardar unidades de hora
DHRS:	.byte	1	// Espacio en RAM para guardar decenas de hora
UDAY:	.byte	1	// Espacio en RAM para guardar unidades de día
DDAY:	.byte	1	// Espacio en RAM para guardar decenas de día
UMO:	.byte	1	// Espacio en RAM para guardar unidades de mes
DMO:	.byte	1	// Espacio en RAM para guardar decenas de mes


.cseg
.org	0x0000
	JMP		SETUP

.org	PCI0addr
	JMP		PBREAD		//Sub-rutina de interrupción cuando se presionen los botones

.org	OVF2addr
	JMP		TMR0_1V		//Sub-rutina de interrupción cuando hay overflow en el timer0

.org	OVF0addr
	JMP		TMR0_OV		//Sub-rutina de interrupción cuando hay overflow en el timer0


/*---------------------------------------------------------------------------------------------------*/
SETUP:
	// Se apagan las interrupciones globales
	CLI

	// Lista de valores para mostrar números en el display
	Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
	//				 0		1	 2	   3	 4	   5	 6	   7	 8	   9
	Meses:		.DB 0x1F, 0x1C, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F
	//			  | Jan | Feb |	Mar | Apr | May | Jun |	Jul | Aug | Sep | Oct | Nov | Dec |

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

	// Se habilitan las interrupciones de Timer1
	LDI		R16, (1 << TOIE1)
	STS		TIMSK1, R16

	// Se habilitan las interrupciones de Timer2
	LDI		R16, (1 << TOIE2)
	STS		TIMSK2, R16

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

	CLR		COUNT_T0	// Se coloca 0x00 a R17
	CLR		LEDMODE		// Se coloca 0x00 a R18
	LDI		PBSTATE, 0xFF	// Se coloca 0xFF a R19
	CLR		TRDISP		// Se coloca 0x00 a R20
	CLR		MODE		// Se coloca en el primer modo del reloj

	CALL	INICIAR_DISP// Se inicia el display donde se mostrará el contador
	
	SEI					// Habilitamos las interrupciones globales nuevamente

/*---------------------------------------------------------------------------------------------------*/
MAIN:
	CPI		MODE, 0
	BREQ	HORA		// Modo que muestra la hora
	CPI		MODE, 1
	BREQ	FECHA		// Modo que muestra la fecha
	CPI		MODE, 2
	BREQ	CONFIG_MIN	// Modo que configura los minutos
	CPI		MODE, 3
	BREQ	CONFIG_HRS	// Modo que configura la hora
	CPI		MODE, 4
	BREQ	CONFIG_DAY	// Modo que configura el día
	CPI		MODE, 5
	BREQ	CONFIG_MONTH// Modo que configura el mes
	CPI		MODE, 6
	BREQ	CONFAL_MIN	// Modo que configura los minutos de la alarma
	CPI		MODE, 7
	BREQ	CONFAL_HRS	// Modo que configura la hora de la alarma
	CPI		MODE, 8
	BREQ	ALARM_OFF	// Modo que apaga la alarma
 	RJMP	MAIN	// Para mantener entretenido el main loop

/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina de modos
HORA:
	CPI		COUNT_T0, 0x00
	BRBC	SREG_Z, +1
	CALL	TR1_TIME

	RET

FECHA:
	RET

CONFIG_MIN:
	RET

CONFIG_HRS:
	RET

CONFIG_DAY:
	RET

CONFIG_MONTH:
	RET

CONFAL_MIN:
	RET

CONFAL_HRS:
	RET

ALARM_OFF:
	RET

/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1 << CS01) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 64
	LDI		R16, 178
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

INIT_TMR1:
	LDI		R16, (1 << CS11) | (1 << CS10)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 64
	LDI		R16, 178
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

INIT_TMR2:
	LDI		R16, (1 << CS22)
	STS		TCCR2B, R16	// Setear prescaler del TIMER2 a 64
	LDI		R16, 178
	STS		TCNT2, R16	// Cargar valor inicial en TCNT0
	RET

INICIAR_DISP:	// Se modifica la dirección a la que apunta Z a la primera de la lista
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	LPM		R16, Z		// Se carga el valor guardado en la primera dirección
	OUT		PORTD, R16	// Se saca a PORTD el primer valor al que apunta Z
	RET

TR1_TIME:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R20		// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_TIME:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTC, PC0
	SBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_TIME:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	SBI		PORTC, PC2
	CBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_TIME:
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R22		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	SBI		PORTC, PC3	// Se habilitan los transistores para sacar solamente el valor a un disp
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
	INC		COUNT_T0
	CPI		COUNT_T0, 0x04
	BREQ	OVERFLOW_CT0
	RJMP	EXIT_TMR0

OVERFLOW_CT0:
	CLR		COUNT_T0
	RJMP	EXIT_TMR0

EXIT_TMR0:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI


// Sub-rutina de interrupcion para suma de tiempo de reloj
TIMER1_OV:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

SUMA: 
	INC		R20
	CPI		R20, 0x0A	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_10M	// Si llega a 10M, reinicia las unidades y le suma uno a las decenas
	LPM		R16, Z
	LDI		COUNT_T0, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_10M:
	LDI		R20, 0x00	// Se reinicia el contador completo
	INC		R21
	CPI		R21, 0x06
	BREQ	OVERFLOW_60M
	LDI		COUNT_T0, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_60M:
	LDI		R20, 0x00
	LDI		R21, 0x00	// Se reinicia el contador completo
	INC		R22
	CPI		R24, 0x02
	BREQ	OVERFLOW_24H
	CPI		R22, 0x0A
	BREQ	OVERFLOW_10H
	LDI		COUNT_T0, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_10H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R24
	CPI		R24, 0x02
	BREQ	OVERFLOW_20H
	LDI		COUNT_T0, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_20H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	// Se reinicia el contador completo
	INC		R24
	CPI		R24, 0x06
	BREQ	OVERFLOW_24H
	LDI		COUNT_T0, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_24H:
	LDI		R20, 0x00
	LDI		R21, 0x00
	LDI		R22, 0x00	
	LDI		R24, 0x00	// Se reinicia el contador completo
	BREQ	OVERFLOW_10D
	LDI		COUNT_T0, 0		// Se reinicia el contador para el timer
	RJMP	RETURN_T0
OVERFLOW_10D:


RETURN_T0:
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

TMR0_1V:
	RETI