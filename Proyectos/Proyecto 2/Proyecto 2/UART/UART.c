/*
 * UART.c
 *
 * Created: 5/4/2025 8:03:52 PM
 *  Author: edvin
 */ 
#include <avr/io.h>

void initUART()	// Funci�n de inicio de UART
{
	// Paso 1: Configurar pines PD0 (rx) y PD1 (tx)
	DDRD	|= (1 << DDD1);
	DDRD	&= ~(1 << DDD0);
	
	// Paso 2: Configurar UCSR0A
	UCSR0A |= (1 << U2X0);
	
	// Paso 3: Configurar UCSR0B, Habilitando interrupts al recibir; Habilitando recepci�n; Habilitando transmisi�n
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	
	// Paso 4: UCSR0C
	UCSR0C |= (1 << UCSZ00) | (1 << UCSZ01);
	
	// Paso 5: UBRR0: UBRR0 = 103 -> 9600 @ 16MHz
	UBRR0 = 12;
}

void writeChar(char caracter)	// Funci�n para escribir un caracter
{
	while ((UCSR0A & (1 << UDRE0)) == 0);  // Esperar a que el registro de datos est� vac�o
	UDR0 = caracter;  // Enviar el caracter al registro de UART
}

void escribir_cadena (char* cadena)	// Funci�n para escribir una cadena
{
	for (uint8_t puntero = 0; *(cadena+puntero) != '\0'; puntero++)  // Itera sobre cada car�cter de la cadena
	{
		writeChar(*(cadena+puntero));  // Enviar cada car�cter a trav�s de UART
	}
}

uint8_t ascii_to_int(char* i)	// Funci�n para convertir de ascii a int
{
	int resultado = 0;	// Se declara e inicializa una variable para guardar el resultado de la conversi�n
	while (*i >= '0' && *i <= '9')	// Se mantiene en el while siempre que el d�gito al que apunte sea un n�mero (termina si detecta \n o \0 por ejemplo)
	{
		resultado = resultado * 10 + (*i - '0');	// Toma el ascii, lo convierte en d�gito y lo ordena en sistema decimal
		i++;	// suma al caracter a convertir
	}
	return resultado;	// Se retorna el valor del resultado de la conversi�n
}

void enviar_valor_uart(uint16_t valor, char *prefijo)	// Funci�n para enciar UART (Feedback)
{
	uint8_t update[3];				// Se declara una lista para guardar el ascii convertido
	update[0] = valor % 10;			// Se separan las unidades
	update[1] = (valor % 100) / 10;	// Se separan las decenas
	update[2] = valor / 100;		// Se separan las centenas

	escribir_cadena(prefijo);		// Se manda el prefijo para interpretaci�n usando escribir_cadena
	writeChar(update[2] + '0');		// Se env�an las centenas traducidas a ascii
	writeChar(update[1] + '0');		// Se env�an las decenas traducidas a ascii
	writeChar(update[0] + '0');		// Se env�an las unidades traducidas a ascii
}
