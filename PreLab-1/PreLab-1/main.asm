/*
*	PreLab-1.asm
*
*	Creado: 2/2/2025 7:02:46 PM
*	Autor: Edvin Paiz
*	Descripción: El prelab 1 consiste en un sumador con antirebotes integrado
*/
.include "M328PDEF.inc"

.cseg
.org 0x0000

// Se configura la pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16

// Se configura el MCU
SETUP:
	// Se realiza la configuración del prescaler al valor deseado
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16	// Se haiblita la configuracion del prescaler
	LDI		R16, 0x04
	STS		CLKPR, R16	// Se configura el prescaler a 1MHz

	// Se configuran pines de entrada y salida (DDRx, PORTx, PINx)
	// Se configura PORTB como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRB, R16	// Se configura el puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16	// Se configuran los pines con pull-up activado

	// Se configura PORTD y PORTD como salida inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16	// Se configura el puerto D como salida
	OUT		DDRC, R16	// Se configura el puerto C como salida
	LDI		R16, 0x00
	OUT		PORTC, R16
	OUT		PORTD, R16	// Se configuran los pines para estar inicialmente apagados

	LDI		R17, 0xFF	// Variable para guardar estado de botones
	LDI		R20, 0x00	// Variable para guardar estado de Leds contador 1
	LDI		R21, 0x00	// Variable para guardar estado de Leds contador 2

// Loop infinito
MAIN:
	IN		R16, PINB	// Se guarda el estado de PORTB en R16
	CP		R17, R16	// Compara el estado anterior con el estado actual del pb1
	BREQ	MAIN		// Si es el mismo estado repite los dos pasos anteriores
	CALL	DELAY
	IN		R16, PINB	// Lee nuevamente R16 para ver si no fue un error de lectura
	CP		R17, R16
	BREQ	MAIN		// Si fue un error de lectura regresa a MAIN
	MOV		R17, R16	// Guardamos el valor de la lectura anterior en R17
	SBIS	PINB, 0		
	CALL	SUMA_C1		// Comprobamos que se presiona pb1, sí: suma_c1, no: ignora
	SBIS	PINB, 1
	CALL	RESTA_C1	// Comprobamos que se presiona pb2, sí: resta_c1, no: ignora
	SBIS	PINB, 2
	CALL	SUMA_C2		// Comprobamos que se presiona pb3, sí: suma_c2, no: ignora
	SBIS	PINB, 3
	CALL	RESTA_C2	// Comprobamos que se presiona pb4, sí: resta_c2, no: ignora
	SBIS	PINB, 4
	CALL	SUMA_CONT	// Comprobamos que se presiona pb5, sí: suma_cont, no:ignora
	RJMP	MAIN

// Sub-rutina (no de interrupcion)
DELAY: // Se realiza un delay como medida antirrebote
	LDI		R18, 0xFF
	LDI		R19, 0xFF	// Cargamos los valores necesarios a dos registros
SUB_DELAY:
	DEC		R18
	CPI		R18, 0		
	BRNE	SUB_DELAY	// Se resta 1 a R18 hasta que llegue a 0 y ignora el BRNE
	DEC		R19
	CPI		R19, 0		// Se resta 1 a R19 hasta que llegue a 0	
	RET					// Al llegar R19 a 0 regresa a MAIN: CALL

CONT_PORTD:
	MOV		R22, R21	// Guardamos el dato de R21 en R22 para imprimir en PORTD
	LSL		R22
	LSL		R22
	LSL		R22
	LSL		R22			// Se corren los bits de R21 para usar solo PORTD
	ADD		R22, R20	// Se suman los dos contadores en una variable
	OUT		PORTD, R22	// Se imprime el valor de los contadores en PORTD
	RET

SUMA_C1: // Se realiza la suma en R20 como sub-rutina
	INC		R20
	CPI		R20, 0x10	// Le sumamos 1 a R20 y comparamos si hay overflow
	BREQ	OVERFLOW_SUMC1	// Si hay overflow, reinicia el sumador
	CALL	CONT_PORTD
	RET
OVERFLOW_SUMC1:
	LDI		R20, 0X00	// Si hay overflow, hacemos reset al registro R20
	CALL	CONT_PORTD
	RET

RESTA_C1: // Se realiza la resta en R20 como sub-rutina
	DEC		R20
	CPI		R20, 0xFF	// Le restamos 1 a R20 y comparamos si hay underflow
	BREQ	UNDERFLOW_RESC1		// Si hay underflow, setea el sumador
	CALL	CONT_PORTD
	RET
UNDERFLOW_RESC1:
	LDI		R20, 0X0F	// Si hay underflow, hacemos set al registro R20
	CALL	CONT_PORTD
	RET

SUMA_C2: // Se realiza la suma en R21 como sub-rutina
	INC		R21
	CPI		R21, 0x10	// Le sumamos 1 a R21 y comparamos si hay overflow
	BREQ	OVERFLOW_SUMC2	// Si hay overflow, reinicia el sumador
	CALL	CONT_PORTD
	RET
OVERFLOW_SUMC2:
	LDI		R21, 0X00	// Si hay overflow, hacemos reset al registro R21
	CALL	CONT_PORTD
	RET

RESTA_C2: // Se realiza la resta en R21 como sub-rutina
	DEC		R21
	CPI		R21, 0xFF	// Le restamos 1 a R21 y comparamos si hay underflow
	BREQ	UNDERFLOW_RESC2		// Si hay underflow, setea el sumador
	CALL	CONT_PORTD
	RET
UNDERFLOW_RESC2:
	LDI		R21, 0X0F	// Si hay underflow, hacemos set al registro R21
	CALL	CONT_PORTD
	RET

SUMA_CONT:
	MOV		R23, R21	// Se carga el valor del contador 2 al registro R23 
	ADD		R23, R20	// Se realiza la suma del contador 1 y 2 en R23
	OUT		PORTC, R23	// Se imprime el valor de la suma a PORTC
	/* Debido a que la suma puede generar como máximo un valor de 0x1E,
	   se utiliza el bit 5 como referencia para verificar si existe overflow. */
	RET