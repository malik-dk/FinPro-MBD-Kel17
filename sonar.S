
; read_sonar1 - Baca Sensor Luar
; TRIG: PD7 | ECHO: PB0
read_sonar1:
    ; Trig low
    cbi _SFR_IO_ADDR(PORTD), TRIG1_BIT
    rcall delay_10us
    ; Kirim pulse TRIG HIGH selama ~10us 
    sbi _SFR_IO_ADDR(PORTD), TRIG1_BIT
    rcall delay_10us
    rcall delay_10us
    cbi _SFR_IO_ADDR(PORTD), TRIG1_BIT
    ; Tunggu ECHO naik 
    ldi r26, 0xFF
    ldi r27, 0x3F
wait_echo_high1:
    sbic _SFR_IO_ADDR(PINB), ECHO1_BIT
    rjmp count_start1       ; ECHO sudah HIGH
    dec r26
    brne wait_echo_high1
    dec r27
    brne wait_echo_high1
    clr r24               
    ret

count_start1:
    clr r24                 ; Reset 
count_loop1:
    sbis _SFR_IO_ADDR(PINB), ECHO1_BIT
    ret                     
    rcall delay_1cm         
    inc r24
    cpi r24, 255
    breq sonar1_timeout
    rjmp count_loop1
sonar1_timeout:
    ret                   


; read_sonar2 - Baca Sensor Dalam 
; TRIG: PD6 | ECHO: PB2
read_sonar2:
    cbi _SFR_IO_ADDR(PORTD), TRIG2_BIT
    rcall delay_10us

    ; Kirim pulse TRIG HIGH selama ~10us
    sbi _SFR_IO_ADDR(PORTD), TRIG2_BIT
    rcall delay_10us
    rcall delay_10us
    cbi _SFR_IO_ADDR(PORTD), TRIG2_BIT

    ; Tunggu ECHO naik 
    ldi r26, 0xFF
    ldi r27, 0x3F
wait_echo_high2:
    sbic _SFR_IO_ADDR(PINB), ECHO2_BIT
    rjmp count_start2      
    dec r26
    brne wait_echo_high2
    dec r27
    brne wait_echo_high2
    clr r24                 
    ret

count_start2:
    clr r24                 ; Reset 
count_loop2:
    sbis _SFR_IO_ADDR(PINB), ECHO2_BIT
    ret                 
    rcall delay_1cm        
    inc r24
    cpi r24, 255
    breq sonar2_timeout
    rjmp count_loop2
sonar2_timeout:
    ret                  
