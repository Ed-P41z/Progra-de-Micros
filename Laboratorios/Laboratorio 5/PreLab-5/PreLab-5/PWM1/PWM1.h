/*
 * PWM1.h
 *
 * Created: 4/6/2025 8:04:00 PM
 *  Author: edvin
 */ 


#ifndef PWM1_H_
#define PWM1_H_

// Prototipos de funciones
void initPWM0A(uint8_t invertido, uint16_t perscaler);
void updateDutyCycle_T1(uint16_t duty);
uint16_t ADC_to_PWM_Servo(uint8_t lec_adc);
uint16_t PWM_to_Servo(uint16_t mapeo);

#endif /* PWM1_H_ */