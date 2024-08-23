unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StateMachine, StdCtrls;

type
  TForm1 = class(TForm)
    btn1: TButton;
    btn2: TButton;
    btn3: TButton;
    btn4: TButton;
    mmo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TTest = class(TNcSysFiberStateMachine)
  protected
    function Execute: TFunc<Boolean>; override;
    procedure Stop; override;
    procedure Pause; override;
    procedure Resume; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

var
  Form1: TForm1;
  A: TTest;

implementation
uses
  CodeSiteLogging;

{$R *.dfm}

procedure TForm1.btn1Click(Sender: TObject);
begin
  CodeSite.Send('Execute');
  A.SetEvent(evExecute);
end;

procedure TForm1.btn2Click(Sender: TObject);
begin
  A.SetEvent(evStop);
end;

procedure TForm1.btn3Click(Sender: TObject);
begin
  A.SetEvent(evPause);
end;

procedure TForm1.btn4Click(Sender: TObject);
begin
  A.SetEvent(evResume);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  A := TTest.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(A);
end;

{ TTest }

procedure TTest.AfterConstruction;
begin
  inherited;

end;

procedure TTest.BeforeDestruction;
begin
  inherited;

end;

constructor TTest.Create;
begin
  inherited;

end;

destructor TTest.Destroy;
begin

  inherited;
end;

function TTest.Execute: TFunc<Boolean>;
var
  I: Integer;
begin
  TThread.Synchronize(nil,
    procedure
    begin

      while I < 100 do
      begin
        Form1.mmo1.Lines.Add(IntToStr(I));
        Sleep(100);
        Application.ProcessMessages;
        Inc(I);
      end;


    end
   );




end;

procedure TTest.Pause;
begin
  inherited;

end;

procedure TTest.Resume;
begin
  inherited;

end;

procedure TTest.Stop;
begin
  inherited;

end;

end.
