/*
 * PWM2.h
 *
 * Created: 4/7/2025 4:42:52 PM
 *  Author: edvin
 */ 


#ifndef PWM2_H_
#define PWM2_H_

void initPWM2A(uint8_t invertido, uint16_t perscaler);
void updateDutyCycle_T2(uint16_t duty);
uint16_t ADC_to_PWM_ServoT2(uint8_t lec_adc);



#endif /* PWM2_H_ */
