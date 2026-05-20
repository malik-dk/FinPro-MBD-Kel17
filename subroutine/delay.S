#include "config.inc"

.global delay_1cm
.global delay_10us
.global delay_50us
.global delay_2ms
.global delay_5ms
.global delay_20ms
.global servo_sweep

delay_1cm:
    ldi r18, 100

d1c:
    nop
    nop
    nop
    nop
    nop
    nop

    dec r18
    brne d1c

    ret

delay_10us:
    ldi r18, 50

d10:
    dec r18
    brne d10

    ret

delay_50us:
    ldi r18, 250

d50:
    dec r18
    brne d50

    ret

delay_2ms:
    ldi r19, 32

d2o:
    ldi r18, 250

d2i:
    nop
    dec r18
    brne d2i

    dec r19
    brne d2o

    ret

delay_5ms:
    rcall delay_2ms
    rcall delay_2ms

    ldi r19, 16

d5o:
    ldi r18, 250

d5i:
    dec r18
    brne d5i

    dec r19
    brne d5o

    ret

delay_20ms:
    rcall delay_5ms
    rcall delay_5ms
    rcall delay_5ms
    rcall delay_5ms

    ret

servo_sweep:
    lds r24, OCR1AL
    lds r25, OCR1AH

sweep_loop:
    cp r24, r23
    cpc r25, r22
    breq sweep_done

    brlo sweep_up

sweep_down:
    ldi r16, 1
    sub r24, r16

    ldi r16, 0
    sbc r25, r16

    rjmp sweep_write

sweep_up:
    ldi r16, 1
    add r24, r16

    ldi r16, 0
    adc r25, r16

sweep_write:
    sts OCR1AH, r25
    sts OCR1AL, r24

    rcall delay_2ms
    rjmp sweep_loop

sweep_done:
    ret