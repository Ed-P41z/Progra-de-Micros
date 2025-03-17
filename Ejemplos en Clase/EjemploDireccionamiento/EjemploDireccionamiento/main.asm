;
; EjemploDireccionamiento.asm
;
; Created: 2/5/2025 4:09:36 PM
; Author : edvin
;


.include "M328PDEF.inc"
.cseg
.org 0x0000

LDI		R16, LOW(RAMEND)
OUT		SPL, R16
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16


/*
LDI		R16, 0x20
LDI		R17, 0x25

LDI		XL, 0x00
LDI		XH, 0x01
ST		X, R17


LDI		R18, 1
ADD		XL, R18
ST		X, R17


COPIAR:
	// ADIW	X, 1
	ST		X+, R17
	DEC		R16
	BRNE	COPIAR
	*/

TABLA7SEG:	.DB		0x7E, 0x30, 0x6D, 0x79
mytable:	.DB	"Hola Mundo! "

SETUP:
	LDI		ZL, LOW(mytable << 1)
	LDI		ZH, HIGH(mytable << 1)
	LPM		R16, Z

MAIN:
	LPM		R18, Z+
	CPI		R18, '!'
	BREQ	TERMINAR
	ST		X+, R18
	RJMP	MAIN_LOOP

TERMINAR:
	RJMP	TERMINAR