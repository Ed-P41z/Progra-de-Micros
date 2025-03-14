/*
*	Proyecto-1.asm
*	Creado: 2/24/2025 4:48:35 PM
*	Autor: Edvin Paiz
*	Descripción: El proyecto 1 consiste en hacer un reloj digital con varias funciones
*/
/*---------------------------------------------------------------------------------------------------*/

.include "M328PDEF.inc"

.equ	T0VALUE		= 0xFD
.equ	T1HVALUE	= 0x1B//0xFF
.equ	T1LVALUE	= 0x1E//0xFF
.equ	T2VALUE		= 0x64
.equ	MODES		= 8
.def	COUNT_T0	= R17	// Registro que guarda el contador de Timer0
.def	COUNT_T2	= R22	// Regritro que guarda el contador de Timer2
.def	LEDMODE		= R18	// Registro que guarda el estado de los LEDS de modo
.def	PBSTATE		= R19	// Registro que guarda el estado de los botones
.def	TRDISP		= R20	// Registro que guarda el estado de los transistores
.def	MODE		= R21	// Registro que guarda el modo actual
.def	MES			= R24	// Registro que guarda el mes actual
.def	TRMODE		= R25	// Registro que guarda el modo de los transistores

	// Registros ocupados: R16, R17, R18, R18, R20, R21, R22, R23, R24, R25

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
ALUMIN:	.byte	1	// Espacio en RAM para guardar unidades de minutos de Alarma
ALDMIN:	.byte	1	// Espacio en RAM para guardar decenas de minutos de Alarma
ALUHRS:	.byte	1	// Espacio en RAM para guardar unidades de horas de Alarma
ALDHRS:	.byte	1	// Espacio en RAM para guardar decenas de horas de Alarma


.cseg
.org	0x0000
	JMP		SETUP

.org	PCI0addr
	JMP		PBREAD		//Sub-rutina de interrupción cuando se presionen los botones

.org	OVF2addr
	JMP		TMR2_OV		//Sub-rutina de interrupción cuando hay overflow en el timer1

.org	OVF1addr
	JMP		TMR1_OV		//Sub-rutina de interrupción cuando hay overflow en el timer1

.org	OVF0addr
	JMP		TMR0_OV		//Sub-rutina de interrupción cuando hay overflow en el timer0


/*---------------------------------------------------------------------------------------------------*/
SETUP:
	// Se apagan las interrupciones globales
	CLI

	// Lista de valores para mostrar números en el display
	Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
	//				 0		1	 2	   3	 4	   5	 6	   7	 8	   9
	Meses:		.DB	0x31, 0x28, 0x31, 0x30, 0x31, 0x30, 0x31, 0x31, 0x30, 0x31, 0x30, 0x31
	//			.DB 0x1F, 0x1C, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F
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
	LDI		R16, (1 << PCINT0) | (1 << PCINT1) | (1 << PCINT2)
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

	// Se inicializan las variables
	LDI		R16, 0x00	// Se carga 0 a los espacios de la RAM donde se guarda la hora y fecha
	STS		UMIN, R16 
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16
	STS		DDAY, R16
	STS		DMO, R16
	STS		ALUMIN, R16 
	STS		ALDMIN, R16
	STS		ALUHRS, R16
	STS		ALDHRS, R16
	LDI		R16, 0x01	// Se carga 1 únicamente a Unidades de día para que no empiecen en 0
	STS		UDAY, R16
	STS		UMO, R16
	CLR		COUNT_T0	// Se coloca 0x00 a R17
	CLR		LEDMODE		// Se coloca 0x00 a R18
	LDI		PBSTATE, 0xFF	// Se coloca 0xFF a R19
	CLR		TRDISP		// Se coloca 0x00 a R20
	LDI		MODE, 0x00		// Se coloca en el primer modo del reloj
	CLR		MES			// Se coloca el registro que guarda el mes actual en enero
	CLR		R26

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
	RJMP	MAIN
HORA:
	RJMP	MODE_HORA
FECHA:
	RJMP	MODE_FECHA
CONFIG_MIN:
	RJMP	MODE_CONFIG_MIN
CONFIG_HRS:
	RJMP	MODE_CONFIG_HRS
CONFIG_DAY:
	RJMP	MODE_CONFIG_DAY
CONFIG_MONTH:
	RJMP	MODE_CONFIG_MONTH
CONFAL_MIN:
	RJMP	MODE_CONFAL_MIN
CONFAL_HRS:
	RJMP	MODE_CONFAL_HRS
ALARM_OFF:
	RJMP	MODE_ALARM_OFF
RJMP	MAIN
/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina de modos
// Modo de Hora
MODE_HORA:
	LDI		R16, (1 << TOIE1)
	STS		TIMSK1, R16		// Se habilitan las interrupciones del Timer1
	CPI		R26, 0x01
	BREQ	ENABLE_SUM
	CPI		COUNT_T0, 0x00
	BREQ	U_MIN
	CPI		COUNT_T0, 0x01
	BREQ	D_MIN
	CPI		COUNT_T0, 0x02
	BREQ	U_HRS
	CPI		COUNT_T0, 0x03
	BREQ	D_HRS
	RJMP	MAIN

ENABLE_SUM:
	CLR		R26
	CALL	SUM_TIMER1
	RJMP	MAIN

U_MIN:
	LDI		COUNT_T0, 0x01
	CALL	TR1_TIME
	RJMP	MAIN
	
D_MIN:
	LDI		COUNT_T0, 0x02
	CALL	TR2_TIME
	RJMP	MAIN

U_HRS:
	LDI		COUNT_T0, 0x03
	CALL	TR3_TIME
	RJMP	MAIN

D_HRS:
	LDI		COUNT_T0, 0x00
	CALL	TR4_TIME
	RJMP	MAIN


// Modo de Fecha
MODE_FECHA:
	CPI		R26, 0x01
	BREQ	ENABLE_SUMA
	CPI		COUNT_T0, 0x00
	BREQ	U_DAY
	CPI		COUNT_T0, 0x01
	BREQ	D_DAY
	CPI		COUNT_T0, 0x02
	BREQ	U_MO
	CPI		COUNT_T0, 0x03
	BREQ	D_MO
	RJMP	MAIN

ENABLE_SUMA:
	CLR		R26
	CALL	SUM_TIMER1
	RJMP	MAIN

U_DAY:
	LDI		COUNT_T0, 0x01
	CALL	TR1_DATE
	RJMP	MAIN
	
D_DAY:
	LDI		COUNT_T0, 0x02
	CALL	TR2_DATE
	RJMP	MAIN

U_MO:
	LDI		COUNT_T0, 0x03
	CALL	TR3_DATE
	RJMP	MAIN

D_MO:
	LDI		COUNT_T0, 0x00
	CALL	TR4_DATE
	RJMP	MAIN


// Modo de configuración de minutos
MODE_CONFIG_MIN:
	CLR		R16
	STS		TIMSK1, R16		// Se deshabilitan las interrupciones del Timer1
	CPI		COUNT_T0, 0x00
	BREQ	U_MIN
	CPI		COUNT_T0, 0x01
	BREQ	D_MIN
	CPI		COUNT_T0, 0x02
	BREQ	U_HRS
	CPI		COUNT_T0, 0x03
	BREQ	D_HRS
	RJMP	MAIN


// Modo de configuración de hora
MODE_CONFIG_HRS:
	CPI		COUNT_T0, 0x00
	BREQ	U_MIN
	CPI		COUNT_T0, 0x01
	BREQ	D_MIN
	CPI		COUNT_T0, 0x02
	BREQ	U_HRS
	CPI		COUNT_T0, 0x03
	BREQ	D_HRS
	RJMP	MAIN


// Modo de configuración de día
MODE_CONFIG_DAY:
	CPI		COUNT_T0, 0x00
	BREQ	U_DAY
	CPI		COUNT_T0, 0x01
	BREQ	D_DAY
	CPI		COUNT_T0, 0x02
	BREQ	U_MO
	CPI		COUNT_T0, 0x03
	BREQ	D_MO
	RJMP	MAIN


// Modo de configuración de mes
MODE_CONFIG_MONTH:
	CPI		COUNT_T0, 0x00
	BREQ	U_DAY
	CPI		COUNT_T0, 0x01
	BREQ	D_DAY
	CPI		COUNT_T0, 0x02
	BREQ	U_MO
	CPI		COUNT_T0, 0x03
	BREQ	D_MO
	RJMP	MAIN


// Modo de configuración de minutos de alarma
MODE_CONFAL_MIN:
	CPI		COUNT_T0, 0x00
	BREQ	ALU_MIN
	CPI		COUNT_T0, 0x01
	BREQ	ALD_MIN
	CPI		COUNT_T0, 0x02
	BREQ	ALU_HRS
	CPI		COUNT_T0, 0x03
	BREQ	ALD_HRS
	RJMP	MAIN

ALU_MIN:
	LDI		COUNT_T0, 0x01
	CALL	TR1_ALARM
	RJMP	MAIN
	
ALD_MIN:
	LDI		COUNT_T0, 0x02
	CALL	TR2_ALARM
	RJMP	MAIN

ALU_HRS:
	LDI		COUNT_T0, 0x03
	CALL	TR3_ALARM
	RJMP	MAIN

ALD_HRS:
	LDI		COUNT_T0, 0x00
	CALL	TR4_ALARM
	RJMP	MAIN

// Modo de configuración de horas de alarma
MODE_CONFAL_HRS:
	CPI		COUNT_T0, 0x00
	BREQ	ALU_MIN
	CPI		COUNT_T0, 0x01
	BREQ	ALD_MIN
	CPI		COUNT_T0, 0x02
	BREQ	ALU_HRS
	CPI		COUNT_T0, 0x03
	BREQ	ALD_HRS
	RJMP	MAIN

// Modo de apagado de alarma
MODE_ALARM_OFF:
	CPI		COUNT_T0, 0x00
	BREQ	ALU_MIN
	CPI		COUNT_T0, 0x01
	BREQ	ALD_MIN
	CPI		COUNT_T0, 0x02
	BREQ	ALU_HRS
	CPI		COUNT_T0, 0x03
	BREQ	ALD_HRS
	RJMP	MAIN

/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1 << CS02) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 1024
	LDI		R16, T0VALUE
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

INIT_TMR1:
	LDI		R16, (1 << CS12) | (1 << CS10)
	STS		TCCR1B, R16	// Setear prescaler del TIMER1 a 1024
	LDI		R16, T1HVALUE
	STS		TCNT1H, R16	// Cargar valor inicial en TCNT1H
	LDI		R16, T1LVALUE
	STS		TCNT1L, R16 // Cargar valor inicial en TCNT1L
	RET

INIT_TMR2:
	LDI		R16, (1 << CS22)
	STS		TCCR2B, R16	// Setear prescaler del TIMER2 a 64
	LDI		R16, T2VALUE
	STS		TCNT2, R16	// Cargar valor inicial en TCNT2
	RET

INICIAR_DISP:	// Se modifica la dirección a la que apunta Z a la primera de la lista
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	LPM		R16, Z		// Se carga el valor guardado en la primera dirección
	OUT		PORTD, R16	// Se saca a PORTD el primer valor al que apunta Z
	RET

TR1_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, UMIN
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC3  // Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, DMIN
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC2	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, UHRS
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC1	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, DHRS
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR1_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, UDAY
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC3  // Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, DDAY
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC2	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, UMO
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC1	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, DMO
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR1_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, ALUMIN
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC3  // Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, ALDMIN
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC2	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, ALUHRS
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC1	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	LDS		R16, ALDHRS
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16		// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z		// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16	// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0	// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

SUM_TIMER1:	// Suma del tiempo en el reloj
	LDS		R16, UMIN
	INC		R16	
	CPI		R16, 0x0A	// Se le suma 1 a UMIN y comparamos si hay overflow
	BREQ	SUM_DMIN	// Si llega a 10M salta a SUM_DMIN
	STS		UMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RET
SUM_DMIN:
	CLR		R16
	STS		UMIN, R16	// Se reinicia UMIN y se guarda en la RAM
	LDS		R16, DMIN
	INC		R16
	CPI		R16, 0x06	// Se le suma 1 a DMIN y comparamos si hay overflow
	BREQ	SUM_UHRS	// Si llega a 1H salta a SUM_UHRS
	STS		DMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RET
SUM_UHRS:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16	// Se reinician los minutos y se guarda en la RAM
	LDS		R16, DHRS
	CPI		R16, 0x02	// Se verifica si llegó a 20HRS
	BREQ	SUM_24HRS	// Si llegó a 20HRS, salta a SUM_24HRS
	LDS		R16, UHRS
	INC		R16
	CPI		R16, 0x0A	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUM_DHRS	// Si llega a 10H salta a SUM_DHRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
SUM_DHRS:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, DHRS
	INC		R16
	STS		DHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RET
SUM_24HRS:
	LDS		R16, UHRS
	INC		R16			
	CPI		R16, 0x04	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUM_UDAY	// Si llega a 24H salta a SUM_UDAY
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
SUM_UDAY:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16	// Se reinician los minutos y las horas, y se guarda en la RAM
	LDS		R16, UDAY
	LDS		R23, DDAY
	LSL		R23
	LSL		R23
	LSL		R23
	LSL		R23
	ADD		R23, R16	// Se sacan los valores de UDAY y DDAY y se suman en un registro
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z		// Se saca el valor de la cantidad de días que tiene el Mes actual
	CP		R23, R16
	BREQ	SUM_UMO	// Se comparan los valores de días actuales con los días del mes, si son iguales salta a SUM_MDAY
	LDS		R16, UDAY
	INC		R16
	CPI		R16, 0x0A	// Se le suma 1 a UDAY y comparamos si hay overflow
	BREQ	SUM_DDAY	// Si llega a 10D salta a SUM_DDAY
	STS		UDAY, R16	// Se actualiza el valor de DDAY en la RAM
	RET
SUM_DDAY:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16
	STS		UDAY, R16	// Se reinician los minutos, las horas y UDAY, y se guarda en la RAM
	LDS		R16, UDAY
	LDS		R23, DDAY
	LSL		R23
	LSL		R23
	LSL		R23
	LSL		R23
	ADD		R23, R16	// Se sacan los valores de UDAY y DDAY y se suman en un registro
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z		// Se saca el valor de la cantidad de días que tiene el Mes actual
	CP		R23, R16
	BREQ	SUM_UMO	// Se comparan los valores de días actuales con los días del mes, si son iguales salta a SUM_MDAY
	LDS		R16, DDAY
	INC		R16
	STS		DDAY, R16
	RET
SUM_UMO:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16
	STS		DDAY, R16
	LDI		R16, 0x01
	STS		UDAY, R16	// Se reinician los minutos, las horas y UDAY, y se guarda en la RAM
	INC		MES
	LDS		R16, DMO
	CPI		R16, 0x01
	BREQ	SUM_YMO
	LDS		R16, UMO
	INC		R16
	CPI		R16, 0x0A
	BREQ	SUM_DMO
	STS		UMO, R16
	RET

SUM_DMO:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16
	STS		UMO, R16
	LDI		R16, 0x01
	STS		UDAY, R16	// Se reinician los minutos, las horas y UDAY, y se guarda en la RAM
	LDS		R16, DMO
	INC		R16
	STS		DMO, R16
	RET

SUM_YMO:
	LDS		R16, UMO
	INC		R16
	CPI		R16, 0x03
	BREQ	HAPPY_NEW_YEAR
	STS		UMO, R16
	RET

HAPPY_NEW_YEAR:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16
	STS		DDAY, R16
	STS		DMO, R16
	LDI		R16, 0x01
	STS		UMO, R16
	STS		UDAY, R16
	CLR		MES
	RET


/*---------------------------------------------------------------------------------------------------*/
// Sub-rutina de interrupcion
// Sub-rutina de interrupcion para mostrar displays
TMR0_OV:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16			// Se guarda el valor de r16 y del SREG en la pila

	SBI		TIFR0, TOV0	// Si está encendida la bandera de overflow, salta a apagarla
	LDI		R16, T0VALUE
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
	POP		R16			// Se saca el valor de r16 y del SREG de la pila
	RETI


// Sub-rutina de interrupcion para suma de tiempo de reloj
TMR1_OV:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16			// Se guarda el valor de R16 y del SREG en la pila

	SBI		TIFR1, TOV1	// Si está encendida la bandera de overflow, salta a apagarla
	LDI		R16, T1HVALUE
	STS		TCNT1H, R16	// Se vuelve a cargar un valor inicial a Timer1H
	LDI		R16, T1LVALUE
	STS		TCNT1L, R16 // Se vuelve a cargar un valor inicial a Timer1L
	LDI		R26, 0x01

	POP		R16
	OUT		SREG, R16
	POP		R16			// Se saca el valor de r16 y del SREG de la pila
	RETI


// Sub-rutina de interrupcion para overflow del Timer2
TMR2_OV:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16			// Se guarda el valor de r16 y del SREG en la pila

	SBI		TIFR2, TOV2	// Si está encendida la bandera de overflow, salta a apagarla
	LDI		R16, T2VALUE
	STS		TCNT2, R16	// Se vuelve a cargar un valor inicial a Timer0 
	INC		COUNT_T2
	CPI		COUNT_T2, 50
	BREQ	TOGGLE_LEDS
	RJMP	OUT_TMR2
TOGGLE_LEDS:
	SBI		PINC, PC5
	CLR		COUNT_T2
	RJMP	OUT_TMR2

OUT_TMR2:
	POP		R16
	OUT		SREG, R16
	POP		R16			// Se saca el valor de r16 y del SREG de la pila
	RETI


// Sub-rutina de interrupcion para detectar botones
PBREAD:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16			// Se guarda el valor de r16 y del SREG en la pila

	IN		R16, PINB	// Se guarda el estado de PORTB en R16
	SBIS	PINB, PB0
	RJMP	MODE_CHANGE		// En caso que se presione pb0: Cambia de modo, no: Salta
	CPI		MODE, 2
	BREQ	MINUTOS		// Modo que configura los minutos
	CPI		MODE, 3
	BREQ	HORAS		// Modo que configura la hora
	CPI		MODE, 4
	BREQ	DIAS		// Modo que configura el día
	CPI		MODE, 5
	BREQ	MONTH		// Modo que configura el mes
//	CPI		MODE, 6
//	BREQ	MINUTOS_AL	// Modo que configura los minutos de la alarma
//	CPI		MODE, 7
//	BREQ	HORAS_AL	// Modo que configura la hora de la alarma
	RJMP	OUT_PB

MINUTOS:
	RJMP	EDIT_MINUTOS
HORAS:
	RJMP	EDIT_HORAS
DIAS:
	RJMP	EDIT_DIAS
MONTH:
	RJMP	EDIT_MESES
RJMP	OUT_PB


MODE_CHANGE:
	INC		MODE
	CPI		MODE, 0x09	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_MODE	// Si hay overflow, reinicia el sumador
	RJMP	OUT_PB
OVERFLOW_MODE:
	LDI		MODE, 0x00	// Si hay overflow, hacemos reset al registro R20
	RJMP	OUT_PB

EDIT_MINUTOS:
	IN		R16, PORTB
	SBIS	PINB, PB1
	RJMP	SUMA_UMIN
	SBIS	PINB, PB2
	RJMP	RES_UMIN
	RJMP	OUT_PB

SUMA_UMIN:
	LDS		R16, UMIN
	INC		R16	
	CPI		R16, 0x0A	// Se le suma 1 a UMIN y comparamos si hay overflow
	BREQ	SUMA_DMIN	// Si llega a 10M salta a SUM_DMIN
	STS		UMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RJMP	OUT_PB
SUMA_DMIN:
	CLR		R16
	STS		UMIN, R16	// Se reinicia UMIN y se guarda en la RAM
	LDS		R16, DMIN
	INC		R16
	CPI		R16, 0x06	// Se le suma 1 a DMIN y comparamos si hay overflow
	BREQ	OVERFLOW_MIN	// Si llega a 1H salta a OVERFLOW_MIN
	STS		DMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RJMP	OUT_PB
OVERFLOW_MIN:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16	// Se reinician los minutos y se guardan los valores en la RAM
	RJMP	OUT_PB

RES_UMIN:
	LDS		R16, UMIN
	DEC		R16	
	CPI		R16, 0xFF	// Se le resta 1 a UMIN y comparamos si hay underflow
	BREQ	RES_DMIN	// Si resta menos de 0M salta a RES_DMIN
	STS		UMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RJMP	OUT_PB
RES_DMIN:
	LDI		R16, 0x09
	STS		UMIN, R16	// Se carga 0x09 a UMIN y se guarda en la RAM
	LDS		R16, DMIN
	DEC		R16
	CPI		R16, 0xFF	// Se le resta 1 a DMIN y comparamos si hay underflow
	BREQ	UNDERFLOW_MIN	// Si llega a menos de 0H salta a UNDERFLOW_MIN
	STS		DMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RJMP	OUT_PB
UNDERFLOW_MIN:
	LDI		R16, 0x09
	STS		UMIN, R16
	LDI		R16, 0x05
	STS		DMIN, R16	// Se reinician los minutos y se guardan los valores en la RAM
	RJMP	OUT_PB

EDIT_HORAS:
	IN		R16, PORTB
	SBIS	PINB, PB1
	RJMP	SUMA_UHRS
	SBIS	PINB, PB2
	RJMP	RES_UHRS
	RJMP	OUT_PB

SUMA_UHRS:
	LDS		R16, DHRS
	CPI		R16, 0x02	// Se verifica si llegó a 20HRS
	BREQ	SUMA_24HRS	// Si llegó a 20HRS, salta a SUM_24HRS
	LDS		R16, UHRS
	INC		R16
	CPI		R16, 0x0A	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUMA_DHRS	// Si llega a 10H salta a SUM_DHRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RJMP	OUT_PB
SUMA_DHRS:
	CLR		R16
	STS		UHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, DHRS
	INC		R16
	STS		DHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RJMP	OUT_PB
SUMA_24HRS:
	LDS		R16, UHRS
	INC		R16			
	CPI		R16, 0x04	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	OVERFLOW_HRS	// Si llega a 24H salta a OVERFLOW_HRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RJMP	OUT_PB
OVERFLOW_HRS:
	CLR		R16
	STS		UHRS, R16
	STS		DHRS, R16
	RJMP	OUT_PB

RES_UHRS:
	LDS		R16, UHRS
	DEC		R16
	CPI		R16, 0xFF	// Se le suma 1 a UHRS y comparamos si hay underflow
	BREQ	RES_DHRS	// Si llega a 10H salta a SUM_DHRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RJMP	OUT_PB
RES_DHRS:
	LDI		R16, 0x09
	STS		UHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, DHRS
	DEC		R16
	CPI		R16, 0xFF
	BREQ	UNDERFLOW_HRS
	STS		DHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RJMP	OUT_PB
UNDERFLOW_HRS:
	LDI		R16, 0x03
	STS		UHRS, R16
	LDI		R16, 0x02
	STS		DHRS, R16
	RJMP	OUT_PB

EDIT_DIAS:
	IN		R16, PORTB
	SBIS	PINB, PB1
	RJMP	SUMA_UDAY
	SBIS	PINB, PB2
	RJMP	RES_UDAY
	RJMP	OUT_PB

SUMA_UDAY:
	LDS		R16, UDAY
	LDS		R23, DDAY
	LSL		R23
	LSL		R23
	LSL		R23
	LSL		R23
	ADD		R23, R16	// Se sacan los valores de UDAY y DDAY y se suman en un registro
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z		// Se saca el valor de la cantidad de días que tiene el Mes actual
	CP		R23, R16
	BREQ	OVERFLOW_DIA	// Se comparan los valores de días actuales con los días del mes, si son iguales salta a SUM_MDAY
	LDS		R16, UDAY
	INC		R16
	CPI		R16, 0x0A	// Se le suma 1 a UDAY y comparamos si hay overflow
	BREQ	SUMA_DDAY	// Si llega a 10D salta a SUM_DDAY
	STS		UDAY, R16	// Se actualiza el valor de DDAY en la RAM
	RJMP	OUT_PB
SUMA_DDAY:
	CLR		R16
	STS		UDAY, R16	// Se reinicia UDAY y se guarda en la RAM
	LDS		R16, UDAY
	LDS		R23, DDAY
	LSL		R23
	LSL		R23
	LSL		R23
	LSL		R23
	ADD		R23, R16	// Se sacan los valores de UDAY y DDAY y se suman en un registro
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z		// Se saca el valor de la cantidad de días que tiene el Mes actual
	CP		R23, R16
	BREQ	OVERFLOW_DIA	// Se comparan los valores de días actuales con los días del mes, si son iguales salta a SUM_MDAY
	LDS		R16, DDAY
	INC		R16
	STS		DDAY, R16
	RJMP	OUT_PB
OVERFLOW_DIA:
	LDI		R16, 0x01
	STS		UDAY, R16
	CLR		R16
	STS		DDAY, R16
	RJMP	OUT_PB

RES_UDAY:
	LDS		R16, DDAY
	CPI		R16, 0x00
	BREQ	RES_MDAY
	LDS		R16, UDAY
	DEC		R16
	CPI		R16, 0xFF	// Se le suma 1 a UDAY y comparamos si hay overflow
	BREQ	RES_DDAY	// Si llega a 10D salta a SUM_DDAY
	STS		UDAY, R16	// Se actualiza el valor de DDAY en la RAM
	RJMP	OUT_PB
RES_DDAY:
	LDI		R16, 0x09
	STS		UDAY, R16
	LDS		R16, DDAY
	DEC		R16
	STS		DDAY, R16
	RJMP	OUT_PB
RES_MDAY:
	LDS		R16, UDAY
	DEC		R16
	CPI		R16, 0x00
	BREQ	UNDERFLOW_DIA
	STS		UDAY, R16
	RJMP	OUT_PB
UNDERFLOW_DIA:
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z
	MOV		R23, R16
	LSR		R23
	LSR		R23
	LSR		R23
	LSR		R23
	STS		DDAY, R23
	ANDI	R16, 0x0F
	STS		UDAY, R16
	RJMP	OUT_PB

EDIT_MESES:
	IN		R16, PORTB
	SBIS	PINB, PB1
	RJMP	SUMA_UMO
	SBIS	PINB, PB2
	RJMP	RES_UMO
	RJMP	OUT_PB

SUMA_UMO:
	INC		MES
	LDS		R16, DMO
	CPI		R16, 0x01
	BREQ	SUMA_YMO
	LDS		R16, UMO
	INC		R16
	CPI		R16, 0x0A
	BREQ	SUMA_DMO
	STS		UMO, R16
	RJMP	OUT_PB
SUMA_DMO:
	CLR		R16
	STS		UMO, R16
	LDS		R16, DMO
	INC		R16
	STS		DMO, R16
	RJMP	OUT_PB
SUMA_YMO:
	LDS		R16, UMO
	INC		R16
	CPI		R16, 0x03
	BREQ	OVERFLOW_MESES
	STS		UMO, R16
	RJMP	OUT_PB
OVERFLOW_MESES:
	CLR		MES
	LDI		R16, 0x01
	STS		UMO, R16
	CLR		R16
	STS		DMO, R16
	RJMP	OUT_PB

RES_UMO:
	DEC		MES
	LDS		R16, DMO
	CPI		R16, 0x00
	BREQ	RES_YMO
	LDS		R16, UMO
	DEC		R16
	CPI		R16, 0xFF
	BREQ	RES_DMO
	STS		UMO, R16
	RJMP	OUT_PB
RES_DMO:
	LDI		R16, 0x09
	STS		UMO, R16
	LDS		R16, DMO
	DEC		R16
	STS		DMO, R16
	RJMP	OUT_PB
RES_YMO:
	LDS		R16, UMO
	DEC		R16
	CPI		R16, 0x00
	BREQ	UNDERFLOW_MESES
	STS		UMO, R16
	RJMP	OUT_PB
UNDERFLOW_MESES:
	LDI		MES, 0x0C
	LDI		R16, 0x02
	STS		UMO, R16
	LDI		R16, 0x01
	STS		DMO, R16
	RJMP	OUT_PB

OUT_PB:
	POP		R16
	OUT		SREG, R16
	POP		R16			// Se saca el valor de r16 y del SREG de la pila
	RETI
	