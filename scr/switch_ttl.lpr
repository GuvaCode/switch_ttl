program switch_ttl;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  Process;

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    ttl:String;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure WriteAbout;  virtual;
    procedure SwitchTTL(Val:String); virtual;
    function GetDefaultTTL:String; virtual;
    function IsRoot:Boolean; virtual;
  end;

 const
 about='Switch Time To Live 0.1';
 by='By The GuvaCode: https://github.com/GuvaCode/switch_ttl';
 cpr='(C) 2016-2017 GuvaCode';
 line='          ';
 noroot='You cannot change the ttl. Using the sudo command to get root (superuser) privileges.';
 err='Usage: --help or -h for help.';
 noparam='No parameters found.';


function PadL(cVal: string; nWide: integer): string;
var
  i1, nStart: integer;
begin
  if length(cVal) < nWide then
  begin
    nStart:=length(cVal);
    for i1:=nStart to nWide-1 do
      cVal:=' '+cVal;
  end;
  PadL:=cVal;
end;

{ TMyApplication }
procedure TMyApplication.DoRun;
var
  ErrorMsg: String;

begin
  // quick check parameters
  ErrorMsg:=CheckOptions('hbymdc', 'help beeline yota mts default');
  if (ErrorMsg<>'') then begin
  writeln(ErrorMsg+'. '+err);
  Terminate;
  Exit;
  end;

  if paramstr(1)='' then begin
   writeln(noparam+' '+err);
  Terminate;
  Exit;

  end;
  {if (ErrorMsg='') then begin
  writeln(ErrorMsg+'. '+noparam);
  Terminate;
  Exit;
  end; }

 // parse parameters
  if HasOption('h', 'help') then begin
    WriteAbout;
    WriteHelp;
    Terminate;
    Exit;
  end;

   if HasOption('b','beeline') then ttl:='63';// Set ttl
   if HasOption('y','yota')    then ttl:='65';
   if HasOption('m','mts')     then ttl:='65';
   if HasOption('d')           then ttl:= GetDefaultTTL;
   if HasOption('c')           then ttl:= GetOptionValue('c'); // set custom ttl

   if not IsRoot then
   begin
    writeln(noroot);
    Terminate;
    Exit;
   end;

   { add your program here }
  SwitchTTL(ttl);
  // stop program loop
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  writeln('  --help           -h'+line+'Print this help screen');
  writeln('  --beeline        -b'+line+'Change ttl value for «Beeline» network');
  writeln('  --yota           -y'+line+'Change ttl value for «Yota» network');
  writeln('  --mts            -m'+line+'Change ttl value for «MTS» network');
  writeln('  --default        -d'+line+'Set default ttl');
  writeln('                   -c [value]'+'  '+'Set custom value');
  writeln;
end;

procedure TMyApplication.WriteAbout;
var len: integer;
begin
  len := length(about);
  writeln;
  writeln(PadL(about,len div 2+40));
  len := length(by);
  writeln(PadL(by,len div 2+40));
  len := length(cpr);
  writeln(PadL(cpr,len div 2+40));
   writeln;
end;

procedure TMyApplication.SwitchTTL(Val: String);
var Proc: TProcess;
begin
  Proc := TProcess.Create(nil);
  Proc.Options := [poWaitOnExit,poUsePipes];
  Proc.Executable := 'iptables';
  Proc.Parameters.Add('-t');
  Proc.Parameters.Add('mangle');
  Proc.Parameters.Add('-A');
  Proc.Parameters.Add('POSTROUTING');
  Proc.Parameters.Add('-j');
  Proc.Parameters.Add('TTL');
  Proc.Parameters.Add('--ttl-set');
  Proc.Parameters.Add(Val);
  Proc.Execute;
  Proc.free;
end;

function TMyApplication.GetDefaultTTL: String;
begin
  result:='64';
end;

function TMyApplication.IsRoot: Boolean;
var OutList: Tstringlist;
    Proc: TProcess;
begin
  OutList := Tstringlist.create;
  Proc := TProcess.Create(nil);
  Proc.Options := [poWaitOnExit,poUsePipes];
  Proc.Executable := 'whoami';
  Proc.Execute;
  OutList.LoadFromStream(Proc.Output);
  Proc.Free;
  if OutList.Strings[0]='root' then Result:=true else
   Result:=false;
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='switch ttl';
  Application.Run;
  Application.Free;
end.

