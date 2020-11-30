program ASAP;

uses
  Vcl.Forms,
  uASAPMain in 'uASAPMain.pas' {frmMainApp},
  bass in 'bass\bass.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainApp, frmMainApp);
  Application.Run;
end.
