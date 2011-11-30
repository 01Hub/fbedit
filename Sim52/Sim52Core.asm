
.data

JmpTab				dd NOP_,AJMP_$cad,LJMP_$cadP0,RR_A,INC_A,INC_$dad,INC_@R0,INC_@R1,INC_R0,INC_R1,INC_R2,INC_R3,INC_R4,INC_R5,INC_R6,INC_R7
					dd JBC$bad_$cad,ACALL_$cadP0,LCALL_$cad,RRC_A,DEC_A,DEC_$dad,DEC_@R0,DEC_@R1,DEC_R0,DEC_R1,DEC_R2,DEC_R3,DEC_R4,DEC_R5,DEC_R6,DEC_R7
					dd JB_$bad_$cad,AJMP_$cadP1,RET_,RL_A,ADD_A_dd,ADD_A_$dad,ADD_A_@R0,ADD_A_@R1,ADD_A_R0,ADD_A_R1,ADD_A_R2,ADD_A_R3,ADD_A_R4,ADD_A_R5,ADD_A_R6,ADD_A_R7
					dd JNB_$bad_$cad,ACALL_$cadP1,RETI_,RLC_A,ADDC_A_dd,ADDC_A_$dad,ADDC_A_@R0,ADDC_A_@R1,ADDC_A_R0,ADDC_A_R1,ADDC_A_R2,ADDC_A_R3,ADDC_A_R4,ADDC_A_R5,ADDC_A_R6,ADDC_A_R7

					dd JC_$cad,AJMP_$cadP2,ORL_$dad_A,ORL_$dad_dd,ORL_A_dd,ORL_A_$dad,ORL_A_@R0,ORL_A_@R1,ORL_A_R0,ORL_A_R1,ORL_A_R2,ORL_A_R3,ORL_A_R4,ORL_A_R5,ORL_A_R6,ORL_A_R7
					dd JNC_$cad,ACALL_$cadP2,ANL_$dad_A,ANL_$dad_dd,ANL_A_dd,ANL_A_$dad,ANL_A_@R0,ANL_A_@R1,ANL_A_R0,ANL_A_R1,ANL_A_R2,ANL_A_R3,ANL_A_R4,ANL_A_R5,ANL_A_R6,ANL_A_R7
					dd JZ_$cad,AJMP_$cadP3,XRL_$dad_A,XRL_$dad_dd,XRL_A_dd,XRL_A_$dad,XRL_A_@R0,XRL_A_@R1,XRL_A_R0,XRL_A_R1,XRL_A_R2,XRL_A_R3,XRL_A_R4,XRL_A_R5,XRL_A_R6,XRL_A_R7
					dd JNZ_$cad,ACALL_$cadP3,ORL_C_$bad,JMP_@A_DPTR,MOV_A_dd,MOV_$dad_dd,MOV_@R0_dd,MOV_@R1_dd,MOV_R0_dd,MOV_R1_dd,MOV_R2_dd,MOV_R3_dd,MOV_R4_dd,MOV_R5_dd,MOV_R6_dd,MOV_R7_dd

					dd SJMP_$cad,AJMP_$cadP4,ANL_C_$bad,MOVC_A_@A_PC,DIV_AB,MOV_$dad_$dad,MOV_$dad_@R0,MOV_$dad_@R1,MOV_$dad_R0,MOV_$dad_R1,MOV_$dad_R2,MOV_$dad_R3,MOV_$dad_R4,MOV_$dad_R5,MOV_$dad_R6,MOV_$dad_R7
					dd MOV_DPTR_dw,ACALL_$cadP4,MOV_$bad_C,MOVC_A_@A_DPTR,SUBB_A_dd,SUBB_A_$dad,SUBB_A_@R0,SUBB_A_@R1,SUBB_A_R0,SUBB_A_R1,SUBB_A_R2,SUBB_A_R3,SUBB_A_R4,SUBB_A_R5,SUBB_A_R6,SUBB_A_R7
					dd ORL_C_n$bad,AJMP_$cadP5,MOV_C_$bad,INC_DPTR,MUL_AB,reserved,MOV_@R0_$dad,MOV_@R1_$dad,MOV_R0_$dad,MOV_R1_$dad,MOV_R2_$dad,MOV_R3_$dad,MOV_R4_$dad,MOV_R5_$dad,MOV_R6_$dad,MOV_R7_$dad
					dd ANL_C_n$bad,ACALL_$cadP5,CPL_$bad,CPL_C,CJNE_A_dd_$cad,CJNE_A_$dad_$cad,CJNE_@R0_dd_$cad,CJNE_@R1_dd_$cad,CJNE_R0_dd_$cad,CJNE_R1_dd_$cad,CJNE_R2_dd_$cad,CJNE_R3_dd_$cad,CJNE_R4_dd_$cad,CJNE_R5_dd_$cad,CJNE_R6_dd_$cad,CJNE_R7_dd_$cad

					dd PUSH_$dad,AJMP_$cadP6,CLR_$bad,CLR_C,SWAP_A,XCH_A_$dad,XCH_A_@R0,XCH_A_@R1,XCH_A_R0,XCH_A_R1,XCH_A_R2,XCH_A_R3,XCH_A_R4,XCH_A_R5,XCH_A_R6,XCH_A_R7
					dd POP_$dad,ACALL_$cadP6,SETB_$bad,SETB_C,DA_A,DJNZ_$dad_$cad,XCHD_A_@R0,XCHD_A_@R1,DJNZ_R0_$cad,DJNZ_R1_$cad,DJNZ_R2_$cad,DJNZ_R3_$cad,DJNZ_R4_$cad,DJNZ_R5_$cad,DJNZ_R6_$cad,DJNZ_R7_$cad
					dd MOVX_A_@DPTR,AJMP_$cadP7,MOVX_A_@R0,MOVX_A_@R1,CLR_A,MOV_A_$dad,MOV_A_@R0,MOV_A_@R1,MOV_A_R0,MOV_A_R1,MOV_A_R2,MOV_A_R3,MOV_A_R4,MOV_A_R5,MOV_A_R6,MOV_A_R7
					dd MOVX_@DPTR_A,ACALL_$cadP7,MOVX_@R0_A,MOVX_@R1_A,CPL_A,MOV_$dad_A,MOV_@R0_A,MOV_@R1_A,MOV_R0_A,MOV_R1_A,MOV_R2_A,MOV_R3_A,MOV_R4_A,MOV_R5_A,MOV_R6_A,MOV_R7_A

.code

NOP_:
AJMP_$cad:
LJMP_$cadP0:
RR_A:
INC_A:
INC_$dad:
INC_@R0:
INC_@R1:
INC_R0:
INC_R1:
INC_R2:
INC_R3:
INC_R4:
INC_R5:
INC_R6:
INC_R7:

JBC$bad_$cad:
ACALL_$cadP0:
LCALL_$cad:
RRC_A:
DEC_A:
DEC_$dad:
DEC_@R0:
DEC_@R1:
DEC_R0:
DEC_R1:
DEC_R2:
DEC_R3:
DEC_R4:
DEC_R5:
DEC_R6:
DEC_R7:

JB_$bad_$cad:
AJMP_$cadP1:
RET_:
RL_A:
ADD_A_dd:
ADD_A_$dad:
ADD_A_@R0:
ADD_A_@R1:
ADD_A_R0:
ADD_A_R1:
ADD_A_R2:
ADD_A_R3:
ADD_A_R4:
ADD_A_R5:
ADD_A_R6:
ADD_A_R7:

JNB_$bad_$cad:
ACALL_$cadP1:
RETI_:
RLC_A:
ADDC_A_dd:
ADDC_A_$dad:
ADDC_A_@R0:
ADDC_A_@R1:
ADDC_A_R0:
ADDC_A_R1:
ADDC_A_R2:
ADDC_A_R3:
ADDC_A_R4:
ADDC_A_R5:
ADDC_A_R6:
ADDC_A_R7:

JC_$cad:
AJMP_$cadP2:
ORL_$dad_A:
ORL_$dad_dd:
ORL_A_dd:
ORL_A_$dad:
ORL_A_@R0:
ORL_A_@R1:
ORL_A_R0:
ORL_A_R1:
ORL_A_R2:
ORL_A_R3:
ORL_A_R4:
ORL_A_R5:
ORL_A_R6:
ORL_A_R7:

JNC_$cad:
ACALL_$cadP2:
ANL_$dad_A:
ANL_$dad_dd:
ANL_A_dd:
ANL_A_$dad:
ANL_A_@R0:
ANL_A_@R1:
ANL_A_R0:
ANL_A_R1:
ANL_A_R2:
ANL_A_R3:
ANL_A_R4:
ANL_A_R5:
ANL_A_R6:
ANL_A_R7:

JZ_$cad:
AJMP_$cadP3:
XRL_$dad_A:
XRL_$dad_dd:
XRL_A_dd:
XRL_A_$dad:
XRL_A_@R0:
XRL_A_@R1:
XRL_A_R0:
XRL_A_R1:
XRL_A_R2:
XRL_A_R3:
XRL_A_R4:
XRL_A_R5:
XRL_A_R6:
XRL_A_R7:

JNZ_$cad:
ACALL_$cadP3:
ORL_C_$bad:
JMP_@A_DPTR:
MOV_A_dd:
MOV_$dad_dd:
MOV_@R0_dd:
MOV_@R1_dd:
MOV_R0_dd:
MOV_R1_dd:
MOV_R2_dd:
MOV_R3_dd:
MOV_R4_dd:
MOV_R5_dd:
MOV_R6_dd:
MOV_R7_dd:

SJMP_$cad:
AJMP_$cadP4:
ANL_C_$bad:
MOVC_A_@A_PC:
DIV_AB:
MOV_$dad_$dad:
MOV_$dad_@R0:
MOV_$dad_@R1:
MOV_$dad_R0:
MOV_$dad_R1:
MOV_$dad_R2:
MOV_$dad_R3:
MOV_$dad_R4:
MOV_$dad_R5:
MOV_$dad_R6:
MOV_$dad_R7:

MOV_DPTR_dw:
ACALL_$cadP4:
MOV_$bad_C:
MOVC_A_@A_DPTR:
SUBB_A_dd:
SUBB_A_$dad:
SUBB_A_@R0:
SUBB_A_@R1:
SUBB_A_R0:
SUBB_A_R1:
SUBB_A_R2:
SUBB_A_R3:
SUBB_A_R4:
SUBB_A_R5:
SUBB_A_R6:
SUBB_A_R7:

ORL_C_n$bad:
AJMP_$cadP5:
MOV_C_$bad:
INC_DPTR:
MUL_AB:
reserved:
MOV_@R0_$dad:
MOV_@R1_$dad:
MOV_R0_$dad:
MOV_R1_$dad:
MOV_R2_$dad:
MOV_R3_$dad:
MOV_R4_$dad:
MOV_R5_$dad:
MOV_R6_$dad:
MOV_R7_$dad:

ANL_C_n$bad:
ACALL_$cadP5:
CPL_$bad:
CPL_C:
CJNE_A_dd_$cad:
CJNE_A_$dad_$cad:
CJNE_@R0_dd_$cad:
CJNE_@R1_dd_$cad:
CJNE_R0_dd_$cad:
CJNE_R1_dd_$cad:
CJNE_R2_dd_$cad:
CJNE_R3_dd_$cad:
CJNE_R4_dd_$cad:
CJNE_R5_dd_$cad:
CJNE_R6_dd_$cad:
CJNE_R7_dd_$cad:

PUSH_$dad:
AJMP_$cadP6:
CLR_$bad:
CLR_C:
SWAP_A:
XCH_A_$dad:
XCH_A_@R0:
XCH_A_@R1:
XCH_A_R0:
XCH_A_R1:
XCH_A_R2:
XCH_A_R3:
XCH_A_R4:
XCH_A_R5:
XCH_A_R6:
XCH_A_R7:

POP_$dad:
ACALL_$cadP6:
SETB_$bad:
SETB_C:
DA_A:
DJNZ_$dad_$cad:
XCHD_A_@R0:
XCHD_A_@R1:
DJNZ_R0_$cad:
DJNZ_R1_$cad:
DJNZ_R2_$cad:
DJNZ_R3_$cad:
DJNZ_R4_$cad:
DJNZ_R5_$cad:
DJNZ_R6_$cad:
DJNZ_R7_$cad:

MOVX_A_@DPTR:
AJMP_$cadP7:
MOVX_A_@R0:
MOVX_A_@R1:
CLR_A:
MOV_A_$dad:
MOV_A_@R0:
MOV_A_@R1:
MOV_A_R0:
MOV_A_R1:
MOV_A_R2:
MOV_A_R3:
MOV_A_R4:
MOV_A_R5:
MOV_A_R6:
MOV_A_R7:

MOVX_@DPTR_A:
ACALL_$cadP7:
MOVX_@R0_A:
MOVX_@R1_A:
CPL_A:
MOV_$dad_A:
MOV_@R0_A:
MOV_@R1_A:
MOV_R0_A:
MOV_R1_A:
MOV_R2_A:
MOV_R3_A:
MOV_R4_A:
MOV_R5_A:
MOV_R6_A:
MOV_R7_A:
