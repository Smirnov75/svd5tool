program RolandSVD5Tool;
{$mode Delphi}
uses DOS;

type	svdHeaderRecordT = packed record
				id:	packed array [0..3] of char;
				sign:	UInt32;
				offset:	UInt32;
				length:	UInt32;
			end;

	svdHeaderT = packed record
				headerLength: UInt16;
				headerId:     UInt32;
				emptyData: packed array [0..4] of UInt16;
			end;

	svdRecordInfo = packed record
				recordCount:	UInt32;
				recordLength:	UInt32;
				infoLength:	UInt32;
				emptydata:	UInt32;
			end;

Procedure HaltMessage(msg: String);
begin
	WriteLn(msg);
	halt;
end;

Function PtrOffset(basePtr: Pointer; offset: PtrUInt): Pointer;
begin
	PtrOffset := Pointer(PtrUInt(basePtr) + offset);
end;

function CalculateCRC16(Data: Pointer; dataLength: UInt16): string;
var
	CRC: UInt16;
	i, j, startPos: UInt32;
	ByteData: PByte;
const
	HexChars: array[0..15] of Char = '0123456789ABCDEF';

begin
	CRC := $FFFF;
	ByteData := PByte(Data);
	if dataLength > 15 then startPos := 16 else startPos := 0;
	ByteData := PtrOffset(ByteData, startPos);
	for i := startPos to dataLength - 1 do
	begin
		CRC := CRC xor (ByteData^ shl 8);
		Inc(ByteData);
		for j := 0 to 7 do if (CRC and $8000) <> 0 then CRC := (CRC shl 1) xor $1021 else CRC := CRC shl 1;
	end;
	CRC := CRC and $FFFF;
	Result :=  HexChars[(CRC shr 12) and $F] + HexChars[(CRC shr 8) and $F] + HexChars[(CRC shr 4) and $F] + HexChars[CRC and $F];
end;

Procedure ExtractBackup(filename: string);
type patchNameType = packed array [0..15] of Char;
var
	fl, flo, floh: file;
	cpt, flpt: pointer;
	header:    ^svdHeaderT;
	headerRec: ^svdHeaderRecordT;
	recInfo:   ^svdRecordInfo;
	patchName: ^patchNameType;
	i, r, c, recNum, lastChar: UInt16;
	st, id, stName: string;
	size: UInt32;
	addName: Boolean;
	cChar: Char;

begin
	AssignFile(fl, filename);
	{$I-}
	Reset(fl, 1);
	{$I+}
	if IOResult <> 0 then HaltMessage(' Error! Can''t open ' + filename);

	size := FileSize(fl);
	GetMem(flpt, size);
	BlockRead(fl, flpt^, size);
	Close(fl);
	stName := '';
	header := flpt;
	recNum := ((header^.headerLength-14) div sizeOf(svdHeaderRecordT));
	if header^.headerId <> 893670995 then HaltMessage(' Wrong SVD5 header');

	headerRec := PtrOffset(flpt, sizeOf(svdHeaderT));

	WriteLn('  Unpacking '+ filename +' ...');
	WriteLn('---------------------------------------------');
	AssignFile(floh, 'DAT.rdt');
	Rewrite(floh, 1);
	BlockWrite(floh, header^, sizeOf(svdHeaderT) + recNum*sizeOf(svdHeaderRecordT));

	for i:=1 to recNum do
	begin
		headerRec := PtrOffset(flpt, sizeOf(svdHeaderT) + (i-1)*sizeOf(svdHeaderRecordT));
		recInfo := PtrOffset(flpt, headerRec^.offset);
		cpt := PtrOffset(recInfo, recInfo^.infoLength);
		BlockWrite(floh, recInfo^, recInfo^.infoLength);
		id := headerRec^.id[0]+headerRec^.id[1]+headerRec^.id[2];
		Write('  '+id+' : '); Write(recInfo^.recordCount); Write(' x '); Write(recInfo^.recordLength); WriteLn;

		addName := ((id='PAT') or (id='PRF') or (id='RHI') or (id='RHY'));
		stName := '';
		for r:=1 to recInfo^.recordCount do
		begin
			if addName then
			begin
				if id = 'PAT' then patchName := PtrOffset(cpt, 16) else patchName := cpt;
				stName := ' - ';
				lastChar := 0;
				for c:=0 to 15 do
				begin
					cChar := patchName^[c];
					if (Ord(cChar) < 33) or (Ord(cChar) > 122) then cChar := ' ';
					if (cChar in ['\', ':', '*', '?', '"', '<', '>', '|', '/']) then cChar := '_';
					stName := stName + cChar;
					if Ord(cChar) <> 32 then lastChar := c;
				end;
				stName := copy(stName, 1, lastChar+4);
			end;
			Str(r, st);
			st:='00'+ st;
			AssignFile(flo, id+'.'+copy(st, Length(st)-2, 3)+stName+' ['+ CalculateCRC16(cpt, recInfo^.recordLength)+'].rdt');
			Rewrite(flo, 1);
			BlockWrite(flo, cpt^, recInfo^.recordLength);
			close(flo);
			cpt := PtrOffset(cpt, recInfo^.recordLength);
		end;
		headerRec := PtrOffset(headerRec, sizeOf(svdHeaderRecordT));
	end;
	close(floh);
	WriteLn('---------------------------------------------');
end;

Procedure PackBackup(filename: string);
var
	fl, flo: file;
	cpt, flpt: pointer;
	header:    ^svdHeaderT;
	headerRec: ^svdHeaderRecordT;
	recInfo:   ^svdRecordInfo;
	srRec: SearchRec;
	i, r, recNum: UInt16;
	st, id: string;
	size: UInt32;
begin
	AssignFile(fl, 'DAT.rdt');
	{$I-}
	Reset(fl, 1);
	{$I+}
	if IOResult <> 0 then HaltMessage(' Error! Can''t open DAT.rdt');

	size := FileSize(fl);
	GetMem(flpt, size);
	BlockRead(fl, flpt^, size);
	Close(fl);
	WriteLn('  Packing '+ filename +' ...');
	WriteLn('---------------------------------------------');
	AssignFile(flo, filename);
	Rewrite(flo, 1);
	header := flpt;
	recNum := ((header^.headerLength-14) div sizeOf(svdHeaderRecordT));

	BlockWrite(flo, header^, sizeOf(svdHeaderT) + recNum*sizeOf(svdHeaderRecordT));
	for i:=1 to recNum do
	begin
		headerRec := PtrOffset(header, sizeOf(svdHeaderT) + (i-1)*sizeOf(svdHeaderRecordT));
		recInfo := PtrOffset(header, sizeOf(svdHeaderT) + recNum*sizeOf(svdHeaderRecordT) + (i-1)*sizeOf(svdRecordInfo));
		BlockWrite(flo, recInfo^, recInfo^.infoLength);
		id := headerRec^.id[0]+headerRec^.id[1]+headerRec^.id[2];
		Write('  '+id+' : '); Write(recInfo^.recordCount); Write(' x '); Write(recInfo^.recordLength); WriteLn;
		GetMem(cpt, recInfo^.recordLength);
		for r:=1 to recInfo^.recordCount do
		begin
			Str(r, st);
			st:='00'+ st;
			st:= id+'.'+copy(st, Length(st)-2, 3);
			FindFirst(st+'*.rdt', 0, srRec);
			if DosError = 0 then st := srRec.Name else st := st+'.rdt';
			FindClose(srRec);
			AssignFile(fl, st);
			{$I-}
			Reset(fl, 1);
			{$I+}
			if IOResult <> 0 then
			begin
				Rewrite(flo, 1);
				Close(flo);
				HaltMessage(' Error! Can''t open ' + st);
			end;
			BlockRead(fl, cpt^, recInfo^.recordLength);
			Close(fl);
			BlockWrite(flo, cpt^, recInfo^.recordLength);
		end;
		FreeMem(cpt, recInfo^.recordLength);
	end;
	FreeMem(flpt, size);
	Close(flo);
	WriteLn('---------------------------------------------');
end;

begin
	WriteLn('---------------------------------------------');
	WriteLn(' Roland SVD5 tool (c) Max Smirnov.2025 v0.97');
	WriteLn('---------------------------------------------');
	if paramCount()<2 Then HaltMessage(' USAGE: svd5tool <unpack|pack> <file.SVD>');
	if (paramStr(1) = 'unpack') Then ExtractBackup(paramStr(2));
	if (paramStr(1) = 'pack') Then PackBackup(paramStr(2));
end.
