/*
 * EEPROM.c
 *
 * Created: 5/8/2025 9:18:10 PM
 *  Author: edvin
 */ 
#include <avr/io.h>

void write_EEPROM(uint16_t direccion, uint8_t dato) // Función para escribir en la EEPROM
{
	while (EECR & (1 << EEPE));	// Espera a que la EEPROM termine el proceso anterior
	EEAR = direccion;			// Se carga la dirección en la que se guardará
	EEDR = dato;				// Se carga el dato que se guardará
	EECR |= (1 << EEMPE);		// Se activa el bit Master
	EECR |= (1 << EEPE);		// Se activa la escritura de la EEPROM
}

uint8_t read_EEPROM(uint16_t direccion)	// Función para leer de la EEPROM
{
	while (EECR & (1 << EEPE));	// Espera a que la EEPROM termine el proceso anterior
	EEAR = direccion;			// Se carga la dirección que leerá
	EECR |= (1 << EERE);		// Se habilita el bit de lectura de la EEPROM
	return EEDR;				// Regresa el dato guardado en la dirección
}

void save_pos(uint8_t servo, uint8_t state, uint8_t value)	// Función para guardar posición de los servos
{
	uint8_t direction = (servo * 4) + state;	// Se hace el cálculo de la dirección a la que apuntar dependiendo del estado y el servo
	write_EEPROM(direction, value);				// Se llama la función de escribir en la EEPROM
}

uint8_t read_pos(uint8_t servo, uint8_t state)	// Función para leer la posición de los servos guardada
{
	uint8_t direction = (servo * 4) + state;	// Se hace el cálculo de la dirección a la que apuntar dependiendod del estado y el servo
	return read_EEPROM(direction);				// Se llama la función de leer de la EEPROM
}
