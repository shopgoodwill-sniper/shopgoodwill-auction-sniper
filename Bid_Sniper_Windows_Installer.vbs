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

Sub KillRunningAppProcesses()
    Dim objWMIService, colProcesses, objProcess, exePath

    On Error Resume Next

    ' Connect to WMI service
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    If Err.Number <> 0 Then
        MsgBox "Error: Unable to connect to WMI service. Ensure WMI is enabled and you have administrative privileges.", vbCritical
        Exit Sub
    End If

    ' Query for all processes
    Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process")
    If Err.Number <> 0 Then
        MsgBox "Error: Unable to query processes. Ensure you have administrative privileges.", vbCritical
        Exit Sub
    End If

    ' Loop through all processes and terminate those in "\Bid_Sniper\" path
    For Each objProcess In colProcesses
        exePath = ""
        On Error Resume Next
        exePath = objProcess.ExecutablePath
        On Error GoTo 0

        If Not IsNull(exePath) And exePath <> "" Then
            If InStr(LCase(exePath), "\bid_sniper\") > 0 Then
                On Error Resume Next
                objProcess.Terminate
                If Err.Number <> 0 Then
                    MsgBox "Error terminating process: " & Err.Description, vbExclamation
                    Err.Clear
                End If
                On Error GoTo 0
            End If
        End If
    Next

    ' Clean up objects
    Set colProcesses = Nothing
    Set objWMIService = Nothing

    On Error GoTo 0
End Sub

Sub DownloadAndExtract()
    Dim downloadAndExtractScript, psCommand
    
    ' Escape any single quotes in the paths
    Dim safeZipFile, safeExtractPath, safeFullExtractPath, safeLogFile
    safeZipFile = Replace(zipFile, "'", "''")
    safeExtractPath = Replace(extractPath, "'", "''")
    safeFullExtractPath = Replace(fullExtractPath, "'", "''")
    safeLogFile = Replace(logFile, "'", "''")
    
    downloadAndExtractScript = _
        "param($url, $zipFile, $extractPath, $fullExtractPath)" & vbCrLf & _
        "$ErrorActionPreference = 'Stop'" & vbCrLf & _
        "Write-Host 'Using paths:' -ForegroundColor Cyan" & vbCrLf & _
        "Write-Host 'Zip file: ' $zipFile" & vbCrLf & _
        "Write-Host 'Extract path: ' $extractPath" & vbCrLf & _
        "Write-Host 'Full extract path: ' $fullExtractPath" & vbCrLf & _
        "try {" & vbCrLf & _
        "    # Check and remove zip file if it exists" & vbCrLf & _
        "    if (Test-Path -Path $zipFile) {" & vbCrLf & _
        "        Remove-Item -Path $zipFile -Force" & vbCrLf & _
        "        Write-Host 'Removed existing zip file'" & vbCrLf & _
        "    }" & vbCrLf & _
        "    # Check and remove extract directory if it exists" & vbCrLf & _
        "    if (Test-Path -Path $fullExtractPath) {" & vbCrLf & _
        "        Remove-Item -Path $fullExtractPath -Recurse -Force" & vbCrLf & _
        "        Write-Host 'Removed existing extract directory'" & vbCrLf & _
        "    }" & vbCrLf & _
        "    Write-Host 'Downloading file...' -ForegroundColor Green" & vbCrLf & _
        "    Start-BitsTransfer -Source $url -Destination $zipFile" & vbCrLf & _
        "    Write-Host 'Download complete, extracting...' -ForegroundColor Green" & vbCrLf & _
        "    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force" & vbCrLf & _
        "    Write-Host 'Creating firewall rule...' -ForegroundColor Green" & vbCrLf & _
        "    New-NetFirewallRule -DisplayName 'Allow Bid Sniper App' -Direction Inbound -Program (Join-Path $fullExtractPath 'node_modules\electron\dist\electron.exe') -Action Allow -Profile Any" & vbCrLf & _
        "} catch {" & vbCrLf & _
        "    Write-Host 'Error:' $_.Exception.Message -ForegroundColor Red" & vbCrLf & _
        "    Write-Host 'Stack trace:' $_.ScriptStackTrace -ForegroundColor Red" & vbCrLf & _
        "    exit 1" & vbCrLf & _
        "}"

    psCommand = "powershell -NoProfile -ExecutionPolicy Bypass -Command " & _
                """& {" & downloadAndExtractScript & "} " & _
                "-url '" & dropboxUrl & "' " & _
                "-zipFile '" & safeZipFile & "' " & _
                "-extractPath '" & safeExtractPath & "' " & _
                "-fullExtractPath '" & safeFullExtractPath & "' " & _
                "| Out-File -FilePath '" & safeLogFile & "' -Encoding utf8; if ($LASTEXITCODE -ne 0) { exit 1 }"""

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

Call KillRunningAppProcesses()

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