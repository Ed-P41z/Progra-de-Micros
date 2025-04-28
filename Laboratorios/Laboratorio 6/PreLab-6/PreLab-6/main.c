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
char recibido_b;
char recibido_d;
uint8_t adc_b;
uint8_t adc_d;
uint8_t mostrar_menu;
uint8_t lec_adc;
uint8_t u_adc;
uint8_t d_adc;
uint8_t c_adc;
uint8_t envio_ascii;
uint8_t recibido_ascii;
uint8_t verif;

//*********************************************
// Function prototypes
void setup();
void initADC();
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
			escribir_cadena("\n 1- Leer Potenci�metro.");
			escribir_cadena("\n 2- Enviar Ascii.");
			mostrar_menu = 0;  // Ya se mostr� el men�, no volver a mostrar hasta que sea necesario
		}
		else if (recibido == 49)  // Si se recibe '1', se ejecuta la opci�n de lectura del potenci�metro
		{
			escribir_cadena("\n Lectura Potenci�metro: ");
			
			adc_b = lec_adc >> 2;    // Los 6 bits m�s significativos se asignan a PORTB
			adc_d = (lec_adc & 0x03) << 6;  // Los 2 bits menos significativos se asignan a PORTD (desplazados a la izquierda)
			
			PORTB = adc_b;  // Se actualiza PORTB con los 6 bits m�s significativos
			PORTD = adc_d;  // Se actualiza PORTD con los 2 bits menos significativos
			
			u_adc = lec_adc % 10;         // Divisi�n a Unidades
			d_adc = (lec_adc % 100) / 10; // Divisi�n a Decenas
			c_adc = lec_adc / 100;        // Divisi�n a Centenas
			
			writeChar(c_adc + '0'); // Se escribe el n�mero en ascii
			writeChar(d_adc + '0'); // Se escribe el n�mero en ascii
			writeChar(u_adc + '0'); // Se escribe el n�mero en ascii
			
			recibido = 0;       // Se resetea para comenzar nuevamente l�gica de men�
			mostrar_menu = 1;   // Se setea para mostrar el men� nuevamente en el primer if
		}
		else if (recibido == 50)  // Si se recibe '2', se ejecuta la opci�n de enviar un ASCII
		{
			escribir_cadena("\n Env�e un Ascii: ");
			envio_ascii = 1;        // Activar modo de recepci�n especial
			recibido = 0;           // Limpiar para no confundir

			while (verif != 1);    // Se espera para recibir el ascii
			
			writeChar('c');    // Env�a un 'c' como confirmaci�n de recepci�n de ASCII
			
			recibido_b = recibido_ascii >> 2;   // Los 6 bits m�s significativos se asignan a PORTB
			recibido_d = (recibido_ascii & 0x03) << 6; // Los 2 bits menos significativos se asignan a PORTD (desplazados a la izquierda)
			
			PORTB = recibido_b;  // Se actualiza PORTB con los 6 bits m�s significativos del ASCII recibido
			PORTD = recibido_d;  // Se actualiza PORTD con los 2 bits menos significativos del ASCII recibido

			mostrar_menu = 1;       // Se vuelve al men� principal
			recibido = 0;
			verif = 0;
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
	DDRD	= 0xFF;			// Se configura PORTD como salida
	PORTD	= 0x00;			// PORTD inicialmente apagado
	DDRC	= 0x00;			// Se configura PORTC como entrada
	PORTC	= 0x00;			// PORTC sin pull-up
	
	// Inicializaci�n de Variables
	mostrar_menu = 1;
	envio_ascii = 0;
	recibido_ascii = 0;
	
	// Inicio de Timers
	
	// Inicio de ADC
	initADC();
	ADCSRA	|= (1 << ADSC);	// Se hace la primera lectura del ADC
	
	// Inicio de UART
	initUART();
	
	// Configuraci�n de Interrupciones
	
	sei(); // Se encienden las interrupciones globales
}

void initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);
	ADMUX	|= (1 << ADLAR);
	ADMUX	&= ~((1 << MUX3) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0));	// Se configura el PC0 y la justificaci�n
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS2) | (1 << ADPS1);
	ADCSRA	|= (1 << ADIE);
	ADCSRA	|= (1 << ADEN);					// Se configura la interrupci�n y el prescaler
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
	
	if (envio_ascii == 1)
	{
		recibido_ascii = recibido;  // Se guarda el valor recibido 
		envio_ascii = 0;	// Se apaga la bandera para no reingresar al if en el men� principal
		verif = 1;			// Se activa la verificaci�n para salir del bucle principal en el main
	}
}

ISR(ADC_vect)
{
	lec_adc = ADCH;			// Se guarda ADCH
	ADCSRA	|= (1 << ADSC);	// Se realiza la lectura de ADC
}
