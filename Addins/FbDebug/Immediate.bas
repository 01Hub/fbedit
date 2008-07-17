
Function GetVarVal(ByVal typ As Integer,ByVal adr As Integer,ByVal pres As RES Ptr) As Integer
	Dim As ZString*256 buff,bval

	Select Case typ
		Case 0
			' Proc
		Case 1
			' Integer
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
				pres->dval=Peek(Integer,@bval)
				pres->ntyp=INUM
			EndIf
		Case 2
			' Byte
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
				pres->dval=Peek(Byte,@bval)
				pres->ntyp=INUM
			EndIf
		Case 3
			' UByte
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
				pres->dval=Peek(UByte,@bval)
				pres->ntyp=INUM
			EndIf
		Case 4
			' Char
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,65,0)
				If Len(buff)>64 Then
					buff=Left(buff,64) & "..."
				EndIf
				pres->sval=buff
				pres->ntyp=ISTR
			EndIf
		Case 5
			' Short
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
				pres->dval=Peek(Short,@bval)
				pres->ntyp=INUM
			EndIf
		Case 6
			' UShort
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
				pres->dval=Peek(UShort,@bval)
				pres->ntyp=INUM
			EndIf
		Case 7
			' Void
			buff=""
		Case 8
			' UInteger
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
				pres->dval=Peek(UInteger,@bval)
				pres->ntyp=INUM
			EndIf
		Case 9
			' Longint
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				pres->dval=Peek(LongInt,@bval)
				pres->ntyp=INUM
			EndIf
		Case 10
			' ULongint
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				pres->dval=Peek(ULongInt,@bval)
				pres->ntyp=INUM
			EndIf
		Case 11
			' Single
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
				pres->dval=Peek(Single,@bval)
				pres->ntyp=INUM
			EndIf
		Case 12
			' Double
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				pres->dval=Peek(Double,@bval)
				pres->ntyp=INUM
			EndIf
		Case 13
			' String
			If adr Then
				buff=String(66,0)
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				adr=Peek(Integer,@bval)
				i=Peek(Integer,@bval+4)
				If adr>0 And i>0 Then
					If i>65 Then
						i=65
					EndIf
					ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,i,0)
					If Len(buff)>64 Then
						buff=Left(buff,64) & "..."
					EndIf
				EndIf
				pres->sval=buff
				pres->ntyp=ISTR
			EndIf
		Case 14
			' ZString
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,65,0)
				If Len(buff)>64 Then
					buff=Left(buff,64) & "..."
				EndIf
				pres->sval=buff
				pres->ntyp=ISTR
			EndIf
		Case 15
			' PChar
			buff=""
		Case Else
			'
	End Select
	Return 0

End Function

Function GetVarSize(ByVal typ As Integer) As Integer
	Dim s As Integer

	Select Case typ
		Case 0
			' Proc
		Case 1
			' Integer
			s=4
		Case 2
			' Byte
			s=1
		Case 3
			' UByte
			s=1
		Case 4
			' Char
		Case 5
			' Short
			s=2
		Case 6
			' UShort
			s=2
		Case 7
			' Void
		Case 8
			' UInteger
			s=4
		Case 9
			' Longint
			s=8
		Case 10
			' ULongint
			s=8
		Case 11
			' Single
		Case 12
			' Double
			s=8
		Case 13
			' String
			s=12
		Case 14
			' ZString
		Case 15
			' PChar
		Case Else
			'
	End Select
	Return s

End Function

Function FindVarVal(ByVal lpBuff As ZString Ptr,ByVal pres As RES Ptr,ByVal n As Integer,parr() As RES) As Integer
	Dim As ZString*256 buff,nme1,nme2,nsp,bval
	Dim As Integer i,j,adr,siz,fGlobal,fParam,typ
	Dim lpArr As tarr Ptr

	buff=*lpBuff
	If Left(buff,1)="." Then
		' With block, fixup buff
		i=IsProjectFile(@lpData->filename)
		i=SendMessage(lpHandles->hpr,PRM_ISINWITHBLOCK,i,nLnDebug)
		If i Then
			lstrcpy(@nme1,Cast(ZString Ptr,i))
			buff=nme1 & buff
		EndIf
	EndIf
	nme1=UCase(buff)
	' Fixup nme1
	While InStr(nme1,"->")
		i=InStr(nme1,"->")
		nme1=Left(nme1,i-1) & "." & Mid(nme1,i+2)
	Wend
	i=InStr(nme1,".")
	If i Then
		nsp="NS : " & nme1
		nme2=Mid(nme1,i+1)
		nme1=Left(nme1,i-1)
	EndIf
	i=1
	adr=0
	While i<=vrbnb
		If (vrb(i).pn=procsv Or vrb(i).pn<0) And (nme1=vrb(i).nm Or nsp=vrb(i).nm) Then
			Select Case vrb(i).mem
				Case 1
					adr=vrb(i).adr
					fGlobal=1
					'
				Case 2
					adr=vrb(i).adr
					fGlobal=1
					'
				Case 3
					adr=ebp_this+vrb(i).adr
					fParam=2
					'
				Case 4
					adr=ebp_this+vrb(i).adr
					fParam=1
					'
				Case 5
					adr=ebp_this+vrb(i).adr
					'
				Case Else
					nme1="Unknown"
			End Select
			If fGlobal=0 Then
				If fParam Then
					' Parameter
					If proc(procsv).nu=nLnDebug+1 Then
						If fParam=2 Then
							' ByRef
							ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@adr,4,0)
						EndIf
					Else
						adr=0
					EndIf
				Else
					' Check if in scope
					For j=1 To linenb
						If rline(j).nu=nLnDebug+1 And rline(j).sv=procsv Then
							If rline(j).ad<proc(procsv).db Or rline(j).ad>proc(procsv).fn Then
								adr=0
							EndIf
							Exit For
						EndIf
					Next
				EndIf
			EndIf
			If adr Then
				typ=vrb(i).typ
				If vrb(i).arr Then
					siz=GetVarSize(typ)
					lpArr=vrb(i).arr
MessageBox(0,Str(n),Str(lpArr->dmn),MB_OK)
					If n=lpArr->dmn Then
						For j=0 To lpArr->dmn-1
							If parr(j).ntyp=INUM Then
								If parr(j).dval<lpArr->nlu(j).lb Or parr(j).dval>lpArr->nlu(j).ub Then
									adr=0
									Exit For
								EndIf
							Else
								adr=0
								Exit For
							EndIf
						Next
					Else
						adr=0
					EndIf
				EndIf
				For j=1 To vrb(i).pt
					ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@adr,4,0)
				Next
				If typ>15 Then
					For i=udt(typ).lb To udt(typ).ub
						If cudt(i).nm=nme2 Then
							If adr Then
								adr+=cudt(i).ofs
							EndIf
							If cudt(i).arr Then
								' Array
								'lpArr=Cast(tarr Ptr,cudt(i).arr)
								'dp=InStr(dp+1,*lpszBuff,"(")
								'*lpszBuff=Left(*lpszBuff,dp) & GetUdtDim(@audt(cudt(i).arr)) & Mid(*lpszBuff,dp+1)
							EndIf
							typ=cudt(i).Typ
							GetVarVal(typ,adr,pres)
							Exit For
						EndIf
					Next
				Else
					GetVarVal(typ,adr,pres)
				EndIf
			EndIf
			Return adr
		EndIf
		i+=1
	Wend
	Return adr

End Function

Function ExecFunc(ByVal f As Integer,ByVal pres1 As RES Ptr,ByVal pres2 As RES Ptr) As Integer
	Dim res As RES

	Select Case f
		Case FADD
			' +
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval+pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->sval=pres1->sval & pres2->sval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FSUB
			' -
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval-pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FSHL
			' Shl
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Shl pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FSHR
			' Shr
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Shr pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FMOD
			' Mod
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Mod pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FIDIV
			' \
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval\pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FMUL
			' *
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval*pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FDIV
			' *
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval/pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FNEG
			If pres2->ntyp=INUM Then
				pres1->ntyp=INUM
				pres1->dval=-pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FEXP
			' ^
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval^pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FLE
			' <
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval<pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->dval=pres1->sval<pres2->sval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FLEEQ
			' <=
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval<=pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->dval=pres1->sval<=pres2->sval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FEQ
			' =
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval=pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->dval=pres1->sval=pres2->sval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FNEQ
			' <>
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval<>pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->dval=pres1->sval<>pres2->sval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FGTEQ
			' >=
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval>=pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->dval=pres1->sval>=pres2->sval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FGT
			' >
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval>pres2->dval
			ElseIf pres1->ntyp=ISTR And pres2->ntyp=ISTR Then
				pres1->dval=pres1->sval>pres2->sval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FNOT
			' Not
			If pres2->ntyp=INUM Then
				pres1->dval=Not pres2->dval
				pres1->ntyp=INUM
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FAND
			' And
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval And pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FLOR
			' Or
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Or pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FXOR
			' Xor
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Xor pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FEQV
			' Eqv
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Eqv pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FIMP
			' Imp
			If pres1->ntyp=INUM And pres2->ntyp=INUM Then
				pres1->dval=pres1->dval Imp pres2->dval
			Else
				pres1->ntyp=IERR
				Return -1
			EndIf
		Case FSADD
			' &
			pres1->sval=pres1->sval & pres2->sval
	End Select
	Return 0

End Function

Function ImmFunc(ByVal px As Integer Ptr,ByVal n As Integer,ByVal f As Integer,ByVal pres As RES Ptr) As Integer
	Dim As Integer l

	Select Case f
		Case INUM
			l=szCompiled[*px]
			*px+=1
			pres->ntyp=f
			pres->dval=Val(Mid(szCompiled,*px+1,l))
			*px+=l
		Case ISTR
			l=szCompiled[*px]
			*px+=1
			pres->ntyp=f
			pres->sval=Mid(szCompiled,*px+1,l)
			*px+=l
	End Select
	Return 0

End Function

Function ArgFunc(ByVal px As Integer Ptr,pres() As RES) As Integer
	Dim As Integer i,lret

	lret=EvalFunc(px,0,@pres(i))
	i+=1
	While szCompiled[*px]=MFUN And szCompiled[*px+1]=FCOMMA
		*px+=2
		lret=EvalFunc(px,0,@pres(i))
		i+=1
	Wend
	Return i

End Function

Function NumFunc(ByVal px As Integer Ptr,ByVal f As Integer,ByVal pres As RES Ptr) As Integer
	Dim lret As Integer
	Dim res(8) As RES

	lret=ArgFunc(px,res())
	pres->ntyp=INUM
	Select Case f
		Case NASC
			If lret=1 And res(0).ntyp=ISTR Then
				pres->dval=Asc(res(0).sval)
			ElseIf lret=2 And res(0).ntyp=ISTR And res(1).ntyp=INUM Then
				pres->dval=Asc(res(0).sval,res(1).dval)
			Else
				GoTo NErr
			EndIf
		Case NLEN
			If lret=1 And res(0).ntyp=ISTR Then
				pres->dval=Len((res(0).sval))
			Else
				GoTo NErr
			EndIf
		Case NINSTR
			If lret=2 And res(0).ntyp=ISTR And res(1).ntyp=ISTR Then
				pres->dval=InStr(res(0).sval,res(1).sval)
			ElseIf lret=3 And res(0).ntyp=INUM And res(1).ntyp=ISTR And res(2).ntyp=ISTR Then
				pres->dval=InStr(res(0).dval,res(1).sval,res(2).sval)
			Else
				GoTo NErr
			EndIf
		Case NINSTRREV
			If lret=2 And res(0).ntyp=ISTR And res(1).ntyp=ISTR Then
				pres->dval=InStrRev(res(0).sval,res(1).sval)
			ElseIf lret=3 And res(0).ntyp=ISTR And res(1).ntyp=ISTR And res(2).ntyp=INUM Then
				pres->dval=InStrRev(res(0).sval,res(1).sval,res(2).dval)
			Else
				GoTo NErr
			EndIf
	End Select
	If szCompiled[*px]=MFUN And szCompiled[*px+1]=FRPA Then
		*px+=2
		Return 0
	EndIf
NErr:
	pres->ntyp=IERR
	Return -1

End Function

Function StrFunc(ByVal px As Integer Ptr,ByVal f As Integer,ByVal pres As RES Ptr) As Integer
	Dim As Integer lret,i
	Dim res(8) As RES

	lret=ArgFunc(px,res())
	pres->ntyp=ISTR
	Select Case f
		Case SSTR
			If lret=1 And res(0).ntyp=INUM Then
				pres->sval=Str(res(0).dval)
			Else
				GoTo SErr
			EndIf
		Case SCHR
			pres->sval=""
			For i=0 To lret-1
				If res(i).ntyp=INUM Then
					pres->sval &=Chr(res(i).dval)
				Else
					GoTo SErr
				EndIf
			Next
		Case SLEFT,SRIGHT
			If lret=2 And res(0).ntyp=ISTR And res(1).ntyp=INUM Then
				If f=SLEFT Then
					pres->sval=Left(res(0).sval,res(1).dval)
				Else
					pres->sval=Right(res(0).sval,res(1).dval)
				EndIf
			Else
				GoTo SErr
			EndIf
		Case SMID
			If lret=2 And res(0).ntyp=ISTR And res(1).ntyp=INUM Then
				pres->sval=Mid(res(0).sval,res(1).dval)
			ElseIf lret=3 And res(0).ntyp=ISTR And res(1).ntyp=INUM And res(2).ntyp=INUM Then
				pres->sval=Mid(res(0).sval,res(1).dval,res(2).dval)
			Else
				GoTo SErr
			EndIf
		Case SSPACE
			If lret=1 And res(0).ntyp=INUM Then
				pres->sval=Space(res(0).dval)
			Else
				GoTo SErr
			EndIf
		Case SSTRING
			If lret=2 And res(0).ntyp=INUM Then
				If res(1).ntyp=ISTR Then
					pres->sval=String(res(0).dval,res(1).sval)
				Else
					pres->sval=String(res(0).dval,res(1).dval)
				EndIf
			Else
				GoTo SErr
			EndIf
	End Select
	If szCompiled[*px]=MFUN And szCompiled[*px+1]=FRPA Then
		*px+=2
		Return 0
	EndIf
SErr:
	pres->ntyp=IERR
	Return -1

End Function

Function VarFunc(ByVal px As Integer Ptr,ByVal pres As RES Ptr) As Integer
	Dim As Integer l,n
	Dim svar As ZString*256
	Dim res(8) As RES

	l=szCompiled[*px]
	*px+=1
	svar=LCase(Mid(szCompiled,*px+1,l))
	*px+=l
	If hThread Then
		If szCompiled[*px]=MFUN And szCompiled[*px+1]=FLPA Then
			' Array
			*px+=2
			n=ArgFunc(px,res())
			If szCompiled[*px]=MFUN And szCompiled[*px+1]=FRPA Then
				*px+=2
				l=FindVarVal(@svar,pres,n,res())
			Else
				l=FindVarVal(@svar,pres,0,res())
			EndIf
		EndIf
	Else
		Select Case svar
			Case "i"
				pres->ntyp=INUM
				pres->dval=i
			Case "d"
				pres->ntyp=INUM
				pres->dval=d
			Case "di"
			Case "s"
				pres->ntyp=ISTR
				pres->sval=s
			Case "si"
		End Select
	EndIf
	Return 0

End Function

Function EvalFunc(ByVal px As Integer Ptr,ByVal pf As Integer,ByVal pres As RES Ptr) As Integer
	Dim As Integer n,f,lret
	Dim res As RES

	While TRUE
Nxt:
		If lret=-1 Then
			pres->ntyp=IERR
			Return -1
		EndIf
		n=szCompiled[*px]
		f=szCompiled[*px+1]
		Select Case n
			Case IFUN
				*px+=2
				lret=ImmFunc(px,n,f,@res)
				GoTo Nxt
			Case NFUN
				*px+=2
				If szCompiled[*px]=MFUN And szCompiled[*px+1]=FLPA Then
					*px+=2
					lret=NumFunc(px,f,@res)
					GoTo Nxt
				EndIf
				pres->ntyp=IERR
				Return -1
			Case SFUN
				*px+=2
				If szCompiled[*px]=MFUN And szCompiled[*px+1]=FLPA Then
					*px+=2
					lret=StrFunc(px,f,@res)
					GoTo Nxt
				EndIf
				pres->ntyp=IERR
				Return -1
			Case VFUN
				*px+=2
				lret=VarFunc(px,@res)
				GoTo Nxt
			Case 0,MFUN
				Select Case f
					Case FLPA
						*px+=2
						lret=EvalFunc(px,f,@res)
						If szCompiled[*px]=MFUN And szCompiled[*px+1]=FRPA Then
							*px+=2
							lret=ExecFunc(pf,pres,@res)
							GoTo Nxt
						Else
							pres->ntyp=IERR
							Return -1
						EndIf
					Case FRPA,FCOMMA
						f=0
				End Select
				Select Case pf
					Case FXOR,FIMP,FEQV
						' Xor, Imp, Eqv
						If f<FLOR Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FLOR
						' Or
						If f<FAND Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FAND
						' And
						If f<FNOT Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FNOT
						' Not
						If f<FGTEQ Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FGTEQ
						' >=
						If f<FLEEQ Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FLEEQ
						' <=
						If f<FGT Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FGT
						' >
						If f<FLE Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FLE
						' <
						If f<FNEQ Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FNEQ
						' <>
						If f<FEQ Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FEQ
						' =
						If f<FADD Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FADD,FSUB
						' +,-
						If f<FSHL Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FSHL,FSHR
						' Shl, Shr
						If f<FMOD Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FMOD
						' Mod
						If f<FIDIV Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FIDIV
						' \
						If f<FMUL Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FMUL,FDIV
						' *,/
						If f<FNEG Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FNEG
						' -
						If f<FEXP Then
							Return ExecFunc(pf,pres,@res)
						EndIf
					Case FEXP
						' ^
						Return ExecFunc(pf,pres,@res)
					Case FSADD
						' &
						Return ExecFunc(pf,pres,@res)
				End Select
			Case Else
				Return -1
		End Select
		If f Then
			*px+=2
			lret=EvalFunc(px,f,@res)
		Else
			pres->ntyp=res.ntyp
			pres->dval=res.dval
			pres->sval=res.sval
			Return 0
		EndIf
	Wend
	pres->ntyp=IERR
	Return -1

End Function

Function FindFunction(lpBuff As ZString Ptr) As Integer
	Dim x As Integer
	Dim buff As ZString*256

	buff=LCase(*lpBuff)
	For x=0 To 255
		If buff=fn(x).szText Then
			*lpBuff=buff
			Return fn(x).nID
		EndIf
	Next
	Return 0

End Function

Sub AddFunction(n As Integer,ftyp As Integer,lpBuff As ZString Ptr)

	Select Case n
		Case IFUN,VFUN
			szCompiled &=Chr(n) & Chr(ftyp) & Chr(Len(*lpBuff)) & *lpBuff
			*lpBuff=""
		Case MFUN,NFUN,SFUN
			szCompiled &=Chr(n) & Chr(ftyp)
			*lpBuff=""
	End Select

End Sub

Function Compile(lpLine As ZString Ptr) As Integer
	Dim As Integer i,x,c,ftyp,npara
	Dim buff As ZString*512
	
	szCompiled=String(SizeOf(szCompiled),0)
	For x=0 To Len(*lpLine)-1
		c=lpLine[x]
		If ftyp=ISTR Then
			If c=34 Then
				AddFunction(IFUN,ftyp,@buff)
				ftyp=0
			Else
				buff &=Chr(c)
			EndIf
		ElseIf (c>=48 And c<=57) Then
			'0 to 9
			If ftyp=INUM Or (ftyp=0 And Len(buff)=0) Then
				buff &=Chr(c)
				ftyp=INUM
			ElseIf ftyp=0 Then
				buff &=Chr(c)
			Else
				MessageBox(0,"Error","Compile",MB_OK)
				Return -1
			EndIf
		ElseIf c=46 Then
			' .
			If ftyp=INUM Or (ftyp=0 And Len(buff)=0) Then
				buff &=Chr(c)
				ftyp=INUM
			ElseIf ftyp=0 Then
				buff &=Chr(c)
			Else
				MessageBox(0,"Error","Compile",MB_OK)
				Return -1
			EndIf
		ElseIf c=34 Then
			' "
			If ftyp=0 Then
				buff=""
				ftyp=ISTR
			Else
				MessageBox(0,"Error","Compile",MB_OK)
				Return -1
			EndIf
		ElseIf c=32 Or c=9 Or c=40 Or c=41 Or c=43 Or c=45 Or c=42 Or c=47 Or c=94 Or c=60 Or c=61 Or c=62 Or c=38 Or c=44 Or c=92 Then
			' (, ), +, -, *, /, ^, <, =, >, &, \, ,
			If buff<>"" Then
				If ftyp Then
					AddFunction(IFUN,ftyp,@buff)
				Else
					ftyp=FindFunction(@buff)
					If ftyp Then
						If ftyp<32 then
							' Math
							AddFunction(MFUN,ftyp,@buff)
						ElseIf ftyp<128 Then
							' Numeric
							AddFunction(NFUN,ftyp,@buff)
						Else
							' String
							AddFunction(SFUN,ftyp,@buff)
						EndIf
					Else
						' Variable
						AddFunction(VFUN,VFUN,@buff)
					EndIf
				EndIf
			EndIf
			If c<>32 And c<>9 Then
				buff=Chr(c)
				If c=60 Then
					' <
					c=lpLine[x+1]
					If c=61 Or c=62 Then
						' <=, <>
						buff &=Chr(c)
						x+=1
					EndIf
				ElseIf c=62 Then
					' >
					c=lpLine[x+1]
					If c=61 Then
						' >=
						buff &=Chr(c)
						x+=1
					EndIf
				EndIf
				ftyp=FindFunction(@buff)
				If ftyp=FSUB Then
					i=Len(szCompiled)
					If i>1 Then
						If szCompiled[i-2]=MFUN Then
							If szcompiled[i-1]=FSUB Then
								szCompiled[i-1]=FADD
								buff=""
								ftyp=0
							ElseIf szcompiled[i-1]=FADD Then
								szCompiled[i-1]=FSUB
								buff=""
								ftyp=0
							ElseIf szcompiled[i-1]=FNEG Then
								szcompiled=Left(szcompiled,i-2)
								buff=""
								ftyp=0
							Else
								ftyp=FNEG
							EndIf
						EndIf
					ElseIf i=0 Then
						ftyp=FNEG
					EndIf
				EndIf
				If ftyp Then
					AddFunction(MFUN,ftyp,@buff)
					If ftyp=FLPA Then
						npara+=1
					ElseIf ftyp=FRPA Then
						npara-=1
					EndIf
				EndIf
			EndIf
			ftyp=0
		Else
			buff &=Chr(c)
		EndIf
	Next
	If buff<>"" Then
		If ftyp Then
			AddFunction(IFUN,ftyp,@buff)
		Else
			ftyp=FindFunction(@buff)
			If ftyp Then
				If ftyp<32 Then
					' Math
					AddFunction(MFUN,ftyp,@buff)
				ElseIf ftyp<128 Then
					' Numeric
					AddFunction(NFUN,ftyp,@buff)
				Else
					' String
					AddFunction(SFUN,ftyp,@buff)
				EndIf
			Else
				' Variable
				AddFunction(VFUN,VFUN,@buff)
			EndIf
		EndIf
	EndIf
	If npara Then
		Return -1
	EndIf
	buff=" ("
	For i=0 To Len(szCompiled)
		buff &=Str(szCompiled[i]) & ","
	Next
	buff=Left(buff,Len(buff)-1) & ")"
	SendMessage(lpHandles->hout,EM_REPLACESEL,0,Cast(LPARAM,@buff))
	Return 0

End Function

Function Immediate() As Integer
	Dim buff As ZString*256
	Dim As Integer lret,x
	Dim res As RES

	buff=String(SizeOf(buff),0)
	lret=SendMessage(lpHandles->hout,EM_GETSEL,0,0)
	lret=LoWord(lret)
	lret=SendMessage(lpHandles->hout,EM_LINEFROMCHAR,lret,0)
	buff[0]=255
	lret=SendMessage(lpHandles->hout,EM_GETLINE,lret,Cast(LPARAM,@buff))
	buff[lret]=0
	If Left(buff,1)="?" Then
		buff=Mid(buff,2)
		lret=Compile(@buff)
		If lret=0 Then
			x=0
			lret=EvalFunc(@x,0,@res)
			If lret=0 Then
				Select Case res.ntyp
					Case INUM
						buff=Chr(VK_RETURN,10) & Str(res.dval) & Chr(VK_RETURN,10)
						SendMessage(lpHandles->hout,EM_REPLACESEL,0,Cast(LPARAM,@buff))
					Case ISTR
						buff=Chr(VK_RETURN,10) & res.sval & Chr(VK_RETURN,10)
						SendMessage(lpHandles->hout,EM_REPLACESEL,0,Cast(LPARAM,@buff))
				End Select
			EndIf
		EndIf
	ElseIf InStr(buff,"=") Then
		buff=Mid(buff,InStr(buff,"=")+1)
		lret=Compile(@buff)
		If lret=0 Then
			lret=EvalFunc(@x,0,@res)
			If lret=0 Then
				i=res.dval
				buff=Chr(VK_RETURN,10)
				SendMessage(lpHandles->hout,EM_REPLACESEL,0,Cast(LPARAM,@buff))
			EndIf
		EndIf
	Else
		lret=-1
	EndIf
	If lret=-1 Then
		buff=Chr(VK_RETURN,10) & "Syntax error" & Chr(VK_RETURN,10)
		SendMessage(lpHandles->hout,EM_REPLACESEL,0,Cast(LPARAM,@buff))
	EndIf
	Return 0

End Function
