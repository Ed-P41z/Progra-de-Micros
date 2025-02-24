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


