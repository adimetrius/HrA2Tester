MODULE AdPlugin;	(* Test plugin for WebHTTPServer *)

	IMPORT SYSTEM,
		Streams,  Commands, Strings, KernelLog,
		WebHTTP, WebHTTPServer,
		AdLoader;

		PROCEDURE Hex (hi, lo: CHAR; VAR ch: CHAR; VAR ok: BOOLEAN);
			VAR h, l: INTEGER;
		BEGIN
			h := ORD(hi) - ORD('0');
			IF h > 9 THEN h := ORD(hi) - ORD('A') + 10 END;
			ok := (0 <= h) & (h < 16);
			IF ok THEN
				 l:= ORD(lo) - ORD('0');
				IF l > 9 THEN l := ORD(lo) - ORD('A') + 10 END;
				ok := (0 <= l) & (l < 16);
				IF ok THEN ch := CHR(h * 10H + l) END
			END
		END Hex;

		PROCEDURE Mtext (CONST from: ARRAY OF CHAR; VAR to: POINTER TO ARRAY OF CHAR);
			VAR i, j, len: SIZE; ok: BOOLEAN;
		BEGIN
			len := Strings.Length(from);
			IF ~ODD(len) THEN
				NEW(to, len DIV 2 + 1);
				i := 0; j := 0; REPEAT Hex(from[i], from[i+1], to^[j], ok); INC(i, 2); INC(j)
				UNTIL ~ok OR (i >= len);
				IF ~ok THEN to := NIL END
			ELSE KernelLog.String("Bad length of mtext"); KernelLog.Ln
			END
		END Mtext;
		
		PROCEDURE TMT*;
			VAR res: POINTER TO ARRAY OF CHAR; i: SIZE;
				a: ARRAY 64 OF CHAR;
		BEGIN Mtext("55488BEC5756C705ECFFFFFF112233445E5F488BE55DC300", res); 
			a[0] := 055X; a[1] := 048X; a[2] := 08BX; a[3] := 0ECX; a[4] := 057X; a[5] := 056X; a[6] := 0C7X; a[7] := 005X; a[8] := 0ECX; a[9] := 0FFX; a[10] := 0FFX; a[11] := 0FFX; a[12] := 011X; a[13] := 022X; a[14] := 033X; a[15] := 044X; a[16] := 05EX; a[17] := 05FX; a[18] := 048X; a[19] := 08BX; a[20] := 0E5X; a[21] := 05DX; a[22] := 0C3X; a[23] := 0X;
			i := 0; WHILE i < LEN(res^) DO 
				IF a[i] # res^[i] THEN KernelLog.Size(i); KernelLog.Hex(ORD(a[i]), 2); KernelLog.Hex(ORD(res^[i]), 2); KernelLog.Ln END; 
				INC(i) 
			END;

		END TMT;

	TYPE
		Plugin = OBJECT (WebHTTPServer.HTTPPlugin)

		PROCEDURE CanHandle*(host : WebHTTPServer.Host; VAR header: WebHTTP.RequestHeader; secure : BOOLEAN): BOOLEAN;
		BEGIN RETURN TRUE
		END CanHandle;

		PROCEDURE Handle*(host: WebHTTPServer.Host; VAR request: WebHTTP.RequestHeader; VAR reply: WebHTTP.ResponseHeader;
			VAR in: Streams.Reader; VAR out: Streams.Writer);
		VAR c: WebHTTP.ChunkedOutStream; w: Streams.Writer;
			ch: CHAR; af: WebHTTP.AdditionalField; beg, conlen: SIZE; buf: ARRAY 16 OF CHAR;
			len, fuck, i, j, dsize: SIGNED32;
			ok: BOOLEAN;
			res, mtext: POINTER TO ARRAY OF CHAR;
			a: ARRAY 24 OF CHAR;
			data: POINTER TO ARRAY OF SYSTEM.BYTE;
		BEGIN
			KernelLog.String("THIS begins"); KernelLog.Ln;
			IF (request.method IN {WebHTTP.GetM}) THEN
				WebHTTPServer.GetDefaultResponseHeader(request, reply);

				IF request.method = WebHTTP.PostM THEN w.String("This is a POST request"); w.Ln;
					KernelLog.Size(in.Available() (* hangs *)); KernelLog.Ln
				ELSIF request.method = WebHTTP.GetM THEN
					(* w.String("<html><head><title>ADIMETRIUS</title></head>");
					w.String("<body>Hello, this is Adimetrius; follows the echo of request content<hr><address>");
					w.String(WebHTTPServer.ServerVersion); w.String("</address>"); *)
					dsize := -1;
					af := request.additionalFields;
					WHILE af # NIL DO
						conlen := -1;
						IF (af.key = "content-length") OR (af.key = "Content-length") THEN
							Strings.StrToSize(af.value, conlen)
						ELSIF af.key = "mtext" THEN Mtext(af.value, mtext)
						ELSIF af.key = "dsize" THEN Strings.StrToInt(af.value, dsize)
						END;
						(* w.String(af.key); w.String(" = "); w.String(af.value); w.Ln; *)
						KernelLog.String(af.key); KernelLog.String(" = "); KernelLog.String(af.value); KernelLog.Ln;
						af := af.next
					END;
				END;
				reply.contenttype := "text/plain";
				IF (dsize <= 0) OR (mtext = NIL) THEN (* error *)
					reply.statuscode := WebHTTP.BadRequest;
					reply.contentlength := 0;
					WebHTTP.SendResponseHeader(reply, out)
				ELSE
					reply.contentlength := dsize;
					reply.statuscode := WebHTTP.OK;
					WebHTTP.SendResponseHeader(reply, out);
					w := out;
					a[0] := 055X; a[1] := 048X; a[2] := 08BX; a[3] := 0ECX; a[4] := 057X; a[5] := 056X; a[6] := 0C7X; a[7] := 005X; a[8] := 0ECX; a[9] := 0FFX; a[10] := 0FFX; a[11] := 0FFX; a[12] := 011X; a[13] := 022X; a[14] := 033X; a[15] := 044X; a[16] := 05EX; a[17] := 05FX; a[18] := 048X; a[19] := 08BX; a[20] := 0E5X; a[21] := 05DX; a[22] := 0C3X; a[23] := 0X;

					i := 0; WHILE (i < LEN(mtext^)) & (i < LEN(a)) DO ASSERT(a[i] = mtext^[i], 55); INC(i) END;

					KernelLog.String(a);
					KernelLog.String(mtext^);
					AdLoader.Execute(dsize, mtext^, data);
					ASSERT(data # NIL, 90); ASSERT(LEN(data) >= dsize, 91);
					fuck := 1;
					(* w.RawLInt(dsize); *)
					fuck := 2;
					NEW(res, dsize);
					fuck := 3;
					i := 0; WHILE i < dsize DO res[i] := CHR(data[i]); INC(i) END;
					fuck := 4;
					w.Bytes(res^, 0, dsize);
					fuck := 5;
					;fuck := 6
				END;
				(* IF mtext # NIL THEN
					(* NEW(c, w, out, request, reply); *)w := out;
					w.String(mtext^); w.Update
					(* c.Close *)
				END *)
			END;
			KernelLog.String("THIS is over..."); KernelLog.Ln;
		END Handle;
	END Plugin;


PROCEDURE Install*(context : Commands.Context); (** [{host}]. Host may include wildcards. *)
VAR
	host: ARRAY 1024 OF CHAR;
	hl: WebHTTPServer.HostList; p: Plugin;
BEGIN
	NEW(p, 'AdPlugin');

	REPEAT
		context.arg.SkipWhitespace; context.arg.String(host);
		Strings.Trim(host, " ");

		hl := WebHTTPServer.FindHosts(host);
		IF (hl # NIL) THEN
			WHILE (hl # NIL) DO
				hl.host.AddPlugin(p);
				context.out.String("AdPlugin"); context.out.String(" added to ");
				IF (hl.host.name = "") THEN context.out.String("default host")
				ELSE context.out.String(hl.host.name)
				END;
				context.out.Ln;
				hl := hl.next
			END
		ELSE
			context.out.String("Host '"); context.out.String(host); context.out.String("' not found."); context.out.Ln
		END
	UNTIL (context.arg.res # Streams.Ok);
END Install;


END AdPlugin.


AdPlugin.Install ~
System.FreeDownTo TCP ~

WebHTTPServerTools.Start \r:httproot \l:HTTP.Log ~
WebHTTPServerTools.Stop

WebHTTPServerTools.ListHosts

System.Free AdPlugin ~

Restart: System.DoCommands
	WebHTTPServerTools.Stop ~
	System.FreeDownTo TCP ~
	System.Free AdPlugin ~

	WebHTTPServerTools.Start \r:httproot \l:HTTP.Log ~
	AdPlugin.Install ~
~

AdPlugin.TMT