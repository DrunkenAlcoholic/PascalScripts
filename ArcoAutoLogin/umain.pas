unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ECSwitch, ECLink, StrUtils, FileUtil,
  Process;

type

  { TfrmArcoAutoLogin }

  TfrmArcoAutoLogin = class(TForm)
    cbSession: TComboBox;
    lblLink: TECLink;
    lblAutoLogin: TLabel;
    swcOnOff: TECSwitch;
    imgArcoLinux: TImage;
    lblDbg: TLabel;
    memDebug: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure swcOnOffClick(Sender: TObject);
    procedure swcOnOffEnter(Sender: TObject);
    procedure swcOnOffMouseEnter(Sender: TObject);
  private
    function CheckGroupExsist(sGroupName: string): boolean;
    function AddGroupAndUser(sGroup, sUsername: string): boolean;
    function ExecuteCommand(sCmd: string): string;
    procedure LogIt(sString: string);

  public

  end;

var
  frmArcoAutoLogin: TfrmArcoAutoLogin;
  //Globle varibales for User and session
  sSession, sUsername, sPassword: string;
  //Set sGroup as "autologin" to use globle
  sGroup: string = 'autologin';

implementation

{$R *.lfm}

{ TfrmArcoAutoLogin }
procedure TfrmArcoAutoLogin.FormCreate(Sender: TObject);
begin
  //Check if lightdm.conf exists
  if FileExists('/etc/lightdm/lightdm.conf') then
  begin
    //Check if autologin is enabled in lightdm.conf, set slider to on/off
    if AnsiContainsStr(ExecuteCommand(
      'grep ''autologin-user='' /etc/lightdm/lightdm.conf'), '#') then
      swcOnOff.state := cbUnchecked
    else
      swcOnOff.state := cbChecked;
  end
  else
  begin
    ShowMessage('Error: lightdm not found at default location, Lightdm must be installed first');
    Application.Terminate;
  end;
end;

procedure TfrmArcoAutoLogin.FormShow(Sender: TObject);
var
  sSessions, sStr: string;
begin

  //Get current session and username/password and set to global varible
  sSession := ExecuteCommand('echo $DESKTOP_SESSION');
  sUsername := ExecuteCommand('whoami');
  sPassword := PasswordBox('Enter sudo Password', 'Administrator Password: ');

  //Ensure username and current session is set
  if ((sUsername.Length > 0) and (sSession.Length > 0)) then
  begin
    //Get Sessions from xsession
    sSessions := Trim(StringReplace(ExecuteCommand('ls /usr/share/xsessions/'),
      '.desktop', '', [rfReplaceAll]));
    //Add found sessions to dropdown box
    for sStr in sSessions.Split(LineEnding) do
      cbSession.Items.Add(lowercase(sStr));
    //Select current session in dropdown box
    if cbSession.Items.Count > 0 then
      cbSession.ItemIndex := cbSession.Items.IndexOf(sSession);
  end
  else
  begin
    ShowMessage('Error: While Retrieving Username and Current Session.... Exiting');
    Close;
  end;

  //Check if "autologin" group exsist or aske dto create it
  if CheckGroupExsist('autologin') then
  begin
    if not AnsiContainsStr(ExecuteCommand('groups ' + sUsername), 'autologin') then
      if MessageDlg('Question', sUsername +
        ' is not part of the autologin group, would you like me to add it?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        if sPassword.Length > 0 then
          ShowMessage(ExecuteCommand('echo ' + sPassword +
            ' | sudo -S gpasswd -a ' + sUsername + '  ' + sGroup));
      end;
  end
  else
  begin
    if MessageDlg('Question', sGroup +
      ' doesn''t exsist, would you like to create it and add ' +
      sUsername + ' the group?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if sPassword.Length > 0 then
        ShowMessage(ExecuteCommand('echo ' + sPassword +
          ' | sudo -S groupadd -r ' + sGroup + '; sudo -S gpasswd -a ' +
          sUsername + '  ' + sGroup));
    end
    else
      Close;
  end;
end;

procedure TfrmArcoAutoLogin.swcOnOffClick(Sender: TObject);
var
  cmd, sResults: string;
begin

  if swcOnOff.State = cbChecked then
  begin
    if ((sUsername.Length > 0) and (cbSession.ItemIndex > -1) and
      (sPassword.Length > 0)) then
    begin
      cmd := 'echo ' + sPassword +
        ' | sudo -S sed -i -e ''/autologin-user=/c \autologin-user=' +
        sUsername + ''' -e ''/autologin-session=/c \autologin-session=' +
        cbSession.Text + '''  -e ''/user-session=/c \user-session=' +
        cbSession.Text + ''' /etc/lightdm/lightdm.conf';
      //Run command and put the returned results in sResults
      sResults := ExecuteCommand(cmd);

      //If the sResult contain any string then it failed
      if sResults.length > 0 then
        ShowMessage('Error: ' + sResults)
      else
        //If the sResult has no strings, then it succeeded
        ShowMessage('Enabled Autologin for ' + sUsername + ' / ' + cbSession.Text);
    end;
  end
  else
  begin
    if ((sUsername.Length > 0) and (sPassword.length > 0)) then
    begin
      cmd := 'echo ' + sPassword +
        ' | sudo -S sed -i ''/autologin-user=/c \#autologin-user=' +
        sUsername + ''' /etc/lightdm/lightdm.conf';

      //Run command and put the returned results in sResults
      sResults := ExecuteCommand(cmd);

      //If the sResult contain any string then it failed
      if sResults.length > 0 then
        ShowMessage('Error: ' + sResults)
      else
        //If the sResult has no strings, then it succeeded
        ShowMessage('Disabled Autologin for ' + sUsername);
    end
    else
      ShowMessage('Error: Can not find lightdm.conf');
  end;
end;

procedure TfrmArcoAutoLogin.swcOnOffEnter(Sender: TObject);
begin
  memDebug.SetFocus;
end;

procedure TfrmArcoAutoLogin.swcOnOffMouseEnter(Sender: TObject);
begin
  memDebug.SetFocus;
end;

//Log to memDebug debug output
procedure TfrmArcoAutoLogin.LogIt(sString: string);
begin
  memDebug.Lines.Add(sString);
end;

//Not used yet but will be a function to create any group and add any user
function TfrmArcoAutoLogin.AddGroupAndUser(sGroup, sUsername: string): boolean;
var
  cmd, sResults: string;
begin

  Result := False;
  //Set command with pkexec(root privliages)
  cmd := 'echo ' + sPassword + ' | sudo -S groupadd -r ' + sGroup +
    ' ; sudo -S gpasswd -a ' + sUsername + ' ' + sGroup;
  //Execute the command
  sResults := ExecuteCommand(cmd);
  //Show returned string to inform user
  ShowMessage(sResults);

  //Double check to make sure the group exsist after creating it
  if CheckGroupExsist(sGroup) then
    ShowMessage('Success: group autologin created')
  else
    ShowMessage('Error: group creation failed');

end;

//Execute a command
function TfrmArcoAutoLogin.ExecuteCommand(sCmd: string): string;
var
  hProcess: TProcess;
  OutputLines: TStringList;
  sReturnString: string;
begin
  Result := 'Error';
  //Creat a process
  hProcess := TProcess.Create(nil);
  //Create a StringList for output
  OutputLines := TStringList.Create;
  try
    hProcess.Executable := 'bash';
    hProcess.Parameters.DelimitedText := '-c "' + sCmd + '"';
    hProcess.Options := hProcess.Options + [poWaitOnExit, poUsePipes];
    hProcess.ShowWindow := swoHide;
    hProcess.Execute;

    //If process status is 0 then succeeded
    if hProcess.ExitStatus = 0 then
    begin
      OutputLines.LoadFromStream(hprocess.Output);
      sReturnString := Trim(Outputlines.Text);
      LogIt(sReturnString);
      Result := sReturnString;
    end;
    //handle expeptions and show message
  except
    on E: Exception do
      ShowMessage('Error with Command  : ' + E.message);
  end;
  //Log process status successful/error code
  LogIt(IntToStr(hProcess.ExitStatus));
  //Free the process
  hProcess.Free;
  //Free the stringlist
  OutputLines.Free;
end;

//Check if group exists
function TfrmArcoAutoLogin.CheckGroupExsist(sGroupName: string): boolean;
begin
  Result := False;
  //If retrun string contains group then it already exsists
  if Pos(sGroupName, ExecuteCommand('getent group ' + sGroupName)) > 0 then
    Result := True;
end;

end.
