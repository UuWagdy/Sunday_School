' Sunday School LAN Thin Client - Change Server Address Utility
Option Explicit

Dim objFSO, objShell, scriptDir, configFile, currentUrl, fileStream, newUrl

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

scriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
configFile = objFSO.BuildPath(scriptDir, "server_url.txt")

currentUrl = "192.168.1.100:5050"

If objFSO.FileExists(configFile) Then
    On Error Resume Next
    Set fileStream = objFSO.OpenTextFile(configFile, 1, False, -2)
    If Not fileStream.AtEndOfStream Then
        currentUrl = Trim(fileStream.ReadLine)
    End If
    fileStream.Close
    On Error GoTo 0
End If

newUrl = InputBox("يرجى إدخال عنوان أو IP جهاز السيرفر الرئيسي على الشبكة:" & vbCrLf & vbCrLf & _
                  "أمثلة شائعة:" & vbCrLf & _
                  "- 192.168.1.100:5050" & vbCrLf & _
                  "- http://192.168.1.100:5050" & vbCrLf & _
                  "- http://server-pc:5050", _
                  "تغيير عنوان خادم مدارس الأحد", currentUrl)

newUrl = Trim(newUrl)

If Len(newUrl) > 0 Then
    If InStr(1, newUrl, "http://", 1) = 0 And InStr(1, newUrl, "https://", 1) = 0 Then
        newUrl = "http://" & newUrl
    End If
    
    On Error Resume Next
    Set fileStream = objFSO.CreateTextFile(configFile, True, False)
    If Err.Number <> 0 Then
        MsgBox "تعذر حفظ الملف. تأكد من تشغيل الأداة بصلاحيات مناسبة." & vbCrLf & Err.Description, vbCritical, "خطأ"
    Else
        fileStream.WriteLine newUrl
        fileStream.Close
        MsgBox "تم تحديث عنوان السيرفر بنجاح إلى:" & vbCrLf & newUrl, vbInformation, "مدارس الأحد"
    End If
    On Error GoTo 0
End If
