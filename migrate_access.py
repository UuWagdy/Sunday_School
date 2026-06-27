import sqlite3
import pyodbc
import os
import sys
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from decimal import Decimal

# ═══════════════════════════════════════════
# Column mapping overrides (Access col → SQLite col)
# ═══════════════════════════════════════════
COLUMN_MAPS = {
    'Pass': {'Person_Name': 'Person_Name', 'Pass_Word': 'Pass_Word'},
}

# Access table name → SQLite table name
TARGET_MAP = {
    'Stages': 'Stages',
    'Areas': 'Areas',
    'Fathers': 'Fathers',
    'Persons': 'Persons',
    'Coming': 'Coming',
    'Pass': 'Pass',
    'Credit': 'Credit',
    'Jender': 'Jender',
    'Absent_Persons': 'Absent_Persons',
    'Absent_Print': 'Absent_Print',
    'Adding': 'Adding',
    'Services': 'Services',
    'Khoroses': 'Khoroses',
    'Tayo_Cards': 'Tayo_Cards',
    'Person_Tayo_Points': 'Person_Tayo_Points',
    'Settings': 'Settings',
}

# ═══════════════════════════════════════════
# Table creation SQL (same schema as Flutter app)
# ═══════════════════════════════════════════
CREATE_TABLES_SQL = [
    '''CREATE TABLE IF NOT EXISTS Stages (
        Stage_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Stage_Name TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Areas (
        Area_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Area_Name TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Fathers (
        Father_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Father_Name TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Persons (
        Person_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Person_Name TEXT,
        Stage_ID INTEGER,
        Khoros_ID INTEGER,
        Area_ID INTEGER,
        Street_Name TEXT,
        Phone TEXT,
        Mobile TEXT,
        Day INTEGER,
        Month INTEGER,
        Year INTEGER,
        Jender_Name TEXT,
        Father_ID INTEGER,
        Photo BLOB
    )''',
    '''CREATE TABLE IF NOT EXISTS Coming (
        Id INTEGER,
        Person_ID INTEGER,
        date_Week TEXT,
        Point INTEGER,
        Mont_1 INTEGER,
        Year_1 INTEGER,
        Service_ID INTEGER,
        Attend_Time TEXT,
        Visited INTEGER,
        Visit_Notes TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Pass (
        Pass_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Pass_Word TEXT,
        Person_Name TEXT,
        can_persons INTEGER DEFAULT 0,
        can_stages INTEGER DEFAULT 0,
        can_areas INTEGER DEFAULT 0,
        can_fathers INTEGER DEFAULT 0,
        can_reports INTEGER DEFAULT 0,
        can_users INTEGER DEFAULT 0,
        can_absence INTEGER DEFAULT 0,
        can_maintenance INTEGER DEFAULT 0,
        can_id_card INTEGER DEFAULT 0,
        can_tayo INTEGER DEFAULT 0,
        can_transfer INTEGER DEFAULT 0,
        can_services INTEGER DEFAULT 0,
        can_khoros INTEGER DEFAULT 0
    )''',
    '''CREATE TABLE IF NOT EXISTS Credit (
        Id INTEGER,
        Person_ID INTEGER,
        Person_Name TEXT,
        Stage_Name TEXT,
        Area_name TEXT,
        Street TEXT,
        Phone TEXT,
        Mobile TEXT,
        Day INTEGER,
        month INTEGER,
        year INTEGER,
        Jender TEXT,
        Photo BLOB,
        Parcode BLOB
    )''',
    '''CREATE TABLE IF NOT EXISTS Jender (
        Jender_ID INTEGER,
        Jender_Name TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Absent_Persons (
        ID INTEGER,
        Person_ID INTEGER,
        Person_Name TEXT,
        Stage TEXT,
        Month_1 TEXT,
        First TEXT,
        second TEXT,
        third TEXT,
        Forth TEXT,
        fife TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Absent_Print (
        ID INTEGER,
        Person_ID INTEGER,
        Person_Name TEXT,
        Stage_ID INTEGER,
        Stage_Name TEXT,
        Khoros_ID INTEGER,
        Khoros_Name TEXT,
        Area_ID INTEGER,
        Area_Name TEXT,
        Street_Name TEXT,
        Phone TEXT,
        Mobile TEXT,
        Date_From TEXT,
        Date_To TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Adding (
        Date_ID INTEGER,
        Date TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Services (
        Service_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Service_Name TEXT,
        Day_Of_Week INTEGER,
        Hour INTEGER,
        Minute INTEGER,
        Logo BLOB
    )''',
    '''CREATE TABLE IF NOT EXISTS Khoroses (
        Khoros_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Khoros_Name TEXT,
        Logo BLOB
    )''',
    '''CREATE TABLE IF NOT EXISTS Settings (
        Setting_Key TEXT PRIMARY KEY,
        Setting_Value TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS Tayo_Cards (
        Card_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Card_Name TEXT,
        Card_Points INTEGER,
        Card_Image BLOB
    )''',
    '''CREATE TABLE IF NOT EXISTS Person_Tayo_Points (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Person_ID INTEGER,
        Card_ID INTEGER,
        Points INTEGER,
        Award_Date TEXT,
        Is_Attendance INTEGER,
        Notes TEXT,
        Service_ID INTEGER
    )''',
]


class ConverterApp:
    def __init__(self, root):
        self.root = root
        self.root.title('تحويل قاعدة بيانات Access إلى SQLite — بطرس بولس')
        self.root.geometry('700x580')
        self.root.resizable(True, True)

        # Variables
        self.mdb_path = tk.StringVar()
        self.sqlite_path = tk.StringVar()
        self.password = tk.StringVar(value='')

        # Default SQLite path
        docs = os.path.join(os.path.expanduser('~'), 'Documents')
        self.sqlite_path.set(os.path.join(docs, 'Betros_Bols.db'))

        self._build_ui()

    def _build_ui(self):
        main_frame = ttk.Frame(self.root, padding=20)
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Title
        title = ttk.Label(main_frame, text='أداة تحويل قاعدة بيانات بطرس بولس',
                          font=('Segoe UI', 14, 'bold'))
        title.pack(pady=(0, 5))

        subtitle = ttk.Label(main_frame, text='تحويل من Access (.mdb / .accdb) إلى SQLite (.db)',
                             font=('Segoe UI', 10), foreground='gray')
        subtitle.pack(pady=(0, 15))

        # --- Access file ---
        f1 = ttk.LabelFrame(main_frame, text='ملف Access (.mdb / .accdb)', padding=10)
        f1.pack(fill=tk.X, pady=5)
        ttk.Entry(f1, textvariable=self.mdb_path, width=60).pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        ttk.Button(f1, text='استعراض...', command=self._browse_mdb).pack(side=tk.LEFT)

        # --- SQLite output ---
        f2 = ttk.LabelFrame(main_frame, text='ملف SQLite الهدف (.db)', padding=10)
        f2.pack(fill=tk.X, pady=5)
        ttk.Entry(f2, textvariable=self.sqlite_path, width=60).pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        ttk.Button(f2, text='استعراض...', command=self._browse_sqlite).pack(side=tk.LEFT)

        # --- Password ---
        f3 = ttk.LabelFrame(main_frame, text='كلمة سر ملف Access (اتركها فارغة لو مفيش كلمة سر)', padding=10)
        f3.pack(fill=tk.X, pady=5)
        ttk.Entry(f3, textvariable=self.password, width=30).pack(side=tk.LEFT)

        # --- Convert button ---
        self.convert_btn = ttk.Button(main_frame, text='بدء التحويل ▶', command=self._start_conversion)
        self.convert_btn.pack(pady=15)

        # --- Progress ---
        self.progress = ttk.Progressbar(main_frame, mode='determinate', length=400)
        self.progress.pack(fill=tk.X, pady=5)

        self.status_label = ttk.Label(main_frame, text='جاهز للتحويل', font=('Segoe UI', 10))
        self.status_label.pack(pady=5)

        # --- Log ---
        log_frame = ttk.LabelFrame(main_frame, text='سجل التحويل', padding=5)
        log_frame.pack(fill=tk.BOTH, expand=True, pady=5)

        self.log_text = tk.Text(log_frame, height=10, wrap=tk.WORD, font=('Consolas', 9))
        scrollbar = ttk.Scrollbar(log_frame, orient=tk.VERTICAL, command=self.log_text.yview)
        self.log_text.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.log_text.pack(fill=tk.BOTH, expand=True)

    def _browse_mdb(self):
        path = filedialog.askopenfilename(
            title='اختر ملف Access',
            filetypes=[('Access Database', '*.mdb *.accdb'), ('All Files', '*.*')]
        )
        if path:
            self.mdb_path.set(path)

    def _browse_sqlite(self):
        path = filedialog.asksaveasfilename(
            title='اختر مكان حفظ ملف SQLite',
            defaultextension='.db',
            filetypes=[('SQLite Database', '*.db'), ('All Files', '*.*')],
            initialfile='Betros_Bols.db'
        )
        if path:
            self.sqlite_path.set(path)

    def _log(self, msg):
        self.root.after(0, lambda: self._append_log(msg))

    def _append_log(self, msg):
        self.log_text.insert(tk.END, msg + '\n')
        self.log_text.see(tk.END)

    def _set_status(self, msg):
        self.root.after(0, lambda: self.status_label.configure(text=msg))

    def _set_progress(self, value):
        self.root.after(0, lambda: self.progress.configure(value=value))

    def _start_conversion(self):
        mdb = self.mdb_path.get().strip()
        sqlite = self.sqlite_path.get().strip()
        pwd = self.password.get().strip()

        if not mdb:
            messagebox.showerror('خطأ', 'يرجى اختيار ملف Access أولاً')
            return
        if not os.path.exists(mdb):
            messagebox.showerror('خطأ', f'ملف Access غير موجود:\n{mdb}')
            return
        if not sqlite:
            messagebox.showerror('خطأ', 'يرجى تحديد مكان حفظ ملف SQLite')
            return

        self.convert_btn.configure(state='disabled')
        self.log_text.delete('1.0', tk.END)
        self.progress.configure(value=0)

        thread = threading.Thread(target=self._run_migration, args=(mdb, sqlite, pwd), daemon=True)
        thread.start()

    def _run_migration(self, mdb_path, sqlite_path, password):
        try:
            self._log(f'ملف Access: {mdb_path}')
            self._log(f'ملف SQLite: {sqlite_path}')
            self._set_status('جاري الاتصال...')

            # Ensure directory exists
            sqlite_dir = os.path.dirname(sqlite_path)
            if sqlite_dir and not os.path.exists(sqlite_dir):
                os.makedirs(sqlite_dir)

            # Try to remove existing SQLite file, if locked save to alternative path
            original_path = sqlite_path
            if os.path.exists(sqlite_path):
                try:
                    os.remove(sqlite_path)
                except PermissionError:
                    # File is locked (app is running), save to alternative path
                    base, ext = os.path.splitext(sqlite_path)
                    sqlite_path = f'{base}_migrated{ext}'
                    self._log(f'⚠️ الملف الأصلي مقفول (التطبيق شغال)')
                    self._log(f'   سيتم الحفظ في: {sqlite_path}')
                    self._log(f'   اقفل التطبيق ثم احذف الملف القديم وغير اسم الملف الجديد')
                    self._log('')
                    if os.path.exists(sqlite_path):
                        os.remove(sqlite_path)

            # Create/open SQLite and create tables
            sqlite_conn = sqlite3.connect(sqlite_path)
            sqlite_cursor = sqlite_conn.cursor()
            sqlite_cursor.execute('PRAGMA foreign_keys = ON')

            self._log('إنشاء الجداول في SQLite...')
            for sql in CREATE_TABLES_SQL:
                sqlite_cursor.execute(sql)
            sqlite_conn.commit()

            sqlite_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            existing_tables = [r[0] for r in sqlite_cursor.fetchall()]
            self._log(f'عدد الجداول الموجودة: {len(existing_tables)}')

            # Connect to Access (with optional password)
            conn_str = f'DRIVER={{Microsoft Access Driver (*.mdb, *.accdb)}};DBQ={mdb_path};'
            if password:
                conn_str += f'PWD={password};'

            self._set_status('جاري الاتصال بـ Access...')
            try:
                access_conn = pyodbc.connect(conn_str)
            except Exception as e:
                self._log(f'❌ خطأ في الاتصال بـ Access: {e}')
                self._log('')
                self._log('تأكد من:')
                self._log('1. كلمة السر صحيحة (لو فيه كلمة سر)')
                self._log('2. تثبيت Microsoft Access Database Engine')
                self._log('   https://www.microsoft.com/en-us/download/details.aspx?id=13255')
                self._set_status('❌ فشل الاتصال بـ Access')
                return

            access_cursor = access_conn.cursor()
            mdb_tables = [t.table_name for t in access_cursor.tables(tableType='TABLE')]
            self._log(f'جداول Access: {", ".join(mdb_tables)}')

            total_tables = len(TARGET_MAP)
            done_tables = 0

            for expected_mdb, target_sqlite in TARGET_MAP.items():
                done_tables += 1
                pct = int((done_tables / total_tables) * 100)
                self._set_progress(pct)

                actual_name = next((t for t in mdb_tables if t.lower() == expected_mdb.lower()), None)
                if not actual_name:
                    self._log(f'⏭ {expected_mdb} — غير موجود في Access')
                    continue
                if target_sqlite not in existing_tables:
                    self._log(f'⏭ {target_sqlite} — غير موجود في SQLite')
                    continue

                self._set_status(f'تحويل {actual_name} → {target_sqlite}...')
                try:
                    access_cursor.execute(f'SELECT * FROM [{actual_name}]')
                    
                    rows = access_cursor.fetchall()
                    if not rows:
                        self._log(f'○ {actual_name} — لا توجد بيانات')
                        continue

                    columns = [col[0] for col in access_cursor.description]
                    
                    # Fetch SQLite schema to only insert valid columns
                    sqlite_cursor.execute(f"PRAGMA table_info([{target_sqlite}])")
                    valid_sqlite_cols = {row[1].lower() for row in sqlite_cursor.fetchall()}

                    sqlite_columns = []
                    cols_to_keep_indices = []
                    
                    overrides = COLUMN_MAPS.get(target_sqlite, {})
                    for i, col in enumerate(columns):
                        mapped = overrides.get(col, overrides.get(col.lower(), col))
                        if mapped.lower() in valid_sqlite_cols:
                            sqlite_columns.append(mapped)
                            cols_to_keep_indices.append(i)

                    placeholders = ', '.join(['?'] * len(sqlite_columns))
                    cols_str = ', '.join(f"[{c}]" for c in sqlite_columns)
                    insert_sql = f'INSERT OR REPLACE INTO [{target_sqlite}] ({cols_str}) VALUES ({placeholders})'

                    success = 0
                    errors = 0
                    for row in rows:
                        try:
                            row_data = []
                            for i in cols_to_keep_indices:
                                val = row[i]
                                if isinstance(val, Decimal):
                                    row_data.append(float(val))
                                elif hasattr(val, 'isoformat'):
                                    row_data.append(val.isoformat())
                                elif isinstance(val, bytearray):
                                    row_data.append(bytes(val))
                                else:
                                    row_data.append(val)
                            sqlite_cursor.execute(insert_sql, tuple(row_data))
                            success += 1
                        except Exception as e:
                            # self._log(f'Row error: {e}')
                            errors += 1

                    sqlite_conn.commit()
                    msg = f'✓ {actual_name} → {target_sqlite}: {success}/{len(rows)} صف'
                    if errors:
                        msg += f' ({errors} أخطاء)'
                    self._log(msg)

                except Exception as e:
                    self._log(f'✗ {actual_name}: {str(e)[:80]}')

            # Ensure at least one admin user exists
            sqlite_cursor.execute('SELECT COUNT(*) FROM Pass')
            if sqlite_cursor.fetchone()[0] == 0:
                self._log('📋 إضافة مستخدم admin افتراضي...')
                sqlite_cursor.execute(
                    'INSERT INTO Pass (Person_Name, Pass_Word, can_persons, can_stages, can_areas, can_fathers, can_reports, can_users, can_absence, can_maintenance, can_id_card, can_tayo, can_transfer, can_services, can_khoros) VALUES (?, ?, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)',
                    ('admin', '1234')
                )
            else:
                # Give existing users all permissions
                self._log('📋 تحديث صلاحيات المستخدمين الموجودين...')
                sqlite_cursor.execute(
                    'UPDATE Pass SET can_persons=1, can_stages=1, can_areas=1, can_fathers=1, can_reports=1, can_users=1, can_absence=1, can_maintenance=1, can_id_card=1, can_tayo=1, can_transfer=1, can_services=1, can_khoros=1'
                )
            sqlite_conn.commit()

            access_conn.close()
            sqlite_conn.close()

            self._set_progress(100)
            self._set_status('✓ اكتمل التحويل بنجاح!')
            self._log('\n═══════════════════════════════════')
            self._log('تم التحويل بنجاح!')
            self._log(f'ملف SQLite: {sqlite_path}')
            self._log('')
            self._log('📌 انسخ الملف الناتج إلى:')
            self._log(f'   {os.path.join(os.path.expanduser("~"), "Documents", "Betros_Bols.db")}')
            self._log('═══════════════════════════════════')

            self.root.after(0, lambda: messagebox.showinfo('نجاح', f'تم تحويل البيانات بنجاح!\n\nالملف الناتج:\n{sqlite_path}'))

        except Exception as e:
            self._set_status(f'✗ خطأ: {str(e)[:60]}')
            self._log(f'\n✗ خطأ عام: {e}')
            self.root.after(0, lambda: messagebox.showerror('خطأ', f'حدث خطأ:\n{e}'))

        finally:
            self.root.after(0, lambda: self.convert_btn.configure(state='normal'))

def main():
    root = tk.Tk()
    app = ConverterApp(root)
    root.mainloop()

if __name__ == '__main__':
    main()
