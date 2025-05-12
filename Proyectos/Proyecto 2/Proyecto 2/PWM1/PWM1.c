/*
 * PWM1.c
 *
 * Created: 4/22/2025 6:16:52 PM
 *  Author: edvin
 */ 

#include <avr/io.h>

void initPWM1AB()
{
	TCCR1A	|= (1 << COM1A1); // No invertido en A
	TCCR1A	|= (1 << COM1B1); // No invertido en B

	TCCR1A	|= (1 << WGM10);
	TCCR1B	|= (1 << WGM12); // Fast PWM, Top = 0x00FF
	
	TCCR1B	|= (1 << CS11) | (1 << CS10);	// Prescaler = 64
}

uint16_t ADC_to_PWM_ServoT1A(uint8_t lec_adc)
{
	return (lec_adc * 35UL / 255)/2 + 5; 	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}

uint16_t ADC_to_PWM_ServoT1B(uint8_t lec_adc)
{
	return (lec_adc * 35UL / 255)/3 + 5; 	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}

void updateDutyCycle_T1A(uint16_t duty)
{
	OCR1A = duty;	// Se actualiza el bit del duty cycle
}

void updateDutyCycle_T1B(uint16_t duty)
{
	OCR1B = duty;	// Se actualiza el bit del duty cycle
}