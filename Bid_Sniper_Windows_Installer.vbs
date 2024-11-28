Dim shell, fso, tempDir, profilePath, dropboxUrl, zipFile, extractPath, fullExtractPath, logFile

' Initialize objects
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Expand environment variables
tempDir = shell.ExpandEnvironmentStrings("%TEMP%")
profilePath = shell.ExpandEnvironmentStrings("%USERPROFILE%")

' Set paths
dropboxUrl = "https://dl.dropboxusercontent.com/scl/fi/0tx8dtk5iqkyp8g5iebk7/Bid_Sniper_win32.zip?rlkey=izl1nt0ithhhmx7vvh00c4n68&dl=1&raw=1"
zipFile = tempDir & "\Bid_Sniper.zip"
extractPath = profilePath
fullExtractPath = profilePath & "\Bid_Sniper"
logFile = tempDir & "\download_extract_log.txt"

' Delete log file if it exists
If fso.FileExists(logFile) Then fso.DeleteFile logFile, True

' Check if the script is running as administrator
Function IsAdmin()
    Dim adminStatus
    
    ' Run the net session command and check its exit code
    adminStatus = shell.Run("net session", 0, True)
    
    ' If the command was successful (exit code 0), return True, else False
    If adminStatus = 0 Then
        IsAdmin = True
    Else
        IsAdmin = False
    End If
End Function

Sub ElevateIfNotAdmin()
    ' Check if the script is running as an administrator
    If Not IsAdmin() Then
        CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """", "", "runas", 1
        WScript.Quit
    End If
End Sub

Call ElevateIfNotAdmin()

Sub DisplayMessage(message)
    MsgBox message
End Sub

' Function to check for errors by reading the log file
Function CheckForErrors()
    If fso.FileExists(logFile) Then
        Dim logFileContent, logContent
        Set logFileContent = fso.OpenTextFile(logFile, 1, False)
        logContent = logFileContent.ReadAll
        logFileContent.Close
        
        ' Check if log contains "Exception" or any typical error message
        If InStr(logContent, "Exception") > 0 Or InStr(logContent, "Error") > 0 Then
            CheckForErrors = True
        Else
            CheckForErrors = False
        End If
    Else
        CheckForErrors = True
    End If
End Function

Sub KillBidSniperProcesses()
    Dim objWMIService, colProcesses, objProcess, scriptName, currentPID

    On Error Resume Next

    ' Get the current script's name
    scriptName = WScript.ScriptName

    ' Connect to WMI service
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    If Err.Number <> 0 Then
        MsgBox "Error: Unable to connect to WMI service. Ensure WMI is enabled and you have administrative privileges.", vbCritical
        Exit Sub
    End If

    ' Retrieve the current script's PID
    currentPID = -1
    Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'wscript.exe' OR Name = 'cscript.exe'")
    For Each objProcess In colProcesses
        If InStr(LCase(objProcess.CommandLine), LCase(scriptName)) > 0 Then
            currentPID = objProcess.ProcessId
            Exit For
        End If
    Next

    ' If the current PID could not be determined, exit safely
    If currentPID = -1 Then
        MsgBox "Error: Unable to determine the current script's process ID.", vbCritical
        Exit Sub
    End If

    ' Query for "Electron" processes and filter by CommandLine
    Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'electron.exe'")
    If Err.Number <> 0 Then
        MsgBox "Error: Unable to query processes. Ensure you have administrative privileges.", vbCritical
        Exit Sub
    End If

    For Each objProcess In colProcesses
        ' Check if "Bid Sniper" is in the CommandLine and exclude the current script process
        If objProcess.ProcessId <> currentPID And InStr(LCase(objProcess.CommandLine), "bid sniper") > 0 Then
            objProcess.Terminate
        End If
    Next

    ' Clean up objects
    Set colProcesses = Nothing
    Set objWMIService = Nothing

    On Error GoTo 0
End Sub

Sub DownloadAndExtract()
    Dim downloadAndExtractScript, psCommand
    downloadAndExtractScript = _
        "param($url, $zipFile, $extractPath, $fullExtractPath)" & vbCrLf & _
        "if (Test-Path $zipFile) { Remove-Item $zipFile -Force }" & vbCrLf & _
        "if (Test-Path $fullExtractPath) { Remove-Item $fullExtractPath -Recurse -Force }" & vbCrLf & _
        "Start-BitsTransfer -Source $url -Destination $zipFile" & vbCrLf & _
        "Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force" & vbCrLf & _
        "New-NetFirewallRule -DisplayName 'Allow Bid Sniper App' -Direction Inbound -Program '" & fullExtractPath & "\node_modules\electron\dist\electron.exe' -Action Allow -Profile Any"

    psCommand = "powershell -NoProfile -Command " & _
                """& {" & downloadAndExtractScript & "} -url '" & dropboxUrl & "' -zipFile '" & zipFile & "' -extractPath '" & extractPath & "' -fullExtractPath '" & fullExtractPath & "' 2>&1 | Out-File -FilePath '" & logFile & "' -Encoding utf8"""

    shell.Run psCommand, 1, True
End Sub

Function ReadLogFile()
    Dim logFileContent, logContent
    If fso.FileExists(logFile) Then
        On Error Resume Next
        Set logFileContent = fso.OpenTextFile(logFile, 1, False)
        If Not logFileContent.AtEndOfStream Then
            logContent = logFileContent.ReadAll
        Else
            logContent = ""
        End If
        logFileContent.Close
        On Error GoTo 0
        ReadLogFile = logContent
    Else
        ReadLogFile = "An unexpected error occurred: the log file was not created."
    End If
End Function

Function InstallationSuccessful()
    InstallationSuccessful = fso.FileExists(fullExtractPath & "\node.exe")
End Function

Sub CreateLaunchScript()
    Dim launchScriptPath, launchScript
    launchScriptPath = fullExtractPath & "\LaunchBidSniper.vbs"
    
    Set launchScript = fso.CreateTextFile(launchScriptPath, True)
    launchScript.WriteLine "Set WshShell = CreateObject(""WScript.Shell"")"
    launchScript.WriteLine "WshShell.Run ""cmd /c cd /d """"" & fullExtractPath & """"" && set NODE_ENV=production && """"" & fullExtractPath & "\node.exe"""" """"" & fullExtractPath & "\node_modules\electron\cli.js"""" """"" & fullExtractPath & """"""", 0, False"
    launchScript.Close
End Sub

Sub CreateDesktopShortcut()
    Dim shortcutPath, shortcut, iconPath
    shortcutPath = shell.SpecialFolders("Desktop") & "\Bid Sniper.lnk"
    iconPath = fullExtractPath & "\img\icons\win\icon.ico"
    
    ' Check if shortcut exists and delete if it does
    If fso.FileExists(shortcutPath) Then fso.DeleteFile shortcutPath, True
    
    Set shortcut = shell.CreateShortcut(shortcutPath)
    With shortcut
        .TargetPath = fullExtractPath & "\LaunchBidSniper.vbs"
        .WorkingDirectory = fullExtractPath
        .Arguments = ""
        .IconLocation = iconPath
        .Save
    End With
End Sub

Call KillBidSniperProcesses()

' Main script execution
DisplayMessage "This script will now download and install Bid Sniper and create a desktop shortcut for it. PowerShell will open and close during this process, which is normal."

Call DownloadAndExtract()

Dim logContent
logContent = ReadLogFile()

If Not CheckForErrors() And InstallationSuccessful() Then
    Call CreateLaunchScript()
    Call CreateDesktopShortcut()
    DisplayMessage "Bid Sniper is now installed. You can launch it from the desktop shortcut."
Else
    DisplayMessage "An error occurred during the installation: " & vbCrLf & logContent
End If