/*
 * Clase_9_UART.c
 *
 * Created: 4/9/2025 4:51:57 PM
 * Author : edvin
 * Description: Después lo pongo xd
 */ 
//*******************************************
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include "UARTlibrary/UART.h"

//*******************************************
// Function prototypes
void setup();


//*******************************************
// Main Function
int main(void)
{
	setup();
	writeChar('H');
	writeChar('o');
	writeChar('l');
	writeChar('a');
	writeString("Ustedes \n tienen tarea para semana santa");
	while (1)
	{
		
	}
}


//*******************************************
// NON-Interrupt subroutines
void setup()
{
	cli ();
	initUART();
	sei();
}


//*******************************************
// Interrupt routines
ISR(USART_RX_vect)
{
	char temporal = UDR0;
	writeChar('T');
	writeChar('e');
	writeChar('x');
	writeChar('t');
	writeChar('o');
	writeChar(':');
	writeChar(' ');
	writeChar(temporal);
}
