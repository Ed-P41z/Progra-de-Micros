/*
 * PWM0.c
 *
 * Created: 4/22/2025 6:16:14 PM
 *  Author: edvin
 */ 

#include <avr/io.h>

void initPWM0AB()
{
	TCCR0A	|= (1 << COM0A1); // No invertido en A
	TCCR0A	|= (1 << COM0B1); // No invertido en B

	TCCR0A	|= (1 << WGM00) | (1 << WGM01); // Fast PWM, Top = 0x00FF
	
	TCCR0B	|= (1 << CS01) | (1 << CS00);	// Prescaler = 64
}

uint16_t ADC_to_PWM_ServoT0(uint8_t lec_adc)
{
	return (lec_adc * 35UL / 255) + 5; 	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}

void updateDutyCycle_T0A(uint16_t duty)
{
	OCR0A = duty;	// Se actualiza el bit del duty cycle
}

void updateDutyCycle_T0B(uint16_t duty)
{
	OCR0B = duty;	// Se actualiza el bit del duty cycle
}

