unit StateMachine;

interface

uses
  Windows, Classes, SysUtils, SyncObjs;

type

  TNcSysState = (stIdle, stRunning, stPaused);

  TNcSysEvent = (evExecute, evStop, evPause, evResume);

  TNcSysFiberStateMachine = class;

  TNcSysStateMachineThread = class(TThread)
  private
    FStateMachine: TNcSysFiberStateMachine;
  public
    procedure Execute; override;
    constructor Create(AStateMachine: TNcSysFiberStateMachine);
    destructor Destroy; override;
  end;

  TNcSysFiberStateMachine = class
  private
    FState: TNcSysState;
    FEvent: TNcSysEvent;
    FEventLock: TCriticalSection;
    FEventChanged: Boolean;
    FWaitFunc: TFunc<Boolean>;
    FThread: TNcSysStateMachineThread;
    FStopProcess: Boolean;
    { State Fibers }
    FMainFiber: Cardinal;
    FIdleFiber: Pointer;
    FRunningFiber: Pointer;
    FPausedFiber: Pointer;
    procedure InitailizeFibers;
    procedure FinalizeFibers;
    procedure SwitchToState(AState: TNcSysState);
    { Event Handle }
    procedure HandleEvent;
    procedure IdleHandleEvent;
    procedure RunningHandleEvent;
    procedure PausedHandleEvent;
    { State Process }
    procedure ThreadProc;
    procedure ProcessIdle;
    procedure ProcessRunning;
    procedure ProcessPaused;
  protected
    function Execute: TFunc<Boolean>; virtual;
    procedure Stop; virtual; abstract;
    procedure Pause; virtual; abstract;
    procedure Resume; virtual; abstract;
  public
    procedure SetEvent(AEvent: TNcSysEvent);
    procedure WaitFor(AFunc: TFunc<Boolean>);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

implementation

uses
  TypInfo, CodeSiteLogging;

/// <summary>
/// 将一个纤程转化为线程
/// </summary>
/// <returns></returns>
function ConvertFiberToThread():BOOL;stdcall;external kernel32;

procedure Log(AStr: string);
begin

end;

function StateName(AState: TNcSysState): string;
begin
  Result := GetEnumName(TypeInfo(TNcSysState), Ord(AState));
end;

function EventName(AEvent: TNcSysEvent): string;
begin
  Result := GetEnumName(TypeInfo(TNcSysEvent), Ord(AEvent));
end;

procedure LogUnexpectedEvent(AState: TNcSysState; AEvent: TNcSysEvent);
begin
  Log('Unexpected Event [ State: ' + StateName(AState) +
                        ' Event: ' + EventName(AEvent) + ']');
end;

{ TNcSysStateMachineThread }

constructor TNcSysStateMachineThread.Create(
  AStateMachine: TNcSysFiberStateMachine);
begin
  inherited Create(True);
  FStateMachine := AStateMachine;
end;

destructor TNcSysStateMachineThread.Destroy;
begin
  FStateMachine := nil;
  inherited;
end;

procedure TNcSysStateMachineThread.Execute;
begin
  inherited;
  FStateMachine.ThreadProc;
end;

{ TNcSysFiberStateMachine }

procedure IdleProc(P: Pointer); stdcall;
begin
  TNcSysFiberStateMachine(P).ProcessIdle;
end;

procedure RunningProc(P: Pointer); stdcall;
begin
  TNcSysFiberStateMachine(P).ProcessRunning;
end;

procedure PausedProc(P: Pointer); stdcall;
begin
  TNcSysFiberStateMachine(P).ProcessPaused;
end;

procedure TNcSysFiberStateMachine.ThreadProc;
begin
  FMainFiber := ConvertThreadToFiber(nil);
  if FMainFiber = 0 then
    RaiseLastOSError;

  InitailizeFibers;
  try
    try
      SwitchToState(stIdle);
    except
      on E: Exception do
        CodeSite.Send(E.Message);
    end;
  finally
    FinalizeFibers;
    ConvertFiberToThread;
  end;
end;

procedure TNcSysFiberStateMachine.ProcessIdle;
begin
  while True do
  begin
    Sleep(1);
    HandleEvent;
  end;
end;

procedure TNcSysFiberStateMachine.ProcessRunning;
begin
  while True do
  begin
    if Assigned(FWaitFunc) then
    begin
      if FWaitFunc = True then
      begin
        FWaitFunc := nil;
        SwitchToState(stIdle);
      end;
    end
    else
      SwitchToState(stIdle);

    Sleep(1);
    HandleEvent;
  end;
end;

procedure TNcSysFiberStateMachine.ProcessPaused;
begin
  while True do
  begin
    Sleep(1);
    HandleEvent;
  end;
end;

procedure TNcSysFiberStateMachine.InitailizeFibers;
begin
  FIdleFiber := CreateFiber(0, @IdleProc, Self);
  FRunningFiber := CreateFiber(0, @RunningProc, Self);
  FPausedFiber := CreateFiber(0, @PausedProc, Self);

  if (FIdleFiber = nil) or (FRunningFiber = nil) or (FPausedFiber = nil) then
    raise Exception.Create('Error InitailizeFibers');
end;

procedure TNcSysFiberStateMachine.FinalizeFibers;
begin
  DeleteFiber(FPausedFiber);
  DeleteFiber(FRunningFiber);
  DeleteFiber(FIdleFiber);
end;

procedure TNcSysFiberStateMachine.SwitchToState(AState: TNcSysState);
begin
  FState := AState;
  case FState of
    stIdle:    SwitchToFiber(FIdleFiber);
    stRunning: SwitchToFiber(FRunningFiber);
    stPaused:  SwitchToFiber(FPausedFiber);
  end;
end;

procedure TNcSysFiberStateMachine.IdleHandleEvent;
begin
  if FEvent = evExecute then
  begin
    FWaitFunc := Execute();
    SwitchToState(stRunning);
  end
  else
    LogUnexpectedEvent(FState, FEvent);
end;

procedure TNcSysFiberStateMachine.RunningHandleEvent;
begin
  case FEvent of
    evStop:
      begin
        Stop;
        SwitchToState(stIdle);
      end;
    evPause:
      begin
        Pause;
        SwitchToState(stPaused);
      end;
  else
    LogUnexpectedEvent(FState, FEvent);
  end;
end;

procedure TNcSysFiberStateMachine.PausedHandleEvent;
begin
  case FEvent of
    evResume:
      begin
        Resume;
        SwitchToState(stRunning);
      end;
    evStop:
      begin
        Stop;
        SwitchToState(stIdle);
      end;
  else
    LogUnexpectedEvent(FState, FEvent);
  end;
end;

procedure TNcSysFiberStateMachine.HandleEvent;
begin
  FEventLock.Enter;

  try

    if FStopProcess then
      SwitchToFiber(Pointer(FMainFiber));

    if not FEventChanged then Exit;

    try
      case FState of
        stIdle:    IdleHandleEvent;
        stRunning: RunningHandleEvent;
        stPaused:  PausedHandleEvent;
      end;

      FEventChanged := False;

    except
      on E: Exception do
      begin
        Log(E.Message);
        FEventChanged := False;
        {$IFDEF DEBUG}
          raise;
        {$ELSE}
          SwitchToState(stIdle);
        {$ENDIF}
      end;
    end;
  finally
    FEventLock.Leave;
  end;
end;

function TNcSysFiberStateMachine.Execute: TFunc<Boolean>;
begin
  Result := nil;
end;

procedure TNcSysFiberStateMachine.SetEvent(AEvent: TNcSysEvent);
begin
  FEventLock.Enter;
  try
    FEvent := AEvent;
    FEventChanged := True;
  finally
    FEventLock.Leave;
  end;
end;

procedure TNcSysFiberStateMachine.WaitFor(AFunc: TFunc<Boolean>);
begin
  FWaitFunc := AFunc;
  SwitchToState(stRunning);
end;

constructor TNcSysFiberStateMachine.Create;
begin
  FState := stIdle;
  FEventLock := TCriticalSection.Create;
  FEventChanged := False;
  FWaitFunc := nil;
  FStopProcess := False;
end;

destructor TNcSysFiberStateMachine.Destroy;
begin
  FWaitFunc := nil;
  FreeAndNil(FThread);
  FreeAndNil(FEventLock);
  inherited;
end;

procedure TNcSysFiberStateMachine.AfterConstruction;
begin
  inherited;
  FThread := TNcSysStateMachineThread.Create(Self);
  FThread.Start;
end;

procedure TNcSysFiberStateMachine.BeforeDestruction;
begin
  inherited;
  FStopProcess := True;
  FThread.Terminate;
  Sleep(1);
  FThread.WaitFor;
end;

end.
