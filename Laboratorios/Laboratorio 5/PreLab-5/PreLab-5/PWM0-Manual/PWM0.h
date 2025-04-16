/*
 * PWM0.h
 *
 * Created: 4/15/2025 11:35:50 PM
 *  Author: edvin
 */ 


#ifndef PWM0_H_
#define PWM0_H_

void initPWM0A();
void pwm0_cp(uint8_t top, uint8_t compare);
uint8_t adc0_map(uint8_t lec_adc0);


#endif /* PWM0_H_ */
