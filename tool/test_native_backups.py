"""Exercise both servers against disposable PostgreSQL databases and restore dumps.

Never uses installed app data. Build both .NET servers in Release first.
"""
import base64
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MEMBERSHIP = Path('E:/el odwia/project')
PG = ROOT / 'installer/payload/server/postgresql/bin'
TEMP = Path(tempfile.mkdtemp(prefix='native-backup-regression-'))
HIDDEN = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, creationflags=HIDDEN,
                          stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=180, **kwargs)


def main():
    pg_port = free_port()
    backend = None
    env = dict(os.environ, PGHOST='127.0.0.1', PGPORT=str(pg_port), PGUSER='postgres', PGCLIENTENCODING='UTF8')
    results = []
    def sql(database, text):
        fixture = TEMP/'fixture.sql'
        fixture.write_text(text, encoding='utf-8')
        return subprocess.check_output([str(PG/'psql.exe'), '-h', '127.0.0.1', '-p', str(pg_port),
            '-U', 'postgres', '-d', database, '-v', 'ON_ERROR_STOP=1', '-tA', '-f', str(fixture)],
            env=env, creationflags=HIDDEN).decode('utf-8').strip()
    try:
        run([PG/'initdb.exe', '-D', TEMP/'data', '-U', 'postgres', '-A', 'trust', '--no-locale', '-E', 'UTF8'])
        # pg_ctl's detached child must not inherit captured pipe handles.
        subprocess.run([str(PG/'pg_ctl.exe'), '-D', str(TEMP/'data'), '-l', str(TEMP/'postgres.log'),
            '-o', f'-h 127.0.0.1 -p {pg_port}', '-w', 'start'], check=True, creationflags=HIDDEN,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180)
        for membership in (False, True):
            name = 'membership_backup_test' if membership else 'sunday_backup_test'
            prefix = 'ChurchMembership' if membership else 'SundaySchool'
            run([PG/'createdb.exe', '-h', '127.0.0.1', '-p', pg_port, '-U', 'postgres', name])
            api_port = free_port()
            base = f'http://127.0.0.1:{api_port}'
            state = TEMP / prefix
            archive_dir = state / 'chosen external folder'
            connection = f'Host=127.0.0.1;Port={pg_port};Database={name};Username=postgres'
            server_env = dict(env, PORT=str(api_port), BindLocalOnly='true', DATABASE_URL=connection,
                ConnectionStrings__DefaultConnection=connection, ConnectionStrings__Postgres=connection,
                POSTGRES_BIN=str(PG), BACKUP_SETTINGS_ROOT=str(state), BACKUP_DEFAULT_DIRECTORY=str(state/'default'),
                SqliteSeed__InitialDbPath=str(TEMP/'nonexistent-seed.db'))
            dll = MEMBERSHIP/'AbonaFlemoon.SyncServer/bin/Release/net8.0/ChurchMembership.SyncServer.dll' if membership else ROOT/'SundaySchool.SyncServer/bin/Release/net8.0/SundaySchool.SyncServer.dll'
            headers = {}
            def request(method, path, body=None, expected=200, raw=False, auth=True):
                data = body if isinstance(body, bytes) else json.dumps(body).encode() if body is not None else None
                req = urllib.request.Request(base+path, data=data, method=method,
                    headers={**(headers if auth else {}), 'Content-Type': 'application/octet-stream' if isinstance(body, bytes) else 'application/json'})
                try:
                    with urllib.request.urlopen(req, timeout=120) as response:
                        code, payload = response.status, response.read()
                except urllib.error.HTTPError as error:
                    code, payload = error.code, error.read()
                assert code == expected, (prefix, path, code, expected, payload[:600])
                return payload if raw or not payload or code != 200 else json.loads(payload)
            def start():
                nonlocal backend
                state.mkdir(parents=True, exist_ok=True)
                log = open(state/f'server-{time.time_ns()}.log', 'wb')
                backend = subprocess.Popen(['dotnet', str(dll)], cwd=state, env=server_env,
                    stdout=log, stderr=log, creationflags=HIDDEN)
                log.close()
                for _ in range(180):
                    try:
                        request('GET', '/api/auth/ping' if membership else '/health')
                        return
                    except (OSError, AssertionError):
                        if backend.poll() is not None: raise AssertionError(f'{prefix} exited; see {state}')
                        time.sleep(.5)
                raise AssertionError('Backend did not start')
            start()
            if membership:
                sql(name, "UPDATE users SET user_name='backup_admin',pass_word='secret' WHERE pass_id=1")
                headers['Authorization'] = 'Basic '+base64.b64encode(b'backup_admin:secret').decode()
            else:
                sql(name, "UPDATE pass SET person_name='backup_admin',pass_word='secret',can_maintenance=1 WHERE pass_id=1")
                headers['Authorization'] = 'Bearer '+request('POST', '/api/auth/login', {'username':'backup_admin','password':'secret'})['token']
            request('GET', '/api/backups/settings', expected=403 if membership else 401, auth=False)
            request('PUT', '/api/backups/settings', {'enabled':False,'directory':str(archive_dir),'retention':2})
            sql(name, "CREATE TABLE backup_probe (id SERIAL PRIMARY KEY, label TEXT, payload BYTEA); INSERT INTO backup_probe(label,payload) VALUES ('اختبار النسخ', decode('0011ff','hex'))")
            settings = request('POST', '/api/backups/run')
            assert Path(settings['lastPath']).read_bytes().startswith(b'PGDMP')
            data = request('GET', '/api/backups/download', raw=True)
            assert data.startswith(b'PGDMP'), 'Server mode must download a native PostgreSQL dump'
            archive = state/'download.dump'
            archive.write_bytes(data)
            verification_db = name+'_verify'
            run([PG/'createdb.exe', '-h','127.0.0.1','-p',pg_port,'-U','postgres',verification_db])
            run([PG/'pg_restore.exe', '--no-owner','--no-privileges','--exit-on-error','--single-transaction','--dbname',verification_db,archive], env=env)
            restored = sql(verification_db,"SELECT label || ':' || encode(payload,'hex') FROM backup_probe")
            assert restored == 'اختبار النسخ:0011ff', repr(restored)
            sequence = sql(verification_db,"INSERT INTO backup_probe(label) VALUES ('next') RETURNING id")
            assert sequence.splitlines()[0] == '2', ('Sequence was not restored', repr(sequence))
            sql(name,"UPDATE backup_probe SET label='modified'")
            request('POST','/api/backups/restore', data)
            assert sql(name,"SELECT label FROM backup_probe") == 'اختبار النسخ'
            assert list((archive_dir/'before-restore').glob('*.dump')), 'Restore must retain a safety snapshot'
            request('POST','/api/backups/restore', b'PGDMP-invalid-archive', expected=400)
            assert sql(name,"SELECT label FROM backup_probe") == 'اختبار النسخ'
            # A truncated archive may have a valid TOC but fail during COPY. Rollback must preserve data.
            sql(name,"UPDATE backup_probe SET label='must survive invalid restore'")
            request('POST','/api/backups/restore', data[:-60], expected=400)
            assert sql(name,"SELECT label FROM backup_probe") == 'must survive invalid restore'
            unrelated = archive_dir/'unrelated.dump'
            unrelated.write_bytes(b'keep')
            for _ in range(3): request('POST','/api/backups/run')
            assert len(list(archive_dir.glob(f'{prefix}_postgresql_auto_*.dump'))) == 2
            assert unrelated.read_bytes() == b'keep'
            # Configure a new destination so a backup is due; restart without opening any Flutter client.
            scheduled = state/'scheduled-only'
            request('PUT','/api/backups/settings', {'enabled':True,'directory':str(scheduled),'retention':2})
            backend.terminate(); backend.wait(timeout=30); backend=None
            start()
            for _ in range(60):
                if list(scheduled.glob('*.dump')): break
                time.sleep(.5)
            else: raise AssertionError('Independent server scheduler did not create its due backup')
            assert request('GET','/api/backups/settings')['lastSuccessUtc']
            results.append({'project':prefix,'native_dump':True,'restored_to_empty_database':True,
                'arabic_blob_sequence_preserved':True,'restore_endpoint':True,'invalid_restore_rollback':True,
                'retention':True,'independent_schedule':True,'unauthenticated_denied':True})
            backend.terminate(); backend.wait(timeout=30); backend=None
            print(prefix+': PASS',flush=True)
        (TEMP/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
        print('RESULTS='+str(TEMP/'results.json'),flush=True)
    finally:
        if backend is not None and backend.poll() is None: backend.terminate(); backend.wait(timeout=30)
        subprocess.run([str(PG/'pg_ctl.exe'),'-D',str(TEMP/'data'),'-m','fast','-w','stop'],
            stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=HIDDEN,timeout=180)


if __name__ == '__main__': main()
