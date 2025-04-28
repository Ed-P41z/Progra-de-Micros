/*
 * PWM0.h
 *
 * Created: 4/22/2025 6:15:59 PM
 *  Author: edvin
 */ 


#ifndef PWM0_H_
#define PWM0_H_

void initPWM0AB();
uint16_t ADC_to_PWM_ServoT0(uint8_t lec_adc);
void updateDutyCycle_T0A(uint16_t duty);
void updateDutyCycle_T0B(uint16_t duty);

#endif /* PWM0_H_ */