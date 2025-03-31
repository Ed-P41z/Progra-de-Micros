/*
 * PruebaADC.c
 *
 * Created: 3/26/2025 4:52:14 PM
 * Author: edvin
 * Description: Después xd
 */
//
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>

//*********************************************
// Function prototypes
void setup();
void initADC();

//*********************************************
// Main Function

int main(void)
{
	while(1)
	{
	}
	
}

//*********************************************
// NON-Interrupt subroutines
void setup()
{
	cli();
	// Configurar presclaer de sistema
	CLKPR	= (1 << CLKPCE);
	CLKPR	= (1 << CLKPS2); // 16 PRESCALER -> 1MHz
	
	DDRD	= 0xFF;
	UCSR0B	= 0x00;
	
	initADC();
	
	ADCSRA	|= (1 << ADSC);
	
	sei();
}

void	 initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);
	//ADMUX	&= ~(1 << REFS1);  No es indispensable
	ADMUX	|= (1 << ADLAR);
	ADMUX	|= (1 << MUX2) | (1 << MUX1); // Todo esto se puede hacer en una línea
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);
	ADCSRA	|= (1 << ADIE);
	ADCSRA	|= (1 << ADEN); // También se puede hacer en una línea	
}
//*********************************************
// Interrupt routines
ISR(ADC_vect)
{
	PORTD	= ADCH;
	ADCSRA	|= (1 << ADSC);
}
