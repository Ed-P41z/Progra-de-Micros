/*
*	Proyecto-1.asm
*	Creado: 2/24/2025 4:48:35 PM
*	Autor: Edvin Paiz
*	Descripción: El proyecto 1 consiste en hacer un reloj digital con varias funciones
*/
/*---------------------------------------------------------------------------------------------------*/

.include "M328PDEF.inc"

.equ	T0VALUE		= 0xFD	// Valor que cuenta 3ms con Timer0
.equ	T1HVALUE	= 0x1B	// Valor en High de Timer1 que cuenta 1 minuto
.equ	T1LVALUE	= 0x1E	// Valor en Low de Timer1 que cuenta 1 minuto
.equ	T2VALUE		= 0x64	// Valor que cuenta 10ms con Timer2 (se usará un contador para que cuente 500ms en total)
.equ	MODES		= 8		// Total de modos que se usarán en el proyecto
.def	COUNT_T0	= R17	// Registro que guarda el contador de Timer0
.def	COUNT_T2	= R22	// Regritro que guarda el contador de Timer2
.def	LEDMODE		= R18	// Registro que guarda el estado de los LEDS de modo
.def	PBSTATE		= R19	// Registro que guarda el estado de los botones
.def	TRDISP		= R20	// Registro que guarda el estado de los transistores
.def	MODE		= R21	// Registro que guarda el modo actual
.def	MES			= R24	// Registro que guarda el mes actual
.def	PBACTION	= R25	// Registro que guarda la acción de los botones

	// Registros ocupados: R16, R17, R18, R18, R20, R21, R22, R23, R24, R25, R26, R27

//*******************(Segmento donde se guardan datos del reloj en RAM)*******************//
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

//**************(Segmento donde se guarda el código del funcionamiento del reloj)**************//
.cseg
.org	0x0000
	JMP		SETUP		// Rutina de setup que solo se ejecutará una vez

.org	PCI0addr
	JMP		PBREAD		//Sub-rutina de interrupción cuando se presionen los botones

.org	OVF2addr
	JMP		TMR2_OV		//Sub-rutina de interrupción cuando hay overflow en el Timer2

.org	OVF1addr
	JMP		TMR1_OV		//Sub-rutina de interrupción cuando hay overflow en el Timer1

.org	OVF0addr
	JMP		TMR0_OV		//Sub-rutina de interrupción cuando hay overflow en el Timer0


/*---------------------------------------------------------------------------------------------------*/
//*******************(Rutina de Setup para realizar el reloj)*******************//
SETUP:
	// Se apagan las interrupciones globales
	CLI

	//*******************(Listas para displays y meses)*******************//
	// Lista de valores para mostrar números en el display
	Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
	//				 0		1	 2	   3	 4	   5	 6	   7	 8	   9
	
	// Lista de valores de lso días individuales de cada mes
	Meses:		.DB	0x31, 0x28, 0x31, 0x30, 0x31, 0x30, 0x31, 0x31, 0x30, 0x31, 0x30, 0x31
	//			  | Jan | Feb |	Mar | Apr | May | Jun |	Jul | Aug | Sep | Oct | Nov | Dec |

	//*******************(Configuración de pila)*******************//
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16
	
	//*******************(Configuración de Prescalers y Timers)*******************//
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se habilita el cambio del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz
	CALL	INIT_TMR0	// Se inicia el Timer0
	CALL	INIT_TMR1	// Se inicia el Timer1
	CALL	INIT_TMR2	// Se inicia el Timer2

	//*******************(Configuración Pines Serial)*******************//
	// Desabilitar el serial
	LDI R16, 0x00
	STS UCSR0B, R16

	//*******************(Habilitar interrupciones)*******************//
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

	//*******************(Configuración de Inputs y Outputs)*******************//
	// Se configura PORTD y PORTC como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16	// Se configura el puerto D como salida
	OUT		DDRC, R16	// Se configura el puerto C como salida
	LDI		R16, 0x00
	OUT		PORTD, R16	
	OUT		PORTC, R16	// Se configuran los pines para estar inicialmente apagados


	// Se configura PORTB como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRB, R16	// Se configura el puerto B como entrada y pb3-pb5 como salida
	LDI		R16, (1 << PB5) | (1 << PB4) | (1 << PB3)
	OUT		DDRB, R16
	LDI		R16, 0xFF
	OUT		PORTB, R16	// Se configuran los pines con pull-up activado
	LDI		R16, (0 << PB5) | (0 << PB4) | (0 << PB3)
	OUT		PORTB, R16	// Se configuran pb3-pb5 para estar inicialmente apagados

	//*******************(Inicialización de variables)*******************//
	LDI		R16, 0x00	// Se carga 0 a los espacios de la RAM donde se guarda la hora, fecha y alarma
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
	LDI		R16, 0x01	// Se carga 1 únicamente a Unidades de día y mes para que no empiecen en 0
	STS		UDAY, R16
	STS		UMO, R16
	CLR		COUNT_T0	// Se coloca 0x00 a R17
	CLR		LEDMODE		// Se coloca 0x00 a R18
	LDI		PBSTATE, 0xFF	// Se coloca 0xFF a R19
	CLR		TRDISP		// Se coloca 0x00 a R20
	LDI		MODE, 0x00	// Se coloca en el primer modo del reloj
	CLR		MES			// Se coloca el registro que guarda el mes actual en enero
	CLR		PBACTION	// Se coloca 0x00 a R25
	CLR		R26			// Se coloca 0x00 a R26

	//*******************(Iniciar Display)*******************//
	CALL	INICIAR_DISP// Se inicia el display donde se mostrará el contador
	

	SEI					// Habilitamos las interrupciones globales nuevamente

/*---------------------------------------------------------------------------------------------------*/
//*******************(Rutina Main)*******************//
MAIN:
	CPI		PBACTION, 0x01
	BREQ	CAMBIAR_MODO	// Se compara la bandera de cambio de modo y salta a cambiar de modo si está encendida
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
CAMBIAR_MODO:
	CALL	MODE_CHANGE	// Se llama a la sub-rutina de cambio de modo
	CLR		PBACTION	// Se limpia la bandera de cambio de modo
	RJMP	MAIN		// Regresa a Main
HORA:
	RJMP	MODE_HORA	// Salta a la sub-rutina del Modo de Hora 
FECHA:
	RJMP	MODE_FECHA	// Salta a la sub-rutina del Modo de Fecha
CONFIG_MIN:
	RJMP	MODE_CONFIG_MIN	// Salta a la sub-rutina del Modo de Configuración de Minutos
CONFIG_HRS:
	RJMP	MODE_CONFIG_HRS	// Salta a la sub-rutina del Modo de Configuración de Horas
CONFIG_DAY:
	RJMP	MODE_CONFIG_DAY	// Salta a la sub-rutina del Modo de Configuración de Día
CONFIG_MONTH:
	RJMP	MODE_CONFIG_MONTH	// Salta a la sub-rutina del Modo de Configuración de Mes
CONFAL_MIN:
	RJMP	MODE_CONFAL_MIN	// Salta a la sub-rutina del Modo de Configuración de Minutos de Alarma
CONFAL_HRS:
	RJMP	MODE_CONFAL_HRS	// Salta a la sub-rutina del Modo de Configuración de Horas de Alarma
ALARM_OFF:
	RJMP	MODE_ALARM_OFF	// Salta a la sub-rutina del Modo de Apagar Alarma
RJMP	MAIN		// Regresa a Main


/*---------------------------------------------------------------------------------------------------*/
//*******************(Sub-rutinas de Modos)*******************//


	//*******************(Sub-rutina de Hora)*******************//
MODE_HORA:
	LDI		R16, (1 << TOIE1)
	STS		TIMSK1, R16		// Se habilitan las interrupciones del Timer1
	CPI		R26, 0x01
	BREQ	ENABLE_SUM		// Se verica si la bandera de la suma de Timer1 está encendida (1 minuto)
	CPI		COUNT_T0, 0x00
	BREQ	U_MIN			// Se verifica si el contador del Timer0 mostrará unidades de minutos
	CPI		COUNT_T0, 0x01
	BREQ	D_MIN			// Se verifica si el contador del Timer0 mostrará decenas de minutos
	CPI		COUNT_T0, 0x02
	BREQ	U_HRS			// Se verifica si el contador del Timer0 mostrará unidades de horas
	CPI		COUNT_T0, 0x03
	BREQ	D_HRS			// Se verifica si el contador del Timer0 mostrará decenas de horas
	RJMP	MAIN			// Regresa a Main

ENABLE_SUM:
	CLR		R26			// Se apaga la bandera de la suma de Timer1
	CALL	SUM_TIMER1	// Se llama la suma del Timer1
	RJMP	MAIN		// Regresa a Main

U_MIN:
	LDI		COUNT_T0, 0x01	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR1_TIME		// Se llama a la sub-rutina del muestreo de unidades de minutos
	RJMP	MAIN			// Regresa a Main
	
D_MIN:
	LDI		COUNT_T0, 0x02	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR2_TIME		// Se llama a la sub-rutina del muestreo de decenas de minutos
	RJMP	MAIN			// Regresa a Main

U_HRS:
	LDI		COUNT_T0, 0x03	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR3_TIME		// Se llama a la sub-rutina del muestreo de unidades de horas
	RJMP	MAIN			// Regresa a Main

D_HRS:
	LDI		COUNT_T0, 0x00	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR4_TIME		// Se llama a la sub-rutina del muestreo de decenas de horas
	RJMP	MAIN			// Regresa a Main

	//*******************(Sub-rutina de Fecha)*******************//
MODE_FECHA:
	CPI		R26, 0x01		
	BREQ	ENABLE_SUMA		// Se verica si la bandera de la suma de Timer1 está encendida (1 minuto)
	CPI		COUNT_T0, 0x00
	BREQ	U_DAY			// Se verifica si el contador del Timer0 mostrará unidades de día
	CPI		COUNT_T0, 0x01
	BREQ	D_DAY			// Se verifica si el contador del Timer0 mostrará decenas de día
	CPI		COUNT_T0, 0x02
	BREQ	U_MO			// Se verifica si el contador del Timer0 mostrará unidades de mes
	CPI		COUNT_T0, 0x03
	BREQ	D_MO			// Se verifica si el contador del Timer0 mostrará decenas de mes
	RJMP	MAIN			// Regresa a Main

ENABLE_SUMA:
	CLR		R26			// Se apaga la bandera de la suma de Timer1
	CALL	SUM_TIMER1	// Se llama la suma del Timer1
	RJMP	MAIN		// Regresa a Main

U_DAY:
	LDI		COUNT_T0, 0x01	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR1_DATE		// Se llama a la sub-rutina del muestreo de unidades de día
	RJMP	MAIN			// Regresa a Main
	
D_DAY:
	LDI		COUNT_T0, 0x02	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR2_DATE		// Se llama a la sub-rutina del muestreo de decenas de día
	RJMP	MAIN			// Regresa a Main

U_MO:
	LDI		COUNT_T0, 0x03	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR3_DATE		// Se llama a la sub-rutina del muestreo de unidades de mes
	RJMP	MAIN			// Regresa a Main

D_MO:
	LDI		COUNT_T0, 0x00	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR4_DATE		// Se llama a la sub-rutina del muestreo de decenas de mes
	RJMP	MAIN			// Regresa a Main


	//*******************(Sub-rutina de Configuración de Minutos)*******************//
MODE_CONFIG_MIN:
	CLR		R16
	STS		TIMSK1, R16			// Se deshabilitan las interrupciones del Timer1
	CPI		PBACTION, 0x02
	BREQ	REALIZA_SUMA_MIN	// Se verifica si la bandera de suma del botón está encendida
	CPI		PBACTION, 0x03
	BREQ	REALIZA_RESTA_MIN	// Se verifica si la bandera de resta del botón está encendida
	CPI		COUNT_T0, 0x00	
	BREQ	U_MIN1				// Se verifica si el contador del Timer0 mostrará unidades de minutos
	CPI		COUNT_T0, 0x01
	BREQ	D_MIN1				// Se verifica si el contador del Timer0 mostrará decenas de minutos
	CPI		COUNT_T0, 0x02
	BREQ	U_HRS1				// Se verifica si el contador del Timer0 mostrará unidades de horas
	CPI		COUNT_T0, 0x03
	BREQ	D_HRS1				// Se verifica si el contador del Timer0 mostrará decenas de horas
	RJMP	MAIN				// Regresa a Main

U_MIN1:
	LDI		COUNT_T0, 0x01	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR1_TIME		// Se llama a la sub-rutina del muestreo de unidades de minutos
	RJMP	MAIN			// Regresa a Main
	
D_MIN1:
	LDI		COUNT_T0, 0x02	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR2_TIME		// Se llama a la sub-rutina del muestreo de decenas de minutos
	RJMP	MAIN			// Regresa a Main

U_HRS1:
	LDI		COUNT_T0, 0x03	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR3_TIME		// Se llama a la sub-rutina del muestreo de unidades de horas
	RJMP	MAIN			// Regresa a Main

D_HRS1:
	LDI		COUNT_T0, 0x00	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR4_TIME		// Se llama a la sub-rutina del muestreo de decenas de horas
	RJMP	MAIN			// Regresa a Main

REALIZA_SUMA_MIN:
	CALL	SUMA_UMIN		// Se llama a la subrutina de suma de minutos con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

REALIZA_RESTA_MIN:
	CALL	RES_UMIN		// Se llama a la subrutina de resta de minutos con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

	//*******************(Sub-rutina de Configuración de Hora)*******************//
MODE_CONFIG_HRS:
	CPI		PBACTION, 0x02
	BREQ	REALIZA_SUMA_HRS	// Se verifica si la bandera de suma del botón está encendida
	CPI		PBACTION, 0x03
	BREQ	REALIZA_RESTA_HRS	// Se verifica si la bandera de resta del botón está encendida
	CPI		COUNT_T0, 0x00
	BREQ	U_MIN1				// Se verifica si el contador del Timer0 mostrará unidades de minutos
	CPI		COUNT_T0, 0x01
	BREQ	D_MIN1				// Se verifica si el contador del Timer0 mostrará decenas de minutos
	CPI		COUNT_T0, 0x02
	BREQ	U_HRS1				// Se verifica si el contador del Timer0 mostrará unidades de horas
	CPI		COUNT_T0, 0x03
	BREQ	D_HRS1				// Se verifica si el contador del Timer0 mostrará decenas de horas
	RJMP	MAIN				// Regresa a Main

REALIZA_SUMA_HRS:
	CALL	SUMA_UHRS		// Se llama a la subrutina de suma de horas con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

REALIZA_RESTA_HRS:
	CALL	RES_UHRS		// Se llama a la subrutina de resta de horas con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

	//*******************(Sub-rutina de Configuración de Día)*******************//
MODE_CONFIG_DAY:
	CPI		PBACTION, 0x02
	BREQ	REALIZA_SUMA_DAY	// Se verifica si la bandera de suma del botón está encendida
	CPI		PBACTION, 0x03
	BREQ	REALIZA_RESTA_DAY	// Se verifica si la bandera de resta del botón está encendida
	CPI		COUNT_T0, 0x00
	BREQ	U_DAY1				// Se verifica si el contador del Timer0 mostrará unidades de día
	CPI		COUNT_T0, 0x01
	BREQ	D_DAY1				// Se verifica si el contador del Timer0 mostrará decenas de día
	CPI		COUNT_T0, 0x02
	BREQ	U_MO1				// Se verifica si el contador del Timer0 mostrará unidades de mes
	CPI		COUNT_T0, 0x03
	BREQ	D_MO1				// Se verifica si el contador del Timer0 mostrará decenas de mes
	RJMP	MAIN				// Regresa a Main

U_DAY1:
	LDI		COUNT_T0, 0x01	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR1_DATE		// Se llama a la sub-rutina del muestreo de unidades de día
	RJMP	MAIN			// Regresa a Main
	
D_DAY1:
	LDI		COUNT_T0, 0x02	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR2_DATE		// Se llama a la sub-rutina del muestreo de decenas de día
	RJMP	MAIN			// Regresa a Main

U_MO1:
	LDI		COUNT_T0, 0x03	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR3_DATE		// Se llama a la sub-rutina del muestreo de unidades de mes
	RJMP	MAIN			// Regresa a Main

D_MO1:
	LDI		COUNT_T0, 0x00	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR4_DATE		// Se llama a la sub-rutina del muestreo de decenas de mes
	RJMP	MAIN			// Regresa a Main

REALIZA_SUMA_DAY:
	CALL	SUMA_UDAY		// Se llama a la subrutina de suma de día con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

REALIZA_RESTA_DAY:
	CALL	RES_UDAY		// Se llama a la subrutina de resta de día con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

	//*******************(Sub-rutina de Configuración de Mes)*******************//
MODE_CONFIG_MONTH:
	CPI		PBACTION, 0x02
	BREQ	REALIZA_SUMA_MO	// Se verifica si la bandera de suma del botón está encendida
	CPI		PBACTION, 0x03
	BREQ	REALIZA_RESTA_MO// Se verifica si la bandera de resta del botón está encendida
	CPI		COUNT_T0, 0x00
	BREQ	U_DAY1			// Se verifica si el contador del Timer0 mostrará unidades de día
	CPI		COUNT_T0, 0x01
	BREQ	D_DAY1			// Se verifica si el contador del Timer0 mostrará decenas de día
	CPI		COUNT_T0, 0x02
	BREQ	U_MO1			// Se verifica si el contador del Timer0 mostrará unidades de mes
	CPI		COUNT_T0, 0x03
	BREQ	D_MO1			// Se verifica si el contador del Timer0 mostrará decenas de mes
	RJMP	MAIN			// Regresa a Main

REALIZA_SUMA_MO:
	CALL	SUMA_UMO	// Se llama a la subrutina de suma de mes con botón
	CLR		PBACTION	// Se limpia la bandera de acción de botón
	RJMP	MAIN		// Regresa a Main

REALIZA_RESTA_MO:
	CALL	RES_UMO		// Se llama a la subrutina de resta de mes con botón
	CLR		PBACTION	// Se limpia la bandera de acción de botón
	RJMP	MAIN		// Regresa a Main


	//*******************(Sub-rutina de Configuración de Minutos de Alarma)*******************//
MODE_CONFAL_MIN:
	CPI		PBACTION, 0x02
	BREQ	REALIZA_SUMA_ALUMIN		// Se verifica si la bandera de suma del botón está encendida
	CPI		PBACTION, 0x03
	BREQ	REALIZA_RESTA_ALUMIN	// Se verifica si la bandera de resta del botón está encendida
	CPI		COUNT_T0, 0x00
	BREQ	ALU_MIN					// Se verifica si el contador del Timer0 mostrará unidades de minutos de alarma
	CPI		COUNT_T0, 0x01
	BREQ	ALD_MIN					// Se verifica si el contador del Timer0 mostrará decenas de minutos de alarma
	CPI		COUNT_T0, 0x02
	BREQ	ALU_HRS					// Se verifica si el contador del Timer0 mostrará unidades de horas de alarma
	CPI		COUNT_T0, 0x03
	BREQ	ALD_HRS					// Se verifica si el contador del Timer0 mostrará decenas de horas de alarma
	RJMP	MAIN					// Regresa a Main

ALU_MIN:
	LDI		COUNT_T0, 0x01	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR1_ALARM		// Se llama a la sub-rutina del muestreo de unidades de minutos de alarma
	RJMP	MAIN			// Regresa a Main
	
ALD_MIN:
	LDI		COUNT_T0, 0x02	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR2_ALARM		// Se llama a la sub-rutina del muestreo de decenas de minutos de alarma
	RJMP	MAIN			// Regresa a Main

ALU_HRS:
	LDI		COUNT_T0, 0x03	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR3_ALARM		// Se llama a la sub-rutina del muestreo de unidades de horas de alarma
	RJMP	MAIN			// Regresa a Main

ALD_HRS:
	LDI		COUNT_T0, 0x00	// Se carga un nuevo valor al contador de Timer0 para que muestre el siguiente dígito
	CALL	TR4_ALARM		// Se llama a la sub-rutina del muestreo de decenas de horas de alarma
	RJMP	MAIN			// Regresa a Main

REALIZA_SUMA_ALUMIN:
	CALL	SUMA_ALUMIN		// Se llama a la subrutina de suma de minutos de alarma con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

REALIZA_RESTA_ALUMIN:
	CALL	RES_ALUMIN		// Se llama a la subrutina de resta de minutos de alarma con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

	//*******************(Sub-rutina de Configuración de Horas de Alarma)*******************//
MODE_CONFAL_HRS:
	CPI		PBACTION, 0x02
	BREQ	REALIZA_SUMA_ALUHRS		// Se verifica si la bandera de suma del botón está encendida
	CPI		PBACTION, 0x03
	BREQ	REALIZA_RESTA_ALUHRS	// Se verifica si la bandera de resta del botón está encendida
	CPI		COUNT_T0, 0x00
	BREQ	ALU_MIN					// Se verifica si el contador del Timer0 mostrará unidades de minutos
	CPI		COUNT_T0, 0x01
	BREQ	ALD_MIN					// Se verifica si el contador del Timer0 mostrará decenas de minutos
	CPI		COUNT_T0, 0x02
	BREQ	ALU_HRS					// Se verifica si el contador del Timer0 mostrará unidades de horas
	CPI		COUNT_T0, 0x03
	BREQ	ALD_HRS					// Se verifica si el contador del Timer0 mostrará decenas de horas
	RJMP	MAIN					// Regresa a Main

REALIZA_SUMA_ALUHRS:
	CALL	SUMA_ALUHRS		// Se llama a la subrutina de suma de horas de alarma con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

REALIZA_RESTA_ALUHRS:
	CALL	RES_ALUHRS		// Se llama a la subrutina de resta de horas de alarma con botón
	CLR		PBACTION		// Se limpia la bandera de acción de botón
	RJMP	MAIN			// Regresa a Main

	//*******************(Sub-rutina de Apagar Alarma)*******************//
MODE_ALARM_OFF:
	CALL	APAGAR_ALARMA		// Se llama a la subrutina para Apagar Alarma
	CPI		COUNT_T0, 0x00		
	BREQ	ALU_MIN				// Se verifica si el contador del Timer0 mostrará unidades de minutos de alarma
	CPI		COUNT_T0, 0x01
	BREQ	ALD_MIN				// Se verifica si el contador del Timer0 mostrará decenas de minutos de alarma
	CPI		COUNT_T0, 0x02
	BREQ	ALU_HRS				// Se verifica si el contador del Timer0 mostrará unidades de horas de alarma
	CPI		COUNT_T0, 0x03
	BREQ	ALD_HRS				// Se verifica si el contador del Timer0 mostrará decenas de horas de alarma
	RJMP	MAIN				// Regresa a Main

/*---------------------------------------------------------------------------------------------------*/
//*******************(Sub-rutinas [no de interrupción])*******************//

	//*******************(Sub-rutina para iniciar Timer0)*******************//
INIT_TMR0:
	LDI		R16, (1 << CS02) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER0 a 1024
	LDI		R16, T0VALUE
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

	//*******************(Sub-rutina para iniciar Timer1)*******************//
INIT_TMR1:
	LDI		R16, (1 << CS12) | (1 << CS10)
	STS		TCCR1B, R16	// Setear prescaler del TIMER1 a 1024
	LDI		R16, T1HVALUE
	STS		TCNT1H, R16	// Cargar valor inicial en TCNT1H
	LDI		R16, T1LVALUE
	STS		TCNT1L, R16 // Cargar valor inicial en TCNT1L
	RET

	//*******************(Sub-rutina para iniciar Timer2)*******************//
INIT_TMR2:
	LDI		R16, (1 << CS22)
	STS		TCCR2B, R16	// Setear prescaler del TIMER2 a 64
	LDI		R16, T2VALUE
	STS		TCNT2, R16	// Cargar valor inicial en TCNT2
	RET

	//*******************(Sub-rutina para iniciar los displays)*******************//
INICIAR_DISP:	// Se modifica la dirección a la que apunta Z a la primera de la lista
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	LPM		R16, Z		// Se carga el valor guardado en la primera dirección
	OUT		PORTD, R16	// Se saca a PORTD el primer valor al que apunta Z
	RET

	//*******************(Sub-rutina de Comparación de Alarma)*******************//
COMPARE_ALARM:
	LDS		R16, UMIN
	LDS		R15, ALUMIN		// Se cargan los valores de unidades de minutos del Reloj y la Alarma
	CP		R16, R15		// Se comparan los valores de Reloj y Alarma
	BREQ	CP_DMIN			// Si son iguales salta a comparar decenas de ambos
	RET						// Regresa a donde se llamó la sub-rutina
CP_DMIN:
	LDS		R16, DMIN
	LDS		R15, ALDMIN		// Se cargan los valores de decenas de minutos del Reloj y la Alarma
	CP		R16, R15		// Se comparan los valores de Reloj y Alarma
	BREQ	CP_UHRS			// Si son iguales salta a comparar decenas de ambos
	RET						// Regresa a donde se llamó la sub-rutina
CP_UHRS:
	LDS		R16, UHRS
	LDS		R15, ALUHRS		// Se cargan los valores de unidades de horas del Reloj y la Alarma
	CP		R16, R15		// Se comparan los valores de Reloj y Alarma
	BREQ	CP_DHRS			// Si son iguales salta a comparar decenas de ambos
	RET						// Regresa a donde se llamó la sub-rutina
CP_DHRS:
	LDS		R16, DHRS
	LDS		R15, ALDHRS		// Se cargan los valores de decenas de horas del Reloj y la Alarma
	CP		R16, R15		// Se comparan los valores de Reloj y Alarma
	BREQ	ALARM_ON		// Si son iguales salta a comparar decenas de ambos
	RET						// Regresa a donde se llamó la sub-rutina
ALARM_ON:
	SBI		PINB, PB5		// Se enciende la Alarma si todos los valores fueron iguales
	RET						// Regresa a donde se llamó la sub-rutina
	
	//*******************(Sub-rutina para Apagar la Alarma)*******************//
APAGAR_ALARMA:
	SBIC	PINB, PB5		// Se compara si la alarma está encendida
	SBI		PINB, PB5		// Si la alarma está encendida, se apaga
	RET						// Regresa a donde se llamó la sub-rutina

	//*******************(Sub-rutinas para Multiplexación de Displays [Hora])*******************//
TR1_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, UMIN				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R20 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC3				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, DMIN				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC2				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, UHRS				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC1				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_TIME:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, DHRS				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

	//*******************(Sub-rutinas para Multiplexación de Displays [Fecha])*******************//
TR1_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, UDAY				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC3  			// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, DDAY				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC2				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, UMO				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC1				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_DATE:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, DMO				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

	//*******************(Sub-rutinas para Multiplexación de Displays [Alarma])*******************//
TR1_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, ALUMIN				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC3  			// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR2_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, ALDMIN				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC2				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR3_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, ALUHRS				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC1				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

TR4_ALARM:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3				// Se apagan todos los transistores
	LDS		R16, ALDHRS				// Se garga el valor que se desea mostrar
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	ADD		ZL, R16					// Se carga a Z Low el valor de R22 por medio de Suma ZL=0
	LPM		R16, Z					// Se carga el valor guardado en la dirección de Z
	OUT		PORTD, R16				// Se saca a PORTD el valor de que estaba guardado en la dirección de Z
	SBI		PORTC, PC0				// Se habilitan los transistores para sacar solamente el valor a un disp
	RET

	//*******************(Sub-rutina para Cambio de Modo)*******************//
MODE_CHANGE:
	INC		MODE			// Se incrementa el modo
	CPI		MODE, 0x01
	BREQ	MODO_2			// Se verifica si está en el segundo modo
	CPI		MODE, 0x02
	BREQ	MODO_3			// Se verifica si está en el tercer modo
	CPI		MODE, 0x03
	BREQ	MODO_4			// Se verifica si está en el cuarto modo
	CPI		MODE, 0x04
	BREQ	MODO_5			// Se verifica si está en el quinto modo
	CPI		MODE, 0x05
	BREQ	MODO_6			// Se verifica si está en el sexto modo
	CPI		MODE, 0x06
	BREQ	MODO_7			// Se verifica si está en el séptimo modo
	CPI		MODE, 0x07
	BREQ	MODO_8			// Se verifica si está en el octavo modo
	CPI		MODE, 0x09		// Se compara si hay overflow
	BREQ	OVERFLOW_MODE	// Si hay overflow, reinicia el sumador
	RET
OVERFLOW_MODE:
	LDI		MODE, 0x00		// Si hay overflow, hacemos reset al registro R20
	BREQ	MODO_1			// Salta al primer modo
	RET
MODO_1:
	SBIC	PORTC, PC4		// Se verifica si está apagado el Led
	SBI		PINC, PC4		// Si está encendido hace toggle
	SBIC	PORTB, PB4		// Se verifica si está apagado el Led
	SBI		PINB, PB4		// Si está encendido hace toggle
	SBIC	PORTB, PB3		// Se verifica si está apagado el Led
	SBI		PINB, PB3		// Si está encendido hace toggle
	RET
MODO_2:
	SBI		PINC, PC4		// Se hace toggle al Led
	RET
MODO_3:
	SBI		PINC, PC4		// Se hace toggle al Led
	SBI		PINB, PB4		// Se hace toggle al Led
	RET
MODO_4:
	SBI		PINC, PC4		// Se hace toggle al Led
	RET
MODO_5:
	SBI		PINC, PC4		// Se hace toggle al Led
	SBI		PINB, PB4		// Se hace toggle al Led
	SBI		PINB, PB3		// Se hace toggle al Led
	RET
MODO_6:
	SBI		PINC, PC4		// Se hace toggle al Led
	RET
MODO_7:
	SBI		PINC, PC4		// Se hace toggle al Led
	SBI		PINB, PB4		// Se hace toggle al Led
	RET
MODO_8:
	SBI		PINC, PC4		// Se hace toggle al Led
	RET

SUM_TIMER1:	// Suma del tiempo en el reloj
	LDS		R16, UMIN
	INC		R16	
	CPI		R16, 0x0A		// Se le suma 1 a UMIN y comparamos si hay overflow
	BREQ	SUM_DMIN		// Si llega a 10M salta a SUM_DMIN
	STS		UMIN, R16		// Se actualiza el valor de UMIN en la RAM
	CALL	COMPARE_ALARM	// Se llama a la sub-rutina de Comparación de Alarma
	RET
SUM_DMIN:
	CLR		R16
	STS		UMIN, R16		// Se reinicia UMIN y se guarda en la RAM
	LDS		R16, DMIN
	INC		R16
	CPI		R16, 0x06		// Se le suma 1 a DMIN y comparamos si hay overflow
	BREQ	SUM_UHRS		// Si llega a 1H salta a SUM_UHRS
	STS		DMIN, R16		// Se actualiza el valor de DMIN en la RAM
	CALL	COMPARE_ALARM	// Se llama a la sub-rutina de Comparación de Alarma
	RET
SUM_UHRS:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16		// Se reinician los minutos y se guarda en la RAM
	LDS		R16, DHRS
	CPI		R16, 0x02		// Se verifica si llegó a 20HRS
	BREQ	SUM_24HRS		// Si llegó a 20HRS, salta a SUM_24HRS
	LDS		R16, UHRS
	INC		R16
	CPI		R16, 0x0A		// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUM_DHRS		// Si llega a 10H salta a SUM_DHRS
	STS		UHRS, R16		// Se actualiza el valor de UHRS en la RAM
	CALL	COMPARE_ALARM	// Se llama a la sub-rutina de Comparación de Alarma
	RET
SUM_DHRS:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16		// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, DHRS
	INC		R16				// Se incrementa el valor de DHRS
	STS		DHRS, R16		// Se actualiza el valor de DHRS en la RAM
	CALL	COMPARE_ALARM	// Se llama a la sub-rutina de Comparación de Alarma
	RET
SUM_24HRS:
	LDS		R16, UHRS
	INC		R16			
	CPI		R16, 0x04		// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUM_UDAY		// Si llega a 24H salta a SUM_UDAY
	STS		UHRS, R16		// Se actualiza el valor de UHRS en la RAM
	CALL	COMPARE_ALARM	// Se llama a la sub-rutina de Comparación de Alarma
	RET
SUM_UDAY:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16			// Se reinician los minutos y las horas, y se guarda en la RAM
	LDS		R16, UDAY
	LDS		R23, DDAY
	LSL		R23
	LSL		R23
	LSL		R23
	LSL		R23			
	ADD		R23, R16			// Se sacan los valores de UDAY y DDAY y se suman en un registro
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z				// Se saca el valor de la cantidad de días que tiene el Mes actual
	CP		R23, R16
	BREQ	SUM_UMO				// Se comparan los valores de días actuales con los días del mes, si son iguales salta a SUM_MDAY
	LDS		R16, UDAY
	INC		R16
	CPI		R16, 0x0A			// Se le suma 1 a UDAY y comparamos si hay overflow
	BREQ	SUM_DDAY			// Si llega a 10D salta a SUM_DDAY
	STS		UDAY, R16			// Se actualiza el valor de DDAY en la RAM
	CALL	COMPARE_ALAR		// Se llama a la sub-rutina de Comparación de Alarma
	RET
SUM_DDAY:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16
	STS		UHRS, R16
	STS		DHRS, R16
	STS		UDAY, R16			// Se reinician los minutos, las horas y UDAY, y se guarda en la RAM
	LDS		R16, UDAY
	LDS		R23, DDAY
	LSL		R23
	LSL		R23
	LSL		R23
	LSL		R23
	ADD		R23, R16			// Se sacan los valores de UDAY y DDAY y se suman en un registro
	LDI		ZL, LOW(Meses << 1)  
	LDI		ZH, HIGH(Meses << 1)  
	ADD		ZL, MES
	LPM		R16, Z				// Se saca el valor de la cantidad de días que tiene el Mes actual
	CP		R23, R16
	BREQ	SUM_UMO				// Se comparan los valores de días actuales con los días del mes, si son iguales salta a SUM_MDAY
	LDS		R16, DDAY
	INC		R16
	STS		DDAY, R16			// Se actualiza el valor de DDAY en la RAM
	CALL	COMPARE_ALARM		// Se llama a la sub-rutina de Comparación de Alarma
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
	CALL	COMPARE_ALARM
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
	CALL	COMPARE_ALARM
	RET

SUM_YMO:
	LDS		R16, UMO
	INC		R16
	CPI		R16, 0x03
	BREQ	HAPPY_NEW_YEAR
	STS		UMO, R16
	CALL	COMPARE_ALARM
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
	CALL	COMPARE_ALARM
	RET


SUMA_UMIN:
	LDS		R16, UMIN
	INC		R16	
	CPI		R16, 0x0A	// Se le suma 1 a UMIN y comparamos si hay overflow
	BREQ	SUMA_DMIN	// Si llega a 10M salta a SUM_DMIN
	STS		UMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RET
SUMA_DMIN:
	CLR		R16
	STS		UMIN, R16	// Se reinicia UMIN y se guarda en la RAM
	LDS		R16, DMIN
	INC		R16
	CPI		R16, 0x06	// Se le suma 1 a DMIN y comparamos si hay overflow
	BREQ	OVERFLOW_MIN	// Si llega a 1H salta a OVERFLOW_MIN
	STS		DMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RET
OVERFLOW_MIN:
	CLR		R16
	STS		UMIN, R16
	STS		DMIN, R16	// Se reinician los minutos y se guardan los valores en la RAM
	RET

RES_UMIN:
	LDS		R16, UMIN
	DEC		R16	
	CPI		R16, 0xFF	// Se le resta 1 a UMIN y comparamos si hay underflow
	BREQ	RES_DMIN	// Si resta menos de 0M salta a RES_DMIN
	STS		UMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RET
RES_DMIN:
	LDI		R16, 0x09
	STS		UMIN, R16	// Se carga 0x09 a UMIN y se guarda en la RAM
	LDS		R16, DMIN
	DEC		R16
	CPI		R16, 0xFF	// Se le resta 1 a DMIN y comparamos si hay underflow
	BREQ	UNDERFLOW_MIN	// Si llega a menos de 0H salta a UNDERFLOW_MIN
	STS		DMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RET
UNDERFLOW_MIN:
	LDI		R16, 0x09
	STS		UMIN, R16
	LDI		R16, 0x05
	STS		DMIN, R16	// Se reinician los minutos y se guardan los valores en la RAM
	RET

SUMA_UHRS:
	LDS		R16, DHRS
	CPI		R16, 0x02	// Se verifica si llegó a 20HRS
	BREQ	SUMA_24HRS	// Si llegó a 20HRS, salta a SUM_24HRS
	LDS		R16, UHRS
	INC		R16
	CPI		R16, 0x0A	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUMA_DHRS	// Si llega a 10H salta a SUM_DHRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
SUMA_DHRS:
	CLR		R16
	STS		UHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, DHRS
	INC		R16
	STS		DHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RET
SUMA_24HRS:
	LDS		R16, UHRS
	INC		R16			
	CPI		R16, 0x04	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	OVERFLOW_HRS	// Si llega a 24H salta a OVERFLOW_HRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
OVERFLOW_HRS:
	CLR		R16
	STS		UHRS, R16
	STS		DHRS, R16
	RET

RES_UHRS:
	LDS		R16, UHRS
	DEC		R16
	CPI		R16, 0xFF	// Se le suma 1 a UHRS y comparamos si hay underflow
	BREQ	RES_DHRS	// Si llega a 10H salta a SUM_DHRS
	STS		UHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
RES_DHRS:
	LDI		R16, 0x09
	STS		UHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, DHRS
	DEC		R16
	CPI		R16, 0xFF
	BREQ	UNDERFLOW_HRS
	STS		DHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RET
UNDERFLOW_HRS:
	LDI		R16, 0x03
	STS		UHRS, R16
	LDI		R16, 0x02
	STS		DHRS, R16
	RET

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
	RET
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
	RET
OVERFLOW_DIA:
	LDI		R16, 0x01
	STS		UDAY, R16
	CLR		R16
	STS		DDAY, R16
	RET

RES_UDAY:
	LDS		R16, DDAY
	CPI		R16, 0x00
	BREQ	RES_MDAY
	LDS		R16, UDAY
	DEC		R16
	CPI		R16, 0xFF	// Se le suma 1 a UDAY y comparamos si hay overflow
	BREQ	RES_DDAY	// Si llega a 10D salta a SUM_DDAY
	STS		UDAY, R16	// Se actualiza el valor de DDAY en la RAM
	RET
RES_DDAY:
	LDI		R16, 0x09
	STS		UDAY, R16
	LDS		R16, DDAY
	DEC		R16
	STS		DDAY, R16
	RET
RES_MDAY:
	LDS		R16, UDAY
	DEC		R16
	CPI		R16, 0x00
	BREQ	UNDERFLOW_DIA
	STS		UDAY, R16
	RET
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
	RET

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
	RET
SUMA_DMO:
	CLR		R16
	STS		UMO, R16
	LDS		R16, DMO
	INC		R16
	STS		DMO, R16
	RET
SUMA_YMO:
	LDS		R16, UMO
	INC		R16
	CPI		R16, 0x03
	BREQ	OVERFLOW_MESES
	STS		UMO, R16
	RET
OVERFLOW_MESES:
	CLR		MES
	LDI		R16, 0x01
	STS		UMO, R16
	CLR		R16
	STS		DMO, R16
	RET

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
	RET
RES_DMO:
	LDI		R16, 0x09
	STS		UMO, R16
	LDS		R16, DMO
	DEC		R16
	STS		DMO, R16
	RET
RES_YMO:
	LDS		R16, UMO
	DEC		R16
	CPI		R16, 0x00
	BREQ	UNDERFLOW_MESES
	STS		UMO, R16
	RET
UNDERFLOW_MESES:
	LDI		MES, 0x0C
	LDI		R16, 0x02
	STS		UMO, R16
	LDI		R16, 0x01
	STS		DMO, R16
	RET

SUMA_ALUMIN:
	LDS		R16, ALUMIN
	INC		R16	
	CPI		R16, 0x0A	// Se le suma 1 a UMIN y comparamos si hay overflow
	BREQ	SUMA_ALDMIN	// Si llega a 10M salta a SUM_DMIN
	STS		ALUMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RET
SUMA_ALDMIN:
	CLR		R16
	STS		ALUMIN, R16	// Se reinicia UMIN y se guarda en la RAM
	LDS		R16, ALDMIN
	INC		R16
	CPI		R16, 0x06	// Se le suma 1 a DMIN y comparamos si hay overflow
	BREQ	OVERFLOW_ALMIN	// Si llega a 1H salta a OVERFLOW_MIN
	STS		ALDMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RET
OVERFLOW_ALMIN:
	CLR		R16
	STS		ALUMIN, R16
	STS		ALDMIN, R16	// Se reinician los minutos y se guardan los valores en la RAM
	RET

RES_ALUMIN:
	LDS		R16, ALUMIN
	DEC		R16	
	CPI		R16, 0xFF	// Se le resta 1 a UMIN y comparamos si hay underflow
	BREQ	RES_ALDMIN	// Si resta menos de 0M salta a RES_DMIN
	STS		ALUMIN, R16	// Se actualiza el valor de UMIN en la RAM
	RET
RES_ALDMIN:
	LDI		R16, 0x09
	STS		ALUMIN, R16	// Se carga 0x09 a UMIN y se guarda en la RAM
	LDS		R16, ALDMIN
	DEC		R16
	CPI		R16, 0xFF	// Se le resta 1 a DMIN y comparamos si hay underflow
	BREQ	UNDERFLOW_ALMIN	// Si llega a menos de 0H salta a UNDERFLOW_MIN
	STS		ALDMIN, R16	// Se actualiza el valor de DMIN en la RAM
	RET
UNDERFLOW_ALMIN:
	LDI		R16, 0x09
	STS		ALUMIN, R16
	LDI		R16, 0x05
	STS		ALDMIN, R16	// Se reinician los minutos y se guardan los valores en la RAM
	RET

SUMA_ALUHRS:
	LDS		R16, ALDHRS
	CPI		R16, 0x02	// Se verifica si llegó a 20HRS
	BREQ	SUMA_AL24HRS	// Si llegó a 20HRS, salta a SUM_24HRS
	LDS		R16, ALUHRS
	INC		R16
	CPI		R16, 0x0A	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	SUMA_ALDHRS	// Si llega a 10H salta a SUM_DHRS
	STS		ALUHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
SUMA_ALDHRS:
	CLR		R16
	STS		ALUHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, ALDHRS
	INC		R16
	STS		ALDHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RET
SUMA_AL24HRS:
	LDS		R16, ALUHRS
	INC		R16			
	CPI		R16, 0x04	// Se le suma 1 a UHRS y comparamos si hay overflow
	BREQ	OVERFLOW_ALHRS	// Si llega a 24H salta a OVERFLOW_HRS
	STS		ALUHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
OVERFLOW_ALHRS:
	CLR		R16
	STS		ALUHRS, R16
	STS		ALDHRS, R16
	RET

RES_ALUHRS:
	LDS		R16, ALUHRS
	DEC		R16
	CPI		R16, 0xFF	// Se le suma 1 a UHRS y comparamos si hay underflow
	BREQ	RES_ALDHRS	// Si llega a 10H salta a SUM_DHRS
	STS		ALUHRS, R16	// Se actualiza el valor de UHRS en la RAM
	RET
RES_ALDHRS:
	LDI		R16, 0x09
	STS		ALUHRS, R16	// Se reinician los minutos y UHRS, y se guarda en la RAM
	LDS		R16, ALDHRS
	DEC		R16
	CPI		R16, 0xFF
	BREQ	UNDERFLOW_ALHRS
	STS		ALDHRS, R16	// Se actualiza el valor de DHRS en la RAM
	RET
UNDERFLOW_ALHRS:
	LDI		R16, 0x03
	STS		ALUHRS, R16
	LDI		R16, 0x02
	STS		ALDHRS, R16
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
	CPI		MODE, 0x08
	BREQ	MODO_9
	RJMP	OUT_TMR2
MODO_9:
	SBI		PINC, PC4
	SBI		PINB, PB4
	SBI		PINB, PB3
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
	MOV		R27, R16
	EOR		R27, PBSTATE
	SBRC	R27, PB0	// Si el bit de PB0 cambió
	RJMP	ACTION_PB1
	SBRC	R27, PB1
	RJMP	ACTION_PB2
	SBRC	R27, PB2
	RJMP	ACTION_PB3
	
	RJMP	OUT_PB

ACTION_PB1:
	SBIS	PINB, PB0	// Y está presionado (0 lógico)
	RJMP	READ_PB0
	RJMP	OUT_PB

ACTION_PB2:
	SBIS	PINB, PB1
	RJMP	READ_PB1
	RJMP	OUT_PB

ACTION_PB3:
	SBIS	PINB, PB2
	RJMP	READ_PB2
	RJMP	OUT_PB

READ_PB0:
	LDI		PBACTION, 0x01
	RJMP	OUT_PB

READ_PB1:
	LDI		PBACTION, 0x02
	RJMP	OUT_PB

READ_PB2:
	LDI		PBACTION, 0x03
	RJMP	OUT_PB


OUT_PB:
	MOV		PBSTATE, R16
	POP		R16
	OUT		SREG, R16
	POP		R16			// Se saca el valor de r16 y del SREG de la pila
	RETI
	