/*
 * PWM0.c
 *
 * Created: 4/15/2025 11:36:00 PM
 *  Author: edvin
 */ 

#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

void initPWM0A() // PWM0 manual usando timer0
{
	// El prescaler es el mismo del timer1 así que solamente le cargaré el mismo valor para que no haya problemas de prescaler
	TCCR0A	|= 0;
	TCCR0B	|= (1 << CS00); // Prescaler = 8
	TIMSK0	= (1 << TOIE0) | (1 << OCIE0A);
	//TCNT0	= 251;
}

void pwm0_cp(uint8_t top, uint8_t compare)
{
	
	if (top < compare)
	{
		PORTD |= (1 << PORTD2);
	}
	else
	{
		PORTD &= ~(1 << PORTD2);	
	}
}

uint8_t adc0_map(uint8_t lec_adc0)
{
	return (lec_adc0 * 200UL) / 255;
}
