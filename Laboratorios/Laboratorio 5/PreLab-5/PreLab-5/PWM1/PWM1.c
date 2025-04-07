/*
 * PWM1.c
 *
 * Created: 4/6/2025 8:04:37 PM
 *  Author: edvin
 */ 

#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

void initPWM0A(uint8_t invertido, uint16_t perscaler)
{
	TCCR1A	&= ~((1 << COM1A1) | (1 << COM1A0));	// Se apagan los bits de configuración del TMR1

	if (invertido == 1)
	{
		TCCR1A	|= (1 << COM1A1) | (1 << COM1A0); // Invertido
	} else
	{
		TCCR1A	|= (1 << COM1A1); // No invertido
	}
	

	TCCR1A	|= (1 << WGM10); 
	TCCR1B	|= (1 << WGM12);	// Fast PWM y top = 0x00FF
	
	TCCR1B	&= ~((1 << CS12) | (1 << CS11) | (1 << CS10));	// Se apagan los bits de configuración del Prescaler
	switch(perscaler){
		case 1:
		TCCR1B	|= (1 << CS10);	// 1
		break;
		case 8:
		TCCR1B	|= (1 << CS11);	// 8
		break;
		case 64:
		TCCR1B	|= (1 << CS11) | (1 << CS10);	// 64
		break;
		case 256:
		TCCR1B	|= (1 << CS12);	// 256
		break;
		case 1024:
		TCCR1B	|= (1 << CS12) | (1 << CS10);	// 1024
		break;
	}
}

void updateDutyCycle_T1(uint8_t duty)
{
	OCR1A = duty;	// Se actualiza el bit del duty cycle
}
