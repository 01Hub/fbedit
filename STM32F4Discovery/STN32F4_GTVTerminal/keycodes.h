
void KeyboardInit(void);
uint32_t parity1(uint32_t x);
void KeyboardReset(void);
uint8_t GetKeyState(uint16_t SC);
uint8_t Shifted(void);
uint8_t Ctrled(void);
uint8_t GetChar(void);

#ifndef _KEYCODES_H_
#define _KEYCODES_H_

#define K_ESC     0x1B
#define K_CAPSLK  0x80
#define K_F1      0x81
#define K_F2      0x82
#define K_F3      0x83
#define K_F4      0x84
#define K_F5      0x85
#define K_F6      0x86
#define K_F7      0x87
#define K_F8      0x88
#define K_F9      0x89
#define K_F10     0x8A
#define K_F11     0x8B
#define K_F12     0x8C
#define K_UP      0x8D
#define K_LEFT    0x8E
#define K_DOWN    0x8F
#define K_RIGHT   0x90
#define K_INS     0x91
#define K_DEL     0x92
#define K_HOME    0x93
#define K_END     0x94
#define K_PGUP    0x95
#define K_PGDN    0x96
#define K_NUMLK   0x97
#define K_SCRLK   0x98
#define K_PRTSC   0x99
#define K_BREAK   0x9A

#endif

/*

PS/2 keyboard scancodes

KEY               MAKE                            BREAK
-------------------------------------------------------------
F9                01                             F0,01
F5                03                             F0,03
F3                04                             F0,04
F1                05                             F0,05
F2                06                             F0,06
F12               07                             F0,07
F10               09                             F0,09
F8                0A                             F0,0A
F6                0B                             F0,0B
F4                0C                             F0,0C
TAB               0D                             F0,0D
`                 0E                             F0,0E

L ALT             11                             F0,11
L SHFT            12                             FO,12
L CTRL            14                             FO,14
Q                 15                             F0,15
1                 16                             F0,16
Z                 1A                             F0,1A
S                 1B                             F0,1B
A                 1C                             F0,1C
W                 1D                             F0,1D
2                 1E                             F0,1E

C                 21                             F0,21
X                 22                             F0,22
D                 23                             F0,23
E                 24                             F0,24
4                 25                             F0,25
3                 26                             F0,26
SPACE             29                             F0,29
V                 2A                             F0,2A
F                 2B                             F0,2B
T                 2C                             F0,2C
R                 2D                             F0,2D
5                 2E                             F0,2E

N                 31                             F0,31
B                 32                             F0,32
H                 33                             F0,33
G                 34                             F0,34
Y                 35                             F0,35
6                 36                             F0,36
M                 3A                             F0,3A
J                 3B                             F0,3B
U                 3C                             F0,3C
7                 3D                             F0,3D
8                 3E                             F0,3E

,                 41                             F0,41
K                 42                             F0,42
I                 43                             F0,43
O                 44                             F0,44
0                 45                             F0,45
9                 46                             F0,46
.                 49                             F0,49
/                 4A                             F0,4A
L                 4B                             F0,4B
;                 4C                             F0,4C
P                 4D                             F0,4D
-                 4E                             F0,4E

'                 52                             F0,52
[                 54                             FO,54
=                 55                             FO,55
CAPS              58                             F0,58
R SHFT            59                             F0,59
ENTER             5A                             F0,5A
]                 5B                             F0,5B
\                 5D                             F0,5D

BKSP              66                             F0,66
KP 1              69                             F0,69
KP 4              6B                             F0,6B
KP 7              6C                             F0,6C

KP 0              70                             F0,70
KP .              71                             F0,71
KP 2              72                             F0,72
KP 5              73                             F0,73
KP 6              74                             F0,74
KP 8              75                             F0,75
ESC               76                             F0,76
NUM               77                             F0,77
F11               78                             F0,78
KP +              79                             F0,79
KP 3              7A                             F0,7A
KP -              7B                             F0,7B
KP *              7C                             F0,7C
KP 9              7D                             F0,7D
SCROLL            7E                             F0,7E

F7                83                             F0,83

R ALT             E0,11                          E0,F0,11
PRNT SCRN         E0,12,E0,7C                    E0,F0,7C,E0,F0,12
R CTRL            E0,14                          E0,F0,14
L GUI             E0,1F                          E0,F0,1F
R GUI             E0,27                          E0,F0,27
APPS              E0,2F                          E0,F0,2F
KP /              E0,4A                          E0,F0,4A
KP EN             E0,5A                          E0,F0,5A
END               E0,69                          E0,F0,69
L ARROW           E0,6B                          E0,F0,6B
HOME              E0,6C                          E0,F0,6C
INSERT            E0,70                          E0,F0,70
DELETE            E0,71                          E0,F0,71
D ARROW           E0,72                          E0,F0,72
R ARROW           E0,74                          E0,F0,74
U ARROW           E0,75                          E0,F0,75
PG DN             E0,7A                          E0,F0,7A
PG UP             E0,7D                          E0,F0,7D

PAUSE             E1,14,77,E1,F0,14,F0,77        - NONE -

*/

#define SC_F9                0x01
#define SC_F5                0x03
#define SC_F3                0x04
#define SC_F1                0x05
#define SC_F2                0x06
#define SC_F12               0x07
#define SC_F10               0x09
#define SC_F8                0x0A
#define SC_F6                0x0B
#define SC_F4                0x0C
#define SC_TAB               0x0D
#define SC_ACCENT            0x0E
#define SC_L_ALT             0x11
#define SC_L_SHFT            0x12
#define SC_L_CTRL            0x14
#define SC_Q                 0x15
#define SC_1                 0x16
#define SC_Z                 0x1A
#define SC_S                 0x1B
#define SC_A                 0x1C
#define SC_W                 0x1D
#define SC_2                 0x1E
#define SC_C                 0x21
#define SC_X                 0x22
#define SC_D                 0x23
#define SC_E                 0x24
#define SC_4                 0x25
#define SC_3                 0x26
#define SC_SPACE             0x29
#define SC_V                 0x2A
#define SC_F                 0x2B
#define SC_T                 0x2C
#define SC_R                 0x2D
#define SC_5                 0x2E
#define SC_N                 0x31
#define SC_B                 0x32
#define SC_H                 0x33
#define SC_G                 0x34
#define SC_Y                 0x35
#define SC_6                 0x36
#define SC_M                 0x3A
#define SC_J                 0x3B
#define SC_U                 0x3C
#define SC_7                 0x3D
#define SC_8                 0x3E
#define SC_COMMA             0x41
#define SC_K                 0x42
#define SC_I                 0x43
#define SC_O                 0x44
#define SC_0                 0x45
#define SC_9                 0x46
#define SC_DOT               0x49
#define SC_SLASH             0x4A
#define SC_L                 0x4B
#define SC_SEMICOLON         0x4C
#define SC_P                 0x4D
#define SC_MINUS             0x4E
#define SC_SINGLEQUOTE       0x52
#define SC_L_BRACKET         0x54
#define SC_EQUAL             0x55
#define SC_CAPS              0x58
#define SC_R_SHFT            0x59
#define SC_ENTER             0x5A
#define SC_R_BRAKET          0x5B
#define SC_BACKSLASH         0x5D
#define SC_BKSP              0x66
#define SC_KP_1              0x69
#define SC_KP_4              0x6B
#define SC_KP_7              0x6C
#define SC_KP_0              0x70
#define SC_KP_DOT            0x71
#define SC_KP_2              0x72
#define SC_KP_5              0x73
#define SC_KP_6              0x74
#define SC_KP_8              0x75
#define SC_ESC               0x76
#define SC_NUM               0x77
#define SC_F11               0x78
#define SC_KP_PLUS           0x79
#define SC_KP_3              0x7A
#define SC_KP_MINUS          0x7B
#define SC_KP_ASTERIX        0x7C
#define SC_KP_9              0x7D
#define SC_SCROLL            0x7E
#define SC_F7                0x83
/* Exstended */
#define SC_R_ALT             0x111
#define SC_R_CTRL            0x114
#define SC_L_GUI             0x11F
#define SC_R_GUI             0x127
#define SC_APPS              0x12F
#define SC_KP_SLASH          0x14A
#define SC_KP_ENTER          0x15A
#define SC_END               0x169
#define SC_L_ARROW           0x16B
#define SC_HOME              0x16C
#define SC_INSERT            0x170
#define SC_DELETE            0x171
#define SC_D_ARROW           0x172
#define SC_R_ARROW           0x174
#define SC_U_ARROW           0x175
#define SC_PG_DN             0x17A
#define SC_PRNTSCRN          0x17C
#define SC_PG_UP             0x17D
// #define SC_PAUSE             0xE1,14,77,E1,F0,14,F0,77
