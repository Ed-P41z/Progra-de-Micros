/*
 * PWM0.c
 *
 * Created: 4/22/2025 6:16:14 PM
 *  Author: edvin
 */ 

#include <avr/io.h>

void initPWM0AB()	// Función para iniciar PWM 0, canales A y B
{
	TCCR0A	|= (1 << COM0A1); // No invertido en A
	TCCR0A	|= (1 << COM0B1); // No invertido en B

	TCCR0A	|= (1 << WGM00) | (1 << WGM01); // Fast PWM, Top = 0x00FF
	
	TCCR0B	|= (1 << CS01) | (1 << CS00);	// Prescaler = 64
}

uint16_t ADC_to_PWM_ServoT0A(uint8_t lec_adc)	// Función para convertir valor ADC a valor PWM0A
{
	return (lec_adc * 35UL / 255) + 5; 	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}

uint16_t ADC_to_PWM_ServoT0B(uint8_t lec_adc)	// Función para convertir valor ADC a valor PWM0B
{
	return (lec_adc * 35UL / 255)/3 + 5; 	// Se realiza la conversión, tomando en cuenta los límites superior e inferior calculados para el servo
}


void updateDutyCycle_T0A(uint16_t duty)	// Función para actualizar el duty cycle del PWM0A
{
	OCR0A = duty;	// Se actualiza el bit del duty cycle
}

void updateDutyCycle_T0B(uint16_t duty)	// Función para actualizar el duty cycle del PWM0B
{
	OCR0B = duty;	// Se actualiza el bit del duty cycle
}

