/*
 * PWM0.h
 *
 * Created: 4/22/2025 6:15:59 PM
 *  Author: edvin
 */ 


#ifndef PWM0_H_
#define PWM0_H_

void initPWM0AB();	// Funci�n para iniciar PWM 0, canales A y B
uint16_t ADC_to_PWM_ServoT0A(uint8_t lec_adc);	// Funci�n para convertir valor ADC a valor PWM0A
uint16_t ADC_to_PWM_ServoT0B(uint8_t lec_adc);	// Funci�n para convertir valor ADC a valor PWM0B
void updateDutyCycle_T0A(uint16_t duty);	// Funci�n para actualizar el duty cycle del PWM0A
void updateDutyCycle_T0B(uint16_t duty);	// Funci�n para actualizar el duty cycle del PWM0B


#endif /* PWM0_H_ */