; 8051 uC Based Multimeter Design - Assembly Code 
; Microvision Project Version 5
; Designed by Team Of DON BOSCO INSTITUTE OF TECHNOLOGY, MUMBAI.

org 0000h
	JMP begin
	
org 0003h						;interrupt for 0, on interrupt 0 change mode
	JMP mode_select
	
org 0100h
	begin:

	JNB	PSW.4,down1			;----changed by y2g 19jan20
		MOV	Sp,#09h				;----changed by y2g 19jan20  reset stack pointer
		MOV 09,#0F0h			;----changed by y2g 19jan20  update dummy return address on TOS
		MOV 08,#0A0h				;----changed by y2g 19jan20  update dummy return address on TOS
		RETI
		dummy_begin_ret:
		MOV	TCON,#01h			;----changed by y2g 19jan20  clear previous INT0 and config INT0 as -ve edge triggered
		
down1:	MOV	IE,#81h				;enable interrupt 0
		MOV	TCON,#01h			;----changed by y2g 19jan20  clear previous INT0 and config INT0 as -ve edge triggered	
	
	SETB PSW.4				;switching to register bank 2 and initialising the first value to 0
	MOV  R0,#00h
	MOV  R1,#01h			;----changed by y2g 19jan20
	MOV  R2,#01h			;----changed by y2g 19jan20
	MOV  R3,#01h			;----changed by y2g 19jan20
	CLR  PSW.4

//----------------------------------------------------------ac voltage conversion part----------------------------------------------------------
						//in the dsn file a dc source is used instead of the converter to reduce the load on cpu

//----------------------------------------------------------setting up of adc----------------------------------------------------------		
	
	
	MOV P2,#0FFh			;configure p2 as input
	SETB P0.2				;set EOC as input
	CLR P0.0				;set ALE as output
	CLR P0.1				;set SC as output
	CLR P0.3				;set OE as output
	
	CLR P0.5				; A = 0
	CLR P0.6				; B = 0
	CLR P0.7				; C = 0
		
		
	LCALL set_led
	
		
//----------DISPLAY AC VOTAGE TEXT ----------------
	MOV DPTR,#acVoltage
	C1:
		CLR 	A
		MOVC	A,@A+DPTR
		LCALL	datamy
		LCALL	delay
		INC		DPTR
		JNZ		C1

//----------------------------------------reading the adc-------------------------------------
acVolt:						;keep reading and displaying the values

	MOV A,#0C0H				
	ACALL command


	LCALL delay
	
	SETB P0.0				;latch ALE
	SETB P0.1				;start conversion
	
	LCALL delay
	
	CLR P0.0				;latch ALE
	CLR P0.1				;start conversion
	
	LCALL delay
	
	here5:
	JNB P0.2, here5			;check till EOC
	SETB P0.3				;set output enable
	MOV R7,P2				;read port2 values into R7
	CLR P0.3



//-----------------------------conversion part for ac voltage measurement-------------------------------------
	MOV A,R7				
	MOV B,#86d				;valur to be multiplied to get the reading in rms
	
	
	MUL	AB


	//digits are extracted and stored from memory 30h
		MOV		R1,#30h		;Point R1 to memory 30h
		MOV		06,B		;dividend Higher Byte to R6  ---> R6 = 03h
		MOV		07,A		;dividend Lower Byte to  R7  ---> R7 = 0E8h
up1:	MOV		04,#00d		;divisor Higher Byte to  R4  ---> R4 = 00d
		MOV		05,#10d		;divisor Lower Byte to   R5  ---> R5 = 10d
		LCALL	SIDIV
		MOV		@R1,05		//Save Units place in 30h
		INC		R1
		MOV		A,R6
		ORL 	A,R7
		JNZ 	up1

	//	Display Digits one-by-one from memory starting from 30h in reverse order
up2:	DEC		R1
		MOV		A,@R1
		ADD 	A,#30h
		LCALL 	datamy
		CJNE 	R1,#32h,up2	; change here to display only the 3 starting values since these values are the ones that show the value

		MOV 	A,#'V'
		LCALL	datamy
		LCALL	DELAY
		
		
		JMP		acVolt
	
;----------------------------------------------------------resistance part----------------------------------------------------------
res2:
	JNB	PSW.4,down7			;----changed by y2g 19jan20
		MOV	Sp,#09h				;----changed by y2g 19jan20  reset stack pointer
		MOV 09,#0F0h			;----changed by y2g 19jan20  update dummy return address on TOS
		MOV 08,#00h				;----changed by y2g 19jan20  update dummy return address on TOS
		RETI
		dummy_res_ret:
		MOV	TCON,#01h			;----changed by y2g 19jan20  clear previous INT0 and config INT0 as -ve edge triggered

down7:	MOV R0,#01h			;----changed by y2g 19jan20					
		MOV R1,#00h			;----changed by y2g 19jan20
		MOV	R2,#01h			;----changed by y2g 19jan20
		MOV R3,#01h			;----changed by y2g 19jan20
		CLR PSW.4					;back to bank 0

	MOV	TCON,#01h			;----changed by y2g 19jan20  clear previous INT0 and config INT0 as -ve edge triggered
	MOV	IE,#81h		;----changed by y2g 19jan20     enable interrupt 0



	MOV P2,#0FFh			;configure p2 as input
	SETB P0.2				;set EOC as input
	CLR P0.0				;set ALE as output
	CLR P0.1				;set SC as output
	CLR P0.3				;set OE as output
	
	SETB P0.5				; A = 0
	CLR P0.6				; B = 0
	CLR P0.7				; C = 0

	
	ACALL set_led


//----------------------displaying text on lcd-------------------------------
	MOV DPTR,#resistance
	
	D1:
		CLR 	A
		MOVC	A,@A+DPTR
		LCALL	datamy
		LCALL	delay
		INC		DPTR
		JNZ		D1	
	
calc_res:
	
	MOV A,#0C0H				
	ACALL command

	LCALL delay
	
	SETB P0.0				;latch ALE
	SETB P0.1				;start conversion
	
	LCALL delay
	
	CLR P0.0				;latch ALE
	CLR P0.1				;start conversion
	
	LCALL delay
	
	here6:
	JNB P0.2, here6				;check till EOC
	SETB P0.3					;set output enable
	MOV R7,P2					;read port2 values into R7
	CLR P0.3
		
////--------------------MAIN MULTIPLICATION-----------------
				
	MOV A,R7

	MOV A,#0FFh				; the reference voltage taken as 5v so that the value never reaches FF in order to prevent divide by 0
	
	SUBB A,R7
	
	MOV	 R1, A
	
	MOV	A, R7
	MOV B, R1
	
	DIV AB
	
	MOV B, #10d
	DIV AB

	;here B will have rem (units place and A will have quo (tens place)    ;----changed by y2g 19jan20
	
	//MOV R2,B		;not required 	   ;----changed by y2g 19jan20
	//MOV A, B		;not required 	   ;----changed by y2g 19jan20

	ADD A, #30h		;disp tens place   ;----changed by y2g 19jan20
	LCALL datamy
	
	MOV A, B
	ADD A, #30h		;disp units place   ;----changed by y2g 19jan20
	LCALL datamy
	
	
	
// Dispaly Unit

	MOV A,#'K'
	LCALL datamy
	
	MOV A,#' '
	LCALL datamy
	
	MOV A,#'O'
	LCALL datamy
	
	MOV A,#'h'
	LCALL datamy
	
	MOV A,#'m'
	LCALL datamy

	
	JMP	calc_res
	
//----------------------------------------------------------dc voltage part----------------------------------------------------------
dc2:
	JNB	PSW.4,down8			;----changed by y2g 19jan20
		MOV	Sp,#09h				;----changed by y2g 19jan20  reset stack pointer
		MOV 09,#0F0h			;----changed by y2g 19jan20  update dummy return address on TOS
		MOV 08,#07h				;----changed by y2g 19jan20  update dummy return address on TOS
		RETI
		dummy_dc2_ret:
		MOV	TCON,#01h			;----changed by y2g 19jan20  clear previous INT0 and config INT0 as -ve edge triggered

down8:	MOV R0,#01h			;----changed by y2g 19jan20				
		MOV R1,#01h			;----changed by y2g 19jan20
		MOV	R2,#00h			;----changed by y2g 19jan20
		MOV R3,#01h			;----changed by y2g 19jan20
		CLR PSW.4					;back to bank 0

	MOV	TCON,#01h			;----changed by y2g 19jan20  clear previous INT0 and config INT0 as -ve edge triggered
	MOV	IE,#81h		;----changed by y2g 19jan20     enable interrupt 0


	MOV P2,#0FFh			;configure p2 as input
	SETB P0.2				;set EOC as input
	CLR P0.0				;set ALE as output
	CLR P0.1				;set SC as output
	CLR P0.3				;set OE as output
	
	CLR P0.5				; A = 0
	SETB P0.6				; B = 1
	CLR P0.7				; C = 0
	
	ACALL set_led
	
//-----------------displaying text on lcd----------------
	MOV DPTR,#dcVoltage
	
	E1:
		CLR 	A
		MOVC	A,@A+DPTR
		LCALL	datamy
		LCALL	delay
		INC		DPTR
		JNZ		E1
		
		
DC_calc:					;keep reading and displaying

	MOV A,#0C0H				
	ACALL command


	LCALL delay
	
	SETB P0.0				;latch ALE
	SETB P0.1				;start conversion
	
	LCALL delay
	
	CLR P0.0				;latch ALE
	CLR P0.1				;start conversion
	
	LCALL delay
		
	here7:
	JNB P0.2, here7				;check till EOC
	SETB P0.3					;set output enable
	MOV R7,P2				;read port2 values into R7
	CLR P0.3
		
//---------------MAIN MULTIPLICATION------------------------
			
	MOV A,R7
		
	MOV B,#20d
	
	MUL	AB
	
	LCALL show				; in order to prevent repaetation of the extraction and mulltiplication code it has been moved to show
			
		
//----- Dispaly Unit ------

	MOV A,#'m'
	ACALL datamy
	
	MOV A,#'V'
	ACALL datamy
			
	JMP	DC_calc

//----------------------------------------------------------frequency measurement----------------------------------------------------------
freq2:
	JNB	PSW.4,down9			;----changed by y2g 19jun20
		MOV	Sp,#09h				;---  reset stack pointer
		MOV 09,#0F0h			;----   update dummy return address on TOS
		MOV 08,#0Bh				;----  update dummy return address on TOS
		RETI
		dummy_freq2_ret:
		MOV	TCON,#01h			;----  clear previous INT0 and config INT0 as -ve edge triggered

down9:	MOV R0,#01h			;----			
	MOV R1,#01h			;----
	MOV	R2,#01h			;----
	MOV R3,#00h			;----
	CLR PSW.4					;back to bank 0

	MOV	TCON,#01h			;---- clear previous INT0 and config INT0 as -ve edge triggered
	MOV	IE,#81h		;----    enable interrupt 0



	ACALL set_led

//-----------------displaying text on lcd----------------
	
	MOV DPTR,#frequency
	
	F1:
		CLR 	A
		MOVC	A,@A+DPTR
		LCALL	datamy
		LCALL	delay
		INC		DPTR
		JNZ		F1
		
	
	
	freq_calc:	
	
	MOV A,#0C0H				
	ACALL command	
MOV	TMOD,#15h				;counter 0 mode 1 , counter 1 mode 1
MOV TH0, #0FFh
MOV TL0,#0FDh
SETB TR0

SETB TR1
MOV R1,#8
LOOP2: MOV R2,#250
LOOP1:MOV R3,#250
DJNZ R3,$
	DJNZ R2,LOOP1
	DJNZ R1,LOOP2
	
	MOV A,TH1
	ADD A,#30
	ACALL datamy
	MOV A,TL1
	ADD A,#30
	ACALL datamy
;start counter
	// code   remaining//
	

	
	SJMP freq_calc
	
	
	
//----------------------------------------------------------setting the lcd----------------------------------------------------------
set_led:	
	MOV A,#38H				;2 lines and 5x7 matrix
	ACALL command
	
	MOV A,#0EH				;display on cursor blinking
	ACALL command
	
	MOV A,#01H				;clear display screen
	ACALL command

	MOV A,#06H				;increment cursor (shift cursor to right) 
	ACALL command
	
	RET
	
	
	
//----------------------------------------------------------led configuration part----------------------------------------------------------//	
	command:
				MOV P1,A
				CLR P3.6
				//CLR P3.5
				SETB P3.7
				LCALL DELAY
				CLR P3.7
				RET
				
	datamy:
				MOV P1,A
				SETB P3.6
				//CLR P3.5
				SETB P3.7
				LCALL DELAY
				CLR P3.7
				RET

//----------------------------------------------------------SELECTING THE MODE----------------------------------------------------------//	
	
	mode_select:
		SETB PSW.4					;switching to register bank 2 so that a permanent counter can be set up
		CJNE R0,#01h, res
		CJNE R1,#01h, dc
		CJNE R2,#01h, freq
		CJNE R3,#01h, begin2		;on overflow, restart back from start
		
		//since the cjne calls were out of bounds
		res:
			LCALL res2
		dc:
			LCALL dc2
		freq:
			LCALL freq2
		begin2:
			LCALL begin
			
			


org 0800h
	DELAY:      MOV R3,#50
	HERE2:		MOV R4,#255
	HERE: 		DJNZ R4,HERE
				DJNZ R3,HERE2
				RET

				
	DELAY1:   
	MOV R5,#8
	L2:MOV R6,#250
	L1:MOV R7,#250
	DJNZ R7,$
	DJNZ R6,L1
	DJNZ R5,L2
	
	RET
	


//----------------------------------------------------------printing the measurements and multiplication----------------------------------------------------------
show:	
		//digits are extracted and stored from memory 30h
		MOV		R1,#30h		;Point R1 to memory 30h
		MOV		06,B		;dividend Higher Byte to R6  ---> R6 = 03h
		MOV		07,A		;dividend Lower Byte to  R7  ---> R7 = 0E8h
up3:	MOV		04,#00d		;divisor Higher Byte to  R4  ---> R4 = 00d
		MOV		05,#10d		;divisor Lower Byte to   R5  ---> R5 = 10d
		LCALL	SIDIV
		MOV		@R1,05		//Save Units place in 30h
		INC		R1
		MOV		A,R6
		ORL 	A,R7
		JNZ 	up3

		//Display Digits one-by-one from memory starting from 30h in reverse order
up4:	DEC		R1
		MOV		A,@R1
		ADD 	A,#30h
		LCALL 	datamy
		CJNE 	R1,#30h,up4	
		
		RET
		


org	1000h
	
	//This function takes following parameters
	//16-bit Dividend in R6(High) R7(Low)
	//16-bit Divisor  in R4(High) R5(Low)
	//This Function returns following parameters
	//16-bit Remainder in R4(High) R5(Low)
	//16-bit Quotient in  R6(High) R7(Low)	
SIDIV:
		CLR      F0
		MOV      A,R4
		JNB      0xE0.7,LBL01
		CPL      F0
		CLR      A
		CLR      C
		SUBB     A,R5
		MOV      R5,A
		CLR      A
		SUBB     A,R4
		MOV      R4,A
LBL01:	MOV      A,R6
		JNB      0xE0.7,LBL02
		CPL      F0
		CLR      A
		CLR      C
		SUBB     A,R7
		MOV      R7,A
		CLR      A
		SUBB     A,R6
		MOV      R6,A
		LCALL    UIDIV
		CLR      C
		CLR      A
		SUBB     A,R5
		MOV      R5,A
		CLR      A
		SUBB     A,R4
		MOV      R4,A
		SJMP     LBL03
LBL02:	LCALL    UIDIV
LBL03:	JNB      F0,LBL04
		CLR      C
		CLR      A
		SUBB     A,R7
		MOV      R7,A
		CLR      A
		SUBB     A,R6
		MOV      R6,A
LBL04:	RET      
UIDIV:
		CJNE     R4,#0x00,LBL05
		CJNE     R6,#0x00,LBL06
		MOV      A,R7
		MOV      B,R5
		DIV      AB
		MOV      R7,A
		MOV      R5,B
		RET      
LBL05:	CLR      A
		XCH      A,R4
		MOV      R0,A
		MOV      B,#0x08
LBL08:	MOV      A,R7
		ADD      A,R7
		MOV      R7,A
		MOV      A,R6
		RLC      A
		MOV      R6,A
		MOV      A,R4
		RLC      A
		MOV      R4,A
		MOV      A,R6
		SUBB     A,R5
		MOV      A,R4
		SUBB     A,R0
		JC       LBL07
		MOV      R4,A
		MOV      A,R6
		SUBB     A,R5
		MOV      R6,A
		INC      R7
LBL07:	DJNZ     B,LBL08
		CLR      A
		XCH      A,R6
		MOV      R5,A
		RET      
LBL06:	MOV      A,R5
		MOV      R0,A
		MOV      B,A
		MOV      A,R6
		DIV      AB
		JB       OV,LBL09
		MOV      R6,A
		MOV      R5,B
		MOV      B,#0x08
LBL12:	MOV      A,R7
		ADD      A,R7
		MOV      R7,A
		MOV      A,R5
		RLC      A
		MOV      R5,A
		JC       LBL10
		SUBB     A,R0
		JNC      LBL11
		DJNZ     B,LBL12
		RET      
LBL10:	CLR      C
		SUBB     A,R0
LBL11:	MOV      R5,A
		INC      R7
		DJNZ     B,LBL12
LBL09:	RET


org		0F000h
					LJMP dummy_res_ret
org		0F007h
					LJMP dummy_dc2_ret
org		0F00Bh
					LJMP dummy_freq2_ret				
org		0F0A0h
					LJMP dummy_begin_ret



org 0600h
	acVoltage:	DB		"AC RMS VOLT-", 0
	resistance:	DB		"RESISTANCE-",  0
	dcVoltage:	DB		"DC VOLTAGE-",  0
	frequency:	DB		"FREQ",			0

END