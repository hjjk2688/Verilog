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
}MYIP_TIMER;

//드라이버 인스턴스
static XUartLite g_uart_inst;
static XIntc g_intc_inst;

volatile char g_rx_buffer[100];
volatile int g_rx_index = 0;
volatile int g_new_data_received = 0;

void UartIntrHandler(void *CallBackRef){
	if(XUartLite_GetStatusReg(g_uart_inst.RegBaseAddress) & XUL_SR_RX_FIFO_VALID_DATA){
		char rx_char = Xil_In32(g_uart_inst.RegBaseAddress + XUL_RX_FIFO_OFFSET);

		if(rx_char == '\r' || rx_char == '\n'){
			g_rx_buffer[g_rx_index] = '\0';
			g_new_data_received = 1;
			g_rx_index = 0;
		}
		else{
			if(g_rx_index < (sizeof(g_rx_buffer) - 1)){
				g_rx_buffer[g_rx_index++] = rx_char;
			}
		}
	}

}

int SetupInterruptSystem(){
	int status;
	status = XUartLite_Initialize(&g_uart_inst, XPAR_AXI_UARTLITE_0_DEVICE_ID);
	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}

	status = XIntc_Initialize(&g_intc_inst, XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
	if (status != XST_SUCCESS){
		return XST_FAILURE;
	}

	status = XIntc_Connect(&g_intc_inst, XPAR_MICROBLAZE_0_AXI_INTC_AXI_UARTLITE_0_INTERRUPT_INTR,
			(XInterruptHandler)UartIntrHandler, (void *)0);
	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}

	status = XIntc_Start(&g_intc_inst, XIN_REAL_MODE);
	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}

	XIntc_Enable(&g_intc_inst, XPAR_MICROBLAZE_0_AXI_INTC_AXI_UARTLITE_0_INTERRUPT_INTR);
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XIntc_InterruptHandler, &g_intc_inst);
	Xil_ExceptionEnable();

	XUartLite_EnableInterrupt(&g_uart_inst);

	return XST_SUCCESS;
}


int main () 
{
   //static XIntc intc; // AXI Interrupt Controller (INTC) IP를 위한 드라이버가 정의한 구조체(struct) 타입
   //print("---Entering main---\n\r");
	Xil_ICacheEnable();
	Xil_DCacheEnable();

	printf("---uart interrupt example ---\r\n");

	int status = SetupInterruptSystem();
	if(status != XST_SUCCESS){
		print("Interrupt Setup FAILED\r\n");
		return XST_FAILURE;
	}
	while(1){
		if(g_new_data_received){
			xil_printf("Received: %s \r\n", g_rx_buffer);

			if(strcmp((const char*)g_rx_buffer, "w") == 0){
				* (unsigned int * )XPAR_AXI_GPIO_0_BASEADDR = 0xf;
				* (unsigned int * )XPAR_MYIP_LED4_0_S00_AXI_BASEADDR = 0xf;
			}
			else if (strcmp((const char*)g_rx_buffer, "s") == 0){
				* (unsigned int * )XPAR_AXI_GPIO_0_BASEADDR = 0x0;
				* (unsigned int * )XPAR_MYIP_LED4_0_S00_AXI_BASEADDR = 0x0;
			}
			g_new_data_received = 0;
		}
		else{

			unsigned int * tcReg = (unsigned int *)XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;
			tcReg[0] = (1 << 31) | (100000000 - 1);
			tcReg[1] = (100000000/2)-1;

			MYIP_TIMER * myip_timer = (MYIP_TIMER *)XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;

			myip_timer->slv_reg2 = (1 << 31) | (100000000- 1);
			myip_timer->slv_reg3 = (80000000/2)-1;
			myip_timer->slv_reg4 = (1 << 31) | (100000000 - 1);
			myip_timer->slv_reg5 = (60000000/2)-1;
			myip_timer->slv_reg6 = (1 << 31) | (100000000 - 1);
			myip_timer->slv_reg7 = (40000000/2)-1;
			myip_timer->slv_reg8 = (1 << 31) | (100000000 - 1);
			myip_timer->slv_reg9 = (20000000/2)-1;
			myip_timer->slv_reg10 = (1 << 31) | (100000000 - 1);
			myip_timer->slv_reg11 = (10000000/2)-1;
		}



	}

	Xil_DCacheDisable();
	Xil_ICacheDisable();
	return 0;
}
