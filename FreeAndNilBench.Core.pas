UNIT FreeAndNilBench.Core;

{=============================================================================================================
   2026.10.11
   www.GabrielMoraru.com
--------------------------------------------------------------------------------------------------------------
   Measures four ways to free an object reference:
     1. FreeAndNil(X)                          - the RTL's own (System.SysUtils)
     2. if Assigned(X) then FreeAndNil(X)      - the explicit nil test in front of it
     3. FreeAndNilBetter(X)                    - a better FreeAndNil: tests nil itself, then calls Destroy
     4. X.Free                                - frees, but leaves X dangling (no nil)
   over three data patterns: all slots nil, all slots objects, 50% mix.

   Method
     - 4096 slots in a global static array (16 KB on Win32, 32 KB on Win64 for the array alone; the objects it points to come on top).
     - One pass = fill the slots (NOT timed), then the timed loop that frees every slot.
     - One run = PassesPerRun passes. Each (way, pattern) gets one warm-up run, then RunCount runs; the fastest run is reported.
     - The 50% mix uses Random(2) with the same RandSeed at the start of every run, so all ways see the same sequence;
       every pass draws a new pattern, so the branch predictor cannot learn it.
     - The objects are plain TObject: the cheapest destructor there is, so the case most favourable to the extra "if".

   Before timing, a self-check runs every way over every pattern with a class that counts its destructor calls.

   Uses RTL units only: it compiles in a stock Delphi.
=============================================================================================================}

{$O+,R-,Q-}

INTERFACE

function RunFreeAndNilBenchmark: string;

IMPLEMENTATION

uses
  Winapi.Windows, System.SysUtils, System.Diagnostics, System.Win.Registry;

CONST
  SlotCount    = 4096;
  PassesPerRun = 1000;                       // 1000 * 4096 = 4,096,000 calls per run
  RunCount     = 5;
  MixSeed      = 20261011;

TYPE
  TPattern = (patNil, patObjects, patMix);

  TFreeAllProc = procedure;

  TWay = record
    Name   : string;
    FreeAll: TFreeAllProc;
    SetsNil: Boolean;      // FALSE for a way that leaves the slots dangling on purpose: the self-check then skips its nil test
  end;

  TCountedObject = class(TObject)
  public
    destructor Destroy; override;
  end;

CONST
  PatternName: array[TPattern] of string = ('nil', 'objects', '50% mix');

// Unit level on purpose: a static array is timed without pointer indirection. Not thread-safe.
VAR
  Slots       : array[0..SlotCount-1] of TObject;
  DestroyCount: Integer;



{-------------------------------------------------------------------------------------------------------------
   A better FreeAndNil: it tests nil itself, so the caller needs no "if Assigned", and calls Destroy instead of Free.
   An inline routine must be defined above its callers, or the compiler does not expand it.
-------------------------------------------------------------------------------------------------------------}
procedure FreeAndNilBetter(const [ref] Obj: TObject); inline;
var
  Temp: TObject;
begin
  if Obj = nil then Exit;

  Temp := Obj;
  TObject(Pointer(@Obj)^) := nil;
  Temp.Destroy;
end;


destructor TCountedObject.Destroy;
begin
  Inc(DestroyCount);
  inherited;
end;



{-------------------------------------------------------------------------------------------------------------
   THE FOUR WAYS - each one is the complete timed loop
-------------------------------------------------------------------------------------------------------------}
procedure FreeAll_RtlFreeAndNil;
var
  i: Integer;
begin
  for i := 0 to High(Slots) do
    FreeAndNil(Slots[i]);
end;


procedure FreeAll_AssignedFreeAndNil;
var
  i: Integer;
begin
  for i := 0 to High(Slots) do
    if Assigned(Slots[i]) then FreeAndNil(Slots[i]);
end;


procedure FreeAll_BetterFreeAndNil;
var
  i: Integer;
begin
  for i := 0 to High(Slots) do
    FreeAndNilBetter(Slots[i]);
end;


{ Leaves every freed slot dangling on purpose. Only FillSlots and ForgetSlots touch the slots afterwards, and both overwrite them without reading them. }
procedure FreeAll_Free;
var
  i: Integer;
begin
  for i := 0 to High(Slots) do
    Slots[i].Free;
end;



function MakeWay(const Name: string; FreeAll: TFreeAllProc; SetsNil: Boolean): TWay;
begin
  Result.Name    := Name;
  Result.FreeAll := FreeAll;
  Result.SetsNil := SetsNil;
end;


{ The first way is the reference row of the difference table. }
function GetWays: TArray<TWay>;
begin
  Result := [MakeWay('RTL FreeAndNil',           FreeAll_RtlFreeAndNil,      TRUE),
             MakeWay('if Assigned + FreeAndNil', FreeAll_AssignedFreeAndNil, TRUE),
             MakeWay('Better FreeAndNil',        FreeAll_BetterFreeAndNil,   TRUE),
             MakeWay('X.Free (no nil)',          FreeAll_Free,               FALSE)];
end;



{-------------------------------------------------------------------------------------------------------------
   FILL
-------------------------------------------------------------------------------------------------------------}
{ Fills every slot for the pattern, with instances of ObjClass. Returns the number of non-nil slots. }
function FillSlots(Pattern: TPattern; ObjClass: TClass): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Slots) do
    begin
      case Pattern of
        patNil    : Slots[i] := nil;
        patObjects: Slots[i] := ObjClass.Create;
        patMix    : if Random(2) = 0
                    then Slots[i] := nil
                    else Slots[i] := ObjClass.Create;
      end;
      if Slots[i] <> nil then Inc(Result);
    end;
end;


{ Forgets every slot without freeing it or reading it. Clears the dangling references that "X.Free (no nil)" leaves behind. }
procedure ForgetSlots;
var
  i: Integer;
begin
  for i := 0 to High(Slots) do
    Slots[i] := nil;
end;



{-------------------------------------------------------------------------------------------------------------
   SELF-CHECK
   Returns '' when every way frees every object exactly once and, if the way sets nil (SetsNil), leaves every slot nil.
-------------------------------------------------------------------------------------------------------------}
function SelfCheck(const Ways: TArray<TWay>): string;
var
  Way                         : TWay;
  Pattern                     : TPattern;
  i, Filled, NotNil, Destroyed: Integer;
begin
  Result := '';
  for Way in Ways do
    for Pattern := Low(TPattern) to High(TPattern) do
      begin
        RandSeed := MixSeed;
        Filled := FillSlots(Pattern, TCountedObject);
        DestroyCount := 0;

        Way.FreeAll;

        Destroyed := DestroyCount;
        if Way.SetsNil then
          begin
            NotNil := 0;
            for i := 0 to High(Slots) do
              if Slots[i] <> nil then Inc(NotNil);
            if NotNil <> 0 then Result := Result + Format('SELF-CHECK FAILED: %s, %s: %d slot(s) not nil after freeing', [Way.Name, PatternName[Pattern], NotNil]) + sLineBreak;
          end;
        if Destroyed <> Filled then Result := Result + Format('SELF-CHECK FAILED: %s, %s: %d destructor call(s), expected %d', [Way.Name, PatternName[Pattern], Destroyed, Filled]) + sLineBreak;

        ForgetSlots;   // A way may leave dangling references behind (on purpose or by a bug)
      end;
end;



{-------------------------------------------------------------------------------------------------------------
   MEASURE
-------------------------------------------------------------------------------------------------------------}
{ One run: PassesPerRun passes. Returns the ticks spent in the freeing loop only. }
function TimeOneRun(const Way: TWay; Pattern: TPattern): Int64;
var
  Pass : Integer;
  Start: Int64;
begin
  Result := 0;
  RandSeed := MixSeed;
  for Pass := 1 to PassesPerRun do
    begin
      FillSlots(Pattern, TObject);           // Not timed. Overwrites the dangling references of the previous pass without reading them.

      Start := TStopwatch.GetTimeStamp;
      Way.FreeAll;
      Result := Result + (TStopwatch.GetTimeStamp - Start);
    end;

  ForgetSlots;                               // Not timed. No dangling reference survives the run.
end;


{ One warm-up run, then RunCount runs. Returns the fastest run, in nanoseconds per call. }
function Measure(const Way: TWay; Pattern: TPattern): Double;
var
  Run        : Integer;
  Ticks, Best: Int64;
begin
  TimeOneRun(Way, Pattern);                  // Warm-up, not reported

  Best := High(Int64);
  for Run := 1 to RunCount do
    begin
      Ticks := TimeOneRun(Way, Pattern);
      if Ticks < Best then Best := Ticks;
    end;

  Result := Best * 1E9 / TStopwatch.Frequency / (Int64(PassesPerRun) * SlotCount);
end;



{-------------------------------------------------------------------------------------------------------------
   REPORT
-------------------------------------------------------------------------------------------------------------}
function GetCpuName: string;
var
  Reg: TRegistry;
begin
  Result := 'unknown';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('HARDWARE\DESCRIPTION\System\CentralProcessor\0')
    and Reg.ValueExists('ProcessorNameString') then
      Result := Trim(Reg.ReadString('ProcessorNameString'));
  finally
    FreeAndNil(Reg);
  end;
end;


function PlatformName: string;
begin
  {$IFDEF WIN64}
  Result := 'Win64';
  {$ELSE}
  Result := 'Win32';
  {$ENDIF}
end;


{ Formats a difference with an explicit sign, so +0.00 and -0.00 never look alike. }
function SignedNs(Value: Double): string;
begin
  Result := FormatFloat('0.00', Abs(Value), TFormatSettings.Invariant);
  if Value < 0
  then Result := '-' + Result
  else Result := '+' + Result;
end;


{ Difference in ns plus its percent of Reference, for example "-0.77 (-66%)". }
function SignedNsAndPercent(Value, Reference: Double): string;
var
  Percent: Integer;
begin
  if Reference > 0
  then Percent := Round(Value * 100 / Reference)
  else Percent := 0;
  if Percent < 0
  then Result := SignedNs(Value) + ' (' + IntToStr(Percent) + '%)'
  else Result := SignedNs(Value) + ' (+' + IntToStr(Percent) + '%)';
end;


function RunFreeAndNilBenchmark: string;
const
  RowLabelWidth = 26;
  ColWidth      = 10;
  DiffColWidth  = 16;
var
  Ways        : TArray<TWay>;
  Ns          : array of array[TPattern] of Double;
  Failed, Line: string;
  w           : Integer;
  Pattern     : TPattern;
  SB          : TStringBuilder;

  function HeaderRow(Width: Integer): string;
  var
    P: TPattern;
  begin
    Result := StringOfChar(' ', RowLabelWidth);
    for P := Low(TPattern) to High(TPattern) do
      Result := Result + PatternName[P].PadLeft(Width);
  end;

begin
  TStopwatch.StartNew;   // Sets TStopwatch.Frequency: GetTimeStamp and Frequency do not initialize the class themselves; only Create and StartNew do
  Ways := GetWays;

  SB := TStringBuilder.Create;
  try
    SB.AppendLine('FreeAndNil benchmark - ns per call, lower is better');
    SB.AppendLine(Format('CompilerVersion: %s   RTLVersion: %s', [FormatFloat('0.0', CompilerVersion, TFormatSettings.Invariant), FormatFloat('0.0', RTLVersion, TFormatSettings.Invariant)]));
    SB.AppendLine('Platform: ' + PlatformName);
    {$IFDEF DEBUG}
    SB.AppendLine('Build: Debug');
    {$ELSE}
    SB.AppendLine('Build: Release');
    {$ENDIF}
    SB.AppendLine('CPU: ' + GetCpuName);
    SB.AppendLine('Date: ' + FormatDateTime('yyyy-mm-dd hh:nn', Now, TFormatSettings.Invariant));
    SB.AppendLine(Format('Slots: %d   Passes per run: %d   Calls per run: %d   Runs: %d (+1 warm-up)', [SlotCount, PassesPerRun, PassesPerRun * SlotCount, RunCount]));

    Failed := SelfCheck(Ways);
    if Failed <> '' then
      begin
        SB.Append(Failed);
        SB.AppendLine('Benchmark not run.');
        EXIT(SB.ToString);
      end;
    SB.AppendLine('Self-check: OK');
    SB.AppendLine;

    SetLength(Ns, Length(Ways));
    for Pattern := Low(TPattern) to High(TPattern) do
      for w := 0 to High(Ways) do
        Ns[w][Pattern] := Measure(Ways[w], Pattern);

    SB.AppendLine('Time per call (ns)');
    SB.AppendLine(HeaderRow(ColWidth));
    for w := 0 to High(Ways) do
      begin
        Line := Ways[w].Name.PadRight(RowLabelWidth);
        for Pattern := Low(TPattern) to High(TPattern) do
          Line := Line + FormatFloat('0.00', Ns[w][Pattern], TFormatSettings.Invariant).PadLeft(ColWidth);
        SB.AppendLine(Line);
      end;
    SB.AppendLine;

    SB.AppendLine('Difference to "RTL FreeAndNil" (ns per call, and percent of the RTL FreeAndNil time)');
    SB.AppendLine(HeaderRow(DiffColWidth));
    for w := 0 to High(Ways) do
      begin
        Line := Ways[w].Name.PadRight(RowLabelWidth);
        for Pattern := Low(TPattern) to High(TPattern) do
          Line := Line + SignedNsAndPercent(Ns[w][Pattern] - Ns[0][Pattern], Ns[0][Pattern]).PadLeft(DiffColWidth);
        SB.AppendLine(Line);
      end;
    SB.AppendLine;

    SB.AppendLine(Format('Objects: plain TObject. Timed part: only the freeing loop. Reported: the fastest of %d runs.', [RunCount]));
    Result := SB.ToString;
  finally
    FreeAndNil(SB);
  end;
end;


end.
