#include "config.inc"

.global read_sonar1
.global read_sonar2

.extern delay_10us
.extern delay_1cm

read_sonar1:
    cbi _SFR_IO_ADDR(PORTD), TRIG1_BIT
    rcall delay_10us

    sbi _SFR_IO_ADDR(PORTD), TRIG1_BIT
    rcall delay_10us
    rcall delay_10us

    cbi _SFR_IO_ADDR(PORTD), TRIG1_BIT

    ldi r26, 0xFF
    ldi r27, 0x3F

w_h1:
    sbic _SFR_IO_ADDR(PINB), ECHO1_BIT
    rjmp c_start1

    dec r26
    brne w_h1

    dec r27
    brne w_h1

    clr r24
    ret

c_start1:
    clr r24

c_loop1:
    sbis _SFR_IO_ADDR(PINB), ECHO1_BIT
    ret

    rcall delay_1cm
    inc r24

    cpi r24, 255
    breq to1

    rjmp c_loop1

to1:
    ret

read_sonar2:
    cbi _SFR_IO_ADDR(PORTD), TRIG2_BIT
    rcall delay_10us

    sbi _SFR_IO_ADDR(PORTD), TRIG2_BIT
    rcall delay_10us
    rcall delay_10us

    cbi _SFR_IO_ADDR(PORTD), TRIG2_BIT

    ldi r26, 0xFF
    ldi r27, 0x3F

w_h2:
    sbic _SFR_IO_ADDR(PINB), ECHO2_BIT
    rjmp c_start2

    dec r26
    brne w_h2

    dec r27
    brne w_h2

    clr r24
    ret

c_start2:
    clr r24

c_loop2:
    sbis _SFR_IO_ADDR(PINB), ECHO2_BIT
    ret

    rcall delay_1cm
    inc r24

    cpi r24, 255
    breq to2

    rjmp c_loop2

to2:
    ret
