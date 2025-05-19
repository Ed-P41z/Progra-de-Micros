/*
 * UART.h
 *
 * Created: 5/4/2025 8:04:02 PM
 *  Author: edvin
 */ 


#ifndef UART_H
#define UART_H_

void initUART();	// Funci�n para iniciar UART
void writeChar(char caracter);	// Funci�n para escribir caracter
void escribir_cadena (char* cadena);	// Funci�n para escribir cadena
uint8_t ascii_to_int(char* i);	// Funci�n para convertir ascii a int
void enviar_valor_uart(uint16_t valor, char *prefijo);	// Funci�n para enviar UART (Feedback)


#endif /* UART_H_ */