program MWgps;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  MWpasU,
  MWgpsU,
  GPSdataU,
  COMportU;

var
  VMWgps : TMWgpsMessageHandler;

begin
  WriteLn(MWgpsU.Name + ' ' + MWgpsU.Version + ' [' + MWgpsU.ReleaseName + ' (' + MWgpsU.ReleaseDate + ')]');
  WriteLn('(C) ' + MWgpsU.CopyrightYear + ' ' + MWgpsU.CopyrightOwner);
  WriteLn('');
  WriteLn('USING:');
  WriteLn(COMportU.Name + ' ' + COMportU.Version + ' [' + COMportU.ReleaseName + ' (' + COMportU.ReleaseDate + ')]');
  WriteLn(GPSdataU.Name + ' ' + GPSdataU.Version + ' [' + GPSdataU.ReleaseName + ' (' + GPSdataU.ReleaseDate + ')]');
  WriteLn(MWpasU.Name + ' ' + MWpasU.Version + ' [' + MWpasU.ReleaseName + ' (' + MWpasU.ReleaseDate + ')]');
  WriteLn('');
  WriteLn('(compatible with MWconn ' + ProgramVersionToString(MWpasU.MWconnIOMinVersion) + ' to ' + ProgramVersionToString(MWpasU.MWconnIOMaxVersion) + ')');
  WriteLn('');

  VMWgps := TMWgpsMessageHandler.Create;
  try
    WriteLn('');
    case VMWgps.ErrorCode of
      CErrorOK        : WriteLn('INFO: EXECUTING');
      CErrorHelp      : WriteLn('INFO: HELP REQUESTED');
      CErrorQuit      : WriteLn('INFO: TERMINATION OF ANOTHER INSTANCE REQUESTED');
      CErrorSection   : WriteLn('ERROR: CRITICAL SECTION COULT NOT BE INITIALIZED');
      CErrorMWconn    : WriteLn('ERROR: MWconn ACCESS COULT NOT BE INITIALIZED');
      CErrorCOMPort   : WriteLn('ERROR: COM-PORT COULD NOT BE INITIALIZED');
      CErrorLogFolder : WriteLn('ERROR: GPS-LOG-FOLDER COULD NOT BE ACCESSED');
      CErrorLogFile   : WriteLn('ERROR: GPS-LOG-FILE COULD NOT BE ACCESSED');
      CErrorGPS       : WriteLn('ERROR: GPS COULD NOT BE INITIALIZED');
      CErrorFolder    : WriteLn('ERROR: LOG-FOLDER COULD NOT BE ACCESSED');
      CErrorFile      : WriteLn('ERROR: LOG-FILE COULD NOT BE ACCESSED');
      CErrorMutex     : WriteLn('ERROR: MUTEX COULD NOT BE INITIALIZED');
      CErrorWindow    : WriteLn('ERROR: WINDOWS COULD NOT BE INITIALIZED');
    else
      WriteLn('ERROR: UNKNOWN ERROR');
    end;

    WriteLn('');
    if (VMWgps.ErrorCode = CErrorOK) then
    begin
      VMWgps.MessageLoop;

      WriteLn('');
      case VMWgps.ErrorCode of
        CErrorTerminate : WriteLn('INFO: TERMINATION REQUESTED BY ANOTHER INSTANCE');
      else
        WriteLn('INFO: TERMINATED FOR AN UNKNOWN REASON');
      end;
    end
    else
    begin
      if (VMWgps.ErrorCode <> CErrorQuit) then
      begin
        WriteLn('HELP:');
        WriteLn('> ' + ExtractFileName(ParamStr(0)) + ' ' +
                '[' + CAppendDirectiveA + '|' + CAppendDirectiveB + '] ' +
                '[' + CGPSOnlyDirectiveA + '|' + CGPSOnlyDirectiveB + '] ' +
                '[' + CHelpDirectiveA + '|' + CHelpDirectiveB + '] ' +
                '[' + CLogAlwaysDirectiveA + '|' + CLogAlwaysDirectiveB + '] ' +
                '[' + CNetworkDirectiveA + '|' + CNetworkDirectiveB + '] ' +
                '[' + CQuitDirectiveA + '|' + CQuitDirectiveB + '] ' +
                '[' + CReadOnlyDirectiveA + '|' + CReadOnlyDirectiveB + '] ' +
                '[' + CBaudDirectiveA + '|' + CBaudDirectiveB + ' BAUDRATE] ' +
                '[' + CFileDirectiveA + '|' + CFileDirectiveB + ' FILENAME] ' +
                '[' + CInstanceDirectiveA + '|' + CInstanceDirectiveB + ' INSTANCENAME] ' +
                '[' + CWriteLogDirectiveA + '|' + CWriteLogDirectiveB + ' FILENAME] ' +
                CPortDirectiveA + '|' + CPortDirectiveB + ' PORTNUMBER');
        WriteLn('');

        WriteLn('[' + CAppendDirectiveA + '|' + CAppendDirectiveB + ']:');
        WriteLn('  Append data instead of recreating log file.');
        WriteLn('  FILE operand has to be set (set file must exist).');
        WriteLn('');
        WriteLn('[' + CGPSOnlyDirectiveA + '|' + CGPSOnlyDirectiveB + ']:');
        WriteLn('  Only log GPS position data.');
        WriteLn('  Reduces logging output from a 5-tupel to a 4-tupel.');
        WriteLn('');
        WriteLn('[' + CHelpDirectiveA + '|' + CHelpDirectiveB + ']:');
        WriteLn('  Show this help.');
        WriteLn('');
        WriteLn('[' + CLogAlwaysDirectiveA + '|' + CLogAlwaysDirectiveB + ']:');
        WriteLn('  Save every log entry even if the data (except the time) have not changed.');
        WriteLn('');
        WriteLn('[' + CNetworkDirectiveA + '|' + CNetworkDirectiveB + ']:');
        WriteLn('  Additionally log network positioning information (PLMN, LAC, CID).');
        WriteLn('  Enhances logging output from a 5-tupel to an 8-tupel.');
        WriteLn('');
        WriteLn('[' + CQuitDirectiveA + '|' + CQuitDirectiveB + ']:');
        WriteLn('  Terminate another instance which listens on the given port number.');
        WriteLn('');
        WriteLn('[' + CReadOnlyDirectiveA + '|' + CReadOnlyDirectiveB + ']:');
        WriteLn('  Open COM port in read-only mode.');
        WriteLn('');
        WriteLn('[' + CBaudDirectiveA + '|' + CBaudDirectiveB + ' BAUDRATE]:');
        WriteLn('  Set baud rate of COM port to given value.');
        WriteLn('');
        WriteLn('[' + CFileDirectiveA + '|' + CFileDirectiveB + ' FILENAME]:');
        WriteLn('  Set log file name to given value.');
        WriteLn('  If this is not set, the log is written to: logs\DATE_TIME.log');
        WriteLn('');
        WriteLn('[' + CInstanceDirectiveA + '|' + CInstanceDirectiveB + ' INSTANCENAME]:');
        WriteLn('  Set the instance name of the preferred MWconn instance (since MWconn 4.5).');
        WriteLn('');
        WriteLn('[' + CWriteLogDirectiveA + '|' + CWriteLogDirectiveB + ' FILENAME]:');
        WriteLn('  Set GPS-log file name to given value.');
        WriteLn('  If this is not set, no GPS-log is going to be written.');
        WriteLn('');
        WriteLn(CPortDirectiveA + '|' + CPortDirectiveB + ' PORTNUMBER:');
        WriteLn('  Set COM port number of GPS receiver.');
        WriteLn('');

        WriteLn('This program collects GPS information and combines them with the current GPRS or UMTS signal strength.');
        WriteLn('The GPS data are read directly from an attached GPS receiver.');
        WriteLn('A GPS receiver that supports the NMEA 0183 format is required.');
        WriteLn('The GPRS/UMTS signal strength is read from Markus B. Weber''s MWconn application.');
        WriteLn('');

        WriteLn('The application outputs data in the following form:');
        WriteLn('{DATE;TIME;LATITUDE;LONGITUDE;SIGNALSTRENGTH}');
        WriteLn('');
        WriteLn('If the GPSONLY operand is set, the output is in this form:');
        WriteLn('{DATE;TIME;LATITUDE;LONGITUDE}');
        WriteLn('');
        WriteLn('If the NETWORK operand is set, the output is in this form:');
        WriteLn('{DATE;TIME;LATITUDE;LONGITUDE;SIGNALSTRENGTH;PLMN;LAC;CID}');
        WriteLn('');

        WriteLn('DATE           is UTC');
        WriteLn('TIME           is UTC');
        WriteLn('LATITUDE       is followed by N(orth) or S(outh)');
        WriteLn('LONGITUDE      is followed by E(ast) or W(est)');
        WriteLn('SIGNALSTRENGTH is in DBM');
        WriteLn('PLMN           is the Public Land Mobile Network number');
        WriteLn('LAC            is the Location Area Code');
        WriteLn('CID            is the Cell IDentifier');
        WriteLn('');
      end;
    end;
  finally
    VMWgps.Free;
  end;
end.
