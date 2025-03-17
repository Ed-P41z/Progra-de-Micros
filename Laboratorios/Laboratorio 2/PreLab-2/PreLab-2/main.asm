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

// Se configura la pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

Disp_Hex:	.DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
//				 0		1	 2	   3	 4	   5	 6	   7	 8	   9	 A	   B	 C	   D     E     F

SETUP:
	// Se realiza la configuración del prescaler
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se habilita el cambio del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz
	CALL	INIT_TMR0	// Se inicia el timer 0 (es el timer que usaré)

	// Desabilitar el serial
	LDI R16, 0x00
	STS UCSR0B, R16

	// Se configuran pines de entrada y salida (DDRx, PORTx, PINx)
	// Se configura PORTD y PORTC como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16	// Se configura el puerto D como salida
	OUT		DDRC, R16	// Se configura el puerto D como salida
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
	LDI		R21, 0x00	// Variable para guardar estado de Leds timer
	LDI		R22, 0xFF	// Variable para guardar estado de botones

	CALL	INICIAR_DISP

// Loop infinito
MAIN:
	// Anti-Rebotes y sumador del display
	IN		R16, PINB	// Se guarda el estado de PORTB en R16
	CP		R22, R16	// Compara el estado anterior con el estado actual del pb
	BREQ	TIMER		// Si es el mismo estado salta a timer para que realice la suma a los 100ms
	CALL	DELAY
	IN		R16, PINB	// Lee nuevamente R16 para ver si no fue un error de lectura
	CP		R22, R16
	BREQ	TIMER		// Si fue un error de lectura salta a timer para realizar la suma a los 100ms
	MOV		R22, R16	// Guardamos el valor de la lectura anterior en R22
	SBIS	PINB, 0		
	CALL	SUMA		// Comprobamos que se presiona pb1, sí: suma, no: ignora
	SBIS	PINB, 1
	CALL	RESTA		// Comprobamos que se presiona pb2, sí: resta, no: ignora

// Timer es solamente una etiqueta que usé para poder alternar entre la suma con tiempo y la verificación de los botones
TIMER:
	// Timer0 con sumador cada segundo
	IN		R16, TIFR0	// Se lee la bandera del registro de interrupción
	SBRS	R16, TOV0	// Se verifica que la bandera de overflow está encendida
	RJMP	MAIN		// Si está apagada la bandera, regresa al inicio del loop (MAIN)
	SBI		TIFR0, TOV0	// Si está encendida la bandera, salta a apagarla
	LDI		R16, 158
	OUT		TCNT0, R16	// Se vuelve a cargar un valor inicial a Timer0 
	INC		R17			// Incrementa cada 100ms
	CPI		R17, 10		// Se compara con 10 para verificar si pasó 1 seg
	BRNE	MAIN		// Si no ha pasado 1 seg regresa a MAIN
	CLR		R17			// Si ya pasó 1 seg limpia el registro del contador de reloj
	CALL	SUMA_T
	CALL	COMPARE		// Se hacen las subrutinas de suma y comparación de igualdad
	RJMP	MAIN


// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI		R16, (1 << CS02) | (1 << CS00)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER 0 a 64
	LDI		R16, 158
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	RET

DELAY: // Se realiza un delay como medida antirrebote
	LDI		R18, 0xFF
	LDI		R19, 0x01	// Cargamos los valores necesarios a dos registros
SUB_DELAY:
	DEC		R18
	CPI		R18, 0		
	BRNE	SUB_DELAY	// Se resta 1 a R18 hasta que llegue a 0 y ignora el BRNE
	DEC		R19
	CPI		R19, 0		// Se resta 1 a R19 hasta que llegue a 0	
	BRNE	SUB_DELAY
	RET					// Al llegar R19 a 0 regresa a MAIN: CALL

INICIAR_DISP:	// Se modifica la dirección a la que apunta Z a la primera de la lista
	LDI		ZL, LOW(Disp_Hex << 1)	
	LDI		ZH, HIGH(Disp_Hex << 1)	// Se apunta a la primera dirección de Z
	LPM		R16, Z	// Se carga el valor guardado en la primera dirección
	OUT		PORTD, R16	// Se saca a PORTD el primer valor al que apunta Z
	RET

SUMA: // Se realiza la suma en R20 como sub-rutina
	ADIW	Z, 1		// Se le suma 1 al valor al que apunta Z
	INC		R20
	CPI		R20, 0x10	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW	// Si hay overflow, reinicia el sumador
	LPM		R16, Z
	OUT		PORTD, R16	// Sacamos el valor guardado en Z a PORTD
	RET
OVERFLOW:
	LDI		R20, 0x00	// Si hay overflow, hacemos reset al registro R20
	CALL	INICIAR_DISP	// Se llama a la subrutina que reinicia el puntero de Z
	RET

RESTA: // Se realiza la resta en R20 como sub-rutina
	SBIW	Z, 1		// Se le resta 1 al valor al que apunta Z
	DEC		R20
	CPI		R20, 0xFF	// Le restamos 1 a R20 y comparamos si hay underflow
	BREQ	UNDERFLOW	// Si hay underflow, setea el sumador
	LPM		R16, Z
	OUT		PORTD, R16	// Sacamos el valor guardado en Z a PORTD
	RET
UNDERFLOW:
	LDI		R20, 0x0F	// Si hay underflow, dejamos en reset al registro R20
	CALL	INICIAR_DISP	// Se llama a la subrutina que reinicia el puntero de Z
	ADIW	Z, 15		// Se le carga al puntero la última dirección donde se guarda un valor en la lista
	LPM		R16, Z
	OUT		PORTD, R16	// Sacamos el valor guardado en Z a PORTD
	RET

SUMA_T:	// Se suma el contador que lleva el timer0
	INC		R21			// Se suma 1 al contador
	CPI		R21, 0x10	// Se verifica si hay overflow
	BREQ	OVERFLOW_T
	OUT		PORTC, R21	// Si no hay overflow se saca el valor a PORTC
	RET
OVERFLOW_T:
	LDI		R21, 0x00
	OUT		PORTC, R21	// Si hay overflow se regresa e valor a 0 y se saca a PORTC
	RET

COMPARE:
	CP		R20, R21	// Se compara su R20 y R21 son iguales
	BREQ	IGUAL		// Si son iguales salta a IGUAL
	RET					// Si no son iguales regresa al call de donde se llamó la sub-rutina
IGUAL:
	SBI     PINB, PB5	// Si son iguales se hace toggle al led del PINB
	LDI		R21, 0x00
	OUT		PORTC, R21	// Se reinicia el estado de los LEDS
    RET
