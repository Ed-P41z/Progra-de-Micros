/*
 * PWM1.h
 *
 * Created: 4/22/2025 6:16:39 PM
 *  Author: edvin
 */ 


#ifndef PWM1_H_
#define PWM1_H_

void initPWM1AB();	// Función para iniciar PWM 1, canales A y B
uint16_t ADC_to_PWM_ServoT1A(uint8_t lec_adc);	// Función para convertir valor ADC a valor PWM1A
uint16_t ADC_to_PWM_ServoT1B(uint8_t lec_adc);	// Función para convertir valor ADC a valor PWM1B
void updateDutyCycle_T1A(uint16_t duty);	// Función para actualizar el duty cycle del PWM1A
void updateDutyCycle_T1B(uint16_t duty);	// Función para actualizar el duty cycle del PWM1B

#endif /* PWM1_H_ */