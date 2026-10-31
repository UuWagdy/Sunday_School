"""Run actual Flutter repositories through HTTP against disposable PostgreSQL."""
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
PG = ROOT / 'installer/payload/server/postgresql/bin'
HIDDEN = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    work = Path(tempfile.mkdtemp(prefix='petros-services-'))
    print('Isolated service test logs:', work, flush=True)
    pg_port, api_port = free_port(), free_port()
    base = f'http://127.0.0.1:{api_port}'
    backend = None
    started = False

    def run(args, **kwargs):
        return subprocess.run([str(arg) for arg in args], check=True,
                              creationflags=HIDDEN, **kwargs)

    def request(path, body=None):
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(base + path, data=data,
                                     headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.load(response)

    try:
        with (work / 'postgres-bootstrap.log').open('wb') as log:
            run([PG / 'initdb.exe', '-D', work / 'data', '-U', 'postgres',
                 '-A', 'trust', '--no-locale', '-E', 'UTF8'], stdout=log, stderr=log)
            run([PG / 'pg_ctl.exe', '-D', work / 'data', '-l', work / 'postgres.log',
                 '-o', f'-h 127.0.0.1 -p {pg_port}', '-w', 'start'], stdout=log, stderr=log)
        started = True
        env = dict(os.environ, PORT=str(api_port), BindLocalOnly='true',
                   BACKUP_SETTINGS_ROOT=str(work / 'backup-state'), POSTGRES_BIN=str(PG),
                   ConnectionStrings__DefaultConnection=f'Host=127.0.0.1;Port={pg_port};Database=petros_service_test;Username=postgres',
                   Jwt__Secret=secrets.token_hex(40))
        with (work / 'backend.log').open('wb') as log:
            backend = subprocess.Popen(['dotnet', str(ROOT / 'SundaySchool.SyncServer/bin/Release/net8.0/SundaySchool.SyncServer.dll')],
                                       cwd=work, env=env, stdout=log, stderr=log, creationflags=HIDDEN)
        for _ in range(120):
            try:
                if request('/health')['ok']:
                    break
            except OSError:
                time.sleep(.25)
        else:
            raise RuntimeError('Isolated server did not start; see backend.log')
        fixture = work / 'fixture.sql'
        fixture.write_text("""DELETE FROM pass;
            INSERT INTO pass(pass_id,person_name,pass_word,can_users,can_maintenance) VALUES
              (1,'fixture-admin','fixture-only',1,1),(2,'fixture-worker','fixture-only',0,0);
            INSERT INTO settings(setting_key,setting_value) VALUES
              ('user_data_scope_2','{"service":["1","2"]}');""", encoding='utf-8')
        run([PG / 'psql.exe', '-h', '127.0.0.1', '-p', pg_port, '-U', 'postgres',
             '-d', 'petros_service_test', '-v', 'ON_ERROR_STOP=1', '-f', fixture])
        token = request('/api/auth/login', {'username': 'fixture-admin', 'password': 'fixture-only'})['token']
        worker = request('/api/auth/login', {'username': 'fixture-worker', 'password': 'fixture-only'})['token']
        flutter = shutil.which('flutter')
        with (work / 'flutter.log').open('wb') as log:
            result = subprocess.run([flutter, 'test', '--no-pub', '--concurrency=1',
                          '--dart-define=SERVICE_TEST_DISPOSABLE=true',
                          '--dart-define=SERVICE_TEST_URL=' + base,
                          '--dart-define=SERVICE_TEST_TOKEN=' + token,
                          '--dart-define=SERVICE_TEST_WORKER_TOKEN=' + worker,
                          'test/service_assignment_regression_test.dart',
                          'test/bulk_person_services_widget_test.dart'],
                         cwd=ROOT, stdout=log, stderr=log, creationflags=HIDDEN)
        print((work / 'flutter.log').read_text(encoding='utf-8', errors='replace'))
        if result.returncode:
            raise RuntimeError('Remote service assignment regression failed')
    finally:
        if backend:
            backend.terminate()
            backend.wait(timeout=20)
        if started:
            with (work / 'postgres-stop.log').open('wb') as log:
                run([PG / 'pg_ctl.exe', '-D', work / 'data', '-m', 'fast', '-w', 'stop'], stdout=log, stderr=log)


if __name__ == '__main__':
    main()
