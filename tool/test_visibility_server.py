"""Isolated, disposable PostgreSQL + HTTP regression suite. Never uses app data.

Run after dotnet build -c Release. Logs are retained in a fresh TEMP directory.
"""
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
import time
import urllib.request
import urllib.error

ROOT = Path(__file__).resolve().parents[1]
PG = ROOT / 'installer/payload/server/postgresql/bin'
TEMP = Path(tempfile.mkdtemp(prefix='petros-scope-test-'))
HIDDEN = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def run(args, **kwargs):
    if Path(str(args[0])).name == 'pg_ctl.exe':
        # The detached postgres child inherits pipe handles on Windows. A pipe
        # would keep communicate() waiting even after pg_ctl exited.
        return subprocess.run([str(x) for x in args], check=True, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, creationflags=HIDDEN, timeout=90, **kwargs)
    return subprocess.run([str(x) for x in args], check=True, capture_output=True,
                          creationflags=HIDDEN, **kwargs)


def port():
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


def main():
    pg_port, api_port = port(), port()
    base = f'http://127.0.0.1:{api_port}'
    backend = None
    started = False
    count = 0

    def sql(statement):
        fixture = TEMP / 'fixture.sql'
        fixture.write_text(statement, encoding='utf-8')
        return run([PG / 'psql.exe', '-h', '127.0.0.1', '-p', pg_port,
                    '-U', 'postgres', '-d', 'petros_scope_test', '-v', 'ON_ERROR_STOP=1',
                    '-f', fixture], encoding='utf-8', env=dict(os.environ,PGCLIENTENCODING='UTF8')).stdout

    def request(path, data=None, token=None, expected=200, method=None):
        nonlocal count
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        req = urllib.request.Request(base + path,
            data=json.dumps(data, ensure_ascii=False).encode() if data is not None else None,
            headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                status, body = r.status, r.read()
        except urllib.error.HTTPError as e:
            status, body = e.code, e.read()
        assert status == expected, f'{path}: expected {expected}, got {status}: {body[:500]!r}'
        count += 1
        return json.loads(body) if body and status == 200 else None

    def params(values):
        return [{'type': 'null' if v is None else 'int' if isinstance(v, int) else 'string',
                 'value': v} for v in values]

    def query(statement, token, values=(), expected=200, tx=None):
        return request('/api/storage/query', {'sql': statement, 'params': params(values),
                       'transactionId': tx}, token, expected)

    def write(statement, token, values=(), endpoint='insert', expected=200, tx=None):
        return request('/api/storage/' + endpoint, {'sql': statement, 'params': params(values),
                       'transactionId': tx}, token, expected)

    try:
        seed = TEMP / 'database' / 'Betros_Bols.db'
        seed.parent.mkdir()
        seed.write_bytes(b'incompatible old client database')
        run([PG / 'initdb.exe', '-D', TEMP / 'data', '-U', 'postgres', '-A', 'trust',
             '--no-locale', '-E', 'UTF8'])
        run([PG / 'pg_ctl.exe', '-D', TEMP / 'data', '-l', TEMP / 'postgres.log',
             '-o', f'-h 127.0.0.1 -p {pg_port}', '-w', 'start'])
        started = True
        env = dict(os.environ, PORT=str(api_port), BindLocalOnly='true',
            ConnectionStrings__DefaultConnection=f'Host=127.0.0.1;Port={pg_port};Database=petros_scope_test;Username=postgres',
            Jwt__Secret=secrets.token_hex(40))
        with open(TEMP / 'backend.log', 'wb') as log:
            backend = subprocess.Popen(['dotnet', str(ROOT / 'SundaySchool.SyncServer/bin/Release/net8.0/SundaySchool.SyncServer.dll')],
                cwd=TEMP, env=env, stdout=log, stderr=log, creationflags=HIDDEN)
        for _ in range(80):
            try:
                if request('/health')['ok']:
                    break
            except (OSError, AssertionError):
                time.sleep(.25)
        else:
            raise AssertionError('isolated backend did not become healthy')

        assert seed.read_bytes() == b'incompatible old client database'
        assert '1' in sql('SELECT COUNT(*) FROM pass;'), 'empty host must seed a default login'

        sql("""
          DELETE FROM pass;
          INSERT INTO pass(pass_id,person_name,pass_word,can_users,can_maintenance,can_persons,can_stages,can_khoros)
            VALUES (1,'scope-admin','fixture-only',1,1,1,1,1),(2,'scope-worker','fixture-only',0,1,1,1,1);
          SELECT setval(pg_get_serial_sequence('pass','pass_id'), 2);
          INSERT INTO services(service_id,service_name) VALUES (101,'A'),(102,'B');
          INSERT INTO stages(stage_id,stage_name) VALUES (105,'5ب'),(106,'6ب');
          INSERT INTO khoroses(khoros_id,khoros_name) VALUES (107,'K');
          INSERT INTO areas(area_id,area_name,parent_id) VALUES (108,'Parent',NULL),(109,'Child',108),(110,'Other',NULL);
          INSERT INTO persons(person_id,person_name,stage_id,khoros_id,jender_name,area_id,rohot,leader)
            VALUES (201,'Visible boy',105,107,'ذكر',109,'R1','L1'),(202,'Hidden girl',105,107,'أنثى',109,'R1','L1'),
            (203,'Hidden stage',106,107,'ذكر',110,'R2','L2'),(204,'Hidden service',105,107,'ذكر',110,'R2','L2');
          INSERT INTO person_services(person_id,service_id) VALUES(201,101),(202,101),(203,101),(204,102);
          INSERT INTO coming(person_id,service_id,date_week,point) VALUES(201,101,'2026-10-16',1),(202,101,'2026-10-16',1),(201,102,'2026-10-16',1);
          INSERT INTO settings(setting_key,setting_value) VALUES
            ('user_data_scope_2','{"service":["101"],"gender":["ذكر"],"stage":["105"]}'),
            ('monthly_fund_payments_json','{"201":10,"202":99}'),
            ('rohot_groups_json','[{"name":"R1","members":[{"id":201},{"id":202}]}]');
        """)
        request('/api/storage/query', {'sql': 'SELECT * FROM "Persons"'}, expected=401)
        users = request('/api/auth/users')
        assert all(not u.get('canUsers') and not u.get('dataVisibilityScope') for u in users)
        admin = request('/api/auth/login', {'username': 'scope-admin', 'password': 'fixture-only'})['token']
        login = request('/api/auth/login', {'username': 'scope-worker', 'password': 'fixture-only'})
        worker = login['token']
        assert login['user']['dataVisibilityScope']['stage'] == ['105']
        rows = query('SELECT "Person_ID" AS id FROM "Persons" ORDER BY "Person_ID"', worker)['rows']
        assert [r['id'] for r in rows] == [201], rows
        assert len(query('SELECT * FROM "Persons"', admin)['rows']) == 4
        assert query('SELECT COUNT(*) AS n FROM "Coming"', worker)['rows'][0]['n'] == 1
        query('SELECT * FROM public.persons', worker, expected=403)
        query('SELECT pg_read_file(?)', worker, ['anything'], expected=403)
        query('SELECT * FROM "Persons"; SELECT * FROM "Pass"', worker, expected=403)
        query('SELECT * FROM "pg_catalog"."pg_authid"', worker, expected=403)
        query('PRAGMA table_info("Persons")', worker)
        assert query('SELECT COALESCE(MAX("Person_ID"),0)+1 AS next_id FROM "Persons"', worker)['rows'][0]['next_id'] == 205
        values = query('SELECT "Setting_Key", "Setting_Value" FROM "Settings"', worker)['rows']
        funds = json.loads(next(r['Setting_Value'] for r in values if r['Setting_Key'] == 'monthly_fund_payments_json'))
        assert funds == {'201': 10}, funds
        projected = query('SELECT "Setting_Value" FROM "Settings" WHERE "Setting_Key"=?', worker, ['monthly_fund_payments_json'])['rows']
        assert json.loads(projected[0]['Setting_Value']) == {'201': 10}
        upsert = 'INSERT INTO "Settings" ("Setting_Key", "Setting_Value") VALUES (?, ?) ON CONFLICT("Setting_Key") DO UPDATE SET "Setting_Value" = ?'
        write(upsert, worker, ['monthly_fund_payments_json','{"201":25}','{"201":25}'])
        result = query('SELECT "Setting_Value" FROM "Settings" WHERE "Setting_Key"=?', admin, ['monthly_fund_payments_json'])['rows'][0]
        assert json.loads(result['Setting_Value']) == {'201': 25, '202': 99}
        write(upsert, worker, ['monthly_fund_payments_json','{"202":1}','{"202":1}'], endpoint='execute', expected=403)
        write(upsert, worker, ['user_data_scope_2','{}','{}'], expected=403)
        # OR must not weaken the appended row predicate.
        changed = write('UPDATE "Persons" SET "Phone"=? WHERE "Person_ID"=? OR "Person_ID"=?', worker, ['safe',201,202], endpoint='execute')
        assert changed['rowsAffected'] == 1, changed
        assert query('SELECT "Phone" FROM "Persons" WHERE "Person_ID"=?', admin, [202])['rows'][0]['Phone'] is None
        write('UPDATE "Persons" SET "Phone"=(SELECT "Pass_Word" FROM "Pass" LIMIT 1)', worker, endpoint='execute', expected=403)
        write('INSERT INTO "Person_Services" ("Person_ID","Service_ID") VALUES (?,?)',worker,[202,102],endpoint='execute',expected=403)
        request('/api/storage/batch', {'statements':[{'sql':'INSERT INTO "Person_Services" ("Person_ID","Service_ID") VALUES (?,?)','argSets':[params([202,102])]}]},worker,403)
        request('/api/storage/export-sqlite',token=worker,expected=403)
        request('/api/storage/import-sqlite',{},worker,403)
        tx = request('/api/storage/tx/begin',{},admin)['transactionId']
        query('SELECT * FROM "Persons"',worker,expected=403,tx=tx)
        request('/api/storage/tx/commit',{'transactionId':tx},worker,403)
        request('/api/storage/tx/rollback',{'transactionId':tx},admin)
        # Restrictions are re-read for the existing token, across all seven dimensions.
        for scope, expected_ids in [({'area':['108']},[201,202]),({'rohot':['R2'],'leader':['L2']},[203,204]),({'khoros':['107'],'gender':['أنثى']},[202]),({'stage':[]},[]),('null',[]),('invalid-json',[]),({},[201,202,203,204])]:
            payload=scope if isinstance(scope,str) else json.dumps(scope,ensure_ascii=False)
            write(upsert,admin,['user_data_scope_2',payload,payload])
            actual=query('SELECT "Person_ID" AS id FROM "Persons" ORDER BY "Person_ID"',worker)['rows']
            assert [r['id'] for r in actual]==expected_ids,(scope,actual)
        request('/hubs/sync/negotiate?negotiateVersion=1',{},expected=401)
        request('/hubs/sync/negotiate?negotiateVersion=1',{},worker)
        write('DELETE FROM "Settings" WHERE NOT ("Setting_Key" LIKE ?)',worker,['user_data_scope_%'],endpoint='execute')
        saved=query('SELECT "Setting_Value" FROM "Settings" WHERE "Setting_Key"=?',admin,['user_data_scope_2'])['rows']
        assert json.loads(saved[0]['Setting_Value'])=={}
        initial_scope='{"service":["101"],"gender":["ذكر"],"stage":["105"]}'
        write(upsert,admin,['user_data_scope_2',initial_scope,initial_scope])
        # Delta cursors: concurrent transactions can commit in the reverse order
        # of their IDs. A max(sequence) cursor would miss the late commit.
        def changes(cursor=None, known=(), who=admin, domain='people'):
            return request('/api/storage/person-changes',
                           {'cursor':cursor,'knownPersonIds':list(known),'domain':domain},who)
        sql("INSERT INTO client_change_journal(table_name,person_id,changed_at) VALUES ('persons',987654,clock_timestamp()-interval '3 days');")
        checkpoint=changes()
        assert checkpoint['resetRequired'] and not checkpoint['personIds']
        assert not changes(checkpoint['cursor'])['personIds']
        first=request('/api/storage/tx/begin',{},admin)['transactionId']
        write('UPDATE "Persons" SET "Phone"=? WHERE "Person_ID"=?',admin,['delta-late',201],endpoint='execute',tx=first)
        second=request('/api/storage/tx/begin',{},admin)['transactionId']
        write('UPDATE "Persons" SET "Phone"=? WHERE "Person_ID"=?',admin,['delta-first',202],endpoint='execute',tx=second)
        request('/api/storage/tx/commit',{'transactionId':second},admin)
        middle=changes(checkpoint['cursor'])
        assert middle['personIds']==[202],middle
        request('/api/storage/tx/commit',{'transactionId':first},admin)
        final=changes(middle['cursor'])
        assert final['personIds']==[201],final
        rollback=request('/api/storage/tx/begin',{},admin)['transactionId']
        write('UPDATE "Persons" SET "Phone"=? WHERE "Person_ID"=?',admin,['delta-rollback',201],endpoint='execute',tx=rollback)
        request('/api/storage/tx/rollback',{'transactionId':rollback},admin)
        assert not changes(final['cursor'])['personIds']
        scoped=changes(who=worker)
        write('UPDATE "Persons" SET "Phone"=? WHERE "Person_ID"=?',admin,['hidden-delta',202],endpoint='execute')
        assert not changes(scoped['cursor'],who=worker)['personIds']
        write('UPDATE "Persons" SET "Stage_ID"=? WHERE "Person_ID"=?',admin,[106,201],endpoint='execute')
        removed=changes(scoped['cursor'],[201],worker)
        assert removed['personIds']==[201],removed
        write('UPDATE "Persons" SET "Stage_ID"=? WHERE "Person_ID"=?',admin,[105,201],endpoint='execute')
        visible=changes(removed['cursor'],who=worker)
        assert visible['personIds']==[201],visible
        deleted=changes()
        write('INSERT INTO "Persons" ("Person_ID","Person_Name") VALUES (?,?)',admin,[290,'delta deletion'])
        write('DELETE FROM "Persons" WHERE "Person_ID"=?',admin,[290],endpoint='execute')
        assert changes(deleted['cursor'],[290])['personIds']==[290]
        # Retention loss and malformed/restarted cursors safely ask for a snapshot.
        sql("UPDATE client_change_state SET floor=pg_snapshot_xmin(pg_current_snapshot());")
        assert changes(final['cursor'])['resetRequired']
        assert changes('invalid')['resetRequired']
        sql("UPDATE client_change_state SET floor='0';")
        query('SELECT * FROM client_change_journal',worker,expected=403)
        metadata=changes()
        write('UPDATE "Stages" SET "Stage_Name"=? WHERE "Stage_ID"=?',admin,['Fixture stage',105],endpoint='execute')
        assert changes(metadata['cursor'])['resetRequired']
        def conditional(tag=None, tx=None, who=admin):
            return request('/api/storage/query',{'sql':'SELECT "Phone" FROM "Persons" WHERE "Person_ID"=?',
                'params':params([201]),'acceptCache':True,'cacheTag':tag,'transactionId':tx},who)
        cached=conditional()
        assert cached['cacheTag'] and cached['rows']
        assert conditional(cached['cacheTag'])['notModified']
        # Changes outside the HTTP writer must invalidate the cached read too.
        sql("UPDATE persons SET phone='external-cache-change' WHERE person_id=201;")
        fresh=conditional(cached['cacheTag'])
        assert not fresh.get('notModified') and fresh['rows'][0]['Phone']=='external-cache-change',fresh
        assert not conditional(fresh['cacheTag'],who=worker).get('notModified')
        cache_tx=request('/api/storage/tx/begin',{},admin)['transactionId']
        tx_read=conditional(fresh['cacheTag'],cache_tx)
        assert not tx_read.get('notModified') and not tx_read.get('cacheTag'),tx_read
        request('/api/storage/tx/rollback',{'transactionId':cache_tx},admin)
        try:
            dart=run([r'C:\Users\Graphic\flutter\bin\flutter.bat','test','--no-pub','--concurrency=1',
                      '--dart-define=SCOPE_TEST_URL='+base,'--dart-define=SCOPE_TEST_TOKEN='+worker,
                      '--dart-define=SCOPE_TEST_ADMIN_TOKEN='+admin,'test/visibility_remote_repository_test.dart',
                      'test/sync_performance_remote_test.dart'],cwd=ROOT)
        except subprocess.CalledProcessError as failure:
            (TEMP/'flutter-repositories.log').write_bytes(failure.stdout+failure.stderr)
            raise AssertionError('Flutter repository checks failed; see '+str(TEMP/'flutter-repositories.log')) from None
        (TEMP/'flutter-repositories.log').write_bytes(dart.stdout+dart.stderr)
        # A stale account session is authentication expiry (401), not a data
        # permission failure (403). Native clients must return to sign-in.
        sql("DELETE FROM pass WHERE pass_id=2;")
        query('SELECT * FROM "Services"', worker, expected=401)
        request('/api/storage/person-changes', {'knownPersonIds': [], 'domain': 'people'}, worker, expected=401)
        request('/hubs/sync/negotiate?negotiateVersion=1', {}, worker, expected=401)

        result={'passed':True,'http_checks':count,'database':'temporary PostgreSQL','logs':str(TEMP)}
        (ROOT/'docs/server-visibility-test-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
        print(json.dumps(result))
    finally:
        if backend:
            backend.terminate()
            backend.wait(timeout=20)
        if started:
            run([PG/'pg_ctl.exe','-D',TEMP/'data','-m','fast','-w','stop'])
        print('Retained isolated logs:',TEMP)


if __name__ == '__main__':
    main()
