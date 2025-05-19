/*
 * EEPROM.c
 *
 * Created: 5/8/2025 9:18:10 PM
 *  Author: edvin
 */ 
#include <avr/io.h>

void write_EEPROM(uint16_t direccion, uint8_t dato) // Funci�n para escribir en la EEPROM
{
	while (EECR & (1 << EEPE));	// Espera a que la EEPROM termine el proceso anterior
	EEAR = direccion;			// Se carga la direcci�n en la que se guardar�
	EEDR = dato;				// Se carga el dato que se guardar�
	EECR |= (1 << EEMPE);		// Se activa el bit Master
	EECR |= (1 << EEPE);		// Se activa la escritura de la EEPROM
}

uint8_t read_EEPROM(uint16_t direccion)	// Funci�n para leer de la EEPROM
{
	while (EECR & (1 << EEPE));	// Espera a que la EEPROM termine el proceso anterior
	EEAR = direccion;			// Se carga la direcci�n que leer�
	EECR |= (1 << EERE);		// Se habilita el bit de lectura de la EEPROM
	return EEDR;				// Regresa el dato guardado en la direcci�n
}

void save_pos(uint8_t servo, uint8_t state, uint8_t value)	// Funci�n para guardar posici�n de los servos
{
	uint8_t direction = (servo * 4) + state;	// Se hace el c�lculo de la direcci�n a la que apuntar dependiendo del estado y el servo
	write_EEPROM(direction, value);				// Se llama la funci�n de escribir en la EEPROM
}

uint8_t read_pos(uint8_t servo, uint8_t state)	// Funci�n para leer la posici�n de los servos guardada
{
	uint8_t direction = (servo * 4) + state;	// Se hace el c�lculo de la direcci�n a la que apuntar dependiendod del estado y el servo
	return read_EEPROM(direction);				// Se llama la funci�n de leer de la EEPROM
}
