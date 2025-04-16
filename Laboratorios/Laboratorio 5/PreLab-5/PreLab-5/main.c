/*
 * PreLab-5.c
 *
 * Created: 4/5/2025 11:03:53 PM
 * Author : edvin
 * Description: El prelab consiste en modificar el brillo de un led con un potenciómetro
 */ 
//*********************************************
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "PWM0-Manual/PWM0.h"
#include "PWM1/PWM1.h"
#include "PWM2/PWM2.h"

uint8_t adc_read;
uint16_t dutyCycle;
uint16_t adc_map;
uint8_t counter_ADC;
uint8_t pwm0_counter;
uint8_t pwm0_map;
uint8_t pwm0_adc;

//*********************************************
// Function prototypes
void setup();
void initADC();

//*********************************************
// Main Function

int main(void)
{
	setup();	// Se manda a llamar la función de Setup
	
	while(1)	// Entra al bucle infinito en donde se ejecuta el programa
	{
	}	
}

//*********************************************
// NON-Interrupt subroutines
void setup()
{
	cli(); // Se apagan las interruciones globales
	
	// Configurar presclaer de sistema
	CLKPR	= (1 << CLKPCE);
	CLKPR	= (1 << CLKPS2); // 16 PRESCALER -> 1MHz
	
	// Configuración de Pines
	DDRD	= 0xFF;			// Se configura PORTD como salida
	PORTD	= 0x00;			// PORTD inicialmente apagado
	DDRB	= 0xFF;			// Se configura PORTD como salida
	PORTB	= 0x00;			// PORTD inicialmente apagado
	DDRC	= 0x00;			// Se configura PORTC como entrada
	PORTC	= 0x00;			// PORTC sin pull-up
	
	// Inicialización de Variables
	counter_ADC = 0;
	
	// Inicio de PWM
	initPWM0A();
	initPWM1A(0, 8);		// Se llama la función de inicio del PWM del Timer1
	initPWM2A(0, 64);		// Se llama la función de inicio del PWM del Timer2
	
	// Inicio de ADC
	initADC();
	ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
	
	// Configuración de Interrupciones
	TIMSK0 |= (1 << TOIE0); // Se habilita la interrupción de overflow de Timer0
	
	sei(); // Se encienden las interrupciones globales
}

void	 initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);
	ADMUX	|= (1 << ADLAR);
	ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));	// Se configura el PC0 y la justificación
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS2) | (1 << ADPS1);
	ADCSRA	|= (1 << ADIE);
	ADCSRA	|= (1 << ADEN);					// Se configura la interrupción y el prescaler
}


//*********************************************
// Interrupt routines
ISR(ADC_vect)
{
	adc_read = ADCH;
	
	
	switch(counter_ADC)
	{
		case 0:
		counter_ADC++;
		pwm0_adc = ADCH;
		ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));
		
		break;
		
		case 1:
		counter_ADC++;
		dutyCycle = ADC_to_PWM_ServoT1(adc_read);	// Se llama a la función que mapea el ADC al servo
		updateDutyCycle_T1(dutyCycle);	// Se llama la función que hace la actualización al registro
		ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));
		ADMUX	|= (1 << MUX0);
		break;
		
		case 2:
		counter_ADC = 0;
		ADMUX	&= ~(1 << MUX0);
		ADMUX	|= (1 << MUX1);
		dutyCycle = ADC_to_PWM_ServoT2(adc_read);	// Se llama a la función que mapea el ADC al servo
		updateDutyCycle_T2(dutyCycle);	// Se llama la función que hace la actualización al registro
		break;
	}
	
	ADCSRA	|= (1 << ADSC);				// Se realiza la lectura de ADC
}

ISR(TIMER0_OVF_vect)
{
	pwm0_counter++;
	pwm0_map = adc0_map(pwm0_adc);
	pwm0_cp(pwm0_counter, pwm0_map);
	if (pwm0_counter == 25)
	{
		pwm0_counter = 0;
	}
	TCNT0	= 251;
}

