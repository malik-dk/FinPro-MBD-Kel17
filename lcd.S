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