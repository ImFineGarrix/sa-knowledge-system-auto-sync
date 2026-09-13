---
name: db-rename-reserved-word
description: "ใช้ skill นี้สำหรับแปลงชื่อ Reserved Word ของ DBMS เป็นชื่อใหม่ตาม Company Type-Prefix Convention (s_, n_, d_, t_, f_ ตาม data type ของ column) Trigger ได้แก่ 'reserved word rename', 'type prefix', 'rename convention', 'company naming', หรือเมื่อ parent skill (db-create-schema / db-create-procedure / db-summary-spec) เจอ Reserved Word ที่ต้อง rename"
---

# db-rename-reserved-word

## Role & Goal

Skill นี้แปลงชื่อ **Reserved Word** ของ DBMS เป็นชื่อใหม่ตาม **Company Type-Prefix Convention** เพื่อ:
1. หลีกเลี่ยง syntax error / quoting overhead จาก reserved words
2. ทำให้ชื่อ column สื่อ data type ได้ทันทีจาก prefix (อ่าน code/query ง่ายขึ้น)
3. รักษา consistency ทั้งระบบ (ทุก SA/Dev rename แบบเดียวกัน)

> **หลักการสำคัญ:** Skill นี้เป็น **utility cross-skill** — `db-create-schema`, `db-create-procedure`, `db-summary-spec` เรียกใช้ได้ทั้งหมด ผ่าน Operation Flow มาตรฐาน

## Inherited Global Rules

สืบทอดจาก `db-create-spec`:
- **กฎข้อ 4 (Naming Standardization)** — แกนหลัก: "No Reserved Words" + Type-Prefix Convention เป็น company standard
- **กฎข้อ 8 (DBMS Specification)** — ต้องระบุ DBMS ก่อน lookup mapping
- **กฎข้อ 12 (Collation)** — Column data type detection สำหรับเลือก prefix (text → s_, numeric → n_, ...)

## Type-Prefix Convention (Single Source of Truth)

> **กฎเหล็ก:** ตารางนี้คือ **single source of truth ของ Prefix Definition** — หากต้องการเพิ่ม prefix ใหม่ ต้องอัปเดตที่นี่ก่อน แล้วค่อย append row ใน `references/reserved-word-mapping.csv`

| Prefix | Meaning | Data Types ครอบคลุม | Context |
|--------|---------|---------------------|---------|
| **`s_`** | **s**tring | `VARCHAR`, `CHAR`, `NVARCHAR`, `NCHAR`, `TEXT`, `NTEXT`, `CLOB`, `NCLOB`, `VARCHAR2`, `STRING` + **Table names ทุกชนิด** | Column ที่เก็บ string + **ชื่อ Table** (เพราะ table = string identifier) |
| **`n_`** | **n**umber | `INT`, `BIGINT`, `SMALLINT`, `TINYINT`, `INTEGER`, `DECIMAL`, `NUMERIC`, `FLOAT`, `DOUBLE`, `REAL`, `MONEY`, `NUMBER`, `SMALLMONEY` | Column ที่เก็บจำนวน (รวม PK ที่เป็น INT) |
| **`d_`** | **d**ate | `DATE`, `DATETIME`, `DATETIME2`, `SMALLDATETIME`, `TIMESTAMP`, `TIMESTAMPTZ`, `DATETIMEOFFSET` | Column ที่เก็บวันที่หรือวันที่+เวลา |
| **`t_`** | **t**ime | `TIME`, `TIMETZ`, `TIME WITH TIME ZONE` | Column ที่เก็บเวลาอย่างเดียว |
| **`f_`** | **f**lag | `BOOLEAN`, `BIT` (logical 0/1), `TINYINT(1)` (MySQL) | Column ที่เก็บ true/false, active/inactive, enabled/disabled |

### Naming Format (บังคับ)

```
<prefix>_<original_reserved_word>
```

- ใช้ **snake_case + lowercase** เสมอ
- Prefix ติด underscore (`_`) เป็น separator
- ห้ามใช้ camelCase / PascalCase (เช่น ห้าม `sCondition`, `SCondition`)
- ห้ามตัด underscore ออก (เช่น ห้าม `scondition`)

### Edge Cases (AI ต้องเดาจาก context)

| Case | กฎ |
|------|-----|
| `BIT` ใน MSSQL ที่เก็บ 0/1 logical | → `f_` (ไม่ใช่ `n_`) |
| `TINYINT` ใน MySQL ที่เก็บ 0/1 | → `f_`; ถ้าเก็บ count → `n_` |
| `BLOB`, `VARBINARY`, `JSON`, `XML`, `UUID` | **ยังไม่มี prefix mapping** — ต้องถาม SA เมื่อเจอ |
| Table name ที่เป็น reserved word | → `s_` ทุกตัว (regardless ของ column types ภายใน) |

### Legacy Exceptions (mappings ใน CSV ที่ไม่ตามกฎ data type — คงไว้ตามต้นฉบับ)

มี case ใน `references/reserved-word-mapping.csv` ที่ map ไม่ตามกฎ data type มาตรฐาน แต่คงไว้ตามไฟล์ legacy ของ company:

| Reserved Word | DBMS | Mapping | Expected by Rule | Reason |
|---------------|------|---------|------------------|--------|
| `dec` | MySQL | `s_dec` | `n_dec` (DECIMAL = number) | Legacy convention จากไฟล์ต้นฉบับ — คงไว้เพื่อ backward compatibility |

> **กฎเหล็ก:** เมื่อเจอ Reserved Word เหล่านี้ → **ใช้ค่าจาก CSV ตรงๆ** (อย่า re-derive จาก data type) — Exception เหล่านี้มีเหตุผลทางประวัติศาสตร์ของ company
>
> **ถ้าจะเพิ่ม Exception ใหม่:** ต้องผ่าน SA approval + บันทึก reason ใน column `note` ของ CSV + เพิ่ม row ในตารางนี้

## 🚨 Multi-Source Reserved Keyword References (บังคับ — Rule 4)

> **Exhaustive Scan ต้องเช็ค 4 sources ตามลำดับ** — ห้าม skip source ใด แม้ source แรกเจอแล้ว

### Source 1: Company `reserved-word-mapping.csv` (authoritative mapping)

อยู่ที่ [`references/reserved-word-mapping.csv`](./references/reserved-word-mapping.csv) — append-only audit log

### Source 2: DBMS T-SQL Reserved Keywords (embedded ที่นี่ — Option A)

**MSSQL (SQL Server 2019+) — Common Reserved (Extended set per company policy):**

> **Note:** รายการนี้รวม **strict Microsoft T-SQL Reserved** (current) **+ Extended set** ที่ครอบคลุม:
> - **Sybase Legacy** keywords (T-SQL inherit จาก Sybase ปี 1994 — ยังมี tooling/parser ที่ตีความเป็น reserved)
> - **ANSI SQL:1999 / SQL:2003 Extended Reserved** (สำหรับ portability ข้าม DBMS)
> - **Cross-DBMS compatibility** keywords (DB2, Oracle ที่ commonly used เป็น column name)
>
> Extended keywords ที่เพิ่มจาก Microsoft strict list ถูก mark **`(*)`** ที่บรรทัดถัดไป
>
> เหตุผลที่ embed รวมเข้า MSSQL list เดียว — ลด risk จาก ORM/migration tool/cross-DBMS deploy ที่อาจ flag

```
ACTION (*), ADD, ALL, ALTER, AND, ANY, AS, ASC, AUTHORIZATION, AVG (*),
BACKUP, BEFORE (*), BEGIN, BETWEEN, BIT (*), BREAK, BROWSE, BULK, BY,
CASCADE, CASE, CHAR (*), CHARACTER (*), CHECK, CHECKPOINT, CLOSE, CLUSTERED,
COALESCE, COLLATE, COLUMN, COMMIT, COMPUTE, CONDITION (*), CONNECT (*),
CONSTRAINT, CONSTRAINTS (*), CONTAINS, CONTAINSTABLE, CONTINUE, CONVERT,
COUNT (*), CREATE, CROSS, CURRENT, CURRENT_DATE, CURRENT_TIME,
CURRENT_TIMESTAMP, CURRENT_USER, CURSOR, DATA (*), DATABASE, DATE (*),
DAY (*), DBCC, DEALLOCATE, DEC (*), DECIMAL (*), DECLARE, DEFAULT, DELETE,
DENY, DESC, DESCRIBE (*), DISK, DISTINCT, DISTRIBUTED, DOMAIN (*), DOUBLE,
DROP, DUMP, ELSE, END, ERRLVL, ESCAPE, EXCEPT, EXCEPTION (*), EXEC,
EXECUTE, EXISTS, EXIT, EXTERNAL, EXTRACT (*), FETCH, FILE, FILLFACTOR,
FIRST (*), FLOAT (*), FOR, FOREIGN, FOUND (*), FREETEXT, FREETEXTTABLE,
FROM, FULL, FUNCTION, GET (*), GLOBAL (*), GO (*), GOTO, GRANT, GROUP,
HAVING, HOLDLOCK, HOUR (*), IDENTITY, IDENTITYCOL, IDENTITY_INSERT, IF,
IMMEDIATE (*), IN, INDEX, INDICATOR (*), INITIALLY (*), INNER, INPUT (*),
INSERT, INT (*), INTEGER (*), INTERSECT, INTERVAL (*), INTO, IS,
ISOLATION (*), JOIN, KEY, KILL, LANGUAGE (*), LAST (*), LEADING (*), LEFT,
LEVEL (*), LIKE, LINENO, LOAD, LOCAL (*), LOWER (*), MATCH (*), MAX (*),
MEMBER (*), METHOD (*), MERGE, MIN (*), MINUTE (*), MODULE (*), MONTH (*),
NAME (*), NAMES (*), NATIONAL, NATURAL (*), NCHAR (*), NEXT (*), NO (*),
NOCHECK, NONCLUSTERED, NONE (*), NOT, NULL, NULLIF, NUMERIC (*), OF, OFF,
OFFSETS, ON, ONLY (*), OPEN, OPENDATASOURCE, OPENQUERY, OPENROWSET,
OPENXML, OPTION, OR, ORDER, OUTER, OUTPUT (*), OVER, OVERLAPS (*),
PARTIAL (*), PERCENT, PIVOT, PLAN, POSITION (*), PRECISION, PREPARE (*),
PRESERVE (*), PRIMARY, PRINT, PRIOR (*), PRIVILEGES (*), PROC, PROCEDURE,
PUBLIC, RAISERROR, READ, READTEXT, REAL (*), RECONFIGURE, REF (*),
REFERENCES, RELATIVE (*), REPLICATION, RESTORE, RESTRICT, RESULT (*),
RETURN, RETURNS (*), REVERT, REVOKE, RIGHT, ROLE (*), ROLLBACK, ROUTINE (*),
ROW (*), ROWS (*), ROWCOUNT, ROWGUIDCOL, RULE, SAVE, SAVEPOINT (*),
SCHEMA, SCROLL (*), SEARCH (*), SECOND (*), SECTION (*), SECURITYAUDIT,
SELECT, SEMANTICKEYPHRASETABLE, SEMANTICSIMILARITYDETAILSTABLE,
SEMANTICSIMILARITYTABLE, SENSITIVE (*), SEQUENCE (*), SESSION (*),
SESSION_USER, SET, SETUSER, SHUTDOWN, SIZE (*), SMALLINT (*), SOME, SPACE (*),
SQL (*), SQLCODE (*), SQLERROR (*), SQLSTATE (*), START (*), STATE (*),
STATEMENT (*), STATIC (*), STATISTICS, STATUS (*), SUBSTRING (*), SUM (*),
SYSTEM (*), SYSTEM_USER, TABLE, TABLESAMPLE, TEMPORARY (*), TEXTSIZE, THEN,
TIME (*), TIMESTAMP (*), TIMEZONE_HOUR (*), TIMEZONE_MINUTE (*), TO, TOP,
TRAILING (*), TRAN, TRANSACTION, TRANSLATE (*), TRANSLATION (*), TRIGGER,
TRIM (*), TRUE (*), TRUNCATE, TRY_CONVERT, TSEQUAL, TYPE (*), UNION, UNIQUE,
UNKNOWN (*), UNPIVOT, UPDATE, UPDATETEXT, UPPER (*), USAGE (*), USE, USER,
USING (*), VALUE (*), VALUES, VARCHAR (*), VARYING, VIEW, WAITFOR, WHEN,
WHENEVER (*), WHERE, WHILE, WITH, WITHIN GROUP, WORK (*), WRITE (*),
WRITETEXT, YEAR (*), ZONE (*)
```

**`(*)` = Extended set additions** — ไม่อยู่ใน Microsoft strict T-SQL Reserved list (current) แต่บังคับใน schema นี้ตาม company policy:
- Sybase legacy: `STATUS`, `LEVEL`, `ROLE`, `WORK`, `ZONE`, `ROW`, `ROWS`, `STATE`, `MEMBER`, ...
- ANSI SQL:1999/2003 extended: `DATA`, `METHOD`, `RESULT`, `RETURNS`, `ROUTINE`, `SECTION`, `STATEMENT`, `STATIC`, `START`, ...
- ODBC SQL-92 (also in Source 3 below — duplicated here for unified single-source MSSQL check): `ACTION`, `AVG`, `CHAR`, `DOMAIN`, `MATCH`, `POSITION`, ...
- DBMS portability: `TYPE`, `NAME`, `VALUE`, `SIZE`, `LANGUAGE`, ...

**Audit trail for additions** — full list documented in `references/reserved-word-mapping.csv` rationale column.

**MySQL 8.0 — Common Reserved (subset):**
```
ACCESSIBLE, ADD, ALL, ALTER, ANALYZE, AND, AS, ASC, ASENSITIVE, BEFORE,
BETWEEN, BIGINT, BINARY, BLOB, BOTH, BY, CALL, CASCADE, CASE, CHANGE, CHAR,
CHARACTER, CHECK, COLLATE, COLUMN, CONDITION, CONSTRAINT, CONTINUE, CONVERT,
CREATE, CROSS, CUBE, CUME_DIST, CURRENT_DATE, CURRENT_TIME, CURRENT_TIMESTAMP,
CURRENT_USER, CURSOR, DATABASE, DATABASES, DAY_HOUR, DAY_MICROSECOND,
DAY_MINUTE, DAY_SECOND, DEC, DECIMAL, DECLARE, DEFAULT, DELAYED, DELETE,
DENSE_RANK, DESC, DESCRIBE, DETERMINISTIC, DISTINCT, DISTINCTROW, DIV, DOUBLE,
DROP, DUAL, EACH, ELSE, ELSEIF, EMPTY, ENCLOSED, ESCAPED, EXCEPT, EXISTS, EXIT,
EXPLAIN, FALSE, FETCH, FIRST_VALUE, FLOAT, FOR, FORCE, FOREIGN, FROM, FULLTEXT,
FUNCTION, GENERATED, GET, GRANT, GROUP, GROUPING, GROUPS, HAVING, HIGH_PRIORITY,
HOUR_MICROSECOND, HOUR_MINUTE, HOUR_SECOND, IF, IGNORE, IN, INDEX, INFILE,
INNER, INOUT, INSENSITIVE, INSERT, INT, INTEGER, INTERVAL, INTO, IS, ITERATE,
JOIN, JSON_TABLE, KEY, KEYS, KILL, LAG, LAST_VALUE, LATERAL, LEAD, LEADING,
LEAVE, LEFT, LIKE, LIMIT, LINEAR, LINES, LOAD, LOCALTIME, LOCALTIMESTAMP, LOCK,
LONG, LONGBLOB, LONGTEXT, LOOP, LOW_PRIORITY, MASTER_BIND, MATCH, MAXVALUE,
MEDIUMBLOB, MEDIUMINT, MEDIUMTEXT, MIDDLEINT, MINUTE_MICROSECOND, MINUTE_SECOND,
MOD, MODIFIES, NATURAL, NOT, NO_WRITE_TO_BINLOG, NTH_VALUE, NTILE, NULL, NUMERIC,
OF, ON, OPTIMIZE, OPTIMIZER_COSTS, OPTION, OPTIONALLY, OR, ORDER, OUT, OUTER,
OUTFILE, OVER, PARTITION, PERCENT_RANK, PRECISION, PRIMARY, PROCEDURE, PURGE,
RANGE, RANK, READ, READS, REAL, RECURSIVE, REFERENCES, REGEXP, RELEASE, RENAME,
REPEAT, REPLACE, REQUIRE, RESIGNAL, RESTRICT, RETURN, REVOKE, RIGHT, RLIKE,
ROW, ROWS, ROW_NUMBER, SCHEMA, SCHEMAS, SECOND_MICROSECOND, SELECT, SENSITIVE,
SEPARATOR, SET, SHOW, SIGNAL, SMALLINT, SPATIAL, SPECIFIC, SQL, SQLEXCEPTION,
SQLSTATE, SQLWARNING, SQL_BIG_RESULT, SQL_CALC_FOUND_ROWS, SQL_SMALL_RESULT,
SSL, STARTING, STORED, STRAIGHT_JOIN, SYSTEM, TABLE, TERMINATED, THEN, TINYBLOB,
TINYINT, TINYTEXT, TO, TRAILING, TRIGGER, TRUE, UNDO, UNION, UNIQUE, UNLOCK,
UNSIGNED, UPDATE, USAGE, USE, USING, UTC_DATE, UTC_TIME, UTC_TIMESTAMP, VALUES,
VARBINARY, VARCHAR, VARCHARACTER, VARYING, VIRTUAL, WHEN, WHERE, WHILE, WINDOW,
WITH, WRITE, XOR, YEAR_MONTH, ZEROFILL
```

**PostgreSQL — Common Reserved (subset):**
```
ALL, ANALYSE, ANALYZE, AND, ANY, ARRAY, AS, ASC, ASYMMETRIC, BOTH, CASE, CAST,
CHECK, COLLATE, COLUMN, CONSTRAINT, CREATE, CURRENT_CATALOG, CURRENT_DATE,
CURRENT_ROLE, CURRENT_TIME, CURRENT_TIMESTAMP, CURRENT_USER, DEFAULT, DEFERRABLE,
DESC, DISTINCT, DO, ELSE, END, EXCEPT, FALSE, FETCH, FOR, FOREIGN, FROM, GRANT,
GROUP, HAVING, IN, INITIALLY, INTERSECT, INTO, LATERAL, LEADING, LIMIT,
LOCALTIME, LOCALTIMESTAMP, NOT, NULL, OFFSET, ON, ONLY, OR, ORDER, PLACING,
PRIMARY, REFERENCES, RETURNING, SELECT, SESSION_USER, SOME, SYMMETRIC, TABLE,
THEN, TO, TRAILING, TRUE, UNION, UNIQUE, USER, USING, VARIADIC, WHEN, WHERE,
WINDOW, WITH
```

**Oracle — Common Reserved (subset):**
```
ACCESS, ADD, ALL, ALTER, AND, ANY, AS, ASC, AUDIT, BETWEEN, BY, CHAR, CHECK,
CLUSTER, COLUMN, COMMENT, COMPRESS, CONNECT, CREATE, CURRENT, DATE, DECIMAL,
DEFAULT, DELETE, DESC, DISTINCT, DROP, ELSE, EXCLUSIVE, EXISTS, FILE, FLOAT,
FOR, FROM, GRANT, GROUP, HAVING, IDENTIFIED, IMMEDIATE, IN, INCREMENT, INDEX,
INITIAL, INSERT, INTEGER, INTERSECT, INTO, IS, LEVEL, LIKE, LOCK, LONG, MAXEXTENTS,
MINUS, MLSLABEL, MODE, MODIFY, NOAUDIT, NOCOMPRESS, NOT, NOWAIT, NULL, NUMBER,
OF, OFFLINE, ON, ONLINE, OPTION, OR, ORDER, PCTFREE, PRIOR, PRIVILEGES, PUBLIC,
RAW, RENAME, RESOURCE, REVOKE, ROW, ROWID, ROWNUM, ROWS, SELECT, SESSION, SET,
SHARE, SIZE, SMALLINT, START, SUCCESSFUL, SYNONYM, SYSDATE, TABLE, THEN, TO,
TRIGGER, UID, UNION, UNIQUE, UPDATE, USER, VALIDATE, VALUES, VARCHAR, VARCHAR2,
VIEW, WHENEVER, WHERE, WITH
```

### Source 3: ODBC Reserved Keywords (portability check)

```
ABSOLUTE, ACTION, ADD, ALL, ALLOCATE, ALTER, AND, ANY, ARE, AS, ASC, ASSERTION,
AT, AUTHORIZATION, AVG, BEGIN, BETWEEN, BIT, BIT_LENGTH, BOTH, BY, CASCADE,
CASCADED, CASE, CAST, CATALOG, CHAR, CHAR_LENGTH, CHARACTER, CHARACTER_LENGTH,
CHECK, CLOSE, COALESCE, COLLATE, COLLATION, COLUMN, COMMIT, CONNECT, CONNECTION,
CONSTRAINT, CONSTRAINTS, CONTINUE, CONVERT, CORRESPONDING, COUNT, CREATE, CROSS,
CURRENT, CURRENT_DATE, CURRENT_TIME, CURRENT_TIMESTAMP, CURRENT_USER, CURSOR,
DATE, DAY, DEALLOCATE, DEC, DECIMAL, DECLARE, DEFAULT, DEFERRABLE, DEFERRED,
DELETE, DESC, DESCRIBE, DESCRIPTOR, DIAGNOSTICS, DISCONNECT, DISTINCT, DOMAIN,
DOUBLE, DROP, ELSE, END, END-EXEC, ESCAPE, EXCEPT, EXCEPTION, EXEC, EXECUTE,
EXISTS, EXTERNAL, EXTRACT, FALSE, FETCH, FIRST, FLOAT, FOR, FOREIGN, FOUND,
FROM, FULL, GET, GLOBAL, GO, GOTO, GRANT, GROUP, HAVING, HOUR, IDENTITY,
IMMEDIATE, IN, INDICATOR, INITIALLY, INNER, INPUT, INSENSITIVE, INSERT, INT,
INTEGER, INTERSECT, INTERVAL, INTO, IS, ISOLATION, JOIN, KEY, LANGUAGE, LAST,
LEADING, LEFT, LEVEL, LIKE, LOCAL, LOWER, MATCH, MAX, MIN, MINUTE, MODULE, MONTH,
NAMES, NATIONAL, NATURAL, NCHAR, NEXT, NO, NOT, NULL, NULLIF, NUMERIC,
OCTET_LENGTH, OF, ON, ONLY, OPEN, OPTION, OR, ORDER, OUTER, OUTPUT, OVERLAPS,
PAD, PARTIAL, POSITION, PRECISION, PREPARE, PRESERVE, PRIMARY, PRIOR,
PRIVILEGES, PROCEDURE, PUBLIC, READ, REAL, REFERENCES, RELATIVE, RESTRICT,
REVOKE, RIGHT, ROLLBACK, ROWS, SCHEMA, SCROLL, SECOND, SECTION, SELECT, SESSION,
SESSION_USER, SET, SIZE, SMALLINT, SOME, SPACE, SQL, SQLCODE, SQLERROR, SQLSTATE,
SUBSTRING, SUM, SYSTEM_USER, TABLE, TEMPORARY, THEN, TIME, TIMESTAMP,
TIMEZONE_HOUR, TIMEZONE_MINUTE, TO, TRAILING, TRANSACTION, TRANSLATE, TRANSLATION,
TRIM, TRUE, UNION, UNIQUE, UNKNOWN, UPDATE, UPPER, USAGE, USER, USING, VALUE,
VALUES, VARCHAR, VARYING, VIEW, WHEN, WHENEVER, WHERE, WITH, WORK, WRITE, YEAR,
ZONE
```

### Source 4: Future Reserved Keywords (DBMS-specific roadmap)

> **Borderline cases** — ไม่ใช่ strict violation ตอนนี้ แต่ DBMS ระบุว่าจะกลายเป็น reserved ใน version หน้า — flag ใน Open Items

**MSSQL Future Reserved:**
```
ABSOLUTE, ACTION, ADMIN, AFTER, AGGREGATE, ALIAS, ALLOCATE, ARE, ARRAY, ASSERTION,
AT, BEFORE, BINARY, BIT, BLOB, BOOLEAN, BOTH, BREADTH, CALL, CALLED, CARDINALITY,
CASCADED, CAST, CATALOG, CHAR, CHARACTER, CLASS, CLOB, COLLATION, COLLECT,
COMPLETION, CONDITION, CONNECT, CONNECTION, CONSTRAINTS, CONSTRUCTOR, CORR,
CORRESPONDING, COVAR_POP, COVAR_SAMP, CUBE, CUME_DIST, CURRENT_CATALOG,
CURRENT_DEFAULT_TRANSFORM_GROUP, CURRENT_PATH, CURRENT_ROLE, CURRENT_SCHEMA,
CURRENT_TRANSFORM_GROUP_FOR_TYPE, CYCLE, DATA, DATE, DAY, DEC, DECIMAL,
DEFERRABLE, DEFERRED, DEPTH, DEREF, DESCRIBE, DESCRIPTOR, DESTROY, DESTRUCTOR,
DETERMINISTIC, DIAGNOSTICS, DICTIONARY, DISCONNECT, DOMAIN, DYNAMIC,
EACH, ELEMENT, EQUALS, EVERY, EXCEPTION, FALSE, FILTER, FIRST, FLOAT, FOUND,
FREE, FULLTEXTTABLE, FUSION, GENERAL, GET, GLOBAL, GO, GROUPING, HOLD, HOST,
HOUR, IGNORE, IMMEDIATE, INDICATOR, INITIALIZE, INITIALLY, INOUT, INPUT, INT,
INTEGER, INTERSECTION, INTERVAL, ISOLATION, ITERATE, LANGUAGE, LARGE, LAST,
LATERAL, LEADING, LESS, LEVEL, LIKE_REGEX, LIMIT, LN, LOCAL, LOCALTIME,
LOCALTIMESTAMP, LOCATOR, MAP, MATCH, MEMBER, METHOD, MINUTE, MOD, MODIFIES,
MODIFY, MODULE, MONTH, MULTISET, NAMES, NATURAL, NCHAR, NCLOB, NEW, NEXT, NO,
NONE, NORMALIZE, NUMERIC, OBJECT, OCCURRENCES_REGEX, OLD, ONLY, OPERATION,
ORDINALITY, OUT, OUTPUT, OVERLAY, PAD, PARAMETER, PARAMETERS, PARTIAL, PARTITION,
PATH, PERCENT_RANK, PERCENTILE_CONT, PERCENTILE_DISC, POSITION_REGEX, POSTFIX,
PREFIX, PREORDER, PREPARE, PRESERVE, PRIOR, PRIVILEGES, RANGE, READS, REAL,
RECURSIVE, REF, REFERENCING, REGR_AVGX, REGR_AVGY, REGR_COUNT, REGR_INTERCEPT,
REGR_R2, REGR_SLOPE, REGR_SXX, REGR_SXY, REGR_SYY, RELATIVE, RELEASE, RESULT,
RETURNS, ROLE, ROLLUP, ROUTINE, ROW, ROWS, SAVEPOINT, SCROLL, SCOPE, SEARCH,
SECOND, SECTION, SENSITIVE, SEQUENCE, SESSION, SETS, SIMILAR, SIZE, SMALLINT,
SPACE, SPECIFIC, SPECIFICTYPE, SQL, SQLEXCEPTION, SQLSTATE, SQLWARNING, START,
STATE, STATEMENT, STATIC, STDDEV_POP, STDDEV_SAMP, STRUCTURE, SUBMULTISET,
SUBSTRING_REGEX, SYMMETRIC, TEMPORARY, TERMINATE, THAN, TIME, TIMESTAMP,
TIMEZONE_HOUR, TIMEZONE_MINUTE, TRAILING, TRANSLATE_REGEX, TRANSLATION, TREAT,
TRUE, UESCAPE, UNDER, UNKNOWN, UNNEST, USAGE, USING, VALUE, VAR_POP, VAR_SAMP,
VARCHAR, VARIABLE, WHENEVER, WIDTH_BUCKET, WITHOUT, WORK, WRITE, XMLAGG,
XMLATTRIBUTES, XMLBINARY, XMLCAST, XMLCOMMENT, XMLCONCAT, XMLDOCUMENT, XMLELEMENT,
XMLEXISTS, XMLFOREST, XMLITERATE, XMLNAMESPACES, XMLPARSE, XMLPI, XMLQUERY,
XMLSERIALIZE, XMLTABLE, XMLTEXT, XMLVALIDATE, YEAR, ZONE
```

> หมายเหตุ: Lists เหล่านี้ ไม่ครบ exhaustive 100% — อ้างอิง official docs ของแต่ละ DBMS เป็น final authoritative source หาก doubt

---

## Reserved Word Mapping — Preview

> **Full mapping อยู่ที่** [`references/reserved-word-mapping.csv`](./references/reserved-word-mapping.csv) — **CSV เป็น authoritative source** สำหรับ data layer

### MySQL (preview 5 of 12)

| Original | Renamed | Prefix | Note |
|----------|---------|--------|------|
| `condition` | `s_condition` | `s_` | |
| `group` | `s_group` | `s_` | Table name |
| `utc_date` | `d_utc_date` | `d_` | |
| `utc_time` | `t_utc_time` | `t_` | |
| `index` | `s_index` | `s_` | Table name |

### MSSQL (preview 5 of 11)

| Original | Renamed | Prefix | Note |
|----------|---------|--------|------|
| `key` | `n_key` | `n_` | Typically PK |
| `index` | `s_index` | `s_` | Table name |
| `user` | `s_user` | `s_` | |
| `password` | `s_password` | `s_` | |
| `convert` | `s_convert` | `s_` | |

> **ดู mapping ครบทุก case ใน CSV** — ก่อน rename ทุกครั้ง Claude ต้อง Read CSV เพื่อ exhaustive check

## Operation Flow

### Step 1: Receive Input (จาก parent หรือ direct SA call)

ต้องการ input 4 อย่าง:

| Input | คำอธิบาย | ตัวอย่าง |
|-------|---------|---------|
| `dbms` | DBMS ที่ใช้ (ตาม Rule 8) | `MSSQL` |
| `original` | Reserved word เดิม | `key` |
| `context` | `table` หรือ `column` | `column` |
| `data_type` | Data type ของ column (ถ้า context=column) — ไม่จำเป็นถ้า context=table | `INT` |

### Step 2: 🚨 Exhaustive Multi-Source Lookup (บังคับ 4 sources ตามลำดับ — Rule 4)

ห้าม skip source ใด — ต้องเช็คครบทั้ง 4 แม้ source แรกเจอแล้ว เพื่อ comprehensive scan

**Source 1: Company CSV (highest priority — authoritative mapping):**
1. **Read** ไฟล์ `references/reserved-word-mapping.csv`
2. Filter rows ที่ `dbms` ตรงกับ input
3. หา row ที่ `original` ตรงกับ input
4. **ถ้าเจอ:** มี existing mapping — ใช้ค่า `renamed` ตรงๆ (ไม่ต้องคำนวณใหม่) → จบ Source 1 + ไป Source 2 (comprehensive)
5. **ถ้าไม่เจอ:** ไป Source 2

**Source 2: DBMS T-SQL Reserved Keywords (current version):**
- ตรวจชื่อกับ keyword list ใน "Multi-Source Reserved Keyword References" section ด้านบน
- ถ้าเจอใน T-SQL list แต่ไม่เจอใน CSV → **case ใหม่ — ต้อง rename** → ไป Step 3 (Auto-detect)

**Source 3: ODBC Reserved Keywords:**
- ตรวจ portability — ถ้าเจอ → flag เป็น "ODBC reserved" + warn SA (อาจ rename เผื่อ portability)
- borderline case ถ้าไม่ใช่ DBMS-specific reserved

**Source 4: Future Reserved Keywords:**
- ตรวจกับ "Future Reserved" list ของ DBMS
- ถ้าเจอ → **borderline case** — ไม่ใช่ strict violation ตอนนี้ แต่จะกลายเป็น reserved ใน version หน้า
- → flag ใน Open Items + SA decide (rename ก่อน หรือ accept risk)

**Result Decision Tree:**
- เจอใน Source 1 (CSV) → ใช้ existing mapping
- เจอใน Source 2 (T-SQL Reserved) แต่ไม่เจอ Source 1 → strict violation, ต้อง rename → Step 3
- เจอใน Source 3 (ODBC) เท่านั้น → portability warning, แนะนำให้ rename
- เจอใน Source 4 (Future) เท่านั้น → borderline, Open Items
- ไม่เจอ source ไหน → ไม่ใช่ reserved word ปลอดภัย

### Step 3: Auto-Detect Prefix (เมื่อ CSV ไม่มี mapping)

ใช้ Decision Tree ตาม Type-Prefix Convention table:

```
1. ถ้า context = "table" → prefix = "s_"
2. ถ้า context = "column":
   2.1 ดู data_type ของ column
   2.2 Match กับ Data Types ครอบคลุม ในตาราง Type-Prefix Convention
   2.3 เลือก prefix ที่ตรง
3. ถ้า data_type อยู่ใน Edge Cases (BIT, TINYINT(1), BLOB, JSON, ...):
   → ถาม SA ก่อนเลือก prefix
4. ถ้า data_type ไม่อยู่ในตารางเลย:
   → ถาม SA + เสนอเพิ่ม prefix ใหม่ใน Type-Prefix Convention
```

### Step 4: Generate Renamed Name

```
renamed = <prefix> + <original>
```

ตัวอย่าง:
- `condition` (VARCHAR, MySQL) → `s_` + `condition` = `s_condition`
- `key` (INT, MSSQL) → `n_` + `key` = `n_key`
- `is_active` (BIT, MSSQL) → `f_` + `is_active` = `f_is_active` (ไม่ใช่ reserved แต่ก็ใช้ convention เดียวกันได้)

### Step 5: Confirm with SA + Append CSV (ถ้าเป็น case ใหม่)

**กรณีที่ Step 2 เจอใน CSV:** ใช้ค่าจาก CSV เลย — แค่ confirm กับ SA ว่า context ตรงไหม

**กรณีที่ Step 3 Auto-detect:** ต้อง confirm 2 ข้อ:
1. SA ยืนยัน prefix ที่ AI เลือกถูกต้อง
2. SA approve การ **append CSV** (เพิ่ม mapping ใหม่)

→ ถ้า approve: AI **append row ใน `references/reserved-word-mapping.csv`** (ตาม Pre-Append Validation ด้านล่าง)

### Step 6: Return Rename Map

ส่งกลับ parent skill ในรูปแบบ:

```markdown
## Rename Map

| Original | Renamed | Prefix | Source | SA Confirmed |
|----------|---------|--------|--------|--------------|
| condition | s_condition | s_ | CSV (existing) | ✅ |
| my_new_word | s_my_new_word | s_ | Auto-detect + CSV appended | ✅ |
```

## Pre-Append Validation (บังคับ — ป้องกัน Drift)

ก่อน append row ใน `references/reserved-word-mapping.csv` AI ต้องทำ validation:

1. **Prefix Existence Check:** ค่าใน column `prefix` ของ row ใหม่ ต้องมีอยู่ใน Type-Prefix Convention table ใน SKILL.md นี้
   - ✅ มี → append ได้
   - ❌ ไม่มี → **หยุด** + แจ้ง SA: "Prefix `<X>` ไม่มีใน Convention — ต้องเพิ่มใน SKILL.md ก่อน"
2. **DBMS Validity Check:** ค่าใน column `dbms` ต้องเป็นชื่อ DBMS valid ตาม Rule 8 (MySQL, MSSQL, PostgreSQL, Oracle, DB2, MariaDB, SQLite, Informix)
3. **Duplicate Check:** ตรวจว่ามี row ที่ `dbms` + `original` ซ้ำใน CSV หรือยัง — ถ้าซ้ำ → ไม่ append
4. **Format Check:** ค่า `renamed` ต้อง = `<prefix><original>` (concat) — ถ้าไม่ตรง → flag error

→ **One-way Dependency:** CSV ขึ้นกับ SKILL.md ทิศทางเดียว — Prefix Definition ต้องอยู่ก่อน

## Extension Process (เมื่อต้องการเพิ่มข้อมูลใหม่)

### Scenario A: เพิ่ม Reserved Word ใหม่ที่ใช้ Prefix เดิม (บ่อยที่สุด)

ตัวอย่าง: เจอ MySQL `interval` → `n_interval`

1. ✅ แก้แค่ **CSV** — append 1 row
2. ❌ SKILL.md ไม่ต้องแตะ
3. Run Pre-Append Validation

### Scenario B: เพิ่ม Prefix ใหม่ (ยังไม่มี case จริง)

ตัวอย่าง: ตัดสินใจรองรับ BLOB → เพิ่ม `b_` (binary)

1. ✅ แก้แค่ **SKILL.md** — เพิ่ม row ใน Type-Prefix Convention table
2. ❌ CSV ไม่ต้องแตะ

### Scenario C: เพิ่ม Prefix ใหม่ + Reserved Word ที่ใช้ Prefix นั้น พร้อมกัน

ตัวอย่าง: เพิ่ม `b_` + เจอ `binary` ใน MSSQL → `b_binary`

1. ✅ แก้ **SKILL.md ก่อน** (define `b_` ใน Type-Prefix Convention)
2. ✅ แก้ **CSV** (append row `MSSQL,binary,b_binary,b_,...`)
3. Run Pre-Append Validation (จะ pass เพราะ `b_` เพิ่ง define)

## Integration Points

Skill นี้ถูกเรียกจาก parent skills ในจุดต่อไปนี้:

### 1. `db-create-schema` — Reserved Words Check Flow

เมื่อ Reserved Words Check เจอ conflict → เรียก skill นี้เป็น **Option (1) Type-Prefix Convention** (company default)
- AI ส่ง: dbms, original, context (table/column), data_type
- รับกลับ: Rename Map
- ใส่ใน Audit Trail Table ของ schema

### 2. `db-create-procedure` — SP Parameter / Variable Naming (เฉพาะตอนชื่อชนกับ Reserved Word)

SP parameter / variable ใช้ Type-Prefix Convention **เฉพาะตอนชื่อตรงกับ Reserved Word** ของ DBMS — ชื่อทั่วไปใช้ snake_case ปกติ:
```sql
-- ตัวอย่าง (MSSQL): mixed naming
CREATE PROCEDURE sp_process_order(
    @customer_id     INT,                                              -- ปกติ
    @customer_name   VARCHAR(100) COLLATE Latin1_General_100_BIN2_UTF8, -- ปกติ
    @order_date      DATE,                                             -- ปกติ
    @n_key           INT,                                              -- key เป็น MSSQL reserved → n_key
    @is_priority     BIT                                               -- ปกติ
)
AS BEGIN
    DECLARE @temp VARCHAR(255) COLLATE Latin1_General_100_BIN2_UTF8;
    DECLARE @s_user VARCHAR(50) COLLATE Latin1_General_100_BIN2_UTF8;  -- user เป็น MSSQL reserved → s_user
    ...
END
```

### 3. `db-summary-spec` — Pattern Detection (Reverse Engineer)

ตอน parse DDL/Live DB หาก detect ชื่อ column/table ตรง pattern `s_*`, `n_*`, `d_*`, `t_*`, `f_*`:
- → infer ว่าใช้ company Type-Prefix Convention
- → ใส่ note ใน DB_SUMMARY ว่า "ใช้ Type-Prefix Convention (สอดคล้องกับ company standard)"
- หาก pattern ไม่ตรง → flag ใน Open Questions ว่า "ระบบเดิมอาจไม่ใช้ company convention"

## Output Format

ส่งกลับ parent skill ในรูปแบบ:

```markdown
## Rename Map — <DBMS>

| Original | Renamed | Prefix | Context | Data Type | Source | Note |
|----------|---------|--------|---------|-----------|--------|------|
| condition | s_condition | s_ | column | VARCHAR | CSV (existing) | |
| key | n_key | n_ | column | INT | CSV (existing) | Typically PK |
| my_new_word | s_my_new_word | s_ | column | VARCHAR | Auto-detect + CSV appended | New mapping |

### Validation Result

- ✅ Prefix Existence: all prefixes exist in Type-Prefix Convention
- ✅ DBMS Validity: <DBMS> valid per Rule 8
- ✅ Duplicate Check: no duplicates found
- ✅ Format Check: renamed = prefix + original
- ✅ SA Confirmed: <date / SA name>

### CSV Update (ถ้ามี)

- Appended <N> new row(s) to `references/reserved-word-mapping.csv`
```

## Anti-patterns (ห้ามทำ)

- ❌ **Override prefix ตามใจ** — ห้าม rename เป็น `my_index`, `Order_index` แทน `s_index`
- ❌ **ใช้ camelCase / PascalCase** กับ prefix — ห้าม `sCondition`, `SCondition`, `S_Condition`
- ❌ **ตัด underscore** — ห้าม `scondition` (ต้องมี `_` คั่น)
- ❌ **เว้น prefix สำหรับ data type ที่ไม่ระบุ** — ห้ามเดา ต้องถาม SA + เสนอเพิ่ม prefix ใหม่
- ❌ **Append CSV โดยไม่ผ่าน Pre-Append Validation** — เสี่ยง drift
- ❌ **แก้ Prefix Definition ใน CSV** — Prefix Definition อยู่ที่ SKILL.md เท่านั้น
- ❌ **เพิ่ม mapping โดยไม่ confirm SA** — ทุก case ใหม่ต้องผ่าน SA approve
- ❌ **ใช้ Type-Prefix สำหรับชื่อที่ไม่ใช่ Reserved Word** — ใช้เฉพาะตอน rename reserved word เท่านั้น (รวม **column ใน schema**, **SP parameter / variable**, และ **temp table column / table variable column**) ห้ามนำไปตั้งชื่อใหม่ทั่วไป
- 🚨 ❌ **Silent Bracket Escape (Rule 4 violation)** — ห้าม AI auto-escape ด้วย `[name]` / `` `name` `` / `"name"` โดยไม่ confirm SA — ทุก bracket workaround ต้องผ่าน AskUserQuestion + บันทึก risk ใน REVIEW_LOG
- 🚨 ❌ **Skip source ใน Multi-Source Scan (Rule 4 violation)** — ห้าม stop scan ที่ source แรก (เช่น เจอใน CSV แล้วไม่เช็ค T-SQL/ODBC/Future) — ต้อง comprehensive scan ทั้ง 4 sources
- 🚨 ❌ **Skip CSV append หลัง rename (Rule 4 violation)** — ทุก rename event ต้อง append CSV (รวม Option 5 bracket) — เป็น compliance violation หาก skip
- 🚨 ❌ **Modify/Delete row ใน CSV** — CSV เป็น append-only audit log — ห้ามแก้ row เดิม (ยกเว้นแก้ typo + บันทึก reason)

## References

> ⚠️ **Path Convention Note:** Relative paths ด้านล่างนี้ assume **flat workspace layout** (`db-skills/<skill>.md` + `db-skills/references/...`) ซึ่งตรงกับโครงสร้าง dev folder ปัจจุบัน หากนำไป install เป็น **folder-per-skill layout** (`.claude/skills/<skill>/SKILL.md`) → `install.ps1` จะ transform paths ให้อัตโนมัติตามนี้:
>
> - **Sibling skill link** (flat `./<skill>.md`) → folder-per-skill `../<skill>/SKILL.md`
> - **References folder** (`./references/...`) คงเดิม — อยู่ภายใน skill folder
>
> หาก deploy แบบ manual (ไม่ใช้ install.ps1) ต้อง update sibling skill links เอง

- **Mapping data:** [`references/reserved-word-mapping.csv`](./references/reserved-word-mapping.csv) — 23 rows เริ่มต้น (MySQL 12 + MSSQL 11)
- **Original convention source:** company internal file `how to convert_reserveword_db.txt`
- **Parent skill:** [`db-create-schema.md`](./db-create-schema.md) — Reserved Words Check Flow
