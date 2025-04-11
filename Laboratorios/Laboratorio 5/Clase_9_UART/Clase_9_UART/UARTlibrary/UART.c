/*
 * UART.c
 *
 * Created: 4/9/2025 5:39:17 PM
 *  Author: edvin
 */ 

#include <avr/io.h>

void initUART()
{
	// Paso 1: Configurar pines PD0 (rx) y PD1 (tx)
	DDRD	|= (1 << DDD1);
	DDRD	&= ~(1 << DDD0);
	
	// Paso 2: Configurar UCSR0A
	UCSR0A = 0;
	
	// Paso 3: Configurar UCSR0B, Habilitando interrupts al recibir; Habilitando recepción; Habilitando transmisión
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	
	// Paso 4: UCSR0C
	UCSR0C |= (1 << UCSZ00) | (1 << UCSZ01);
	
	// Paso 5: UBRR0: UBRR0 = 103 -> 9600 @ 16MHz
	UBRR0 = 103;
}

void writeChar(char caracter)
{
	// uint16_t temporal = UCSR0A & (1 << UDRE0);
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter;
}

void writeString(char* texto)
{
	for (uint8_t i = 0; *(texto+i) != '\0'; i++)
	{
		writeChar(*(texto+i));
	}
}
