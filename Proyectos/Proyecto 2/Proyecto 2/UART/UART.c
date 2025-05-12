/*
 * UART.c
 *
 * Created: 5/4/2025 8:03:52 PM
 *  Author: edvin
 */ 
#include <avr/io.h>

void initUART()
{
	// Paso 1: Configurar pines PD0 (rx) y PD1 (tx)
	DDRD	|= (1 << DDD1);
	DDRD	&= ~(1 << DDD0);
	
	// Paso 2: Configurar UCSR0A
	UCSR0A |= (1 << U2X0);
	
	// Paso 3: Configurar UCSR0B, Habilitando interrupts al recibir; Habilitando recepción; Habilitando transmisión
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	
	// Paso 4: UCSR0C
	UCSR0C |= (1 << UCSZ00) | (1 << UCSZ01);
	
	// Paso 5: UBRR0: UBRR0 = 103 -> 9600 @ 16MHz
	UBRR0 = 12;
}

void writeChar(char caracter)
{
	while ((UCSR0A & (1 << UDRE0)) == 0);  // Esperar a que el registro de datos esté vacío
	UDR0 = caracter;  // Enviar el caracter al registro de UART
}

void escribir_cadena (char* cadena)
{
	for (uint8_t puntero = 0; *(cadena+puntero) != '\0'; puntero++)  // Itera sobre cada carácter de la cadena
	{
		writeChar(*(cadena+puntero));  // Enviar cada carácter a través de UART
	}
}

uint8_t ascii_to_int(char* i) {
	int resultado = 0;
	while (*i >= '0' && *i <= '9') {
		resultado = resultado * 10 + (*i - '0');
		i++;
	}
	return resultado;
}
