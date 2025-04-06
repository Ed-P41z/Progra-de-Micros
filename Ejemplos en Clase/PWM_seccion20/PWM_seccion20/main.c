/*
 * PWM_seccion20.c
 *
 * Created: 4/2/2025 4:36:14 PM
 * Author: edvin
 * Description: Pedro Lore
 */
//**************************************************
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/delay.h>
#define invert 1
#define non_invert 0

uint8_t dutyCycle = 100;

//**************************************************
// Function prototypes
void setup();
void initPWM0A(uint8_t invertido, uint16_t perscaler);
void updateDutyCycle(dutyCycle);

//**************************************************
// Main Function
int main(void)
{
	setup();
	updateDutyCycle(dutyCycle);
	while (1)
	{
		updateDutyCycle(dutyCycle);
		
	}
}

//**************************************************
// NON-Interrupt subroutines
void setup()
{
	cli();
	// PORTB = (1 << PORTB5); IMPORTANTE NO PONER PB5, PONER EL NOMBRE EN LA LIBRERIA
	CLKPR	= (1 << CLKPCE);
	CLKPR	= (1 << CLKPS2); // 1MHz
	
	initPWM0A(invert, 8);
	
	UCSR0B	= 0;
	sei();
}

void initPWM0A(uint8_t invertido, uint16_t perscaler)
{
	DDRD	|= (1 << DDD6);
	
	TCCR0A	&= ~((1 << COM0A1) | (1 << COM0A0));

	if (invertido == invert)
	{
		TCCR0A	|= (1 << COM0A1) | (1 << COM0A0); // Invertido
	} else
	{
		TCCR0A	|= (1 << COM0A1); // No invertido
	}
	

	TCCR0A	|= (1 << WGM01) | (1 << WGM00); // Modo 3 -> Fast PWM y top = 0xFF
	
	TCCR0B	&= ~((1 << CS02) | (1 << CS01) | (1 << CS00));
	switch(perscaler){
		case 1:
			TCCR0B	|= (1 << CS00); 
			break;
		case 8:
			TCCR0B	|= (1 << CS01); 
			break;
		case 64:
			TCCR0B	|= (1 << CS01) | (1 << CS00); 
			break;
		case 256:
			TCCR0B	|= (1 << CS02);
			break;
		case 1024:
			TCCR0B	|= (1 << CS02) | (1 << CS00);
			break;
	}
	TCCR0B	|= (1 << CS01); // 8
}

void updateDutyCycle(uint8_t dutyCycle)
{
	OCR0A	= dutyCycle;
}

//**************************************************
// Interrupt routines
