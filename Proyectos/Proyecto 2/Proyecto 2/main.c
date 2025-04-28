/*
 * Proyecto-2.c
 *
 * Created: 4/22/2025 5:30:40 PM
 * Author : edvin
 * Description: El proyecto consiste en realizar una garra usando 4 servos, implementando ADC, PWM, UART y EEPROM
 */
//*********************************************
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "PWM0/PWM0.h"
#include "PWM1/PWM1.h"

// Variables a usar
uint8_t adc_read;
uint16_t dutyCycle;
uint16_t adc_map;
uint8_t counter_ADC;

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
	initPWM0AB();			// Se llama la función de inicio del PWM del Timer0
	initPWM1AB();			// Se llama la función de inicio del PWM A del Timer1

	// Inicio de ADC
	initADC();
	ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
	
	// Configuración de Interrupciones
	TIMSK0 |= (1 << TOIE0); // Se habilita la interrupción de overflow de Timer0
	
	sei(); // Se encienden las interrupciones globales
}

void initADC()
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
		counter_ADC++;		// Se suma el contador que sirve para multiplexar
		OCR0A = adc_read;
		ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));	// Se selecciona pc0
		
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
		dutyCycle = ADC_to_PWM_ServoT1(adc_read);	// Se llama a la función que mapea el ADC al servo
		updateDutyCycle_T1(dutyCycle);	// Se llama la función que hace la actualización al registro
		break;
	}
	
	ADCSRA	|= (1 << ADSC);				// Se realiza la lectura de ADC
}
