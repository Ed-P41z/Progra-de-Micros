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
#include "UART/UART.h"
#include "EEPROM/EEPROM.h"

// Variables a usar
uint8_t adc_read;
uint8_t dutyCycle1;
uint8_t dutyCycle2;
uint8_t dutyCycle3;
uint8_t dutyCycle4;
uint8_t uart_map1;
uint8_t uart_map2;
uint8_t uart_map3;
uint8_t uart_map4;
uint16_t adc_map;
uint8_t counter_ADC;
uint8_t estado_actual;
uint8_t estado_anterior;
uint8_t modo; // Inicializar
uint8_t first_read; // Ini
uint8_t uart_flag;
uint8_t adc_flag;
uint8_t update_value;
uint8_t pb_flag;
uint8_t temp; // Variable libre
uint8_t buffer_index;
uint8_t servo_num;
uint8_t estado_garra; // Inicializar
uint8_t servos[4];
char recibido;
char update[3];
char buffer[20];



//*********************************************
// Function prototypes
void setup();
void initADC();
void init_TIMR2();

//*********************************************
// Main Function

int main(void)
{
	setup();	// Se manda a llamar la función de Setup	
	
	while(1)	// Entra al bucle infinito en donde se ejecuta el programa
	{	
		switch (modo)
		{
		//-----------------------------------------------------------------------
		// Modo 1: Manual
		case 1:
		
		PORTD &= ~((1 << PORTD2) | (1 << PORTD3));
		PORTD |= (1 << PORTD2);
		
		if (first_read == 1)
		{
			ADCSRA	|= (1 << ADIE);
			ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
			first_read = 0;
		}
		else if (adc_flag == 1)
		{
			adc_flag = 0;
			switch(counter_ADC)
			{
				case 0:
				counter_ADC++;		// Se suma el contador que sirve para multiplexar
				dutyCycle4 = ADC_to_PWM_ServoT1B(adc_read);	// Se llama a la función que mapea el ADC al servo
				updateDutyCycle_T1B(dutyCycle4);	// Se llama la función que hace la actualización al registro
				ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));	// Se selecciona pc0
				break;
				
				case 1:
				counter_ADC++;
				dutyCycle1 = ADC_to_PWM_ServoT0A(adc_read);	// Se llama a la función que mapea el ADC al servo
				updateDutyCycle_T0A(dutyCycle1);	// Se llama la función que hace la actualización al registro
				ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));
				ADMUX	|= (1 << MUX0);	// Se selecciona pc1
				break;
				
				case 2:
				counter_ADC++;
				dutyCycle2 = ADC_to_PWM_ServoT0B(adc_read);	// Se llama a la función que mapea el ADC al servo
				updateDutyCycle_T0B(dutyCycle2);	// Se llama la función que hace la actualización al registro
				ADMUX	&= ~(1 << MUX0);
				ADMUX	|= (1 << MUX1);	// Se selecciona pc2
				break;
				
				case 3:
				counter_ADC = 0;
				dutyCycle3 = ADC_to_PWM_ServoT1A(adc_read);	// Se llama a la función que mapea el ADC al servo
				updateDutyCycle_T1A(dutyCycle3);	// Se llama la función que hace la actualización al registro
				ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));
				ADMUX	|= (1 << MUX1) | (1 << MUX0);	// Se selecciona pc3
				break;
			}
			
			ADCSRA	|= (1 << ADSC);				// Se realiza la lectura de ADC
		}
		else if(pb_flag == 1)
		{
			pb_flag = 0;
			
			PORTD ^= (1 << PORTD2);
			// Lógica para guardar en la eeprom...
			save_pos(0, estado_garra, dutyCycle1);
			save_pos(1, estado_garra, dutyCycle2);
			save_pos(2, estado_garra, dutyCycle3);
			save_pos(3, estado_garra, dutyCycle4);
			PORTD ^= (1 << PORTD2);
			
			estado_garra++;
			if (estado_garra == 4)
			{
				estado_garra = 0;
			}
		}
		else if (pb_flag == 2)
		{
			pb_flag = 0;
			first_read = 1;
			modo = 2;
		}
		else if (uart_flag == 1)
		{
			uart_flag = 0;
			if (buffer[0] == 'M' && buffer[1] == 'D' && buffer[2] == ':' && buffer[3] == '1')
			{
				modo = 2;
			}
		}
		break;
		//-----------------------------------------------------------------------
		// Modo 2: EEPROM
		case 2:
		
		PORTD &= ~((1 << PORTD2) | (1 << PORTD3));
		PORTD |= (1 << PORTD3);
		
		if (first_read == 1)
		{
			ADCSRA	&= ~(1 << ADIE);
			estado_garra = 0;
			first_read = 0;
		}
		else if (pb_flag == 1)
		{
			pb_flag = 0;
			
			PORTD ^= (1 << PORTD2);
			// Lógica de cambio de posiciones dependiendo del botón...
			dutyCycle1 = read_pos(0, estado_garra);
			dutyCycle2 = read_pos(1, estado_garra);
			dutyCycle3 = read_pos(2, estado_garra);
			dutyCycle4 = read_pos(3, estado_garra);
			
			updateDutyCycle_T0A(dutyCycle1);
			updateDutyCycle_T0B(dutyCycle2);
			updateDutyCycle_T1A(dutyCycle3);
			updateDutyCycle_T1B(dutyCycle4);
			
			PORTD ^= (1 << PORTD2);
			
			estado_garra++;
			if (estado_garra == 4)
			{
				estado_garra = 0;
			}
		}
		else if (pb_flag == 2)
		{
			pb_flag = 0;
			first_read = 1;
			modo = 3;
		}
		else if (uart_flag == 1)
		{
			uart_flag = 0;
			if (buffer[0] == 'M' && buffer[1] == 'D' && buffer[2] == ':' && buffer[3] == '1')
			{
				modo = 3;
			}
			else if (buffer[0] == 'E' && buffer[1] == 'P' && buffer[2] == ':' && buffer[3] == '1')
			{
				PORTD ^= (1 << PORTD2);
				// Lógica de cambio de posiciones dependiendo del botón...
				dutyCycle1 = read_pos(0, estado_garra);
				dutyCycle2 = read_pos(1, estado_garra);
				dutyCycle3 = read_pos(2, estado_garra);
				dutyCycle4 = read_pos(3, estado_garra);
				
				updateDutyCycle_T0A(dutyCycle1);
				updateDutyCycle_T0B(dutyCycle2);
				updateDutyCycle_T1A(dutyCycle3);
				updateDutyCycle_T1B(dutyCycle4);
				
				PORTD ^= (1 << PORTD2);
				
				estado_garra++;
				if (estado_garra == 4)
				{
					estado_garra = 0;
				}
			}
		}
		
		else
		{	
		}
		
		break;
		//-----------------------------------------------------------------------
		// Modo 3: UART
		case 3: 
		
		PORTD &= ~((1 << PORTD2) | (1 << PORTD3));
		PORTD |= (1 << PORTD2) | (1 << PORTD3);
		
		if (first_read == 1)
		{
			ADCSRA	&= ~(1 << ADIE);
			first_read = 0;
		}
		else if (uart_flag == 1) 
		{
			uart_flag = 0; 

			if (buffer[0] == 'S' && buffer[1] == '1' && buffer[2] == ':') 
			{
				uart_map1 = ascii_to_int(&buffer[3]);
				dutyCycle1 = ADC_to_PWM_ServoT0A(uart_map1);
				updateDutyCycle_T0A(dutyCycle1);
				update[0] = uart_map1 % 10;
				update[1] = (uart_map1) / 10;
				update[2] = uart_map1 / 100;
				escribir_cadena("S1:");
				writeChar(update[2] + '0');
				writeChar(update[1] + '0');
				writeChar(update[0] + '0');
			}
			else if (buffer[0] == 'S' && buffer[1] == '2' && buffer[2] == ':') 
			{
				uart_map2 = ascii_to_int(&buffer[3]);
				dutyCycle2 = ADC_to_PWM_ServoT0B(uart_map2);
				updateDutyCycle_T0B(dutyCycle2);
			}
			else if (buffer[0] == 'S' && buffer[1] == '3' && buffer[2] == ':') 
			{
				uart_map3 = ascii_to_int(&buffer[3]);
				dutyCycle3 = ADC_to_PWM_ServoT1A(uart_map3);
				updateDutyCycle_T1A(dutyCycle3);
			}
			else if (buffer[0] == 'S' && buffer[1] == '4' && buffer[2] == ':') 
			{
				uart_map4 = ascii_to_int(&buffer[3]);
				dutyCycle4 = ADC_to_PWM_ServoT1B(uart_map4);
				updateDutyCycle_T1B(dutyCycle4);
			}
			else if (buffer[0] == 'E' && buffer[1] == 'P' && buffer[2] == ':' && buffer[3] == '1')
			{
				PORTD ^= (1 << PORTD2);
				// Lógica para guardar en la eeprom...
				save_pos(0, estado_garra, dutyCycle1);
				save_pos(1, estado_garra, dutyCycle2);
				save_pos(2, estado_garra, dutyCycle3);
				save_pos(3, estado_garra, dutyCycle4);
				PORTD ^= (1 << PORTD2);
				
				estado_garra++;
				if (estado_garra == 4)
				{
					estado_garra = 0;
				}
			}
			else if (buffer[0] == 'M' && buffer[1] == 'D' && buffer[2] == ':' && buffer[3] == '1')
			{
				modo = 1;
			}
		}
		else if (pb_flag == 2)
		{
			pb_flag = 0;
			first_read = 1;
			modo = 1;
		}
		else
		{
		}
		
		break;
		//-----------------------------------------------------------------------
		}
	/*if (update_value == 1)
	{
		update_value = 0;
		while(servo_num != 4)
		{
			if (servo_num == 0)
			{
				update[0] = uart_map1 % 10;
				update[1] = (uart_map1) / 10;
				update[2] = uart_map1 / 100;
				escribir_cadena("S1:");
				writeChar(update[2] + '0');
				writeChar(update[1] + '0');
				writeChar(update[0] + '0');
			}
			else if (servo_num == 1)
			{
				update[0] = uart_map2 % 10;
				update[1] = (uart_map2) / 10;
				update[2] = uart_map2 / 100;
				escribir_cadena("S2:");
				writeChar(update[2] + '0');
				writeChar(update[1] + '0');
				writeChar(update[0] + '0');
			}
			else if (servo_num == 2)
			{
				update[0] = uart_map3 % 10;
				update[1] = (uart_map3) / 10;
				update[2] = uart_map3 / 100;
				escribir_cadena("S3:");
				writeChar(update[2] + '0');
				writeChar(update[1] + '0');
				writeChar(update[0] + '0');
			}
			else if (servo_num == 3)
			{
				update[0] = uart_map4 % 10;
				update[1] = (uart_map4) / 10;
				update[2] = uart_map4 / 100;
				escribir_cadena("S4:");
				writeChar(update[2] + '0');
				writeChar(update[1] + '0');
				writeChar(update[0] + '0');
			}
			servo_num++;
		}
		servo_num = 0;
	}*/
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
	PORTC |= (1 << PORTC4) | (1 << PORTC5); // Pull-up para PC4 y PC5
	
	// Inicialización de Variables
	modo = 1;
	counter_ADC = 0;
	first_read = 1;
	buffer_index = 0;
	pb_flag = 0;
	uart_flag = 0;
	
	// Inicio de UART
	initUART();
	
	// Inicio de PWM
	initPWM0AB();			// Se llama la función de inicio del PWM del Timer0
	initPWM1AB();			// Se llama la función de inicio del PWM A del Timer1
	
	// Inicio de Timers
	//init_TIMR2();

	// Inicio de ADC
	initADC();
	
	// Configuración de Interrupciones
	PCICR |= (1 << PCIE1);             // Habilita interrupciones pin-change en el grupo PCINT[14:8] => PINC
	PCMSK1 |= (1 << PCINT12) | (1 << PCINT13); // Habilita interrupciones para PC4 y PC5
	
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
	ADCSRA	&= ~(1 << ADIE);
	ADCSRA	|= (1 << ADEN);					// Se configura la interrupción y el prescaler
}

void init_TIMR2()
{
	TCCR2B |= (1 << CS22);
	TCNT2	= 0;
	TIMSK2 |= (1 <<	TOIE2);
}

//*********************************************
// Interrupt routines
ISR(ADC_vect)
{
	adc_read = ADCH;
	adc_flag = 1;
	
	
}


ISR(USART_RX_vect)
{
	recibido = UDR0;	// Leer el carácter recibido desde el registro de UART

	if (recibido == '\n' || recibido == '\r') {
		buffer[buffer_index] = '\0'; // Termina el string
		uart_flag = 1;
		buffer_index = 0;
	}
	else
	{
		if (buffer_index < sizeof(buffer) - 1) 
		{
			buffer[buffer_index++] = recibido;
		}
	}
}
	
ISR(PCINT1_vect)
{
	estado_actual = PINC & ((1 << PORTC4) | (1 << PORTC5));  // Leer el estado actual de los botones
	
	if (((estado_anterior & (1 << PORTC4)) != 0) && ((estado_actual & (1 << PORTC4)) == 0))	// Se verifica si el botón está presionado y si hubo cambio de estado
	{
		pb_flag = 1;																	// Si PC4 está presionado y hubo cambio de estado, se enciende la bandera de acción de ese botón
	} 
	else if (((estado_anterior & (1 << PORTC5)) != 0) && ((estado_actual & (1 << PORTC5)) == 0))	// Se verifica si el botón está presionado y si hubo cambio de estado
	{
		pb_flag = 2;																	// Si PC5 está presionado y hubo cambio de estado, se enciende la bandera de acción de ese botón
	}
	estado_anterior = estado_actual;  // Guardar el estado actual a estado anterior
}
	
ISR(TIMER2_OVF_vect)
{
	temp++;
	if (temp == 115)
	{
		update_value = 1;
	}
}
