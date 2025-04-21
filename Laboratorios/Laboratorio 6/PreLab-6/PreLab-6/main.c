/*
 * PreLab-6.c
 *
 * Created: 4/16/2025 11:44:31 PM
 * Author : Edvin
 * Description: El prelab consiste en enviar un dato del controlador a la terminal y viceversa
 */ 
//*********************************************
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
char recibido;

//*********************************************
// Function prototypes
void setup();
void initUART();
void writeChar(char caracter);

//*********************************************
// Main Function

int main(void)
{
	setup();	// Se manda a llamar la función de Setup
	
	writeChar('s');
	
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
	//CLKPR	= (1 << CLKPCE);
	//CLKPR	= (1 << CLKPS2); // 16 PRESCALER -> 1MHz
	
	// Configuración de Pines
	DDRB	= 0xFF;			// Se configura PORTB como salida
	PORTB	= 0x00;			// PORTB inicialmente apagado
	//DDRC	= 0x00;			// Se configura PORTC como entrada
	//PORTC	= 0x00;			// PORTC sin pull-up
	
	// Inicialización de Variables
	
	// Inicio de Timers
	
	// Inicio de ADC
	//initADC();
	//ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
	
	// Inicio de UART
	initUART();
	
	// Configuración de Interrupciones
	
	sei(); // Se encienden las interrupciones globales
}

/*void	 initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);
	ADMUX	|= (1 << ADLAR);
	ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));	// Se configura el PC0 y la justificación
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS2) | (1 << ADPS1);
	ADCSRA	|= (1 << ADIE);
	ADCSRA	|= (1 << ADEN);					// Se configura la interrupción y el prescaler
}*/

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
	// uint16_t temporal = UCSR0A & (1 << UDRE0);
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter;
}

//*********************************************
// Interrupt routines
ISR(USART_RX_vect)
{
	recibido = UDR0;  // Leer el carácter recibido desde el registro de UART
	PORTB = recibido;      // Mostrarlo en el puerto B
}

/*ISR(ADC_vect)
{
	ADCSRA	|= (1 << ADSC);				// Se realiza la lectura de ADC
}*/



