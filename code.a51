; Hardware Definitions
RS      EQU P2.7    ; LCD Register Select
RW      EQU P2.6    ; LCD Read/Write
E       EQU P2.5    ; LCD Enable
SEL     EQU 41H     ; Selection flag
BUZZER  EQU P2.1    ; Buzzer output
SERVO   EQU P2.2    ; Servo control
PIR     EQU P1.5    ; PIR sensor input

ORG 000H            ; Start at address 000H
CLR P2.0            ; Clear door flag (close door)
MOV TMOD, #00100001B ; Timer 0 mode 1, Timer 1 mode 2
MOV TH1, #253D      ; Timer 1 reload value for baud rate
MOV SCON, #50H      ; Serial mode 1, receive enabled
SETB TR1            ; Start Timer 1
ACALL LCD_INIT      ; Initialize LCD
MOV DPTR, #TEXT1    ; Load text1 address
ACALL LCD_OUT       ; Display text1
ACALL LINE2         ; Move to line 2
MOV DPTR, #TEXT2    ; Load text2 address
ACALL LCD_OUT       ; Display text2

MAIN:
    ACALL LCD_INIT      ; Reinitialize LCD
    MOV DPTR, #TEXT1   ; Load text1 address
    ACALL LCD_OUT      ; Display text1
    ACALL LINE2        ; Move to line 2
    MOV DPTR, #TEXT2   ; Load text2 address
    CLR P2.0           ; Ensure door is closed
    ACALL LCD_OUT      ; Display text2
    ACALL DELAY1       ; Delay
    ACALL DELAY1       ; Delay
    ACALL READ_KEYPRESS ; Read keypad input
    ACALL LINE1        ; Move to line 1
    MOV DPTR, #CHKMSG  ; Load checking message
    ACALL LCD_OUT      ; Display checking message
    ACALL DELAY1       ; Delay
    ACALL CHECK_PASSWORD ; Check entered password
    SJMP MAIN          ; Loop back to main

LCD_INIT: MOV DPTR,#INIT_COMMANDS ; Load init commands
          SETB SEL               ; Set command mode
          ACALL LCD_OUT          ; Send commands
          CLR SEL                ; Clear command mode
          RET                    ; Return

LCD_OUT:  CLR A                 ; Clear accumulator
           MOVC A,@A+DPTR       ; Load character from code
           JZ EXIT              ; Exit if null terminator
           INC DPTR             ; Point to next character
           JB SEL,CMD          ; If SEL set, send command
           ACALL DATA_WRITE     ; Else write data
           SJMP LCD_OUT         ; Loop
CMD:      ACALL CMD_WRITE       ; Write command
           SJMP LCD_OUT         ; Loop
EXIT:	   RET                  ; Return

LINE2:MOV A,#0C0H          ; LCD line 2 command
    ACALL CMD_WRITE        ; Send command
    RET                    ; Return
    
LINE1: MOV A,#80H          ; LCD line 1 command
ACALL CMD_WRITE            ; Send command
RET

CLRSCR: MOV A,#01H         ; Clear screen command
ACALL CMD_WRITE            ; Send command
RET

CMD_WRITE: MOV P0,A        ; Send command to LCD
    CLR RS                 ; Command mode
    CLR RW                 ; Write mode
    SETB E                 ; Enable LCD
    CLR E                  ; Disable LCD
    ACALL DELAY            ; Wait
    RET

DATA_WRITE:MOV P0,A        ; Send data to LCD
    SETB RS                ; Data mode
    CLR RW                 ; Write mode
    SETB E                 ; Enable LCD
    CLR E                  ; Disable LCD
    ACALL DELAY            ; Wait
    RET

DELAY: CLR E               ; Clear enable
    CLR RS                 ; Command mode
    SETB RW                ; Read mode
    MOV P0,#0FFh           ; Set port to read
    SETB E                 ; Enable LCD
    MOV A,P0               ; Read busy flag
    JB ACC.7,DELAY         ; Wait if busy
    CLR E                  ; Disable LCD
    CLR RW                 ; Write mode
    RET

DELAY_250MS:             ; 250ms delay
        MOV R3, #250     ; Counter
DELAY_LOOP:
        MOV TH0, #0FCh   ; Timer high byte
        MOV TL0, #018h   ; Timer low byte
        SETB TR0         ; Start timer
HERE:   JNB TF0, HERE    ; Wait for overflow
        CLR TR0          ; Stop timer
        CLR TF0          ; Clear flag
        DJNZ R3, DELAY_LOOP
        RET
    
DELAY1:MOV R3,#46D       ; Delay counter
BACK:  MOV TH0,#00000000B ; Timer high byte
       MOV TL0,#00000000B ; Timer low byte
       SETB TR0           ; Start timer
HERE1: JNB TF0,HERE1      ; Wait for overflow
       CLR TR0            ; Stop timer
       CLR TF0            ; Clear flag
       DJNZ R3,BACK       ; Loop
       RET
       
DELAY2: MOV R3,#250D      ; Delay counter
BACK2:   MOV TH0,#0FCH    ; Timer high byte
        MOV TL0,#018H     ; Timer low byte
        SETB TR0          ; Start timer
HERE2:  JNB TF0,HERE2     ; Wait for overflow
        CLR TR0           ; Stop timer
        CLR TF0           ; Clear flag
        DJNZ R3,BACK2     ; Loop
        RET       


READ_KEYPRESS: ACALL CLRSCR ; Clear screen
ACALL LINE1                 ; Move to line 1
MOV DPTR,#IPMSG             ; Load input message
ACALL LCD_OUT               ; Display message
ACALL LINE2                ; Move to line 2
MOV R0,#5D                 ; 5 digits to read
MOV R1,#160D               ; Storage location
ROTATE:ACALL KEY_SCAN      ; Get keypress
MOV @R1,A                  ; Store digit
ACALL DATA_WRITE           ; Display digit
ACALL DELAY2               ; Delay
INC R1                     ; Next location
DJNZ R0,ROTATE             ; Loop for all digits
RET

CHECK_PASSWORD:
    MOV R0, #5D
    MOV R1, #160D
    MOV DPTR, #PASSW 
RPT:
    CLR A
    MOVC A, @A+DPTR
    XRL A, @R1
    JNZ FAIL
    INC R1
    INC DPTR
    DJNZ R0, RPT
    ; Correct password actions
    ACALL CLRSCR
    ACALL LINE1
    MOV DPTR, #TEXT_S1
    ACALL LCD_OUT
    ACALL LINE2
    MOV DPTR, #TEXT_S2
    ACALL LCD_OUT
    ACALL SERVO_OPEN    ; Open door 180°
    SETB P2.0          ; Set door open flag
    ACALL MONITOR_PIR  ; Start PIR monitoring
    SJMP GOBACK
FAIL:   ; Wrong password branch
        ACALL CLRSCR 
        ACALL LINE1
        MOV DPTR,#TEXT_F1
        ACALL LCD_OUT
        ACALL DELAY1
        ACALL LINE2
        MOV DPTR,#TEXT_F2
        ACALL LCD_OUT
        ACALL DELAY1
        
        ; Buzzer activation (Active Low)
        CLR BUZZER       ; Turn ON buzzer
        MOV R5, #8       ; 8 * 250ms = 2s
BUZZ_LOOP:
        ACALL DELAY_250MS
        DJNZ R5, BUZZ_LOOP
        SETB BUZZER      ; Turn OFF buzzer
        
GOBACK: RET

; New PIR Monitoring Routine
MONITOR_PIR:
    ACALL DELAY1
MONITOR_LOOP:
    JB PIR, PERSON_DETECTED
    SJMP MONITOR_LOOP

PERSON_DETECTED:
    ACALL CLRSCR
    ACALL LINE1
    MOV DPTR, #TEXT_S3
    ACALL LCD_OUT
    ACALL SERVO_CLOSE  ; Close door
    CLR P2.0           ; Clear door flag
    ACALL DELAY1
    RET


;----- Servo Control Routines -----

; Modified Servo Routines
SERVO_OPEN:
    MOV R7, #200       ; 200 cycles (2 seconds)
SERVO_OPEN_LOOP:
    SETB SERVO         ; 2ms pulse for 180°
    ACALL DELAY_2MS
    CLR SERVO
    ACALL DELAY_18_5MS
    DJNZ R7, SERVO_OPEN_LOOP
    RET

SERVO_CLOSE:
    MOV R7, #200       ; 200 cycles (2 seconds)
SERVO_CLOSE_LOOP:
    SETB SERVO         ; 1ms pulse for 0°
    ACALL DELAY_1MS
    CLR SERVO
    ACALL DELAY_18_5MS
    DJNZ R7, SERVO_CLOSE_LOOP
    RET

; Additional Delay Routines
DELAY_2MS:
    MOV TH0, #0F8h     ; 2ms delay
    MOV TL0, #030h
    SETB TR0
WAIT2MS:
    JNB TF0, WAIT2MS
    CLR TR0
    CLR TF0
    RET

DELAY_1MS:
    MOV TH0, #0FCh     ; 1ms delay
    MOV TL0, #018h
    SETB TR0
WAIT1MS:
    JNB TF0, WAIT1MS
    CLR TR0
    CLR TF0
    RET
DELAY_18_5MS:       ; 18.5ms delay (Timer 0)
    MOV TH0, #0B7h  ; 0B7ACh = 47036 (12MHz)
    MOV TL0, #0ACh
    SETB TR0
WAIT2:
    JNB TF0, WAIT2
    CLR TR0
    CLR TF0
    RET

KEY_SCAN:MOV P3,#11111111B 
CLR P3.0 
JB P3.4, NEXT1 
MOV A,#49D
RET

NEXT1:JB P3.5,NEXT2
MOV A,#50D

RET
NEXT2: JB P3.6,NEXT3
MOV A,#51D

RET
NEXT3: JB P3.7,NEXT4
MOV A,#65D

RET
NEXT4:SETB P3.0
CLR P3.1 
JB P3.4, NEXT5 
MOV A,#52D

RET
NEXT5:JB P3.5,NEXT6
MOV A,#53D

RET
NEXT6: JB P3.6,NEXT7
MOV A,#54D
RET
NEXT7: JB P3.7,NEXT8
MOV A,#66D

RET
NEXT8:SETB P3.1
CLR P3.2
JB P3.4, NEXT9 
MOV A,#55D

RET
NEXT9:JB P3.5,NEXT10
MOV A,#56D

RET
NEXT10: JB P3.6,NEXT11
MOV A,#57D

RET
NEXT11: JB P3.7,NEXT12
MOV A,#67D

RET
NEXT12:SETB P3.2
CLR P3.3
JB P3.4, NEXT13 
MOV A,#42D

RET
NEXT13:JB P3.5,NEXT14
MOV A,#48D

RET
NEXT14: JB P3.6,NEXT15
MOV A,#35D

RET
NEXT15: JB P3.7,NEXT16
MOV A,#68D
RET
NEXT16:LJMP KEY_SCAN


INIT_COMMANDS:  DB 0CH,01H,06H,80H,3CH,0    
TEXT1: DB "PASSWORD BASED",0 
TEXT2: DB "SECURITY SYSTEM",0 
IPMSG: DB "INPUT 5 DIGITS",0
CHKMSG: DB "CHECKING PASSWORD",0
TEXT_S1: DB "ACCESS - GRANTED",0
TEXT_S2: DB "MONITORING...",0   ; Changed
TEXT_S3: DB "PERSON DETECTED!",0 ; New
TEXT_F1: DB "WRONG PASSWORD",0
TEXT_F2: DB "ACCESS DENIED",0
PASSW: DB 49D,50D,51D,52D,53D,0
END
