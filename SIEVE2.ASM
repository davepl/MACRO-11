;-----------------------------------------------------------------------
; SIEVE2.ASM - Sieve of Eratosthenes in PDP-11 assembly language
;             by Dave Plummer 2024
;-----------------------------------------------------------------------
; 
; This variant uses a single bit per number to mark composites, rather
; than a byte per number.  This reduces memory usage by a factor of 8
; so we can sieve larger ranges, but requires more complex bit work.
;
; TODO: This is one bit per sieve element, but could be optimized to
;       ignore even numbers and use one bit per odd number. Just need
;       to adjust the bit manipulation routines in ISCOMP and SETCMP

                .TITLE  SIEVE                           ; Program title
                .MCALL  .PRINT,.EXIT,.TTYOUT, .GTIM     ; System macros
                .GLOBL  $DIVTK,$DIV60                   ; Global symbols


HELLOMSG:       .ASCIZ  /Sieve of Eratosthenes by Davepl 2024/
DASHESMSG:      .ASCIZ  /------------------------------------/
CBITSMSG:       .ASCII  /Clearing byte array.  Sieve Size: /
                .BYTE   200
RUNMSG:         .ASCIZ  /Running sieve/
DONEMSG:        .ASCIZ  /Sieve complete/
PRIMMSG:        .ASCII  /Prime numbers found: /
                .BYTE   200
TIMRMSG:        .ASCII  /Ticks Elapsed: /
                .BYTE   200                
MARKCMPMSG:     .ASCIZ  /Marking composite: /
CHECKCMPMSG:    .ASCIZ  /Checking if composite: /
TIMESTMP:       .ASCII  /Timestamp: /
                .BYTE   200
NEWLINE:        .ASCIZ  //

LIMIT   =       15000.             ; Upper limit for primes
BSIZE	=       5000.              ; Size of byte array (fixed value)

; Ensure we're on a word boundary in case the strings above are odd length

        .EVEN                      

START:  .PRINT  #HELLOMSG          ; Welcome banner
        .PRINT  #DASHESMSG
        .PRINT  #CBITSMSG          ; Display sieve size
        MOV     #LIMIT, R0
        JSR     PC, PRNUM
        .PRINT  #NEWLINE

;-- Clear the byte array -----------------------------------------------

;        .PRINT  #TIMESTMP          ; Display timestamp
         JSR     PC, STRTTMR
;        JSR     PC, PRNUM
;        .PRINT  #NEWLINE

        MOV     #BSIZE, R1
        CLR     R2
INITL:
        CLRB    BITARR(R2)        ; Clear the byte array
        INC     R2
        CMP     R2, R1
        BNE     INITL

        .PRINT  #RUNMSG           ; Display progress message "Running sieve"; 

;-- Run the sieve ------------------------------------------------------

        MOV     #3, R1            ; Start with 3 (first odd prime)
SIEVE:
        CMP     R1, #LIMIT        ; Check if we've reached the limit
        BGE     DONESV            ; If so, we're done

; Debug - print the number we're checking
;        .PRINT  #CHECKCMPMSG
;        MOV     R1, R0
;        JSR     PC, PRNUM
;        .PRINT  #NEWLINE

        JSR     PC, ISCOMP        ; Check if R1 is composite
        BNE     NXTODD            ; If prime, skip to next odd number

        MOV     R1, R2            ; R2 = R1 (prime number found)
MARK:
        ADD     R1, R2            ; R2 += R1 (next multiple)
        CMP     R2, #LIMIT        ; Check if we've exceeded the limit
        BGE     NXTODD            ; If so, move to next odd number

; Debug - print the number we're marking
;        .PRINT  #MARKCMPMSG
;        MOV     R2, R0
;        JSR     PC, PRNUM
;        .PRINT  #NEWLINE

        JSR     PC, SETCMP        ; Mark R2 as composite
        BR      MARK              ; Continue marking multiples

NXTODD:
        ADD     #2, R1            ; Move to next odd number
        BR      SIEVE             ; Continue sieving

DONESV: 
;        .PRINT  #TIMESTMP          ; Display timestamp
        JSR     PC, STOPTMR       ; Stop the timer
;        JSR     PC, PRNUM
;        .PRINT  #NEWLINE

        .PRINT  #DONEMSG
        .PRINT  #PRIMMSG
        
;-- Print prime numbers ------------------------------------------------

LISTPRM:
        MOV     #1, R3            ; Prime count in R3 

; Debug - Print list of primes
;        MOV     #2, R0            ; Start with 2 (only even prime)
;        JSR     PC, PRNUM
;        MOV     #',, R0
;        .TTYOUT R0

        MOV     #3, R1            ; Start checking odd numbers from 3
PRNLP:
        CMP     R1, #LIMIT        ; Check if we've reached the limit
        BGE     DONE              ; If so, we're done

        JSR     PC, ISCOMP        ; Check if R1 is composite
        BNE     PRNXT             ; If bit set, composite, so skip to next odd number

        INC     R3                ; Bump the count

PRNXT:
        ADD     #2, R1            ; Move to next odd number
        BR      PRNLP             ; Continue printing primes

DONE:   
        MOV     R3, R0            ; Print count of primes
        JSR     PC, PRNUM
        .PRINT  NEWLINE

        .PRINT  #TIMRMSG
        JSR     PC, ELAPSED
        JSR     PC, PRNUM         ; Print elapsed time

        .EXIT                     ; Exit program

;-- Subroutines --------------------------------------------------------

;-----------------------------------------------------------------------
; SETCMP - Set a bit in the byte array to indicate a composite number
; Registers used: R4, R5
;-----------------------------------------------------------------------

SETCMP:
        MOV     R0, -(SP)       ; Preserve R0
        MOV     R1, -(SP)       ; Preserve R1

        MOV     R2, R4          ; Copy bit number to R4
        ASR     R4              ; Divide by 2 (add this line)
        ASR     R4              ; Divide by 8 to get byte offset
        ASR     R4
        ADD     #BITARR, R4     ; Add base address of BITARR
        MOV     R4, R0          ; Store byte address in R0
        
        MOV     R2, R5          ; Copy bit number to R5
        BIC     #^B1111111111111000, R5  ; Keep only lower 3 bits (bit position within byte)
        MOV     #1, R1          ; Prepare a single bit
        ASH     R5, R1          ; Shift left to create bitmask for the specific bit
        
        BISB    R1, (R0)        ; Set the bit (byte operation)

        MOV     (SP)+, R1       ; Restore R1
        MOV     (SP)+, R0       ; Restore R0
        RTS     PC

;-----------------------------------------------------------------------
; ISCOMP - Check if a number is composite (when bit is set)
; Result returned in the Z flag
; Registers used: R0, R2, R4, R4
;-----------------------------------------------------------------------

ISCOMP:
        MOV     R1, R4          ; Copy bit number to R4

        ASR     R4              ; Divide by 8 to get byte offset
        ASR     R4
        ASR     R4

        ADD     #BITARR, R4     ; Add base address of BITARR
        MOV     R4, R0          ; Store byte address in R0

        MOVB    (R0), R4        ; Load the byte containing the bit

        MOV     R1, R5          ; Copy bit number to R5
        BIC     #^B1111111111111000, R5  ; Keep only lower 3 bits (bit position within byte)
        MOV     #1, R2          ; Prepare a single bit
        ASH     R5, R2          ; Shift left to create bitmask for the specific bit

        BITB    R2, R4          ; Test the bit (byte operation)
        RTS     PC              ; Return with carry set if composite

;-----------------------------------------------------------------------
; PRNUM - Print a number in R1 as ASCII
; All registers preserved
;-----------------------------------------------------------------------

PRNUM:
        MOV     R0, -(SP)         ; Save R0 on stack
        MOV     R1, -(SP)         ; Save R1 on stack

        MOV     R0, R1            ; Move number to R1 (low part of dividend)
        CLR     R0                ; Clear R0 (high part of dividend)
        DIV     #10., R0          ; Divide R0:R1 by 10, quotient in R0, remainder in R1

        TST     R0                ; Check if quotient is 0
        BEQ     PRINT             ; If quotient is 0, print digit
        JSR     PC, PRNUM         ; Recursive like I were back in school

PRINT:  ADD     #'0, R1           ; Convert remainder to ASCII
        MOV     R1, R0            ; Move ASCII digit to R0
        .TTYOUT R0                ; Print the digit

        MOV     (SP)+, R1         ; Restore R1
        MOV     (SP)+, R0         ; Restore R0
        RTS     PC                ; Return

        .EVEN

;-----------------------------------------------------------------------
; Timer routines - Used to measure how long the sieve took to execute
;-----------------------------------------------------------------------

; Global variables to store start and stop times
AREA1:   .BLKW   2
TICKS:   .BLKW   2
TICKS1:  .BLKW   2 
TICKS2:  .BLKW   2      

STRTTMR:    MOV     #TICKS, R1
            .GTIM   #AREA1, R1
            MOV     TICKS, TICKS1        ; Store low order time in TICKS1
            MOV     TICKS+2, TICKS1+2    ; Store low order time in TICKS1
            MOV     TICKS+2, R0
            RTS     PC

STOPTMR:    MOV     #TICKS, R1
            .GTIM   #AREA1, R1
            MOV     TICKS, TICKS2     ; Store low order time in TICKS2
            MOV     TICKS+2, TICKS2+2     ; Store low order time in TICKS2
            MOV     TICKS+2, R0
            RTS     PC      

ELAPSED:    MOV     TICKS2+2, R0 
            SUB     TICKS1+2, R0
            RTS     PC

; Bit array data for the sieve
BITARR: .BLKB   BSIZE             ; Byte array for sieve

.END    START


