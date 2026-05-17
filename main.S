#include <avr/io.h>
#include "config.inc"

.global main
.global INT0_vect

.extern delay_20ms
.extern delay_2ms
.extern read_sonar1
.extern read_sonar2
.extern lcd_init
.extern lcd_send_cmd
.extern lcd_send_data
.extern print_distance
.extern servo_sweep

main:
    ; inisialisasi stack
    ldi r16, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH), r16
    ldi r16, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), r16

    ; inisialisasi I/O
    sbi _SFR_IO_ADDR(DDRD), TRIG1_BIT
    sbi _SFR_IO_ADDR(DDRD), TRIG2_BIT
    cbi _SFR_IO_ADDR(DDRD), BTN_BIT
    
    cbi _SFR_IO_ADDR(DDRB), ECHO1_BIT
    cbi _SFR_IO_ADDR(DDRB), ECHO2_BIT
    sbi _SFR_IO_ADDR(DDRB), SERVO_BIT
    sbi _SFR_IO_ADDR(DDRB), LED_BIT

    ; matiin pin awal
    cbi _SFR_IO_ADDR(PORTD), TRIG1_BIT
    cbi _SFR_IO_ADDR(PORTD), TRIG2_BIT
    cbi _SFR_IO_ADDR(PORTB), LED_BIT

    sbi _SFR_IO_ADDR(PORTC), 4
    sbi _SFR_IO_ADDR(PORTC), 5

    ldi r16, 72
    sts TWBR, r16

    clr r8  
    clr r9  
    clr r10 


    ldi r16, (1 << ISC01) | (1 << ISC00)
    sts EICRA, r16
    ldi r16, (1 << INT0)
    out _SFR_IO_ADDR(EIMSK), r16
    sei 

    ldi r16, 0x13
    sts ICR1H, r16
    ldi r16, 0x87
    sts ICR1L, r16

    ldi r16, 0x00
    sts OCR1AH, r16
    ldi r16, 0xFA
    sts OCR1AL, r16

    ldi r16, (1 << COM1A1) | (1 << WGM11)
    sts TCCR1A, r16

    ldi r16, (1 << WGM13) | (1 << WGM12) | (1 << CS11) | (1 << CS10)
    sts TCCR1B, r16

    rcall delay_20ms
    rcall delay_20ms

    rcall lcd_init      

main_loop:
    ldi r24, 0x01
    rcall lcd_send_cmd
    rcall delay_2ms

    ; baca sensor luar (buka/tutup)
    rcall read_sonar1  
    mov r14, r24        

    rcall delay_20ms    

    ; baca sensor dalam (kepenuhan sampah)
    rcall read_sonar2   ; ini nanti ada di file sonar.S buat sensor
    mov r15, r24      

    tst r9
    brne mode_full_logic

mode_normal_logic:
    cbi _SFR_IO_ADDR(PORTB), LED_BIT

    tst r10
    brne apply_servo

    ; jika tutup kebuka, sensor dalam diabaikan aja
    tst r8
    brne normal_check_luar

    ; cek sensor dalam
    mov r24, r15
    cpi r24, 5
    brsh normal_check_luar

    ; masuk mode penuh
    ldi r16, 1
    mov r9, r16
    clr r8
    clr r10
    sbi _SFR_IO_ADDR(PORTB), LED_BIT
    rjmp apply_servo

normal_check_luar:
    mov r24, r14
    cpi r24, 50
    brsh normal_auto_close

    ldi r16, 1
    mov r8, r16
    rjmp apply_servo

normal_auto_close:
    clr r8
    rjmp apply_servo

mode_full_logic:
    sbi _SFR_IO_ADDR(PORTB), LED_BIT

apply_servo:
    tst r8
    brne apply_buka

apply_tutup:
    ldi r22, 0x00
    ldi r23, 0xFA
    rjmp servo_exec

apply_buka:
    ldi r22, 0x01
    ldi r23, 0xF4

servo_exec:
    rcall servo_sweep

update_display:
    ldi r24, 0x80
    rcall lcd_send_cmd

    ldi r24, 'L'
    rcall lcd_send_data
    ldi r24, 'u'
    rcall lcd_send_data
    ldi r24, 'a'
    rcall lcd_send_data
    ldi r24, 'r'
    rcall lcd_send_data
    ldi r24, ':'
    rcall lcd_send_data
    ldi r24, ' '
    rcall lcd_send_data

    mov r24, r14
    rcall print_distance

    ldi r24, 0xC0
    rcall lcd_send_cmd

    ldi r24, 'D'
    rcall lcd_send_data
    ldi r24, 'l'
    rcall lcd_send_data
    ldi r24, 'm'
    rcall lcd_send_data
    ldi r24, ' '
    rcall lcd_send_data
    ldi r24, ':'
    rcall lcd_send_data
    ldi r24, ' '
    rcall lcd_send_data

    mov r24, r15
    rcall print_distance

    ldi r20, 5

delay_polling:
    rcall delay_20ms
    dec r20
    brne delay_polling

    rjmp main_loop

INT0_vect:
    push r16
    in r16, _SFR_IO_ADDR(SREG)
    push r16

    ; cek mode
    tst r9
    brne isr_full_mode

isr_normal_mode:
    ; tombol ditekan di mode normal -> toggle servo
    ldi r16, 1
    eor r8, r16
    mov r10, r8   
    rjmp isr_exit

isr_full_mode:
    ldi r16, 1
    eor r8, r16
    
    ; jika ditutup lagi, keluar dari mode penuh
    tst r8
    brne isr_exit       ; kalo buka, tetep mode penuh
    clr r9              ; jika tutup, reset ke normal
    cbi _SFR_IO_ADDR(PORTB), LED_BIT

isr_exit:
    ldi r16, (1<<INTF0)
    out _SFR_IO_ADDR(EIFR), r16

    pop r16
    out _SFR_IO_ADDR(SREG), r16
    pop r16
    reti