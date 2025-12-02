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

//드라이버 인스턴스
static XUartLite g_uart_inst;
static XIntc g_intc_inst; // AXI Interrupt Controller (INTC) IP를 위한 드라이버가 정의한 구조체(struct) 타입


volatile int g_new_data_received = 0; // flag
volatile char g_received_char; // 한bit씩 받기


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

int main() {
	//static XIntc intc; // AXI Interrupt Controller (INTC) IP를 위한 드라이버가 정의한 구조체(struct) 타입
	//print("---Entering main---\n\r");
	Xil_ICacheEnable();
	Xil_DCacheEnable();


	unsigned int period_val = (100000000 / 1000) - 1;
	unsigned int duty_val = period_val / 2;

	//unsigned int * tcReg = (unsigned int *) XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;
	unsigned int * motorReg = (unsigned int *) XPAR_MYIP_MOTOR_0_S00_AXI_BASEADDR;

	//printf("---uart interrupt example ---\r\n");

	int status = SetupInterruptSystem();

	if (status != XST_SUCCESS) {
		print("Interrupt Setup FAILED\r\n");
		return XST_FAILURE;
	}

	while(1){
		if(g_new_data_received){
			xil_printf("Received: %c \r\n", g_received_char);
			if(g_received_char == 'w'){

				motorReg[8] = (1 << 31) | period_val; // 우앞
				motorReg[9] = duty_val;
				motorReg[10] = 0;
				motorReg[11] = 0;

				motorReg[12] = (1 << 31) | period_val; // 좌앞
				motorReg[13] = duty_val;
				motorReg[14] = 0;
				motorReg[15] = 0;

				motorReg[0] = (1 << 31) | period_val;  // 좌뒤
				motorReg[1] = duty_val;
				motorReg[2] = 0;
				motorReg[3] = 0;

				motorReg[4] = (1 << 31) | period_val; // 우뒤
				motorReg[5] = duty_val;
				motorReg[6] = 0;
				motorReg[7] = 0;


			}
			else if(g_received_char == 's'){
				motorReg[8] = 0; // 우앞
				motorReg[9] = 0;
				motorReg[10] = (1 << 31) | period_val;
				motorReg[11] = duty_val;

				motorReg[12] = 0; // 좌앞
				motorReg[13] = 0;
				motorReg[14] = (1 << 31) | period_val;
				motorReg[15] = duty_val;

				motorReg[0] = 0;  // 좌뒤
				motorReg[1] = 0;
				motorReg[2] = (1 << 31) | period_val;
				motorReg[3] = duty_val;

				motorReg[4] = 0; // 우뒤
				motorReg[5] = 0;
				motorReg[6] = (1 << 31) | period_val;
				motorReg[7] = duty_val;


			}
			else if(g_received_char == 'a'){
				motorReg[8] = 0; // 우앞
				motorReg[9] = 0;
				motorReg[10] = (1 << 31) | period_val;
				motorReg[11] = duty_val;

				motorReg[12] = (1 << 31) | period_val; // 좌앞
				motorReg[13] = duty_val;
				motorReg[14] = 0;
				motorReg[15] = 0;

				motorReg[0] = (1 << 31) | period_val;  // 좌뒤
				motorReg[1] = duty_val;
				motorReg[2] = 0;
				motorReg[3] = 0;

				motorReg[4] = 0; // 우뒤
				motorReg[5] = 0;
				motorReg[6] = (1 << 31) | period_val;
				motorReg[7] = duty_val;

			}
			else if(g_received_char == 'd'){
				motorReg[8] = (1 << 31) | period_val; // 우앞
				motorReg[9] = duty_val;
				motorReg[10] = 0;
				motorReg[11] = 0;

				motorReg[12] = 0; // 좌앞
				motorReg[13] = 0;
				motorReg[14] = (1 << 31) | period_val;
				motorReg[15] = duty_val;

				motorReg[0] = 0;  // 좌뒤
				motorReg[1] = 0;
				motorReg[2] = (1 << 31) | period_val;
				motorReg[3] = duty_val;

				motorReg[4] = (1 << 31) | period_val; // 우뒤
				motorReg[5] = duty_val;
				motorReg[6] = 0;
				motorReg[7] = 0;


			}
			else if(g_received_char == 'f'){
				motorReg[8] = 0; // 우앞
				motorReg[9] = 0;
				motorReg[10] = 0;
				motorReg[11] = 0;

				motorReg[12] = 0; // 좌앞
				motorReg[13] = 0;
				motorReg[14] = 0;
				motorReg[15] = 0;

				motorReg[0] = 0;  // 좌뒤
				motorReg[1] = 0;
				motorReg[2] = 0;
				motorReg[3] = 0;

				motorReg[4] = 0; // 우뒤
				motorReg[5] = 0;
				motorReg[6] = 0;
				motorReg[7] = 0;


			}
			g_new_data_received = 0;
		}


	}

	Xil_DCacheDisable();
	Xil_ICacheDisable();
	return 0;
}
