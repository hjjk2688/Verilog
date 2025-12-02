#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xintc.h"
#include "intc_header.h"
#include "xgpio.h"
#include "gpio_header.h"
#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xil_exception.h"

typedef struct _MYIP_TIMER {
	volatile uint32_t slv_reg0;
	volatile uint32_t slv_reg1;
	volatile uint32_t slv_reg2;
	volatile uint32_t slv_reg3;
	volatile uint32_t slv_reg4;
	volatile uint32_t slv_reg5;
	volatile uint32_t slv_reg6;
	volatile uint32_t slv_reg7;
	volatile uint32_t slv_reg8;
	volatile uint32_t slv_reg9;
	volatile uint32_t slv_reg10;
	volatile uint32_t slv_reg11;
} MYIP_TIMER;

//드라이버 인스턴스
static XUartLite g_uart_inst;
static XIntc g_intc_inst;

volatile char g_rx_buffer[100];
volatile int g_rx_index = 0;
volatile int g_new_data_received = 0; // flag
volatile char g_received_char; // 한bit씩 받기

static unsigned int *motorReg = (unsigned int *)XPAR_MYIP_MOTOR_0_S00_AXI_BASEADDR; // motor PWM

void UartIntrHandler(void *CallBackRef) {
	// 수신 버퍼에 데이터가 있는지 확인
	if (XUartLite_GetStatusReg(	g_uart_inst.RegBaseAddress) & XUL_SR_RX_FIFO_VALID_DATA) {
		// 한 글자를 읽어서 전역 변수에 저장
		g_received_char = Xil_In32(g_uart_inst.RegBaseAddress + XUL_RX_FIFO_OFFSET);
		// "새 글자 도착!" 깃발을 올림
		g_new_data_received = 1;
	}
}

int SetupInterruptSystem() {
	int status;
	status = XUartLite_Initialize(&g_uart_inst, XPAR_AXI_UARTLITE_0_DEVICE_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	status = XIntc_Initialize(&g_intc_inst,
			XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	status = XIntc_Connect(&g_intc_inst,
			XPAR_MICROBLAZE_0_AXI_INTC_AXI_UARTLITE_0_INTERRUPT_INTR,
			(XInterruptHandler) UartIntrHandler, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	status = XIntc_Start(&g_intc_inst, XIN_REAL_MODE);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XIntc_Enable(&g_intc_inst,
			XPAR_MICROBLAZE_0_AXI_INTC_AXI_UARTLITE_0_INTERRUPT_INTR);
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XIntc_InterruptHandler, &g_intc_inst);
	Xil_ExceptionEnable();

	XUartLite_EnableInterrupt(&g_uart_inst);

	return XST_SUCCESS;
}


void SetMotor(int motor_idx, int dir, unsigned int period, unsigned int duty) {
    int base = motor_idx * 4;
    if (dir == 1) { // 전진
        motorReg[base] = (1 << 31) | period;
        motorReg[base+1] = duty;
        motorReg[base+2] = 0;
        motorReg[base+3] = 0;
    }
    else if(dir == 2){ // 후진
        motorReg[base] = 0;
        motorReg[base+1] = 0;
        motorReg[base+2] = (1 << 31) | period;
        motorReg[base+3] = duty;
    }

    else if(dir == 0){ // 정지
        motorReg[base] = 0;
        motorReg[base+1] = 0;
        motorReg[base+2] = 0;
        motorReg[base+3] = 0;
    }
}

void forward(unsigned int period, unsigned int duty) {
    SetMotor(2, 1, period, duty); // 우앞
    SetMotor(3, 1, period, duty); // 좌앞
    SetMotor(0, 1, period, duty); // 좌뒤
    SetMotor(1, 1, period, duty); // 우뒤
}

void backward(unsigned int period, unsigned int duty) {
    SetMotor(2, 2, period, duty); // 우앞
    SetMotor(3, 2, period, duty); // 좌앞
    SetMotor(0, 2, period, duty); // 좌뒤
    SetMotor(1, 2, period, duty); // 우뒤
}

void left(unsigned int period, unsigned int duty) {
    SetMotor(2, 2, period, duty); // 우앞
    SetMotor(3, 1, period, duty); // 좌앞
    SetMotor(0, 1, period, duty); // 좌뒤
    SetMotor(1, 2, period, duty); // 우뒤
}

void right(unsigned int period, unsigned int duty) {
    SetMotor(2, 1, period, duty); // 우앞
    SetMotor(3, 2, period, duty); // 좌앞
    SetMotor(0, 2, period, duty); // 좌뒤
    SetMotor(1, 1, period, duty); // 우뒤
}

void stop(unsigned int period, unsigned int duty) {
    SetMotor(2, 0, period, duty); // 우앞
    SetMotor(3, 0, period, duty); // 좌앞
    SetMotor(0, 0, period, duty); // 좌뒤
    SetMotor(1, 0, period, duty); // 우뒤
}

int main() {
	//static XIntc intc; // AXI Interrupt Controller (INTC) IP를 위한 드라이버가 정의한 구조체(struct) 타입

	Xil_ICacheEnable();
	Xil_DCacheEnable();


	unsigned int period_val = (100000000 / 1000) - 1;
	unsigned int duty_val = period_val / 2; // 시작 속도 50%
	unsigned int duty_step = period_val / 200; // 속도 변경 단계 (0.5%)
	unsigned int min_duty_val = period_val / 4; // 최저 속도 (25%)

	//unsigned int * tcReg = (unsigned int *) XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;

	int status = SetupInterruptSystem();

	if (status != XST_SUCCESS) {
		print("Interrupt Setup FAILED\r\n");
		return XST_FAILURE;
	}

	while(1){
		if(g_new_data_received){
			xil_printf("Received: %c \r\n", g_received_char);
			if(g_received_char == 'w'){
				duty_val += duty_step;
				if (duty_val > period_val) duty_val = period_val; // 최대 100%로 제한
				xil_printf("Speed Up! Duty: %d\r\n", duty_val);
				forward(period_val, duty_val);

			}
			else if(g_received_char == 's'){
				// duty_val에서 duty_step을 빼고, 그 결과가 최저 속도보다 낮거나 오버플로우가 발생했는지 확인
				duty_val -= duty_step;
				if (duty_val < min_duty_val || duty_val > period_val) {
					duty_val = min_duty_val; // 최저 10%로 제한
				}
				xil_printf("Speed Down! Duty: %d\r\n", duty_val);

				backward(period_val, duty_val);

			}
			else if(g_received_char == 'a'){

				left(period_val, duty_val);

			}
			else if(g_received_char == 'd'){

				right(period_val, duty_val);


			}
			else if(g_received_char == 'f'){
				stop(period_val, duty_val);

			}
			g_new_data_received = 0;
		}


	}

	Xil_DCacheDisable();
	Xil_ICacheDisable();
	return 0;
}
