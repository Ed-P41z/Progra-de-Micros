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



