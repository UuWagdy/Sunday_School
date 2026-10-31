"""Exercise dispatch, CLI arguments and safe replacement using disposable fake tools.

Does not build or install the actual apps. Also compiles a tiny real Inno version probe.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

CENTER = Path(__file__).resolve().parents[1]
ROOT = CENTER.parent
TEMP = Path(tempfile.mkdtemp(prefix='build center test '))
POWERSHELL = 'powershell.exe'
HIDDEN = subprocess.CREATE_NO_WINDOW


def command(arguments, expected=0, env=None):
    result = subprocess.run([str(a) for a in arguments], cwd=TEMP, env=env,
        capture_output=True, encoding='utf-8', errors='replace', creationflags=HIDDEN)
    assert result.returncode == expected, (arguments, result.returncode, result.stdout[-5000:], result.stderr[-2000:])
    return result.stdout


def main():
    count = 0
    def passed(message):
        nonlocal count
        count += 1
        print('PASS: ' + message, flush=True)

    wrappers = sorted(CENTER.glob('0*.bat'))
    expected = [1, 1, 1, 1, 2, 2, 4]
    assert len(wrappers) == 7
    for wrapper, jobs in zip(wrappers, expected):
        output = command(['cmd.exe', '/d', '/c', 'call', wrapper, '--plan'])
        assert output.count(' | version ') == jobs, (wrapper, output)
    passed('all seven BAT files dispatch correctly from an unrelated working directory')

    mock = TEMP / 'mock.py'
    mock.write_text(r'''
import json, os, sys, zipfile
from pathlib import Path
tool, *args = sys.argv[1:]
root = Path.cwd()
with open(os.environ['BUILD_CENTER_TEST_COMMANDS'], 'a', encoding='utf-8') as log:
    log.write(json.dumps({'tool':tool,'args':args,'cwd':str(root)})+'\n')
if tool == 'flutter' and args[:2] == ['build','apk']:
    if os.environ.get('BUILD_CENTER_TEST_FAIL') == 'android':
        print('simulated Android compiler failure', file=sys.stderr)
        sys.exit(42)
    apk = root/'build/app/outputs/flutter-apk/app-release.apk'
    apk.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(apk,'w') as z:
        z.writestr('AndroidManifest.xml', 'mock manifest')
        z.writestr('classes.dex', 'mock dex')
        for abi in ['armeabi-v7a','arm64-v8a','x86_64']:
            z.writestr(f'lib/{abi}/libapp.so', b'a'*(1024*1024))
elif tool == 'dotnet':
    Path(args[args.index('-o')+1]).mkdir(parents=True,exist_ok=True)
elif tool == 'iscc':
    directory = Path(next(a[2:] for a in args if a.startswith('/O')))
    name = next(a[2:] for a in args if a.startswith('/F'))
    directory.mkdir(parents=True,exist_ok=True)
    (directory/(name+'.exe')).write_bytes(b'MZ'+b'b'*(2*1024*1024))
print(tool+' mock completed')
''', encoding='utf-8')
    tools = {}
    for tool in ['flutter', 'dotnet', 'iscc']:
        path = TEMP / (tool+'.cmd')
        path.write_text(f'@echo off\n"{sys.executable}" "{mock}" {tool} %*\nexit /b %errorlevel%\n', encoding='ascii')
        tools[tool] = str(path)

    roots = []
    for name, version, backend, manager, iss in [
        ('Sunday School app', '4.5.6+12', 'SundaySchool.SyncServer', 'SundaySchoolServerManager', 'SundaySchoolSetup.iss'),
        ('Church Membership app', '7.8.9+99', 'AbonaFlemoon.SyncServer', 'AbonaFlemoonServerManager', 'AbonaFlemoonSetup.iss'),
    ]:
        root = TEMP/name
        roots.append(root)
        (root/'installer/downloads').mkdir(parents=True)
        (root/'pubspec.yaml').write_text('version: '+version+'\n',encoding='utf-8')
        for project in [backend,manager]:
            (root/project).mkdir()
            (root/project/(project+'.csproj')).write_text('<Project/>')
        (root/'installer'/iss).write_text('; fake installer')
        (root/'installer/validate-server-payload.ps1').write_text(
            'param($BackendRoot,$ManagerRoot,$PostgresRoot)\n'
            'if (-not (Test-Path -LiteralPath $BackendRoot) -or -not (Test-Path -LiteralPath $ManagerRoot)) { throw "publish output missing" }\n')
        # Genuine bundled redistributables let the real prerequisite signature check run.
        for arch in ['x64','x86']:
            import shutil
            shutil.copyfile(ROOT/f'installer/downloads/VC_redist.{arch}.exe', root/f'installer/downloads/VC_redist.{arch}.exe')
    destination = TEMP/'Unified Output'
    config = TEMP/'settings.json'
    config.write_text(json.dumps({'SundaySchoolRoot':str(roots[0]),'ChurchMembershipRoot':str(roots[1]),
        'OutputDirectory':str(destination),'FlutterPath':tools['flutter'],'DotnetPath':tools['dotnet'],'InnoSetupPath':tools['iscc']}),encoding='utf-8')
    receipt = TEMP/'commands.jsonl'
    env = dict(os.environ, BUILD_CENTER_TEST_COMMANDS=str(receipt))
    arguments = [POWERSHELL,'-NoProfile','-ExecutionPolicy','Bypass','-File',CENTER/'_tools/build.ps1',
        '-Target','everything','-ConfigPath',config,'-NoOpenOutput']
    command(arguments,env=env)
    names = ['SundaySchool_Setup.exe','SundaySchool_Android.apk','ChurchMembership_Setup.exe','ChurchMembership_Android.apk']
    assert all((destination/name).is_file() for name in names)
    records = [json.loads(line) for line in receipt.read_text().splitlines()]
    compiler = [r for r in records if r['tool']=='iscc']
    assert len(compiler)==2
    assert '/DMyAppVersion=4.5.6' in compiler[0]['args']
    assert '/DMyAppVersion=7.8.9' in compiler[1]['args']
    assert any('Sunday School' in a for a in compiler[0]['args'])
    assert sum(r['args']==['pub','get'] for r in records if r['tool']=='flutter')==2
    assert all(r['args'][0]!='analyze' for r in records if r['tool']=='flutter')
    info = json.loads((destination/'BUILD_INFO.json').read_text(encoding='utf-8-sig'))
    assert info['SundaySchool_Setup.exe']['version']=='4.5.6+12'
    assert info['ChurchMembership_Android.apk']['version']=='7.8.9+99'
    passed('complete four-artifact pipeline, paths with spaces, automatic versions, checksums and shared Output')

    hashes = {name:hashlib.sha256((destination/name).read_bytes()).hexdigest() for name in names}
    env['BUILD_CENTER_TEST_FAIL']='android'
    command(arguments,expected=1,env=env)
    assert hashes=={name:hashlib.sha256((destination/name).read_bytes()).hexdigest() for name in names}
    passed('a later build failure returns failure and leaves all previous deliverables unchanged')

    # Verify that replacing an existing deliverable works, and that a locked file is preserved.
    core_test = TEMP/'core-test.ps1'
    core_test.write_text('''param($Core,$Folder)
$ErrorActionPreference='Stop'
. $Core
$source=Join-Path $Folder 'new.bin'
$target=Join-Path $Folder 'stable.bin'
[IO.File]::WriteAllText($source,'new')
[IO.File]::WriteAllText($target,'old')
$handle=[IO.File]::Open($target,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
try {
 $failed=$false
 try { Publish-BuildArtifact $source $target | Out-Null } catch { $failed=$true }
 if (-not $failed) { throw 'Expected a locked-output failure' }
} finally { $handle.Dispose() }
if ([IO.File]::ReadAllText($target) -ne 'old') { throw 'Locked output was changed' }
Publish-BuildArtifact $source $target | Out-Null
if ([IO.File]::ReadAllText($target) -ne 'new') { throw 'Stable name was not replaced' }
if (@(Get-ChildItem -LiteralPath $Folder -Filter '*.new' -Force).Count) { throw 'Temporary publication files leaked' }
''',encoding='utf-8')
    command([POWERSHELL,'-NoProfile','-ExecutionPolicy','Bypass','-File',core_test,CENTER/'_tools/Build.Core.ps1',TEMP])
    passed('stable-name replacement, locked-file preservation, and temporary-copy cleanup')

    # Confirm the real compiler accepts version injection and fixed output names.
    probe = TEMP/'version probe.iss'
    probe.write_text('''#ifndef MyAppVersion
 #define MyAppVersion "1.0.0"
#endif
[Setup]
AppName=Build Center Version Probe
AppVersion={#MyAppVersion}
DefaultDirName={tmp}\\VersionProbe
PrivilegesRequired=lowest
VersionInfoVersion={#MyAppVersion}.0
''')
    compile_probe = TEMP/'compile-probe.ps1'
    compile_probe.write_text('''param($Script,$Output)
$ErrorActionPreference='Stop'
& 'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe' /Q /DMyAppVersion=9.8.7 "/O$Output" /FFixedName $Script
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ((Get-Item -LiteralPath (Join-Path $Output 'FixedName.exe')).VersionInfo.ProductVersion.Trim() -ne '9.8.7') { throw 'Injected version was not used' }
''')
    command([POWERSHELL,'-NoProfile','-ExecutionPolicy','Bypass','-File',compile_probe,probe,TEMP/'real compiler output'])
    passed('real Inno Setup compiler accepts injected version, fixed name and output folder with spaces')
    print(f'{count} groups passed. Test files: {TEMP}',flush=True)


if __name__=='__main__': main()
