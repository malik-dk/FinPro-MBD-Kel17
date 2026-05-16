#ifndef CONFIG_INC
#define CONFIG_INC

#include <avr/io.h>

; sensor 1 (Luar / Pembuka)
.equ TRIG1_BIT, 7
.equ ECHO1_BIT, 0

; sensor 2 (Dalam / Sampah Penuh)
.equ TRIG2_BIT, 6
.equ ECHO2_BIT, 2

; output servo
.equ SERVO_BIT, 1
.equ LED_BIT,   5

; input Tombol
.equ BTN_BIT,   2

; I2C LCD
.equ PCF_ADDR, 0x4E
.equ LCD_BACKLIGHT, 0x08
.equ LCD_EN, 0x04
.equ LCD_RS, 0x01

#endif