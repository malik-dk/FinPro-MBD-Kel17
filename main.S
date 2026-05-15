#include <avr/io.h>

.include "config.inc"

.global main

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

    clr r11     ; simpan status tombol sebelumnya
    clr r12     ; simpan status servo manual (0=tutup, 1=buka)

    rcall i2c_init     
    rcall servo_init    
    
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

    mov r24, r15
    cpi r24, 5          
    brlo state_full

state_normal:
    ; sampah normal
    cbi _SFR_IO_ADDR(PORTB), LED_BIT  
    clr r12         

    mov r24, r14
    cpi r24, 100        
    brlo normal_buka

normal_tutup:
    ldi r22, 0x00       
    ldi r23, 0xFA       
    rjmp execute_servo

normal_buka:
    ldi r22, 0x01       
    ldi r23, 0xF4      
    rjmp execute_servo

state_full:
    ; sampah penuh
    sbi _SFR_IO_ADDR(PORTB), LED_BIT  ; LED nyala

    clr r16
    sbic _SFR_IO_ADDR(PIND), BTN_BIT
    ldi r16, 1          

    cp r16, r11
    breq apply_manual   
    cpi r16, 0
    breq save_btn_state 

    ldi r17, 1
    eor r12, r17       

save_btn_state:
    mov r11, r16        

apply_manual:
    mov r24, r12        
    cpi r24, 1
    breq manual_buka

manual_tutup:
    ldi r22, 0x00       
    ldi r23, 0xFA
    rjmp execute_servo

manual_buka:
    ldi r22, 0x01       
    ldi r23, 0xF4

execute_servo:
    rcall set_servo     ; ini nanti ada di file servo.S buat gerakin

update_display:
    ; teks buat layar
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

    ldi r20, 10
delay_polling:
    rcall delay_20ms
    dec r20
    brne delay_polling

    rjmp main_loop

.include "utils.S"
.include "sonar.S"
.include "servo.S"
.include "lcd_i2c.S"