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
#include "PWM1/PWM1.h"

uint8_t adc_read;
uint16_t dutyCycle;
uint16_t adc_map;

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
		//adc_map = (adc_read * 1000) / 255 + 1000;
		//dutyCycle = adc_map;			// Se actualiza el valor del dutyCycle con la lectura del 
		//dutyCycle = ((adc_read * 4000) / 255) + 1000;
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
	
	// Inicio de PWM
	initPWM0A(0, 8);		// Se llama la función de inicio del PWM del Timer1
	
	// Inicio de ADC
	initADC();
	ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
	
	// Configuración de Interrupciones
	
	
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
	dutyCycle = ADC_to_PWM_Servo(adc_read);
	//dutyCycle = PWM_to_Servo(adc_map);
	updateDutyCycle_T1(dutyCycle);	// Se llama la función que hace la actualización al registro
	_delay_ms(1);
	ADCSRA	|= (1 << ADSC);				// Se realiza la lectura de ADC
}


