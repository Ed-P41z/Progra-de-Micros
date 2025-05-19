/*
 * EEPROM.h
 *
 * Created: 5/8/2025 9:17:58 PM
 *  Author: edvin
 */ 

#ifndef EEPROM_H_
#define EEPROM_H_

void write_EEPROM(uint16_t direccion, uint8_t dato);		// Función de escribir EEPROM
uint8_t read_EEPROM(uint16_t direccion);					// Función de leer EEPROM
void save_pos(uint8_t servo, uint8_t state, uint8_t value);	// Función de guardar posición
uint8_t read_pos(uint8_t servo, uint8_t state);				// Función de leer posición


#endif /* EEPROM_H_ */