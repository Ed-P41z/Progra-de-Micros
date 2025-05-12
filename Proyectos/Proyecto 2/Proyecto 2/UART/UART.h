/*
 * UART.h
 *
 * Created: 5/4/2025 8:04:02 PM
 *  Author: edvin
 */ 


#ifndef UART_H_
#define UART_H_

void initUART();
void writeChar(char caracter);
void escribir_cadena (char* cadena);
uint8_t ascii_to_int(char* i);


#endif /* UART_H_ */