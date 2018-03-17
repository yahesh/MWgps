unit MWgpsU;

// Please, don't delete this comment. \\
(*
  Copyright Owner: Yahe
  Copyright Year : 2008-2018

  Unit   : MWgpsU (platform dependant)
  Version: 0.4.5.3c

  Contact E-Mail: hello@yahe.sh
*)
// Please, don't delete this comment. \\

(*
  Description:

  This unit contains the functionality of MWgps.
*)

(*
  Change Log:

  [Version 0.4.5.3c] (15.10.2008: write log release)
  - Write-Log operand has been introduced ('-writelog' and '-w')

  [Version 0.4.5.2c] (15.10.2008: GPSdata 1.3c release)
  - GPSdata has been updated to version 1.3c (now supports different talker IDs)

  [Version 0.4.5.1c] (11.10.2008: instance fix release)
  - MWconn instance name is now handled correctly (no trim)

  [Version 0.4.5c] (09.10.2008: MWpas 1.4.5c release)
  - MWpas has been updated to version 1.4.5c (now supports MWconn 4.5)
  - instance operand has been introduced ('-i' or '-instance')

  [Version 0.4.4.1c] (09.10.2008: GPSonly release)
  - GPS-only operand has been introduced ('-g' and '-gpsonly')

  [Version 0.4.4c] (26.08.2008: first stable release)
  - first stable release
  - version number now reflects the supported version of MWconn

  [Version 0.3.1b] (19.07.2008: synchronize release)
  - COM port is now used with synchronized option enabled
  - message loop simplified

  [Version 0.3b] (19.07.2008: quit release)
  - GPS data are now checked for validity before being written to the log
  - quit operand has been introduced ('-q' and '-quit')

  [Version 0.2b] (17.07.2008: network release)
  - network operand has been introduced ('-n' and '-network')
  - portnumber operands have been set to '-p' and '-port'

  [Version 0.1b] (16.07.2008: initial release)
  - initial source has been written
*)

interface

{$I MWgpsU.inc}

uses
  Windows,
  SysUtils,
  SyncObjs,
  Messages,
  Classes,
  MWpasU,
  GPSdataU,
  COMportU;

const
  MWgpsU_CopyrightOwner = 'Yahe';
  MWgpsU_CopyrightYear  = '2008-2018';
  MWgpsU_Name           = 'MWgps';
  MWgpsU_ReleaseDate    = '15.10.2008';
  MWgpsU_ReleaseName    = 'write log release';
  MWgpsU_Version        = '0.4.5.3c';

const
  CopyrightOwner = MWgpsU_CopyrightOwner;
  CopyrightYear  = MWgpsU_CopyrightYear;
  Name           = MWgpsU_Name;
  ReleaseDate    = MWgpsU_ReleaseDate;
  ReleaseName    = MWgpsU_ReleaseName;
  Version        = MWgpsU_Version;

const
  CFileHeader = 'MWgps';
  CMutexName  = 'MUTEX:MWgps COM';
  CWindowName = 'WINDOW:MWgps COM';

const
  CQuitApplication = WM_USER + 12131;

const
  CErrorOK        = 0;
  CErrorHelp      = 1;
  CErrorQuit      = 2;
  CErrorTerminate = 3;

  CErrorSection   = 11;
  CErrorMWconn    = 12;
  CErrorCOMPort   = 13;
  CErrorLogFolder = 14;
  CErrorLogFile   = 15;
  CErrorGPS       = 16;
  CErrorFolder    = 17;
  CErrorFile      = 18;
  CErrorMutex     = 19;
  CErrorWindow    = 20;

  CErrorUnknown = 255;

const
  CAppendDirectiveA    = '-a';
  CAppendDirectiveB    = '-append';
  CBaudDirectiveA      = '-b';
  CBaudDirectiveB      = '-baud';
//  CDGPSDirectiveA      = '-d';
//  CDGPSDirectiveB      = '-dgps';
  CFileDirectiveA      = '-f';
  CFileDirectiveB      = '-file';
  CGPSOnlyDirectiveA   = '-g';
  CGPSOnlyDirectiveB   = '-gpsonly';
  CHelpDirectiveA      = '-h';
  CHelpDirectiveB      = '-help';
  CInstanceDirectiveA  = '-i';
  CInstanceDirectiveB  = '-instance';
  CLogAlwaysDirectiveA = '-l';
  CLogAlwaysDirectiveB = '-logalways';
  CNetworkDirectiveA   = '-n';
  CNetworkDirectiveB   = '-network';
  CPortDirectiveA      = '-p';
  CPortDirectiveB      = '-port';
  CQuitDirectiveA      = '-q';
  CQuitDirectiveB      = '-quit';
  CReadOnlyDirectiveA  = '-r';
  CReadOnlyDirectiveB  = '-readonly';
  CWriteLogDirectiveA  = '-w';
  CWriteLogDirectiveB  = '-writelog';

const
  CGPSonly = 'GPS only';

type
  TMWgpsMessageHandler = class(TObject)
  private
  protected
    FCID             : String;
    FCOMport         : TCOMport;
    FCriticalSection : TCriticalSection;
    FErrorCode       : Byte;
    FFile            : TextFile;
    FGPSdata         : TGPSdata;
    FGPSOnly         : Boolean;
    FHandle          : LongWord;
    FInWrite         : Boolean;
    FLAC             : String;
    FLatitude        : String;
    FLogAlways       : Boolean;
    FLogFile         : TextFile;
    FLongitude       : String;
    FMutex           : THandle;
    FMWconnFile      : THandle;
    FMWconnIO        : PMWconnIO;
    FNetworkInfo     : Boolean;
    FPLMN            : String;
    FQuit            : Boolean;
    FSignal          : String;
    FStarted         : Boolean;
    FWriteLog        : Boolean;

    procedure DoRMCdata(const ASender : TObject; const ATalkerID : String; const AData : TRMCdata);
    procedure DoSetupConnection(const ASender : TObject; const ACOMhandle : THandle; var AConfig : TCommConfig);
    procedure DoWriteLog(const ASender : TObject; const ALine : String);
    procedure DoWriteLine(const ASender : TObject; const ALine : String);
    procedure HandleMessages(var AMessage : TMessage);
  public
    constructor Create;

    destructor Destroy; override;

    property ErrorCode : Byte read FErrorCode;

    procedure MessageLoop;
  published
  end;

implementation

{ TMWgpsMessageHandler }

constructor TMWgpsMessageHandler.Create;
  function ForceFolder(const AFileName : String) : Boolean;
  var
    LPath : String;
  begin
    LPath := ExtractFilePath(AFileName);

    Result := (Length(LPath) <= 0);
    if not(Result) then
      Result := ForceDirectories(LPath);
  end;

  function GetAppend : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CAppendDirectiveA);
      if not(Result) then
        Result := (LParam = CAppendDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('APPEND    = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

  function GetGPSOnly : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CGPSOnlyDirectiveA);
      if not(Result) then
        Result := (LParam = CGPSOnlyDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('GPSONLY   = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

  function GetHelp : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CHelpDirectiveA);
      if not(Result) then
        Result := (LParam = CHelpDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('HELP      = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

  function GetInstance : String;
  var
    LDone  : Boolean;
    LIndex : LongInt;
    LParam : String;
  begin
    Result := '';

    LDone := false;
    for LIndex := 1 to Pred(ParamCount) do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      LDone := (LParam = CInstanceDirectiveA);
      if not(LDone) then
        LDone := (LParam = CInstanceDirectiveB);

      if LDone then
      begin
        Result := ParamStr(Succ(LIndex)); // do not trim!

        Break;
      end;
    end;

    if not(LDone) then
      Result := '';

    WriteLn('INSTANCE  = ' + Result);
  end;

  function GetLogAlways : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CLogAlwaysDirectiveA);
      if not(Result) then
        Result := (LParam = CLogAlwaysDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('LOGALWAYS = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

  function GetLogFile : String;
  var
    LDone  : Boolean;
    LIndex : LongInt;
    LParam : String;
  begin
    Result := '';

    LDone := false;
    for LIndex := 1 to Pred(ParamCount) do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      LDone := (LParam = CWriteLogDirectiveA);
      if not(LDone) then
        LDone := (LParam = CWriteLogDirectiveB);

      if LDone then
      begin
        Result := Trim(ParamStr(Succ(LIndex)));

        Break;
      end;
    end;

    if not(LDone) then
      Result := '';

    WriteLn('LOGFILE   = ' + Result);
  end;

  function GetNetwork : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CNetworkDirectiveA);
      if not(Result) then
        Result := (LParam = CNetworkDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('NETWORK   = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

  function GetOutputFileName : String;
    function DateTimeToFile : String;
      function IntToStrN(const AInt : LongInt; const AN : Byte) : String;
      begin
        Result := IntToStr(AInt);
        while (Length(Result) < AN) do
          Result := '0' + Result;
      end;
    var
      LDay     : Word;
      LHour    : Word;
      LMinute  : Word;
      LMonth   : Word;
      LMSecond : Word;
      LNow     : TDateTime;
      LSecond  : Word;
      LYear    : Word;
    begin
      LNow := Now;
      DecodeDate(LNow, LYear, LMonth, LDay);
      DecodeTime(LNow, LHour, LMinute, LSecond, LMSecond);

      Result := IntToStrN(LDay, 2) + IntToStrN(LMonth, 2) + IntToStrN(LYear, 2) + '_' +
                IntToStrN(LHour, 2) + IntToStrN(LMinute, 2) + IntToStrN(LSecond, 2) + IntToStrN(LMSecond, 3);
    end;

  const
    CLogExt    = '.log';
    CLogFolder = 'logs\';
  var
    LDone  : Boolean;
    LIndex : LongInt;
    LParam : String;
  begin
    Result := '';

    LDone := false;
    for LIndex := 1 to Pred(ParamCount) do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      LDone := (LParam = CFileDirectiveA);
      if not(LDone) then
        LDone := (LParam = CFileDirectiveB);

      if LDone then
      begin
        Result := Trim(ParamStr(Succ(LIndex)));

        Break;
      end;
    end;

    if not(LDone) then
      Result := ExtractFilePath(ParamStr(0)) + CLogFolder + DateTimeToFile + CLogExt;

    WriteLn('FILENAME  = ' + Result);
  end;

  function GetPort : LongInt;
  var
    LDone  : Boolean;
    LIndex : LongInt;
    LParam : String;
  begin
    Result := - 1;

    LDone := false;
    for LIndex := 1 to Pred(ParamCount) do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      LDone := (LParam = CPortDirectiveA);
      if not(LDone) then
        LDone := (LParam = CPortDirectiveB);

      if LDone then
      begin
        LDone := TryStrToInt(ParamStr(Succ(LIndex)), Result);

        if LDone then
          Break;
      end;
    end;

    if not(LDone) then
      Result := - 1;

    WriteLn('PORT      = ' + IntToStr(Result));
  end;

  function GetQuit : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CQuitDirectiveA);
      if not(Result) then
        Result := (LParam = CQuitDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('QUIT      = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

  function GetReadOnly : Boolean;
  var
    LIndex : LongInt;
    LParam : String;
  begin
    Result := false;

    for LIndex := 1 to ParamCount do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      Result := (LParam = CReadOnlyDirectiveA);
      if not(Result) then
        Result := (LParam = CReadOnlyDirectiveB);

      if Result then
        Break;
    end;

    WriteLn('READONLY  = ' + AnsiUpperCase(BoolToStr(Result, true)));
  end;

var
  LAccessMode     : TMWconnAccessMode;
  LDone           : Boolean;
  LInstance       : String;
  LLogFile        : String;
  LMutex          : THandle;
  LOutputFileName : String;
  LPort           : LongInt;
  LQuit           : Boolean;
  LWindow         : LongWord;
  LWindowText     : String;
begin
  inherited Create;

  FCID             := '';
  FCOMport         := nil;
  FCriticalSection := nil;
  FGPSdata         := nil;
  FGPSOnly         := GetGPSOnly;
  FInWrite         := false;
  FLAC             := '';
  FLatitude        := '';
  FLogAlways       := GetLogAlways;
  FLongitude       := '';
  FMutex           := 0;
  FMWconnFile      := 0;
  FMWconnIO        := nil;
  FNetworkInfo     := GetNetwork;
  FPLMN            := '';
  FQuit            := false;
  FSignal          := '';
  FStarted         := false; // important
  FWriteLog        := false;

  FErrorCode := CErrorUnknown;
  try
    if not(GetHelp) then
    begin
      LPort := GetPort;
      if (LPort > 0) then
      begin
        LQuit := GetQuit;
        if not(LQuit) then
        begin
          FCriticalSection := TCriticalSection.Create;
          try
            FMWconnFile := 0;
            FMWconnIO   := nil;

            LAccessMode := mwamNone;
            if not(FGPSOnly) then
            begin
              LInstance := GetInstance;

              if IsMWconnRunning(LInstance) then
                LAccessMode := OpenMWconnIO(FMWconnFile, FMWconnIO, LInstance);
            end;
            
            if ((LAccessMode <> mwamNone) or FGPSOnly) then
            begin
              try
                FCOMport := TCOMport.Create(LPort);
                try
                  FCOMport.ClearBufferOnOpen  := true;
                  FCOMport.FlushBufferOnClose := true;
                  FCOMport.OnSetupConnection  := DoSetupConnection;
                  FCOMport.ReadOnly           := GetReadOnly;
                  FCOMport.ShowSetupDialog    := false;
                  FCOMport.Synchronized       := true;

                  if FCOMport.OpenConnection then
                  begin
                    FGPSdata := TGPSdata.Create;
                    try
                      LLogFile := GetLogFile;
                      if (Length(LLogFile) > 0) then
                      begin
                        if ForceFolder(LLogFile) then
                        begin
                          AssignFile(FLogFile, LLogFile);
                          try
                            if FileExists(LLogFile) then
                            begin
                              Append(FLogFile);
                              WriteLn(FLogFile, '');
                            end
                            else
                              Rewrite(FLogFile);

                            WriteLn(FLogFile, '{' + DateTimeToStr(Now) + '}');

                            FWriteLog := true;
                          except
                            if (FErrorCode = CErrorUnknown) then
                              FErrorCode := CErrorLogFile;

                            try
                              CloseFile(FLogFile);
                            finally
                              // catch all other exceptions
                            end;

                            raise;
                          end;
                        end
                        else
                        begin
                          if (FErrorCode = CErrorUnknown) then
                            FErrorCode := CErrorLogFolder;

                          raise Exception.Create('');
                        end;
                      end;

                      FGPSdata.COMport                  := FCOMport;
                      FGPSdata.ProceedWithWrongChecksum := false;
                      FGPSdata.OnBeforeSplitLine        := DoWriteLog;
                      FGPSdata.OnRMCdata                := DoRMCdata;
                      FGPSdata.OnWrongChecksum          := DoWriteLine;
                      FGPSdata.ValidateChecksum         := true;

                      LOutputFileName := GetOutputFileName;
                      if ForceFolder(LOutputFileName) then
                      begin
                        AssignFile(FFile, LOutputFileName);
                        try
                          if GetAppend then
                            Append(FFile)
                          else
                          begin
                            Rewrite(FFile);
                            if FGPSOnly then
                              WriteLn(FFile, CFileHeader + '(' + CGPSonly + ')')
                            else
                              WriteLn(FFile, CFileHeader + '(' + OperationModeToString(GetOperationMode(FMWconnIO^.OpMode)) +
                                      ': ' + Trim(FMWconnIO^.Network_Name) + ')');
                            Flush(FFile);
                          end;

                          try
                            FMutex := CreateMutex(nil, true, PChar(CMutexName + IntToStr(FCOMport.Number)));
                            if (FMutex <> 0) then
                            begin
                              try
                                FHandle := AllocateHWnd(HandleMessages);
                                if (FHandle <> 0) then
                                begin
                                  SetWindowText(FHandle, PChar(CWindowName + IntToStr(FCOMport.Number)));

                                  if (FErrorCode = CErrorUnknown) then
                                    FErrorCode := CErrorOK;
                                end
                                else
                                begin
                                  if (FErrorCode = CErrorUnknown) then
                                    FErrorCode := CErrorWindow;

                                  raise Exception.Create('');
                                end;
                              except
                                if (FErrorCode = CErrorUnknown) then
                                  FErrorCode := CErrorMutex;

                                CloseHandle(FMutex);
                                raise;
                              end;
                            end
                            else
                            begin
                              if (FErrorCode = CErrorUnknown) then
                                FErrorCode := CErrorMutex;

                              raise Exception.Create('');
                            end;
                          except
                            if (FErrorCode = CErrorUnknown) then
                              FErrorCode := CErrorFile;

                            CloseFile(FFile);
                            raise;
                          end;
                        except
                          if (FErrorCode = CErrorUnknown) then
                            FErrorCode := CErrorFile;

                          raise;
                        end;
                      end
                      else
                      begin
                        if (FErrorCode = CErrorUnknown) then
                          FErrorCode := CErrorFolder;

                        raise Exception.Create('');
                      end;
                    except
                      if (FErrorCode = CErrorUnknown) then
                        FErrorCode := CErrorGPS;

                      FGPSdata.Free;
                      FGPSdata := nil;
                      raise;
                    end;
                  end
                  else
                  begin
                    if (FErrorCode = CErrorUnknown) then
                      FErrorCode := CErrorCOMPort;

                    raise Exception.Create('');
                  end;
                except
                  if (FErrorCode = CErrorUnknown) then
                    FErrorCode := CErrorCOMPort;

                  FCOMport.Free;
                  FCOMport := nil;
                  raise;
                end;
              except
                if (FErrorCode = CErrorUnknown) then
                  FErrorCode := CErrorMWconn;

                if not(FGPSOnly) then
                  CloseMWconnIO(FMWconnFile, FMWconnIO);
                raise;
              end;
            end
            else
            begin
              if (FErrorCode = CErrorUnknown) then
                FErrorCode := CErrorMWconn;

              raise Exception.Create('');
            end;
          except
            if (FErrorCode = CErrorUnknown) then
              FErrorCode := CErrorSection;

            FCriticalSection.Free;
            FCriticalSection := nil;
            raise;
          end;
        end
        else
        begin
          if (FErrorCode = CErrorUnknown) then
            FErrorCode := CErrorQuit;

          LMutex := OpenMutex(MUTEX_ALL_ACCESS, true, PChar(CMutexName + IntToStr(LPort)));
          if (LMutex <> 0) then
          begin
            try
              LDone := false;

              LWindow := GetTopWindow(0);
              SetLength(LWindowText, Succ(GetWindowTextLength(LWindow)));
              if (GetWindowText(LWindow, @LWindowText[1], Length(LWindowText)) <> 0) then
                LDone := (Trim(LWindowText) = CWindowName + IntToStr(LPort));

              while ((GetNextWindow(LWindow, GW_HWNDNEXT) <> 0) and not(LDone)) do
              begin
                LWindow := GetNextWindow(LWindow, GW_HWNDNEXT);
                SetLength(LWindowText, Succ(GetWindowTextLength(LWindow)));
                if (GetWindowText(LWindow, @LWindowText[1], Length(LWindowText)) <> 0) then
                  LDone := (Trim(LWindowText) = CWindowName + IntToStr(LPort));
              end;

              if LDone then
                PostMessage(LWindow, CQuitApplication, 0, 0);
            finally
              CloseHandle(LMutex);
            end;
          end;

          raise Exception.Create('');
        end;
      end
      else
      begin
        if (FErrorCode = CErrorUnknown) then
          FErrorCode := CErrorCOMPort;

        raise Exception.Create('');
      end;
    end
    else
    begin
      if (FErrorCode = CErrorUnknown) then
        FErrorCode := CErrorHelp;

      raise Exception.Create('');
    end;
  except
  // catch all final exceptions
  end;
end;

destructor TMWgpsMessageHandler.Destroy;
var
  LMsg : TMsg;
begin
  if (FCOMport <> nil) and (FGPSdata <> nil) then
  begin
    while FInWrite do
    begin
      if PeekMessage(LMsg, 0, 0, 0, PM_REMOVE) then
      begin
        TranslateMessage(LMsg);
        DispatchMessage(LMsg);
      end;
    end;

    DeallocateHWnd(FHandle);
    CloseHandle(FMutex);

    Flush(FFile);
    CloseFile(FFile);

    FGPSdata.Free;
    FGPSdata := nil;

    if (FWriteLog) then
    begin
      Flush(FLogFile);
      CloseFile(FLogFile);
    end;

    FCOMport.Free;
    FCOMport := nil;

    if not(FGPSOnly) then
      CloseMWconnIO(FMWconnFile, FMWconnIO);

    FCriticalSection.Free;
    FCriticalSection := nil;
  end;

  inherited Destroy;
end;

procedure TMWgpsMessageHandler.DoRMCdata(const ASender : TObject; const ATalkerID : String; const AData: TRMCdata);
  function ParseDate(const AString: String): String;
  var
    LDay   : String;
    LMonth : String;
    LYear  : String;
  begin
    LDay   := Copy(AString, 1, 2);
    LMonth := Copy(AString, 3, 2);
    LYear  := Copy(AString, 5, 2);

    Result := LDay + '.' + LMonth + '.' + LYear;
  end;

  function ParseTime(const AString : String) : String;
  var
    LHour   : String;
    LMinute : String;
    LSecond : String;
  begin
    LHour    := Copy(AString, 1, 2);
    LMinute  := Copy(AString, 3, 2);
    LSecond  := Copy(AString, 5, 2);

    Result := LHour + ':' + LMinute + ':' + LSecond;
  end;

  function ParseValidity(const AString: String): Boolean;
  begin
    Result := false;

    if (Length(AString) > 0) then
    begin
      case AString[1] of
        'A' : Result := true;
        'V' : Result := false;
      end;
    end;
  end;

var
  LCID       : String;
  LDone      : Boolean;
  LLAC       : String;
  LLatitude  : String;
  LLine      : String;
  LLongitude : String;
  LPLMN      : String;
  LSignal    : String;
begin
  LCID       := '';
  LLAC       := '';
  LLatitude  := '';
  LLine      := '';
  LLongitude := '';
  LPLMN      := '';
  LSignal    := '';

  if (FStarted and not(FQuit)) then
  begin
    FInWrite := true;
    try
      FCriticalSection.Enter;
      try
        if ParseValidity(AData.Status) then
        begin
          if not(FGPSOnly) then
          begin
            LCID    := Trim(FMWconnIO^.CID);
            LLAC    := Trim(FMWconnIO^.LAC);
            LPLMN   := Trim(FMWconnIO^.PLMN);
            LSignal := IntToStr(FMWconnIO^.Signal_DBM);
          end;

          LLatitude  := AData.Latitude + AData.Lat_NorthSouth;
          LLongitude := AData.Longitude + AData.Lon_EastWest;

          LDone := FLogAlways;
          if not(LDone) then
            LDone := (LLatitude <> FLatitude) or (LLongitude <> FLongitude);
          if (not(LDone) and not(FGPSOnly)) then
          begin
            LDone := (LSignal <> FSignal);
            if (not(LDone) and FNetworkInfo) then
              LDone := ((LCID <> FCID) or (LLAC <> FLAC) or (LPLMN <> FPLMN));
          end;

          if LDone then
          begin
            LLine := '{' + ParseDate(AData.Date) + ';' + ParseTime(AData.UTC) + ';' +
                     LLatitude + ';' + LLongitude;
            if not(FGPSOnly) then
            begin
              LLine := LLine + ';' + LSignal;
              if FNetworkInfo then
                LLine := LLine + ';' + LPLMN + ';' + LLAC + ';' + LCID;
            end;
            LLine := LLine + '}';

            WriteLn(FFile, LLine);
            Flush(FFile);
            WriteLn(LLine);

            FCID       := LCID;
            FLAC       := LLAC;
            FLatitude  := LLatitude;
            FLongitude := LLongitude;
            FPLMN      := LPLMN;
            FSignal    := LSignal;
          end;
        end;
      finally
        FCriticalSection.Leave;
      end;
    finally
      FInWrite := false;
    end;
  end;
end;

procedure TMWgpsMessageHandler.DoSetupConnection(const ASender : TObject; const ACOMhandle: THandle; var AConfig: TCommConfig);
  function GetBaudRate(const ADefaultBaudRate : LongInt) : LongInt;
  var
    LDone  : Boolean;
    LIndex : LongInt;
    LParam : String;
  begin
    Result := - 1;

    LDone := false;
    for LIndex := 1 to Pred(ParamCount) do
    begin
      LParam := AnsiLowerCase(Trim(ParamStr(LIndex)));

      LDone := (LParam = CBaudDirectiveA);
      if not(LDone) then
        LDone := (LParam = CBaudDirectiveB);

      if LDone then
      begin
        LDone := TryStrToInt(ParamStr(Succ(LIndex)), Result);

        if LDone then
          Break;
      end;
    end;

    if not(LDone) then
      Result := ADefaultBaudRate;

    WriteLn('BAUD      = ' + IntToStr(Result));
  end;
begin
  AConfig.dcb.BaudRate := GetBaudRate(AConfig.dcb.BaudRate);

//!!! maybe add some more configurations
end;

procedure TMWgpsMessageHandler.HandleMessages(var AMessage: TMessage);
begin
  case AMessage.Msg of
    CQuitApplication :
    begin
      if (FCOMport <> nil) then
        FCOMport.CloseConnection;

      FErrorCode := CErrorTerminate;
      FQuit      := true;
    end;
  else
    DefWindowProc(FHandle, AMessage.Msg, AMessage.wParam, AMessage.lParam);
  end;
end;

procedure TMWgpsMessageHandler.MessageLoop;
var
  LMsg : TMsg;
begin
  FQuit    := false;
  FStarted := true;
  repeat
    if PeekMessage(LMsg, 0, 0, 0, PM_REMOVE) then
    begin
      TranslateMessage(LMsg);
      DispatchMessage(LMsg);
    end;
  until FQuit;
end;

procedure TMWgpsMessageHandler.DoWriteLine(const ASender : TObject; const ALine: String);
begin
{$IF DEFINED(DEBUG_MODE)}
  if FStarted then
    WriteLn('    ' + ALine);
{$IFEND DEFINED(DEBUG_MODE)}
end;

procedure TMWgpsMessageHandler.DoWriteLog(const ASender : TObject; const ALine : String);
begin
  if (FStarted and FWriteLog) then
  begin
    WriteLn(FLogFile, '[' + DateTimeToStr(Now) + '] ' + ALine);
    Flush(FLogFile);
  end;
end;

end.
