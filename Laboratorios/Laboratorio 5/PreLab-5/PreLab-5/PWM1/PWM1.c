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

void initPWM1A(uint8_t invertido, uint16_t perscaler)
{
	TCCR1A	&= ~((1 << COM1A1) | (1 << COM1A0));	// Se apagan los bits de configuración del TMR1

	if (invertido == 1)
	{
		TCCR1A	|= (1 << COM1A1) | (1 << COM1A0); // Invertido
	} else
	{
		TCCR1A	|= (1 << COM1A1); // No invertido
	}
	

	TCCR1A	|= (1 << WGM11); 
	TCCR1B	|= (1 << WGM13) | (1 << WGM12);	
	ICR1 = 2499; // Fast PWM y top = 0x09C3
	
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

void updateDutyCycle_T1(uint16_t duty)
{
	OCR1A = duty;	// Se actualiza el bit del duty cycle
}

uint16_t ADC_to_PWM_ServoT1(uint8_t lec_adc) // (312-69)
{
	return (lec_adc * 239UL / 255) + 69;	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}