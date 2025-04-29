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
	setup();	// Se manda a llamar la función de Setup
	
	while(1)	// Entra al bucle infinito en donde se ejecuta el programa
	{
		if (mostrar_menu)
		{
			escribir_cadena("\n -------------------------------------------------------------------- ");
			escribir_cadena("\n Presione 1 o 2 para seleccionar una opción: ");
			escribir_cadena("\n 1- Encender Led.");
			escribir_cadena("\n 2- Apagar Led.");
			mostrar_menu = 0;  // Ya se mostró el menú, no volver a mostrar hasta que sea necesario
		}
		else if (recibido == 49)  // Si se recibe '1', se ejecuta la opción de lectura del potenciómetro
		{
			escribir_cadena("\n Led encendido");
			PORTB |= (1 << PORTB0);
			recibido = 0;       // Se resetea para comenzar nuevamente lógica de menú
			mostrar_menu = 1;   // Se setea para mostrar el menú nuevamente en el primer if
		}
		else if (recibido == 50)  // Si se recibe '2', se ejecuta la opción de enviar un ASCII
		{
			escribir_cadena("\n Led Apagado");
			PORTB &= ~(1 << PORTB0);
			mostrar_menu = 1;       // Se vuelve al menú principal
			recibido = 0;
			
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
	
	// Configuración de Pines
	DDRB	= 0xFF;			// Se configura PORTB como salida
	PORTB	= 0x00;			// PORTB inicialmente apagado
	DDRC	= 0x00;			// Se configura PORTC como entrada
	PORTC	= 0xFF;			// PORTC con pull-up
	
	// Inicialización de Variables
	mostrar_menu = 1;
	
	// Inicio de Timers
	
	// Inicio de ADC
	
	// Inicio de UART
	initUART();
	
	// Configuración de Interrupciones
	
	sei(); // Se encienden las interrupciones globales
}

void initUART()
{
	// Paso 1: Configurar pines PD0 (rx) y PD1 (tx)
	DDRD	|= (1 << DDD1);
	DDRD	&= ~(1 << DDD0);
	
	// Paso 2: Configurar UCSR0A
	UCSR0A = 0;
	
	// Paso 3: Configurar UCSR0B, Habilitando interrupts al recibir; Habilitando recepción; Habilitando transmisión
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	
	// Paso 4: UCSR0C
	UCSR0C |= (1 << UCSZ00) | (1 << UCSZ01);
	
	// Paso 5: UBRR0: UBRR0 = 103 -> 9600 @ 16MHz
	UBRR0 = 103;
}

void writeChar(char caracter)
{
	while ((UCSR0A & (1 << UDRE0)) == 0);  // Esperar a que el registro de datos esté vacío
	UDR0 = caracter;  // Enviar el caracter al registro de UART
}

void escribir_cadena (char* cadena)
{
	for (uint8_t puntero = 0; *(cadena+puntero) != '\0'; puntero++)  // Itera sobre cada carácter de la cadena
	{
		writeChar(*(cadena+puntero));  // Enviar cada carácter a través de UART
	}
}

//*********************************************
// Interrupt routines
ISR(USART_RX_vect)
{
	recibido = UDR0;  // Leer el carácter recibido desde el registro de UART
}