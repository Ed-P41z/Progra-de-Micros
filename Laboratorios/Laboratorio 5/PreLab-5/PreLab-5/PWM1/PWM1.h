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
void updateDutyCycle_T1(uint8_t duty);

#endif /* PWM1_H_ */