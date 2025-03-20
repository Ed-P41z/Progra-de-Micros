/*
 * EjemploEnC.c
 *
 * Created: 3/19/2025 5:38:12 PM
 * Author: edvin
 * Description: 
 */
//*********************************************
// Encabezado (Libraries)
#define F_CPU 16000000

#include <avr/io.h>
#include <avr/interrupt.h>

uint8_t	counter_10ms;

//*********************************************
// Function prototypes
void setup();
void initTMR0();
	
//*********************************************
// Main Function
int main(void)
{
	setup();
	/* Replace with your application code */
	while (1)
	{
	}
}

//*********************************************
// NON-Interrupt subroutines
void setup()
{
	cli();
	DDRB	= 0xFF;		// Configurar PORTB como salida
	PORTB	= 0xFF;		// Configurar PORTB como encendido
	initTMR0();
	counter_10ms = 0;
	sei();
}

void initTMR0()
{
	TCCR0A	= 0;
	TCCR0B	|= (1 << CS02) | (1 << CS00);
	TCNT0	= 100;
	TIMSK0	=  (1 << TOIE0);
}

//*********************************************
// Interrupt routines

ISR(TIMER0_OVF_vect)
{
	TCNT0 = 100;
	counter_10ms++;
	if (counter_10ms == 50)
	{
		PORTB++;
		PORTB &= 0x0F;
		counter_10ms = 0;
	}
	
}

