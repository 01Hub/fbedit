
' DATA STAB
Type udtstab
	stabs			As Integer
	code			As UShort
	nline			As UShort
	ad				As Integer
End Type

Type tproc
	nm				As String   'name
	db				As UInteger 'lower address
	fn				As UInteger 'upper address
	sr				As Byte     'source index
	ad				As UInteger 'address
	vr				As UInteger 'lower index variable upper (next proc) -1
	rv				As Integer  'return value type
	nu				As UShort	'Line number
End Type

Type tprocr
	sk				As UInteger
	idx			As UInteger
	'lst 			As uinteger 'future array in LIST
End Type

Enum
	TYUDT
	TYRDM
	TYDIM
End Enum

Enum 'type of running
	RTRUN
	RTSTEP
	RTAUTO
End Enum

Type tudt
	nm				As String  'name of udt
	lb				As Integer 'lower limit for components
	ub				As Integer 'upper
	lg				As Integer 'lenght 
End Type

Type tcudt
	nm				As String    'name of components
	Typ			As UShort   'type
	ofs			As UInteger 'offset
	arr			As UInteger 'arr ptr
	pt				As UByte
End Type

Type tnlu
	nb				As UInteger
	lb				As UInteger
	ub				As UInteger
End Type

Type taudt
	dm				As Integer
	nlu(5)		As tnlu
End Type

Type tarr 'five dimensions max
	dat			As Any Ptr
	pot			As Any Ptr
	siz			As UInteger 'nb bytes non used
	dmn			As UInteger
	nlu(5)		As tnlu
End Type

Type tvar
	nm				As String    'name
	typ			As UShort   'type
	adr			As Integer  'address or offset 
	mem			As UByte    'scope 
	arr			As tarr Ptr 'pointer to array def
	pt				As UByte     'pointer
	pn				As Short    'to keep track of vars with same name
End Type

Type tline
	ad				As UInteger	'Address
	nu				As Integer	'Line number
	sv				As Short 	'Source byte
	pr				As UShort	'Proc
	isbp			As Integer	'Breakpoint
End Type

Type tsource
	file			As String	'Filename
	pInx			As Integer	'Project index
End Type

Type tthread
	thread		As HANDLE
	threadid		As UInteger
	threadres	As UInteger
End Type

Dim Shared pinfo As PROCESS_INFORMATION
Dim Shared dbghand As HANDLE
Dim Shared ct As CONTEXT

Dim Shared secnb As UShort
Dim Shared pe As UInteger
Dim Shared secnm As String*8
Dim Shared basestab As UInteger
Dim Shared basestabs As UInteger
Dim Shared recupstab As udtstab
Dim Shared recup As ZString*1000

Dim Shared procnb As Integer,procfg As Byte
Dim Shared As UInteger procsv,procad ,procin,procsk,proccurad

Const PROCMAX=500
Dim Shared proc(PROCMAX) As tproc

'Running proc
Const PROCRMAX=50000
Dim Shared procr(PROCRMAX) As tprocr,procrnb as Integer 'list of running proc
Dim Shared procrsk As UInteger

'sources ===========================================
Dim Shared source(SOURCEMAX) As tsource,sourceix As Integer,sourcenb As Integer

Dim Shared ttyp As Byte

Const TYPEMAX=1500,CTYPEMAX=10000,ATYPEMAX=1000
Dim Shared udt(TYPEMAX) As tudt,udtidx As Integer
Dim Shared cudt(CTYPEMAX) As tcudt,cudtnb As Integer
Dim Shared audt(ATYPEMAX) As taudt,audtnb As Integer
udt(0).nm="Proc"
udt(1).nm="Integer"
udt(2).nm="Byte"
udt(3).nm="Ubyte"
udt(4).nm="Char"
udt(5).nm="Short"
udt(6).nm="Ushort"
udt(7).nm="Void"
udt(8).nm="Uinteger"
udt(9).nm="Longint"
udt(10).nm="Ulongint"
udt(11).nm="Single"
udt(12).nm="Double"
udt(13).nm="String"
udt(14).nm="Zstring"
udt(15).nm="Pchar"

Const VARMAX=5000
Dim Shared vrbnb As UInteger  'nb of variables
Dim Shared vrb(VARMAX) As tvar
Const ARRMAX=1000
Dim Shared arr(ARRMAX) As tarr,arrnb As UShort
Const LINEMAX=250000
Dim Shared rline(LINEMAX) As tline
Dim Shared linenb As UInteger,linesav As UInteger
Const THREADMAX=50
Dim Shared threadnb As UInteger
Dim Shared thread(THREADMAX) As tthread
Dim Shared threadcontext As HANDLE

Dim Shared breakvalue As Integer =&hCC
Dim Shared linead As UInteger
