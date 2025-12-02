/*
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * 
 *
 * This file is a generated sample test application.
 *
 * This application is intended to test and/or illustrate some 
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * SDK application project when you run the "Generate Libraries" menu item.
 *
 */

#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xintc.h"
#include "intc_header.h"
#include "xgpio.h"
#include "gpio_header.h"

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


int main () 
{
   static XIntc intc; // AXI Interrupt Controller (INTC) IP를 위한 드라이버가 정의한 구조체(struct) 타입
   Xil_ICacheEnable();
   Xil_DCacheEnable();
   print("---Entering main---\n\r");

   * (unsigned int * )XPAR_AXI_GPIO_0_BASEADDR = 0xf;
   * (unsigned int * )XPAR_MYIP_LED4_0_S00_AXI_BASEADDR = 0xf;
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

   {
      int status;

      print("\r\n Running IntcSelfTestExample() for microblaze_0_axi_intc...\r\n");

      status = IntcSelfTestExample(XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID);

      if (status == 0) {
         print("IntcSelfTestExample PASSED\r\n");
      }
      else {
         print("IntcSelfTestExample FAILED\r\n");
      }
   }

   {
       int Status;

       Status = IntcInterruptSetup(&intc, XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
       if (Status == 0) {
          print("Intc Interrupt Setup PASSED\r\n");
       }
       else {
         print("Intc Interrupt Setup FAILED\r\n");
      }
   }


   /*
    * Peripheral SelfTest will not be run for axi_uartlite_0
    * because it has been selected as the STDOUT device
    */



   print("---Exiting main---\n\r");
   Xil_DCacheDisable();
   Xil_ICacheDisable();
   return 0;
}
