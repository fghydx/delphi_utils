unit GLMethodHook;

interface

const
  DirecotrCount = 214;
type
  PMethodDirector = ^TMethodDirector;
  TMethodDirector = packed record
    PopEcx: Byte;
    Jmp: Byte;
    JmpOffset: Integer;
    Call: Byte;
    CallOffset: Integer;
    case Integer of
      0: (Next: PMethodDirector);
      1: (Method: TMethod);
  end;
  
  PDirectorBlock = ^TDirectorBlock;
  TDirectorBlock = packed record
    Next: PDirectorBlock;
    Directors: array[0..DirecotrCount] of TMethodDirector;
  end;

function AllocMethodDirector(const Method: TMethod;
  Proc: Pointer): Pointer; overload;
procedure FreeMethodDirector(Director: Pointer);
function AllocMethodDirector(Instance: TObject; MethAddr,
  Proc: Pointer): Pointer; overload;

function SetMethodDirector(var Director:TMethodDirector;
  const Method: TMethod; Proc: Pointer): Pointer; overload;
function SetMethodDirector(var Director: TMethodDirector; Instance: TObject;
  MethAddr, Proc: Pointer): Pointer; overload;

procedure OneParamStdCall(Param: Integer); stdcall;
procedure TwoParamStdCall(P1, P2: Integer); stdcall;
procedure ThreeParamStdCall(P1, P2, P3: Integer); stdcall;
procedure FourParamStdCall(P1, P2, P3, P4: Integer); stdcall;
procedure FiveParamStdCall(P1, P2, P3, P4, P5: Integer); stdcall;
procedure SixParamStdCall(P1, P2, P3, P4, P5, P6: Integer); stdcall;

implementation

type
  DWORD = Cardinal;

const
  MEM_COMMIT = $1000;
  PAGE_EXECUTE_READWRITE = $40;
  
function VirtualAlloc(addr: Pointer; size, alloc_type,
  protect: DWORD): Pointer; stdcall; external 'kernel32' name 'VirtualAlloc';
function VirtualProtect(addr: Pointer; size, new_protect: DWORD;
  var old_protect: DWORD): LongBool; stdcall;
  external 'kernel32' name 'VirtualProtect';
  
var
  DirectorFreeList: PMethodDirector;
  DirectorBlockList: PDirectorBlock;

procedure OneParamStdCall(Param: Integer); stdcall;
asm
  MOV EDX, Param
  MOV EAX,[ECX].TMethod.Data
  CALL [ECX].TMethod.Code
end;

procedure TwoParamStdCall(P1, P2: Integer); stdcall;
asm
  PUSH EBX
  MOV EBX, ECX
  MOV EDX, P1
  MOV ECX, P2
  MOV EAX,[EBX].TMethod.Data
  CALL [EBX].TMethod.Code
  POP EBX
end;

procedure ThreeParamStdCall(P1, P2, P3: Integer); stdcall;
asm
  PUSH EBX
  MOV EBX, ECX
  MOV EDX, P1
  MOV ECX, P2
  PUSH P3
  MOV EAX,[EBX].TMethod.Data
  CALL [EBX].TMethod.Code
  POP EBX
end;

procedure FourParamStdCall(P1, P2, P3, P4: Integer); stdcall;
asm
  PUSH EBX
  MOV EBX, ECX
  MOV EDX, P1
  MOV ECX, P2
  PUSH P3
  PUSH P4
  MOV EAX,[EBX].TMethod.Data
  CALL [EBX].TMethod.Code
  POP EBX
end;

procedure FiveParamStdCall(P1, P2, P3, P4, P5: Integer); stdcall;
asm
  PUSH EBX
  MOV EBX, ECX
  MOV EDX, P1
  MOV ECX, P2
  PUSH P3
  PUSH P4
  PUSH P5
  MOV EAX,[EBX].TMethod.Data
  CALL [EBX].TMethod.Code
  POP EBX
end;

procedure SixParamStdCall(P1, P2, P3, P4, P5, P6: Integer); stdcall;
asm
  PUSH EBX
  MOV EBX, ECX
  MOV EDX, P1
  MOV ECX, P2
  PUSH P3
  PUSH P4
  PUSH P5
  PUSH P6
  MOV EAX,[EBX].TMethod.Data
  CALL [EBX].TMethod.Code
  POP EBX
end;

function AllocMethodDirector(Instance: TObject;
  MethAddr, Proc: Pointer): Pointer;
const
  PageSize = 4096;
var
  Director: PMethodDirector;
  Block: PDirectorBlock;
begin
  if DirectorFreeList = nil then
  begin
    Block := VirtualAlloc(nil, PageSize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    Block^.Next := DirectorBlockList;
    Director := @Block^.Directors;
    repeat
      Director^.PopEcx := $59;
      Director^.Jmp := $e9;
      Director^.Call := $e8;
      Director^.CallOffset := LongInt(@Director^.PopEcx) - LongInt(@Director^.Method);
      Director^.Next := DirectorFreeList;
      DirectorFreeList := Director;
      Inc(Longint(Director), SizeOf(TMethodDirector));
    until Longint(Director) - Longint(Block) >= SizeOf(TDirectorBlock);
    DirectorBlockList := Block;
  end;
  Director := DirectorFreeList;
  DirectorFreeList := Director^.Next;
  Director^.JmpOffset := LongInt(Proc) - LongInt(@Director^.Call);
  Director^.Method.Code := MethAddr;
  Director^.Method.Data := Instance;
  Result := @Director^.Call;
end;

function AllocMethodDirector(const Method: TMethod; Proc: Pointer): Pointer;
begin
  Result := AllocMethodDirector(TObject(Method.Data), Method.Code, Proc);
end;

procedure FreeMethodDirector(Director: Pointer);
var
  dummy: TMethodDirector;
begin
  if Director <> nil then
  begin
    Dec(PAnsiChar(Director), LongInt(@dummy.Call) - LongInt(@dummy));
    PMethodDirector(Director)^.Next := DirectorFreeList;
    DirectorFreeList := Director;
  end;
end;

function SetMethodDirector(var Director: TMethodDirector; const Method: TMethod;
  Proc: Pointer): Pointer; overload;
begin
  Result := SetMethodDirector(Director, TObject(Method.Data), Method.Code, Proc);
end;

function SetMethodDirector(var Director: TMethodDirector; Instance: TObject;
  MethAddr, Proc: Pointer): Pointer; overload;
var
  old_prot: DWORD;
begin
  VirtualProtect(@Director, SizeOf(Director), PAGE_EXECUTE_READWRITE, old_prot);
  with Director do
  begin
    PopEcx := $59;
    Jmp := $e9;
    JmpOffset := Longint(Proc) - LongInt(@Call);
    Call := $e8;
    CallOffset := LongInt(@PopEcx) - LongInt(@Method);
    Method.Code := MethAddr;
    Method.Data := Instance;
    Result := @Call;
  end;
end;

end.
