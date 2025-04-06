/*
 * PreLab-4.c
 *
 * Created: 3/30/2025 6:10:42 PM
 * Author: edvin
 * Description: El prelab consiste en crear un sumador de 8 bits usando dos botones
 */
//*********************************************
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

uint8_t	counter;
uint8_t pb_flag;
uint8_t transitors;
uint8_t estado_actual;
uint8_t estado_anterior;
uint8_t counter_trs;
uint8_t adc_read;
uint8_t disp_1;
uint8_t disp_2;
uint8_t hex_value;
uint8_t disp_value[] = {0x5F, 0x06, 0x3B, 0x2F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x59, 0x3E, 0x79, 0x71};
#define	TCNT0_Value 170;
//*********************************************
// Function prototypes
void setup();
void initTMR0();
void initADC();
void cp_value();

//*********************************************
// Main Function

int main(void)
{
	setup();	// Se manda a llamar la función de Setup
	
	while(1)	// Entra al bucle infinito en donde se ejecuta el programa
	{
		if (pb_flag == 1)	// Si la bandera de acción de PB0 está encendida entra al if
		{
			pb_flag = 0;		// Apaga la bandera de acción de los botones
			counter++;			// Le suma al contador
		}
		else if (pb_flag == 2)	// Si la bandera de acción de PB1 está encendida entra al if
		{
			pb_flag = 0;		// Apaga la bandera de acción de los botones
			counter--;			// Le suma al contador
		}
		else   // El else no hace nada
		{
		}
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
	DDRC	= 0xFF;			// Se configura PORTC como salida
	DDRC	&= ~(1 << DDC3); // Se configura PC3 como input
	PORTC	= 0x00;			// PORTC inicialmente apagado
	PORTC	|= (1 << PORTC4);
	DDRB	= 0x00;			// Se configura PORTB como input
	PORTD	= 0xFF;			// PORTB con pull-up activado
	
	// Inicio de Timers
	initTMR0();
	
	// Inicio de ADC
	initADC();
	ADCSRA	|= (1 << ADSC);
	
	// Configuración de Interrupciones
	PCICR  |= (1 << PCIE0);						// Habilita las interrupciones pin-change para PORTB
	PCMSK0 |= (1 << PCINT0) | (1 << PCINT1);	// Habilita PCINT0 y PCINT1
	
	// Inicialización de Variables
	counter	= 0;
	pb_flag = 0;
	transitors	= 0;
	estado_actual	= 0xFF;
	estado_anterior	= 0xFF;
	counter_trs = 0;
	
	sei(); // Se encienden las interrupciones globales
}

void initTMR0()
{
	TCCR0A  = 0;
	TCCR0B  |= (1 << CS01) | (1 << CS00);
	TCNT0   = TCNT0_Value;
	TIMSK0  = (1 << TOIE0);
}

void	 initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);
	//ADMUX	&= ~(1 << REFS1);  No es indispensable
	ADMUX	|= (1 << ADLAR);
	ADMUX	|= (1 << MUX1) | (1 << MUX0); // Todo esto se puede hacer en una línea
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);
	ADCSRA	|= (1 << ADIE);
	ADCSRA	|= (1 << ADEN); // También se puede hacer en una línea
}

void cp_value()
{
	if (adc_read > counter)
	{
		PORTC |= (1 << PORTC5);
	}else{
		PORTC &= ~(1 << PORTC5);
	}
}

//*********************************************
// Interrupt routines
ISR(PCINT0_vect)
{
	estado_actual = PINB;  // Leer el estado actual de los botones
	
	if (((estado_anterior & (1 << PORTB0)) != 0) && ((estado_actual & (1 << PORTB0)) == 0))	// Se verifica si el botón está presionado y si hubo cambio de estado
	{
		pb_flag = 1;																	// Si PB0 está presionado y hubo cambio de estado, se enciende la bandera de acción de ese botón
	}
	else if (((estado_anterior & (1 << PORTB1)) != 0) && ((estado_actual & (1 << PORTB1)) == 0)) // Se verifica si el botón está presionado y si hubo cambio de estado
	{
		pb_flag = 2;																	// Si PB1 está presionado y hubo cambio de estado, se enciende la bandera de acción de ese botón
	}

	estado_anterior = estado_actual;  // Guardar el estado actual a estado anterior
}
	
ISR(TIMER0_OVF_vect)
{
	TCNT0 = TCNT0_Value;
	counter_trs++;
	if (counter_trs == 3)
	{
		counter_trs = 0;
	}
	
	switch(counter_trs)
	{
		case 0:
		PORTD = 0;
		PORTC &= ~((1<< PORTC4) | (1 << PORTC1) | (1 << PORTC0));
		PORTC |= (1 << PORTC4);
		PORTD = counter;
		break;
		
		case 1:
		PORTD = 0;
		PORTC &= ~((1<< PORTC4) | (1 << PORTC1) | (1 << PORTC0));
		PORTC |= (1 << PORTC1);
		PORTD = disp_value[disp_1];
		break;
		
		case 2:
		PORTD = 0;
		PORTC &= ~((1<< PORTC4) | (1 << PORTC1) | (1 << PORTC0));
		PORTC |= (1 << PORTC0);
		PORTD = disp_value[disp_2];
		break;
	}
}

ISR(ADC_vect)
{
	adc_read = ADCH;
	disp_2 = (adc_read >> 4) & 0x0F; // Decenas
	disp_1 = adc_read & 0x0F; // Unidades
	cp_value();
	ADCSRA	|= (1 << ADSC);
}
