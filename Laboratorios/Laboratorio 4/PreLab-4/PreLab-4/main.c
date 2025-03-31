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

uint8_t	counter;
uint8_t pb_flag;
uint8_t transitors;
uint8_t estado_actual;
uint8_t estado_anterior;
//*********************************************
// Function prototypes
void setup();

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
			PORTD = counter;	// Saca el valor del contador a PORTD
		}
		else if (pb_flag == 2)	// Si la bandera de acción de PB1 está encendida entra al if
		{
			pb_flag = 0;		// Apaga la bandera de acción de los botones
			counter--;			// Le suma al contador
			PORTD = counter;	// Saca el valor del contador a PORTD
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
	DDRC	|= (0 << DDC3); // Se configura PC3 como input
	PORTC	= 0x00;			// PORTC inicialmente apagado
	PORTC	|= (1 << PORTC4);
	DDRB	= 0x00;			// Se configura PORTB como input
	PORTD	= 0xFF;			// PORTB con pull-up activado
	
	// Configuración de Interrupciones
	PCICR  |= (1 << PCIE0);						// Habilita las interrupciones pin-change para PORTB
	PCMSK0 |= (1 << PCINT0) | (1 << PCINT1);	// Habilita PCINT0 y PCINT1
	
	// Inicialización de Variables
	counter	= 0;
	pb_flag = 0;
	transitors	= 0;
	estado_actual	= 0xFF;
	estado_anterior	= 0xFF;
	
	sei(); // Se encienden las interrupciones globales
}


//*********************************************
// Interrupt routines
ISR(PCINT0_vect)
{
	estado_actual = PINB;  // Leer el estado actual de los botones
	
	if (((estado_anterior & (1 << PB0)) != 0) && ((estado_actual & (1 << PB0)) == 0)) // Se verifica si el botón está presionado y si hubo cambio de estado
	{
		pb_flag = 1;  // Si PB0 está presionado y hubo cambio de estado, se enciende la bandera de acción de ese botón
	}
	else if (((estado_anterior & (1 << PB1)) != 0) && ((estado_actual & (1 << PB1)) == 0)) // Se verifica si el botón está presionado y si hubo cambio de estado
	{
		pb_flag = 2; // Si PB1 está presionado y hubo cambio de estado, se enciende la bandera de acción de ese botón
	}

	estado_anterior = estado_actual;  // Guardar el estado actual a estado anterior
}
	