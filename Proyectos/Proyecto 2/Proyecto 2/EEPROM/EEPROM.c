/*
 * EEPROM.c
 *
 * Created: 5/8/2025 9:18:10 PM
 *  Author: edvin
 */ 
#include <avr/io.h>

void write_EEPROM(uint16_t direccion, uint8_t dato) {
	while (EECR & (1 << EEPE));
	EEAR = direccion;
	EEDR = dato;
	EECR |= (1 << EEMPE);
	EECR |= (1 << EEPE);
}

uint8_t read_EEPROM(uint16_t direccion) {
	while (EECR & (1 << EEPE));
	EEAR = direccion;
	EECR |= (1 << EERE);
	return EEDR;
}

void save_pos(uint8_t servo, uint8_t state, uint8_t value)
{
	uint8_t direction = (servo * 4) + state;
	write_EEPROM(direction, value);
}

uint8_t read_pos(uint8_t servo, uint8_t state)
{
	uint8_t direction = (servo * 4) + state;
	return read_EEPROM(direction);
}
