' Sunday School LAN Thin Client Launcher
' Launches Flutter Web in standalone App Mode (Chromeless window)
Option Explicit

Dim objFSO, objShell, scriptDir, configFile, url, fileStream
Dim chromePaths, browserPath, foundBrowser, i

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

scriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
configFile = objFSO.BuildPath(scriptDir, "server_url.txt")

url = "http://192.168.1.100:5050/"

If objFSO.FileExists(configFile) Then
    On Error Resume Next
    Set fileStream = objFSO.OpenTextFile(configFile, 1, False, -2) ' -2 = System default encoding
    If Not fileStream.AtEndOfStream Then
        url = Trim(fileStream.ReadLine)
    End If
    fileStream.Close
    On Error GoTo 0
End If

If Len(url) = 0 Then
    url = "http://192.168.1.100:5050/"
End If

If InStr(1, url, "http://", 1) = 0 And InStr(1, url, "https://", 1) = 0 Then
    url = "http://" & url
End If

chromePaths = Array( _
    objShell.ExpandEnvironmentStrings("%ProgramFiles%\Google\Chrome\Application\chrome.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"), _
    objShell.ExpandEnvironmentStrings("%LocalAppData%\Google\Chrome\Application\chrome.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"), _
    objShell.ExpandEnvironmentStrings("%LocalAppData%\Microsoft\Edge\Application\msedge.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles%\Supermium\chrome.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%\Supermium\chrome.exe"), _
    objShell.ExpandEnvironmentStrings("%LocalAppData%\Supermium\chrome.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe"), _
    objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%\BraveSoftware\Brave-Browser\Application\brave.exe") _
)

foundBrowser = ""
For i = 0 To UBound(chromePaths)
    If objFSO.FileExists(chromePaths(i)) Then
        foundBrowser = chromePaths(i)
        Exit For
    End If
Next

If foundBrowser <> "" Then
    ' Launch in App Mode (chromeless, native app experience)
    objShell.Run """" & foundBrowser & """ --app=""" & url & """ --start-maximized", 1, False
Else
    ' Fallback to system default browser
    objShell.Run """" & url & """", 1, False
End If
