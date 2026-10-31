"""Collect completed local release builds, check containers, and record SHA256."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import zipfile

ROOT=Path(__file__).resolve().parents[1]


def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):
            h.update(chunk)
    return h.hexdigest()


def main():
    version=re.search(r'^version:\s*(\S+)',(ROOT/'pubspec.yaml').read_text(encoding='utf-8'),re.M)[1]
    name=version.split('+')[0]
    installer=ROOT/f'installer/output/Sunday_School_Setup_v{name}.exe'
    apk=ROOT/'build/app/outputs/flutter-apk/app-release.apk'
    latest_source=max(p.stat().st_mtime for p in (ROOT/'lib').rglob('*.dart'))
    windows_aot=ROOT/'build/windows/x64/runner/Release/data/app.so'
    assert windows_aot.stat().st_mtime>=latest_source,'Windows AOT predates current sources'
    assert installer.stat().st_mtime>=windows_aot.stat().st_mtime,'Recompile installer with the latest Windows AOT payload'
    for artifact in [installer,apk]:
        assert artifact.is_file() and artifact.stat().st_size>1024*1024, f'Missing/empty build: {artifact}'
        assert artifact.stat().st_mtime>=latest_source, f'Build predates current sources: {artifact}'
    with installer.open('rb') as f:
        assert f.read(2)==b'MZ','Installer is not a Windows executable'
    with zipfile.ZipFile(apk) as z:
        assert z.testzip() is None,'APK ZIP CRC check failed'
        names=z.namelist()
        assert 'AndroidManifest.xml' in names
        for abi in ['armeabi-v7a','arm64-v8a','x86_64']:
            assert f'lib/{abi}/libapp.so' in names,f'Missing architecture {abi}'
    target=ROOT/'dist/releases'/name
    target.mkdir(parents=True,exist_ok=True)
    records=[]
    for source,filename in [(installer,installer.name),(apk,f'SundaySchool_v{name}.apk')]:
        dest=target/filename
        shutil.copy2(source,dest)
        digest=sha(dest)
        assert digest==sha(source),'Delivery copy hash mismatch'
        records.append({'file':filename,'bytes':dest.stat().st_size,'sha256':digest})
    payload=ROOT/'installer/payload/server/backend/SundaySchool.SyncServer.dll'
    publish=ROOT/'SundaySchool.SyncServer/bin/Release/net8.0/win-x64/SundaySchool.SyncServer.dll'
    assert sha(payload)==sha(publish),'Server payload is not the latest publish'
    server_sources=[p for p in (ROOT/'SundaySchool.SyncServer').rglob('*.cs') if not {'bin','obj'}.intersection(p.parts)]
    assert payload.stat().st_mtime>=max(p.stat().st_mtime for p in server_sources),'Server publish predates its sources'
    assert installer.stat().st_mtime>=payload.stat().st_mtime,'Installer predates current server payload'
    manifest={'version':version,'artifacts':records,'server_dll_sha256':sha(payload),
              'apk_signing':'existing Android debug key; release mode',
              'windows_aot_sha256':sha(windows_aot),
              'installed_or_device_tested':False,
              'validation_report':'docs/release-1.0.1-validation.md'}
    (target/'release-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (target/'SHA256SUMS.txt').write_text(''.join(f"{r['sha256']}  {r['file']}\n" for r in records),encoding='ascii')
    print(json.dumps(manifest,indent=2))


if __name__=='__main__':
    main()
