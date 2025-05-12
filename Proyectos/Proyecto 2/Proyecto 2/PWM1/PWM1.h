/*
 * PWM1.h
 *
 * Created: 4/22/2025 6:16:39 PM
 *  Author: edvin
 */ 


#ifndef PWM1_H_
#define PWM1_H_

void initPWM1AB();
uint16_t ADC_to_PWM_ServoT1A(uint8_t lec_adc);
uint16_t ADC_to_PWM_ServoT1B(uint8_t lec_adc);
void updateDutyCycle_T1A(uint16_t duty);
void updateDutyCycle_T1B(uint16_t duty);

#endif /* PWM1_H_ */