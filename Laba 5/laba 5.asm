; Ports:
; 	P0 <- 2356
; 	P1 <- read position: 1,2,3,4
; 	P2 <- task variant: 123

; N of attempts to enter:
; 	N1 = 2
; 	N2 = N1 + 2
; 	N3 = 4 - 2*N2 mod 3
; 	N4 = 3 + N3

; Result:
; 	error: P1 <- AAh 
; 	success: P1 <- 55h, P2 <- 123 (7B)

; Initial P0 == #00h

MOV P1, #01h
MOV P2, #00h
MOV R1, #00h				; N1
MOV R2, #00h				; N2
MOV R3, #00h				; N3
MOV R4, #00h				; N4
MOV R5, #00h				; Reserv
MOV 24h, #00h				; buf = 00

; Cycle of input reading P0

READ:
	MOV A, P0					; A = P0
	XRL A, 24h					; A = A xor buf
	CJNE A, #00h, CHECK_CHANGES	; If changes detected
	AJMP READ					;
	
; Position controller
CHECK_CHANGES:
	MOV 24h, P0					; Buffer update
	JB P1.2, WORK4				; if(curr pos==4)
	JB P1.1, POS23				; if(curr pos==2 or pos==3)
	JB P1.0, WORK1				; if(curr pos==2)
								; else curr pos==1
POS23:
	JB P1.0, WORK3				
	AJMP WORK2


; checking 1st position, must be '2'
WORK1:
	CJNE A, #0100b, FAIL2		; if(P0[2]!=1)
	MOV P1, #02h				; 2nd state -> pos
	MOV A, R1
	ADD A, #02H	
	MOV R5, A					; N1 + 2
	AJMP READ					; -> read cycle

; Error handling 
FAIL1:
	INC R1						; N1 = N1+1
	; check if(N1<=2)
	MOV A, R1					; A = N1
	CLR C						; C = 0
	SUBB A, #03h				; A =A-3; if(A<3): C = 1; else C = 0
	JC N1S						; Jump if C == 1 (N1 > 2)
N1F:
	AJMP FAILURE				; Limit is exceeded
N1S:
	AJMP READ					; -> read cycle

; checking 2nd position, must be '3'
WORK2:
	CJNE A, #1000b, FAIL2		; if(P0[3]!=1)
	MOV P1, #03h				; 3nd state -> pos
	MOV A, R2					; A = N2
	MOV B, #02H					; B = 2
	MUL AB						; A = 2 * N2
	MOV B, #03H					; B = 3
	DIV AB						; B = (2 * N2) % 3
	MOV A, #04H					; A = 4 
	SUBB A, B					; A = 4 - (2 * N2) % 3
	MOV R5, A
	AJMP READ					; -> read cycle	

FAIL2:
	INC R2						; N2 = N2+1
	; check if(N2<=N1 (old N1 + 2))
	MOV A, R2					; A = N2
	CLR C						; C = 0
	SUBB A, R5					; A = A-(N1 + 2); if(A<(N1 + 2)): C = 1; else C = 0
	JC N2S						; Jump if C == 1 (N1 > 2)
N2F:
	AJMP FAILURE				; Limit is exceeded
N2S:
	AJMP READ					; -> read cycle
	
WORK3:
	CJNE A, #100000b, FAIL3		; if(P0[5]!=1)
	MOV P1, #04h
	MOV A, R3
	ADD A, #03H					; N3 + 3
	MOV R5, A
	AJMP READ					; -> read cycle

FAIL3:
	INC R3						; N2 = N2+1
	; check if(N2<=N1 (old N1 + 2))
	MOV A, R3					; A = N2
	CLR C						; C = 0
	SUBB A, R5					; A = A-(N1 + 2); if(A<(N1 + 2)): C = 1; else C = 0
	JC N3S						; Jump if C == 1 (N1 > 2)
N3F:
	AJMP FAILURE				; Limit is exceeded
N3S:
	AJMP READ					; -> read cycle

WORK4:
	CJNE A, #1000000b, FAIL4	; if(P0[6]!=1)
	AJMP SUCCESS
	
FAIL4:
	INC R4						; N2 = N2+1
	; check if(N2<=N1 (old N1 + 2))
	MOV A, R4					; A = N2
	CLR C						; C = 0
	SUBB A, R5					; A = A-(N1 + 2); if(A<(N1 + 2)): C = 1; else C = 0
	JC N4S						; Jump if C == 1 (N1 > 2)
N4F:
	AJMP FAILURE				; Limit is exceeded
N4S:
	AJMP READ					; -> read cycle
	
SUCCESS:
	MOV P1, #55h				; P1 <- SUCCESS code
	MOV P2, #7Bh				; P2 <- 8(var)
	AJMP TERMINATE

FAILURE:
	MOV P1, #0AAh				; P1 <- FAILURE code
TERMINATE:
	END

