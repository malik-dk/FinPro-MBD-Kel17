#define __SFR_OFFSET 0
#include <avr/io.h>

; ==========================================
; KONFIGURASI PIN
; ==========================================
.equ TRIG1_BIT, 7   ; PD7
.equ ECHO1_BIT, 0   ; PB0
.equ TRIG2_BIT, 6   ; PD6
.equ ECHO2_BIT, 2   ; PB2
.equ SERVO_BIT, 1   ; PB1 (Pin 9)
.equ LED_BIT,   5   ; PB5 (Pin 13)
.equ BTN_BIT,   2   ; PD2 (Pin 2) - INT0

.equ PCF_ADDR, 0x4E
.equ LCD_BACKLIGHT, 0x08
.equ LCD_EN, 0x04
.equ LCD_RS, 0x01

; ==========================================
; PETA REGISTER LOGIKA
; r8  = Target Servo (0=Tutup, 1=Buka)
; r9  = Mode Sistem (0=Normal, 1=Penuh)
; r10 = Kunci Manual (0=Auto, 1=Terkunci Buka)
; r11 = Auto-Open Enable (Mencegah auto-open saat nutup manual)
; ==========================================

.global main
.global INT0_vect

main:
    ; 1. Inisialisasi Stack
    ldi r16, hi8(RAMEND)
    out SPH, r16
    ldi r16, lo8(RAMEND)
    out SPL, r16

    ; 2. Inisialisasi I/O
    sbi DDRD, TRIG1_BIT
    sbi DDRD, TRIG2_BIT
    cbi DDRD, BTN_BIT
    
    cbi DDRB, ECHO1_BIT
    cbi DDRB, ECHO2_BIT
    sbi DDRB, SERVO_BIT
    sbi DDRB, LED_BIT

    ; Matikan pin awal
    cbi PORTD, TRIG1_BIT
    cbi PORTD, TRIG2_BIT
    cbi PORTB, LED_BIT

    sbi PORTC, 4
    sbi PORTC, 5

    ldi r16, 72
    sts TWBR, r16

    ; 3. Reset Logika Register
    clr r8  
    clr r9  
    clr r10 
    ldi r16, 1
    mov r11, r16    ; Auto-Open aktif dari awal

    ; 4. Konfigurasi External Interrupt (INT0)
    ldi r16, (1 << ISC01) | (1 << ISC00)  ; Rising Edge
    sts EICRA, r16
    ldi r16, (1 << INT0)
    out EIMSK, r16
    sei                                   ; Global Interrupt Enable

    ; 5. Konfigurasi Timer1 PWM 50Hz
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

; ==========================================
; LOOP UTAMA
; ==========================================
main_loop:
    ldi r24, 0x01
    rcall lcd_send_cmd
    rcall delay_2ms

    ; Baca sensor luar
    rcall read_sonar1  
    mov r14, r24        
    rcall delay_20ms    

    ; Baca sensor dalam
    rcall read_sonar2   
    mov r15, r24      

    ; (Tombol tidak lagi dipolling di sini, murni diserahkan ke INT0_vect)

    ; Penentuan Jalur Mode
    tst r9
    brne mode_full_logic

; ------------------------------------------
; MODE NORMAL
; ------------------------------------------
mode_normal_logic:
    cbi PORTB, LED_BIT

    tst r10
    brne apply_servo        ; Jika Terkunci Buka oleh tombol, abaikan sensor

    ; Cek Sensor Dalam (Syarat: Servo harus sedang menutup)
    tst r8
    brne normal_check_luar

    mov r24, r15
    cpi r24, 5
    brsh normal_check_luar

    ; Triger MASUK MODE PENUH
    ldi r16, 1
    mov r9, r16             ; Kunci mode penuh
    clr r8                  ; Paksa tutup
    clr r10
    sbi PORTB, LED_BIT      ; Nyalakan LED
    rjmp apply_servo

normal_check_luar:
    mov r24, r14
    cpi r24, 50
    brsh hand_removed       ; Tangan tidak terdeteksi

hand_present:
    tst r11
    breq normal_auto_close  ; Jika Auto-Open dibekukan sementara, tetap tutup!
    
    ldi r16, 1
    mov r8, r16             ; Buka Otomatis
    rjmp apply_servo

hand_removed:
    ldi r16, 1
    mov r11, r16            ; Tangan sudah menjauh, aktifkan kembali Auto-Open!

normal_auto_close:
    clr r8                  ; Tutup Otomatis
    rjmp apply_servo

; ------------------------------------------
; MODE PENUH
; ------------------------------------------
mode_full_logic:
    sbi PORTB, LED_BIT      ; LED dipastikan menyala
    rjmp apply_servo        ; Tombol ditangani ISR, cukup update servo

; ==========================================
; EKSEKUSI SERVO
; ==========================================
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

; ==========================================
; UPDATE LCD DISPLAY
; ==========================================
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

; ==========================================
; INTERRUPT SERVICE ROUTINE (INT0 - TOMBOL)
; ==========================================
INT0_vect:
    push r16
    in r16, SREG
    push r16

    ; Software Debounce (Mencegah false double-clicks)
    rcall delay_20ms

    tst r9
    brne isr_full_mode

isr_normal_mode:
    ldi r16, 1
    eor r8, r16             ; Toggle Servo
    mov r10, r8             ; Sinkronisasi Kunci Manual dengan Servo
    
    tst r8
    brne isr_exit           ; Jika dibuka manual, selesai
    clr r11                 ; Jika DITUTUP manual, bekukan sensor luar sementara!
    rjmp isr_exit

isr_full_mode:
    ldi r16, 1
    eor r8, r16             ; Toggle Servo
    
    tst r8
    brne isr_exit           ; Jika dibuka untuk membuang isinya, biarkan LED & Mode Penuh
    
    ; Jika DITUTUP KEMBALI
    clr r9                  ; Keluar dari Mode Penuh
    clr r11                 ; Bekukan sensor luar sementara
    cbi PORTB, LED_BIT      ; Matikan LED Indikator

isr_exit:
    ldi r16, (1<<INTF0)
    out EIFR, r16           ; Bersihkan sisa bounce interrupt flag

    pop r16
    out SREG, r16
    pop r16
    reti

; ==========================================
; RUTIN DELAY (delay.S)
; ==========================================
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

; ==========================================
; RUTIN SERVO SWEEP (Pergerakan Halus)
; ==========================================
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

; ==========================================
; RUTIN I2C LCD (lcd.S)
; ==========================================
lcd_init:
    rcall delay_20ms
    ldi r24, 0x30
    rcall lcd_send_nibble
    rcall delay_5ms
    ldi r24, 0x30
    rcall lcd_send_nibble
    rcall delay_2ms
    ldi r24, 0x30
    rcall lcd_send_nibble
    rcall delay_2ms
    ldi r24, 0x20
    rcall lcd_send_nibble
    rcall delay_2ms
    ldi r24, 0x28
    rcall lcd_send_cmd
    ldi r24, 0x0C
    rcall lcd_send_cmd
    ldi r24, 0x06
    rcall lcd_send_cmd
    ret

lcd_send_cmd:
    mov r25, r24
    andi r24, 0xF0
    rcall lcd_send_nibble
    mov r24, r25
    swap r24
    andi r24, 0xF0
    rcall lcd_send_nibble
    ret

lcd_send_data:
    mov r25, r24
    andi r24, 0xF0
    ori r24, LCD_RS
    rcall lcd_send_nibble
    mov r24, r25
    swap r24
    andi r24, 0xF0
    ori r24, LCD_RS
    rcall lcd_send_nibble
    ret

lcd_send_nibble:
    ori r24, LCD_BACKLIGHT
    mov r23, r24
    ori r24, LCD_EN
    rcall twi_write_byte
    mov r24, r23
    andi r24, ~(LCD_EN)
    rcall twi_write_byte
    rcall delay_50us
    ret

twi_write_byte:
    ldi r16, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    sts TWCR, r16

twi_wait_start:
    lds r16, TWCR
    sbrs r16, TWINT
    rjmp twi_wait_start

    ldi r16, PCF_ADDR
    sts TWDR, r16
    ldi r16, (1<<TWINT)|(1<<TWEN)
    sts TWCR, r16

twi_wait_addr:
    lds r16, TWCR
    sbrs r16, TWINT
    rjmp twi_wait_addr

    sts TWDR, r24
    ldi r16, (1<<TWINT)|(1<<TWEN)
    sts TWCR, r16

twi_wait_data:
    lds r16, TWCR
    sbrs r16, TWINT
    rjmp twi_wait_data

    ldi r16, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    sts TWCR, r16
    ret

print_distance:
    clr r20
    clr r21
    mov r22, r24
get_h:
    cpi r22, 100
    brlo get_t
    subi r22, 100
    inc r20
    rjmp get_h
get_t:
    cpi r22, 10
    brlo prn
    subi r22, 10
    inc r21
    rjmp get_t
prn:
    mov r24, r20
    subi r24, -48
    rcall lcd_send_data
    mov r24, r21
    subi r24, -48
    rcall lcd_send_data
    mov r24, r22
    subi r24, -48
    rcall lcd_send_data
    ldi r24, ' '
    rcall lcd_send_data
    ldi r24, 'c'
    rcall lcd_send_data
    ldi r24, 'm'
    rcall lcd_send_data
    ret

; ==========================================
; RUTIN SONAR 1 & 2 (sonar.S)
; ==========================================
read_sonar1:
    cbi PORTD, TRIG1_BIT
    rcall delay_10us
    sbi PORTD, TRIG1_BIT
    rcall delay_10us
    rcall delay_10us
    cbi PORTD, TRIG1_BIT

    ldi r26, 0xFF
    ldi r27, 0x3F
w_h1:
    sbic PINB, ECHO1_BIT
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
    sbis PINB, ECHO1_BIT
    ret
    rcall delay_1cm
    inc r24
    cpi r24, 255
    breq to1
    rjmp c_loop1
to1:
    ret

read_sonar2:
    cbi PORTD, TRIG2_BIT
    rcall delay_10us
    sbi PORTD, TRIG2_BIT
    rcall delay_10us
    rcall delay_10us
    cbi PORTD, TRIG2_BIT

    ldi r26, 0xFF
    ldi r27, 0x3F
w_h2:
    sbic PINB, ECHO2_BIT
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
    sbis PINB, ECHO2_BIT
    ret
    rcall delay_1cm
    inc r24
    cpi r24, 255
    breq to2
    rjmp c_loop2
to2:
    ret