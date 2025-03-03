;
; Clase260225.asm
;
; Created: 2/26/2025 4:12:21 PM
; Author : edvin
;


.include	"M328PDEF.inc"
.equ	T1Value = 0xE17B

.cseg
.org	0x0000
	JMP START

.org	OVFladdr

SETUP:
	
