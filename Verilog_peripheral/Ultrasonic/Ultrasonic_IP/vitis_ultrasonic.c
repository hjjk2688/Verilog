#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xintc.h"
#include "intc_header.h"
#include "xgpio.h"
#include "gpio_header.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

#define ULTRASONIC_IP_BASEADDR XPAR_MYIP_ULTRASONIC_FSM_0_S00_AXI_BASEADDR
#define REG0_OFFSET 0
int main ()
{
	Xil_ICacheEnable();
	Xil_DCacheEnable();

	xil_printf("Program Start \r\n");
	u32 reg_value; // 레지스터에서 읽어온 32비트 전체 값
	u32 distance;  // 32비트 값에서 추출한 10비트 거리 값

	while(1){
		reg_value = Xil_In32(ULTRASONIC_IP_BASEADDR + REG0_OFFSET);
		distance = reg_value & 0x3FF;

		xil_printf("Measured Distance: %d cm\r\n", distance);

		sleep(1); // trig_En 1초마다 활성화 되기떄문에  1초 delay를 줘서 맞춰준다. 
	}



	Xil_ICacheDisable();
	Xil_DCacheDisable();
   return 0;
}
