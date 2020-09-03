MODULE AdLoader;	(* Attempt to "load" machine text and execute it *)

	IMPORT SYSTEM, KernelLog;

	TYPE P = PROCEDURE;

	PROCEDURE Test*;
		CONST NOP = 90X; RET = 0C3X;
		VAR padding: SIGNED64; a: ARRAY 64 OF SYSTEM.BYTE;
			adr: ADDRESS; p: P; i: INTEGER; var: SIGNED32;
	BEGIN
		KernelLog.String("Fucking shit"); KernelLog.Ln;
		i := 0; WHILE i < 10 DO a[i] := 0; INC(i) END;
		a[10] := 0C7H; a[11] := 05H; a[12] := 0ECH; a[13] := 0FFH; a[14] := 0FFH; a[15] := 0FFH;
		a[16] := 0AH; a[17] := 0AH; a[18] := 0ACH; a[19] := 01; a[20] := RET;
		adr := ADDRESSOF(a);
		p := SYSTEM.VAL(P, adr + 10);
		p;
		var := SYSTEM.GET32(adr);
		KernelLog.String("Successsy"); KernelLog.Size(var); KernelLog.Ln
	END Test;

	PROCEDURE Execute* (dsize: SIZE; CONST mtext: ARRAY OF CHAR; VAR resdata: POINTER TO ARRAY OF SYSTEM.BYTE);
		CONST NOP = 90X; RET = 0C3X;
		VAR b: POINTER TO ARRAY OF SYSTEM.BYTE;
			p: P; len, i, j: SIZE; adr: ADDRESS;
	BEGIN
		ASSERT(dsize > 0, 20);
		len := LEN(mtext);
		NEW(b, dsize + len + 1);
		i := 0; WHILE i < dsize DO b^[i] := 0; INC(i) END;
		j := 0; WHILE j < len DO b^[i] := ORD(mtext[j]); INC(i); INC(j) END;
		b^[i] := RET;
		p := SYSTEM.VAL(P, dsize + SYSTEM.VAL(ADDRESS, b));
		adr := ADDRESSOF(b[0]);
		p := SYSTEM.VAL(P, ADDRESSOF(b[dsize]));
		p;
		resdata := b
	END Execute;

	PROCEDURE T2*;
		CONST RET = 0C3X;
		VAR a: ARRAY 16 OF CHAR; d: POINTER TO ARRAY OF SYSTEM.BYTE; var: SIZE; ch: CHAR;
	BEGIN
		var := -1;
		a[0] := 0C7X; a[1] := 05X; a[2] := 0ECX; a[3] := 0FFX; a[4] := 0FFX; a[5] := 0FFX;
		a[6] := 0AX; a[7] := 0AX; a[8] := 0ACX; a[9] := 01X; a[10] := RET;
		var := -2;
		Execute(10, a, d);
		var := -3;
		ASSERT(d # NIL, 90);
		var := -4;
		KernelLog.String("Executed: ");
		ch := CHR(d[0]);
		var := ORD(CHR(d[0])) + ORD(CHR(d[1])) * 100H + ORD(CHR(d[2])) * 10000H + ORD(CHR(d[3])) * 1000000H;
		KernelLog.Size(var)
	END T2;

	PROCEDURE T3*;
		CONST RET = 0C3X;
		VAR a: ARRAY 24 OF CHAR; d: POINTER TO ARRAY OF SYSTEM.BYTE; var: SIZE; ch: CHAR; i: SIZE;
	BEGIN
		var := -1;
		a[0] := 055X; a[1] := 048X; a[2] := 08BX; a[3] := 0ECX; a[4] := 057X; a[5] := 056X; a[6] := 0C7X; a[7] := 005X; a[8] := 0ECX; a[9] := 0FFX; a[10] := 0FFX; a[11] := 0FFX; a[12] := 011X; a[13] := 022X; a[14] := 033X; a[15] := 044X; a[16] := 05EX; a[17] := 05FX; a[18] := 048X; a[19] := 08BX; a[20] := 0E5X; a[21] := 05DX; a[22] := 0C3X; a[23] := 0X;
		var := -2;
		Execute(12, a, d);
		var := -3;
		ASSERT(d # NIL, 90);
		var := -4;
		KernelLog.String("Now Executed: ");
		ch := CHR(d[0]);
		i := 8;
		var := ORD(CHR(d[i])) + ORD(CHR(d[i + 1])) * 100H + ORD(CHR(d[i + 2])) * 10000H + ORD(CHR(d[i + 3])) * 1000000H;
		KernelLog.Size(var)
	END T3;

END AdLoader.

AdLoader.Test

AdLoader.T2

AdLoader.T3

System.FreeDownTo AdLoader ~