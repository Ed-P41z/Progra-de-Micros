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
uint8_t modo; 
uint8_t first_read; 
uint8_t uart_flag;
uint8_t adc_flag;
uint8_t update_value;
uint8_t pb_flag;
uint8_t temp;
uint8_t buffer_index;
uint8_t servo_num;
uint8_t estado_garra;
uint8_t servos[4];
char recibido;
char update[3];
char buffer[20];



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
		switch (modo)
		{
		//-----------------------------------------------------------------------
		// Modo 1: Manual
		case 1:
		
		if (first_read == 1) // Ingresa solamente 1 vez al entrar al modo
		{
			PORTD &= ~((1 << PORTD2) | (1 << PORTD3));
			PORTD |= (1 << PORTD2);						// Enciende un led que muestra el modo manual
			
			ADCSRA	|= (1 << ADIE); // Habilita las interrupciones de ADC
			ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
			first_read = 0;			// Se apaga la bandera de acción de first_read
		}
		else if (adc_flag == 1) // Ingresa cada vez que se actualiza
		{
			adc_flag = 0; // Se apaga la bandera de acción de ADC
			
			switch(counter_ADC) // Cambia de servo dependiendo de counter_ADC
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
		else if(pb_flag == 1) // Entra cuando se presiona el botón de EEPROM (Botón 1)
		{
			pb_flag = 0; // Se apaga la bandera de acción del botón 1
			
			PORTD ^= (1 << PORTD2);					// Se hace toggle a un led para indicar que comenzó a guardar
			// Lógica para guardar en la eeprom...
			save_pos(0, estado_garra, dutyCycle1);
			save_pos(1, estado_garra, dutyCycle2);
			save_pos(2, estado_garra, dutyCycle3);
			save_pos(3, estado_garra, dutyCycle4); // Se guarda la posición de cada servo en la EEPROM
			PORTD ^= (1 << PORTD2);				   // Se enciende el LED para mostrar que se terminó de guardar.
			
			estado_garra++;			// Se incrementa al estado a guardar, siendo un total de 4 estados por servo
			if (estado_garra == 4)	// Si el estado cuenta 5 entra al if
			{
				estado_garra = 0;	// Reinicia al primer estado
			}
		}
		else if (pb_flag == 2)	// Entra cuando se presiona el botón de modo (Botón 2)
		{
			pb_flag = 0;		// Se apaga la bandera de acçión del botón 2
			first_read = 1;		// Se enciende la bandera de first_read para el siguiente modo
			modo = 2;			// Cambia al modo 2
		}
		else if (uart_flag == 1) // Entra cuando se enciende la bandera de UART
		{
			uart_flag = 0;	// Apaga la bandera de acción de UART
			if (buffer[0] == 'M' && buffer[1] == 'D' && buffer[2] == ':' && buffer[3] == '1') // Si detecta que recibió cambio de modo en UART entra al if
			{
				first_read = 1;	// Enciende la bandera de first_read para el siguiente modo
				modo = 2;	// Cambia al modo 2
			}
		}
		break;
		//-----------------------------------------------------------------------
		// Modo 2: EEPROM
		case 2:
		
		if (first_read == 1) // Entra a first_read del modo 2
		{
			PORTD &= ~((1 << PORTD2) | (1 << PORTD3));
			PORTD |= (1 << PORTD3);						// Enciende el led que indica el modo EEPROM
			
			ADCSRA	&= ~(1 << ADIE);					// Apaga las interrupciones de ADC
			estado_garra = 0;							// Carga un valor al estado inicial de EEPROM de la garra
			first_read = 0;								// Apaga la bandera de first_read
		}
		else if (pb_flag == 1)	// Entra si la bandera de acción del botón de EEPROM (Botón 1) está encendida
		{
			pb_flag = 0;	// Apaga la bandear de acción del botón 1
			
			PORTD ^= (1 << PORTD2);					// Hace toggle al led de EEPROM para indicar que está leyendo
			dutyCycle1 = read_pos(0, estado_garra);
			dutyCycle2 = read_pos(1, estado_garra);
			dutyCycle3 = read_pos(2, estado_garra);
			dutyCycle4 = read_pos(3, estado_garra);	// Lee los valores guardados en la EEPROM
			
			updateDutyCycle_T0A(dutyCycle1);
			updateDutyCycle_T0B(dutyCycle2);
			updateDutyCycle_T1A(dutyCycle3);
			updateDutyCycle_T1B(dutyCycle4);	// Reproduce los valores guardados en la EEPROM
			
			PORTD ^= (1 << PORTD2);				// Hace toggle al led de EEPROM para indicar que terminó de cargar
			
			estado_garra++;			// Se suma a la variable del estado a cargar
			if (estado_garra == 4)	// Si la suma llega a la posición 5, se reinicia
			{
				estado_garra = 0;	// Se reinicia la variable que guarda la posición a cargar
			}
		}
		else if (pb_flag == 2)	// Entra si la bandera de acción del botón de Modo (Botón 2) está encendida
		{
			pb_flag = 0;	// Apaga la bandera de acción del botón 2
			first_read = 1;	// Enciende la bandera de first read para el siguiente modo
			modo = 3;		// Cambia al modo 3
		}
		else if (uart_flag == 1)	// Entra si la bandera del UART se enciende
		{
			uart_flag = 0;	// Apaga la bandera de acción del UART
			if (buffer[0] == 'M' && buffer[1] == 'D' && buffer[2] == ':' && buffer[3] == '1')	// Si se recibe "MD:1" ingresa al if
			{
				first_read = 1;	// Enciende la bandera de first_read para el siguiente modo
				modo = 3;	// Cambia al modo 3
			}
			else if (buffer[0] == 'E' && buffer[1] == 'P' && buffer[2] == ':' && buffer[3] == '1')	// Si se recibe "EP:1" ingresa al else if
			{
				PORTD ^= (1 << PORTD2);	// Hace toggle al led que indica acción en la EEPROM
				dutyCycle1 = read_pos(0, estado_garra);
				dutyCycle2 = read_pos(1, estado_garra);
				dutyCycle3 = read_pos(2, estado_garra);
				dutyCycle4 = read_pos(3, estado_garra);	// Lee de la EEPROM la posición de cada servo correspondiente
				
				updateDutyCycle_T0A(dutyCycle1);
				updateDutyCycle_T0B(dutyCycle2);
				updateDutyCycle_T1A(dutyCycle3);
				updateDutyCycle_T1B(dutyCycle4);	// Carga a cada servo la posición que le corresponde
				
				PORTD ^= (1 << PORTD2);	// Hace toggle al led para regresarlo a su estado original
				
				estado_garra++;			// Suma la variable del estado de la garra
				if (estado_garra == 4)	// Si el estado pasa de 4 entra al if
				{
					estado_garra = 0;	// Reinicia el estado que guarda o lee de la EEPROM
				}
			}
		}
		
		else
		{	
			// El else no hace nada...
		}
		
		break;
		//-----------------------------------------------------------------------
		// Modo 3: UART
		case 3: 
		
		if (first_read == 1)	// Entra a first_read del modo 3
		{
			PORTD &= ~((1 << PORTD2) | (1 << PORTD3));	
			PORTD |= (1 << PORTD2) | (1 << PORTD3);		// Enciende ambos leds para indicar el modo UART
			ADCSRA	&= ~(1 << ADIE);					// Apaga las interrupciones de ADC
			first_read = 0;								// Apaga la bandera de first_read
		}
		else if (uart_flag == 1)	// Si la bandera de UART está encendida entra al if
		{
			uart_flag = 0;	// Apaga la bandera del UART

			if (buffer[0] == 'S' && buffer[1] == '1' && buffer[2] == ':')	// Si se recibió "S1:" entra al if
			{
				uart_map1 = ascii_to_int(&buffer[3]);			// Se llama la función que transforma de ascii a int
				dutyCycle1 = ADC_to_PWM_ServoT0A(uart_map1);	// Se hace el mapeo del valor recibido
				updateDutyCycle_T0A(dutyCycle1);				// Se carga el valor del mapeo al servo 1
				enviar_valor_uart(uart_map1, "S1:");			// Se envía feedback a Adafruit por UART
			}
			else if (buffer[0] == 'S' && buffer[1] == '2' && buffer[2] == ':')	// Si se recibió "S2:" entra al if
			{
				uart_map2 = ascii_to_int(&buffer[3]);			// Se llama la función que transforma de ascii a int
				dutyCycle2 = ADC_to_PWM_ServoT0B(uart_map2);	// Se hace el mapeo del valor recibido
				updateDutyCycle_T0B(dutyCycle2);				// Se carga el valor del mapeo al servo 2
				enviar_valor_uart(uart_map2, "S2:");			// Se envía feedback a Adafruit por UART
				
			}
			else if (buffer[0] == 'S' && buffer[1] == '3' && buffer[2] == ':')	// Si se recibió "S3:" entra al if
			{
				uart_map3 = ascii_to_int(&buffer[3]);			// Se llama la función que transforma de ascii a int
				dutyCycle3 = ADC_to_PWM_ServoT1A(uart_map3);	// Se hace el mapeo del valor recibido
				updateDutyCycle_T1A(dutyCycle3);				// Se carga el valor del mapeo al servo 3
				enviar_valor_uart(uart_map3, "S3:");			// Se envía feedback a Adafruit por UART
			}
			else if (buffer[0] == 'S' && buffer[1] == '4' && buffer[2] == ':')	// Si se recibió "S4:" entra al if
			{
				uart_map4 = ascii_to_int(&buffer[3]);			// Se llama la función que transforma de ascii a int
				dutyCycle4 = ADC_to_PWM_ServoT1B(uart_map4);	// Se hace el mapeo del valor recibido
				updateDutyCycle_T1B(dutyCycle4);				// Se carga el valor del mapeo al servo 4
				enviar_valor_uart(uart_map4, "S4:");			// Se envía feedback a Adafruit por UART
			}
			else if (buffer[0] == 'E' && buffer[1] == 'P' && buffer[2] == ':' && buffer[3] == '1')	// Si se recibió "EP:1" entra al if
			{
				PORTD ^= (1 << PORTD2);					// Hace toggle al led que indica acción en la EEPROM
				save_pos(0, estado_garra, dutyCycle1);
				save_pos(1, estado_garra, dutyCycle2);
				save_pos(2, estado_garra, dutyCycle3);
				save_pos(3, estado_garra, dutyCycle4);	// Guarda la posición de los cuatro servos en la EEPROM
				PORTD ^= (1 << PORTD2);					// Hace toggle al led para regresarlo a su estado original
				
				estado_garra++;			// Suma al estado qeu se guardará en la EEPROM de la garra
				if (estado_garra == 4)	// Si el estado pasa de 4 entra al if
				{
					estado_garra = 0;	// Reinicia el estado de la garra que se verá en la EEPROM
				}
			}
			else if (buffer[0] == 'M' && buffer[1] == 'D' && buffer[2] == ':' && buffer[3] == '1')	// Si recibión "MD:1" entra al if
			{
				first_read = 1;	// Enciende la bandera de first_read para el siguiente modo
				modo = 1;	// Pasa al modo 1
			}
		}
		else if (pb_flag == 2)	// Entra al if si la bandera de acción del botón de modo (Botón 2) está encendida
		{
			pb_flag = 0;	// Apaga la bandera de acción del botón 2
			first_read = 1;	// Enciende la bandera de first_read para el siguiente modo
			modo = 1;		// Cambia al modo 1
		}
		else
		{
			// El else no hace nada...
		}
		
		break;
		//-----------------------------------------------------------------------
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
	initUART();				// Se llama la función de inicio del UART
	
	// Inicio de PWM
	initPWM0AB();			// Se llama la función de inicio del PWM del Timer0
	initPWM1AB();			// Se llama la función de inicio del PWM A del Timer1
	
	// Inicio de ADC
	initADC();
	
	// Configuración de Interrupciones
	PCICR |= (1 << PCIE1);             // Habilita interrupciones pin-change para PINC
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

//*********************************************
// Interrupt routines

//-----------------Interrupción de ADC-----------------
ISR(ADC_vect)
{
	adc_read = ADCH;	// Se lee ADCH (Justificado a la Izquierda)
	adc_flag = 1;		// Se enciende la bandera de acción de ADC
	
}

//-----------------Interrupción de UART-----------------
ISR(USART_RX_vect)
{
	recibido = UDR0;	// Leer el carácter recibido desde el registro de UART

	if (recibido == '\n') // Si la cadena termina en el caracter de "enter" entra al if
	{
		buffer[buffer_index] = '\0';	// Termina el string
		uart_flag = 1;					// Enciende la bandera de UART
		buffer_index = 0;				// Reinicia el índice del buffer
	}
	else
	{
		if (buffer_index < sizeof(buffer) - 1) // Mientras que el índice del caracter recibido sea menor que el tamaño de la lista (Buffer) entra al if
		{
			buffer[buffer_index++] = recibido;	// Guarda en la lista el caracter recibido y suma uno al índice de la lista
		}
	}
}
	
//-----------------Interrupción de Pin-Change-----------------	
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
