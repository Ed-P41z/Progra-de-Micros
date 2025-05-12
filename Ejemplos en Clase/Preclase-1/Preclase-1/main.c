/*
 * Preclase-1.c
 *
 * Created: 4/29/2025 3:36:20 PM
 * Author : Edvin
 * Description: El prelab consiste en enviar un dato del controlador a la terminal y viceversa
 */ 
//*********************************************
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
char recibido;
uint8_t mostrar_menu;
uint8_t estado_actual;
uint8_t pb_flag;
uint8_t estado_anterior;

//*********************************************
// Function prototypes
void setup();
void initUART();
void writeChar(char caracter);
void escribir_cadena(char* cadena);

//*********************************************
// Main Function

int main(void)
{
	setup();	// Se manda a llamar la funci�n de Setup
	
	while(1)	// Entra al bucle infinito en donde se ejecuta el programa
	{
		if (mostrar_menu)
		{
			escribir_cadena("\n -------------------------------------------------------------------- ");
			escribir_cadena("\n Presione 1 o 2 para seleccionar una opci�n: ");
			escribir_cadena("\n 1- Encender Led.");
			escribir_cadena("\n 2- Apagar Led.");
			mostrar_menu = 0;  // Ya se mostr� el men�, no volver a mostrar hasta que sea necesario
		}
		else if (recibido == 49)  // Si se recibe '1', se ejecuta la opci�n de lectura del potenci�metro
		{
			escribir_cadena("\n Led encendido");
			PORTB |= (1 << PORTB0);
			recibido = 0;       // Se resetea para comenzar nuevamente l�gica de men�
			mostrar_menu = 1;   // Se setea para mostrar el men� nuevamente en el primer if
		}
		else if (recibido == 50)  // Si se recibe '2', se ejecuta la opci�n de enviar un ASCII
		{
			escribir_cadena("\n Led Apagado");
			PORTB &= ~(1 << PORTB0);
			mostrar_menu = 1;       // Se vuelve al men� principal
			recibido = 0;	
		}
		else if (pb_flag == 1)
		{
			// Toggle LED en PB1
			PORTB ^= (1 << PORTB1);
			pb_flag = 0;
		}
	}
}

//*********************************************
// NON-Interrupt subroutines
void setup()
{
	cli(); // Se apagan las interruciones globales
	
	// Configurar presclaer de sistema
	//CLKPR	= (1 << CLKPCE);
	//CLKPR	= (1 << CLKPS2); // 16 PRESCALER -> 1MHz
	
	// Configuraci�n de Pines
	DDRB	= 0xFF;			// Se configura PORTB como salida
	PORTB	= 0x00;			// PORTB inicialmente apagado
	DDRC	= 0x00;			// Se configura PORTC como entrada
	PORTC	= 0xFF;			// PORTC con pull-up
	
	// Inicializaci�n de Variables
	mostrar_menu = 1;
	
	// Inicio de Timers
	
	// Inicio de ADC
	
	// Inicio de UART
	initUART();
	
	// Configuraci�n de Interrupciones
	PCICR |= (1 << PCIE1);      // Habilita interrupci�n para PCINT1 (PORTC)
	PCMSK1 |= (1 << PCINT13);   // Habilita interrupci�n espec�ficamente para PC5
	
	sei(); // Se encienden las interrupciones globales
}

void initUART()
{
	// Paso 1: Configurar pines PD0 (rx) y PD1 (tx)
	DDRD	|= (1 << DDD1);
	DDRD	&= ~(1 << DDD0);
	
	// Paso 2: Configurar UCSR0A
	UCSR0A = 0;
	
	// Paso 3: Configurar UCSR0B, Habilitando interrupts al recibir; Habilitando recepci�n; Habilitando transmisi�n
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	
	// Paso 4: UCSR0C
	UCSR0C |= (1 << UCSZ00) | (1 << UCSZ01);
	
	// Paso 5: UBRR0: UBRR0 = 103 -> 9600 @ 16MHz
	UBRR0 = 103;
}

void writeChar(char caracter)
{
	while ((UCSR0A & (1 << UDRE0)) == 0);  // Esperar a que el registro de datos est� vac�o
	UDR0 = caracter;  // Enviar el caracter al registro de UART
}

void escribir_cadena (char* cadena)
{
	for (uint8_t puntero = 0; *(cadena+puntero) != '\0'; puntero++)  // Itera sobre cada car�cter de la cadena
	{
		writeChar(*(cadena+puntero));  // Enviar cada car�cter a trav�s de UART
	}
}

//*********************************************
// Interrupt�routines
ISR(USART_RX_vect)
{
	recibido = UDR0;  // Leer el car�cter recibido desde el registro de UART
}

ISR(PCINT1_vect)
{
	estado_actual = PINC;  // Leer el estado actual de los botones
	
	if (((estado_anterior & (1 << PORTC5)) != 0) && ((estado_actual & (1 << PORTC5)) == 0))	// Se verifica si el bot�n est� presionado y si hubo cambio de estado
	{
		pb_flag = 1;		// Si PC5 est� presionado y hubo cambio de estado, se enciende la bandera de acci�n de ese bot�n
	}
	estado_anterior = estado_actual;  // Guardar el estado actual a estado anterior
}