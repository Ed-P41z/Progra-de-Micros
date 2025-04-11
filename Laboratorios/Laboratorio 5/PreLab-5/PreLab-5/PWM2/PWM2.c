/*
 * PWM2.c
 *
 * Created: 4/7/2025 4:43:03 PM
 *  Author: edvin
 */ 
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

void initPWM2A(uint8_t invertido, uint16_t perscaler)
{
	TCCR2A	&= ~((1 << COM2A1) | (1 << COM2A0));	// Se apagan los bits de configuración del TMR1

	if (invertido == 1)
	{
		TCCR2A	|= (1 << COM2A1) | (1 << COM2A0); // Invertido
	} else
	{
		TCCR2A	|= (1 << COM2A1); // No invertido
	}
	

	TCCR2A	|= (1 << WGM21) | (1 << WGM20);
		
	TCCR2B	&= ~((1 << CS22) | (1 << CS21) | (1 << CS20));	// Se apagan los bits de configuración del Prescaler
	switch(perscaler){
		case 1:
		TCCR2B	|= (1 << CS20);	// 1
		break;
		case 8:
		TCCR2B	|= (1 << CS21);	// 8
		break;
		case 32:
		TCCR2B	|= (1 << CS21) | (1 << CS20);	// 32
		break;
		case 64:
		TCCR2B	|= (1 << CS22);	// 64
		break;
		case 128:
		TCCR2B	|= (1 << CS22) | (1 << CS20);	// 128
		break;
		case 256:
		TCCR2B	|= (1 << CS22) | (1 << CS21);	// 256
		break;
		case 1024:
		TCCR2B	|= (1 << CS22) | (1 << CS21) | (1 << CS20);	// 1024
		break;
	}
}

void updateDutyCycle_T2(uint16_t duty)
{
	OCR2A = duty;	// Se actualiza el bit del duty cycle
}

uint16_t ADC_to_PWM_ServoT2(uint8_t lec_adc)
{
	return (lec_adc * 220UL / 255) + 50;	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}
