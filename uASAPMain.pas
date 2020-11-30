unit uASAPMain;

interface

uses

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.FileCtrl, WinApi.MMSystem,
  Vcl.WinXCtrls, Vcl.ComCtrls, WinApi.ActiveX, System.ImageList, Vcl.ImgList,
  Vcl.Shell.ShellCtrls,  Winapi.CommCtrl,  Masks,    Types,  INIfiles,
    DragDrop,
  DropTarget,
  DropSource,
  DragDropFile;

type
  TfrmMainApp = class(TForm)
    StatusBar1: TStatusBar;
    FileOpenDialog1: TFileOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    SearchBox1: TSearchBox;
    lblFolder: TLinkLabel;
    btnSelectFolder: TButton;
    chbRecursive: TCheckBox;
    Label2: TLabel;
    btnStop: TButton;
    Panel3: TPanel;
    eRootFolder: TEdit;
    DropSource1: TDropFileSource;
    ImageListSingleFile: TImageList;
    ImageListMultiFile: TImageList;
    chbLoop: TCheckBox;
    lvResults: TListView;
    btnStopSound: TButton;
    TrackBar1: TTrackBar;
    Label1: TLabel;
    procedure btnSelectFolderClick(Sender: TObject);
    procedure SearchBox1InvokeSearch(Sender: TObject);
    procedure lvResultsClick(Sender: TObject);
    procedure lvResultsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lvResultsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnStopClick(Sender: TObject);
    procedure eRootFolderExit(Sender: TObject);
    procedure DropSource1Feedback(Sender: TObject; Effect: Integer;
      var UseDefaultCursors: Boolean);
    procedure DropSource1Drop(Sender: TObject; DragType: TDragType;
      var ContinueDrop: Boolean);
    procedure SearchBox1Change(Sender: TObject);
    procedure btnStopSoundClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    _item: TListItem;
    _num, _scanned, _found, _folders: integer;
    _stop: boolean;
    _channel: DWORD;
    procedure SetSearchFolder;
    procedure ListFileDir(Path: string);
    procedure PlaySelectedItem(Item: TlistItem);
    procedure BASS_PlayFile(FileName: TFileName);
  protected
    procedure Loaded; override;
  public
    { Public declarations }
  end;

var
  frmMainApp: TfrmMainApp;

implementation

{$R *.dfm}
uses
  bass;


procedure TfrmMainApp.btnSelectFolderClick(Sender: TObject);
begiN
  SetSearchFolder;
end;

procedure TfrmMainApp.SearchBox1Change(Sender: TObject);
begin
  //
end;

procedure TfrmMainApp.SearchBox1InvokeSearch(Sender: TObject);
begin


  _scanned := 0;
  _found := 0;
  _folders := 0;
  _num := 0;

  lvResults.Clear;
  StatusBar1.Panels[1].Text := 'Searching...';

  _stop := false;
  btnStop.Visible := true;

  ListFileDir(eRootFolder.Text);

  btnStop.Visible := false;

  StatusBar1.Panels[0].Text := 'Scanned Files:' + IntToStr(_scanned) +
  '   Found: ' + IntToStr(_found) + '  Folders: ' + IntToStr(_folders)  ;

  if _stop = true then
    StatusBar1.Panels[1].Text := 'Stopped.'
  else
    StatusBar1.Panels[1].Text := 'Done.';

end;

procedure TfrmMainApp.SetSearchFolder;
var
  sDir: string;
begin
  sDir := eRootFolder.Text;

  FileOpenDialog1.DefaultFolder := sDir;

  if FileOpenDialog1.Execute then begin
    eRootFolder.Text := IncludeTrailingPathDelimiter(FileOpenDialog1.FileName);
  end;

end;


procedure TfrmMainApp.TrackBar1Change(Sender: TObject);
begin
  // Adjust volume for the current track
  BASS_ChannelSetAttribute(_channel, BASS_ATTRIB_VOL, TrackBar1.Position / 100);
end;

procedure TfrmMainApp.btnStopClick(Sender: TObject);
begin
  _stop := true;
end;

procedure TfrmMainApp.btnStopSoundClick(Sender: TObject);
begin
    // Free the stream if a song is playing
    if _channel <> 0 then begin
      BASS_StreamFree(_channel);
//      btnStopSound.Enabled := false;
    end;
end;

procedure TfrmMainApp.DropSource1Drop(Sender: TObject; DragType: TDragType;
  var ContinueDrop: Boolean);
begin
  ContinueDrop := true;
end;

procedure TfrmMainApp.DropSource1Feedback(Sender: TObject; Effect: Integer;
  var UseDefaultCursors: Boolean);
begin
  UseDefaultCursors := True;
end;

procedure TfrmMainApp.eRootFolderExit(Sender: TObject);
begin
  eRootFolder.Text :=  IncludeTrailingPathDelimiter(eRootFolder.Text)
end;

procedure TfrmMainApp.FormClose(Sender: TObject; var Action: TCloseAction);
var
   Ini: TIniFile;
 begin
   Ini := TIniFile.Create( ChangeFileExt( Application.ExeName, '.INI' ) );
   try

      Ini.WriteString('Search', 'RootFolder', eRootFolder.Text);
      Ini.WriteString('Search', 'SearchText', SearchBox1.Text);
      Ini.WriteBool('Search', 'ScanSubFolders', chbRecursive.Checked);

      Ini.WriteInteger('Audio', 'Volume', TrackBar1.Position);
      Ini.WriteBool('Audio', 'LoopOnPreview', chbLoop.Checked);

   finally
     Ini.Free;
   end;

end;

procedure TfrmMainApp.FormCreate(Sender: TObject);
 var
   Ini: TIniFile;
 begin
   Ini := TIniFile.Create( ChangeFileExt( Application.ExeName, '.INI' ) );
   try

      eRootFolder.Text := Ini.ReadString('Search', 'RootFolder', 'C:' );
      SearchBox1.Text := Ini.ReadString('Search', 'SearchText', '');
      chbRecursive.Checked := Ini.ReadBool('Search', 'ScanSubFolders', true);

      TrackBar1.Position := Ini.ReadInteger('Audio', 'Volume', 70);
      chbLoop.Checked := Ini.ReadBool('Audio', 'LoopOnPreview', false);

   finally
     Ini.Free;
   end;

end;

procedure TfrmMainApp.ListFileDir(Path: string);
var
  SR: TSearchRec;
  Itm: TListItem;
  USRCH, UNAME, UPATH, UEXT: string;
  sf: TShellFolder;
begin

  if FindFirst(IncludeTrailingPathDelimiter(Path) + '*.*', faAnyFile, SR) = 0 then
  begin

    repeat

      StatusBar1.Panels[0].Text := 'Searching... ' + Path + '...';
      Application.ProcessMessages;

      USRCH := Uppercase(Searchbox1.Text);
      UNAME := Uppercase(SR.Name);
      UPATH := Uppercase(Path);
      UEXT  := Uppercase(ExtractFileExt(SR.Name));

      if (SR.Name = '.') or (SR.Name = '..') then begin
        //do nothing for these
      end
      else if (SR.Attr <> faDirectory) then begin

        // not a directory so check it out
        Inc(_scanned);

        // include it if the path also contains the search term
        if(Pos(USRCH, UNAME) > 0) or (Pos(USRCH, UPATH) > 0) or (USRCH = '') then begin

          // make sure it's an audio file
          if(Pos(UEXT, '.MP3.WAV.AIFF.OGG.MP1.MP2')>0) then begin

            inc(_found);

            // create and populate the result item
            Itm := lvResults.Items.Add;
            Itm.Caption := SR.Name;
            Itm.Checked := false;
            Itm.SubItems.Add(ExtractFileExt(SR.Name)); // EXT [0]
            Itm.SubItems.Add(IncludeTrailingPathDelimiter(Path)); // PATH [1]
            Itm.SubItems.Add(IntToStr(_found)); // NUMBER [2]

          end;

        end;

      end
      else if (SR.Attr = faDirectory) and (chbRecursive.Checked) then begin

          Inc(_folders);

          ListFileDir(IncludeTrailingPathDelimiter(Path) + SR.Name);
      end;

    until (FindNext(SR) <> 0) or (_stop = true);

    FindClose(SR);


  end;
end;


procedure TfrmMainApp.lvResultsClick(Sender: TObject);
begin
  if(lvResults.Selected <> nil) then begin

    // dont play if flag set. This is a 1 time check to
    // prevent OnClick and OnSelectItem events from playing the same file
    // as both get triggered at times.
    if(not lvResults.Selected.Checked) then
      PlaySelectedItem(lvResults.Selected);

    lvResults.Selected.Checked := false; // clear flag

  end;

end;

procedure TfrmMainApp.lvResultsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: integer;
  Filename, path, pathfile: string;
  p: TPoint;
  Res: TDragResult;
begin

  // If no files selected then exit...
  if lvResults.SelCount = 0 then
    Exit;

  // Wait for user to move cursor before we start the drag/drop.
  if (DragDetectPlus(TWinControl(Sender))) then
  begin

    // Fill DropSource1.Files with selected files in ListView1 and...
    DropSource1.Files.Clear;
    filename := lvResults.Selected.Caption;
    path := lvResults.Selected.SubItems[1];
    pathfile := IncludeTrailingBackslash(path) + filename;

    DropSource1.Files.Add(pathfile);



{    DropSource1.Images := ImageListSingleFile;
    DropSource1.ImageHotSpotX := X-lvResults.Selected.Left;
    DropSource1.ImageHotSpotY := Y-lvResults.Selected.Top;
    DropSource1.ImageIndex := 0;
}
//    DropSource1.DragTypes := [];
    try

      // OK, now we are all set to go. Let's start the drag...
      Res := DropSource1.Execute;

    finally
      // Enable the list view as a drop target again.
//      DropSource1.Dragtypes := [dtLink];
      DropSource1.Files.Clear;
      lvResults.Update;
    end;



    // Note:
    // The target is responsible, from this point on, for the
    // copying/moving/linking of the file but the target feeds
    // back to the source what (should have) happened via the
    // returned value of Execute.

    // Feedback in Statusbar1 what happened...
    case Res of
      drDropLink: StatusBar1.Panels[2].Text := 'Linked';
      drCancel: StatusBar1.Panels[2].Text := 'Drop cancelled';
      drOutMemory: StatusBar1.Panels[2].Text := 'Drop cancelled - out of memory';
    else
      StatusBar1.Panels[2].Text := 'Drop cancelled - unknown reason';
    end;


  end;
end;

procedure TfrmMainApp.lvResultsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if (Selected) and (Item.Checked = false) then begin
    PlaySelectedItem(Item);
  end;
//  else
//    PlaySelectedItem(Nil); // this should play a empty WAV to stop any current playing audio

end;

procedure TfrmMainApp.Loaded;
begin

  inherited Loaded;

  // Initialize audio - default device, 44100hz, stereo, 16 bits
  if not BASS_Init(-1, 44100, 0, Handle, nil) then
    ShowMessage('Error initializing audio!');

  eRootFolder.Text  := 'D:\M\Drum Kits\'; // initial start
  SearchBox1.Text := 'cym';

end;
procedure TfrmMainApp.BASS_PlayFile(FileName: TFileName);
begin
    // Free the stream if a song is playing
    if _channel <> 0 then
      BASS_StreamFree(_channel);



    // Create a new stream
    if(chbLoop.Checked) then begin
      _channel := BASS_StreamCreateFile(False, PChar(FileName), 0, 0, 0 {$IFDEF UNICODE} or BASS_SAMPLE_LOOP or BASS_UNICODE {$ENDIF});
    end
    else begin
      _channel := BASS_StreamCreateFile(False, PChar(FileName), 0, 0, 0 {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
    end;

    // Check if channel is unable to play
    if _channel = 0 then begin
      ShowMessage('Unable to play');
      Exit;
    end;



    // Set volume for every playback
    BASS_ChannelSetAttribute(_channel, BASS_ATTRIB_VOL, TrackBar1.Position / 100);

    // Play the track
    BASS_ChannelPlay(_channel, False);
end;

procedure TfrmMainApp.PlaySelectedItem(Item: TListItem);
var
  filename, path, pathfile: string;
begin

    Item.Checked := true; // using this property as a flag

    filename := Item.Caption;
    path := Item.SubItems[1];
    pathfile := IncludeTrailingBackslash(path) + filename;

    if FileExists(pathfile) then begin

      BASS_PlayFile(pathfile);

//      if(chbLoop.Checked) then
//        PlaySound(pchar(pathfile), 0, SND_LOOP or SND_FILENAME)
//      else
//        PlaySound(pchar(pathfile), 0, SND_ASYNC or SND_FILENAME);

    end;


end;

end.
