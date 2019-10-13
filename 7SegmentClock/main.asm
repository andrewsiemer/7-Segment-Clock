; 7 Segment Clock - Microprocessors Project (Fall 2019)
; main.asm
;
; Author : Andrew Siemer <andrew@siemer.org>
; Version: 10.12.19
;

.org 0x100 ; create 7SEG CODE TABLE at address 0x100 (word address, which will be byte address of 200)
.DB  0b01000000,0b01111001,0b0100100,0b00110000,0b00011001,0b00010010,0b00000010,0b01111000,0b00000000,0b00011000
//        0    ,     1    ,     2   ,     3    ,    4     ,    5     ,    6     ,    7     ,    8     ,     9    
.org 0x00
jmp start
.org 0x02
jmp pause

start:
    LDI R16, 0xFF ; load 1's into R16
	OUT DDRB, R16 ; output 1's to configure DDRB as "output" port
	OUT DDRC, R16 ; output 1's to configure DDRC as "output" port
	CBI DDRD, 6

	ldi r23, 0x00  ; seconds one's place
	ldi r24, 0x00  ; seconds ten's place
	ldi r25, 0x00  ; minutes one's place
	ldi r26, 0x00  ; minutes tens's place
	ldi r27, 0x00  ; hours one's place
	ldi r28, 0x00  ; hours one's place
	
	ldi r31,0x0a
	ldi r19, 0x00
	sts eicra, r31	; Set eicra to 00001010 (both interrupts trigger on active low)
	ldi r31, 0x03	; Preload binary 00000011 into r31
	out eimsk, r31	; Set eimsk to 00000011 (enable both interrupts)
	ldi r31, 0x00	; Preload binary 00000000 into r31
	out DDRD, r31	; Set ddrd to 00000000 (all pins of portd are input pins, note you only need pins 2 and 3 for the interrupts)
	ldi r31, 0x0c	; Preload binary 00001100 into r31
	out PORTD, r31	; Set portd to 00001100 (portd pins 2 and 3 are internally hooked to pull up resistors)
	sei				; Set enable interrupts

tog:
	sei						; Set enable interrupts
	LDI R22, 8				; Loop to slow down clock
	LOP_1:LDI R21, 10		; Loop to slow down clock
		LOP_2:LDI R20, 11	; Loop to slow down clock
			LOP_3:
				call displayRefresh	; Refresh LCD digits

				DEC R20			; decriment loop iterater
			BRNE LOP_3		; end loop 3
			DEC R21;		; decriment loop iterater
		BRNE LOP_2		; end loop 3
		DEC R22;		; decriment loop iterater
	BRNE LOP_1		; end loop 3
	
	ldi R31, 0x09	; set compare register
	cp r23, r31		; compare reset register with current register
	brsh resetOnesSeconds	; when equal, reset current register

	inc r23   ; seconds one's place, this should be happening at 1Hz
	jmp tog  ; go to tog

resetOnesSeconds:
	ldi r23, 0x00	; resert register count to 0
	inc r24			; increment following count by 1

	ldi R31, 0x06			; set compare register
	cp r24, r31				; compare reset register with current register
	brsh resetTensSeconds	; when equal, reset current register
	jmp tog					; go to tog
	
resetTensSeconds:
	ldi r24, 0x00			; resert register count to 0
	inc r25					; increment following count by 1

	ldi r31, 0x09			; set compare register
	cp r25, r31				; compare reset register with current register
	brsh resetOnesMinutes	; when equal, reset current register
	jmp tog					; go to tog
	
resetOnesMinutes:
	ldi r25, 0x00			; resert register count to 0
	inc r26					; increment following count by 1

	ldi R31, 0x06			; set compare register
	cp r26, r31				; compare reset register with current register
	brsh resetTensMinutes	; when equal, reset current register
	jmp tog					; go to tog
	
resetTensMinutes:
	ldi r26, 0x00			; resert register count to 0
	inc r27					; increment following count by 1

	ldi r31, 0x09			; set compare register
	cp r27, r31				; compare reset register with current register
	brsh resetOnesHours		; when equal, reset current register
	jmp tog					; go to tog
	
resetOnesHours:
	ldi r27, 0x00		; resert register count to 0
	inc r28				; increment following count by 1

	ldi R31, 0x09		; set compare register
	cp r28, r31			; compare reset register with current register
	brsh resetAll		; when equal, reset current register
	jmp tog				; go to tog

resetAll:
	jmp start			; go to start of program

delay:
	ldi r30, 60			; set register to 60
	LOP:
		dec r30			; decrement register value
	BRNE LOP			; end loop 1
	ret					; return to function call

displayRefresh:
	ldi r18, 0b101	; set current digit
	ldi zh,02		; load high byte of z register with high hex portion of 7SEG CODE TABLE address (x2, since it is byte addressing)
	ldi zl,00		; load low byte of z register with low hex portion of table address
	add zl,r23		; add the BCD value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r17,z		; load z into r17 from program memory from 7SEG CODE TABLE using modified z register as pointer
	out PORTB, r17  ; output r17, segment data
	out PORTC, r18  ; output r18, digit data

	call delay		; delay before refreshing

	dec r18		    ; set current digit
	ldi zh,02	    ; load high byte of z register with high hex portion of 7SEG CODE TABLE address (x2, since it is byte addressing)
	ldi zl,00	    ; load low byte of z register with low hex portion of table address
	add zl,r24      ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r17,z	    ; load z into r17 from program memory from 7SEG CODE TABLE using modified z register as pointer
	out PORTB, r17  ; output r18, digit data
	out PORTC, r18  ; output r18, digit data

	call delay		; delay before refreshing

	dec r18		    ; set current digit
	ldi zh,02	    ; load high byte of z register with high hex portion of 7SEG CODE TABLE address (x2, since it is byte addressing)
	ldi zl,00	    ; load low byte of z register with low hex portion of table address
	add zl,r25	    ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r17,z	    ; load z into r17 from program memory from 7SEG CODE TABLE using modified z register as pointer
	out PORTB, r17  ; output r18, digit data
	out PORTC, r18  ; output r18, digit data

	call delay		; delay before refreshing

	dec r18		    ; set current digit
	ldi zh,02	    ; load high byte of z register with high hex portion of 7SEG CODE TABLE address (x2, since it is byte addressing)
	ldi zl,00	    ; load low byte of z register with low hex portion of table address
	add zl,r26	    ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r17,z	    ; load z into r17 from program memory from 7SEG CODE TABLE using modified z register as pointer
	out PORTB, r17  ; output r18, digit data
	out PORTC, r18  ; output r18, digit data

	call delay		; delay before refreshing

	dec r18		    ; set current digit
	ldi zh,02	    ; load high byte of z register with high hex portion of 7SEG CODE TABLE address (x2, since it is byte addressing)
	ldi zl,00	    ; load low byte of z register with low hex portion of table address
	add zl,r27	    ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r17,z	    ; load z into r17 from program memory from 7SEG CODE TABLE using modified z register as pointer
	out PORTB, r17  ; output r18, digit data
	out PORTC, r18  ; output r18, digit data

	call delay		; delay before refreshing

	dec r18		    ; set current digit
	ldi zh,02	    ; load high byte of z register with high hex portion of 7SEG CODE TABLE address (x2, since it is byte addressing)
	ldi zl,00	    ; load low byte of z register with low hex portion of table address
	add zl,r28	    ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r17,z	    ; load z into r17 from program memory from 7SEG CODE TABLE using modified z register as pointer
	out PORTB, r17  ; output r18, digit data
	out PORTC, r18  ; output r18, digit data

	call delay		; delay before refreshing
	ret				; return to function call

pause:
	ldi r31, 0x00
	cp r19, r31
	breq freeze
	ldi r31, 0x01
	cp r19, r31
	breq unfreeze

freeze:
	ldi r19, 0x01
	call displayRefresh

	sei
	
	

	jmp freeze

unfreeze:
	ldi r19, 0x00
	jmp tog

incrementSeconds:
	/*ldi r23, 0x00
	ldi r24, 0x00*/
	
