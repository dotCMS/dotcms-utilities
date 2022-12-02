# Convert a mysqldump file to postgres pg_dump file
## MySQL Support Deprecated
DotCMS 21.06 is the last LTS release to support MySQL, so MySQL DBs must be migrated to Postgres before upgrading to the latest dotCMS.

We *highly* recommend upgrading dotCMS to [our latest LTS release](https://www.dotcms.com/docs/latest/current-releases).

This tool should simplify the database migration process.

## Overview

Create a mysqldump file using option `--no-create-db`

Run this tool on the (uncompressed) mysqldump file

Load the created pg_dump file on a clean Postgres database

Start the latest dotCMS LTS using the postgres DB

This tool has been tested on mysql dbs from dotCMS 5.1 - 21.06.

## Installation
Requires 
* python >= 3.8
* Docker engine or Docker desktop

Tested on OS X 12 and Debian 11.
 
#### Debian 11 prep
On Debian it is easiest to spin up a new VPS, run everything as root, and delete the VPS when complete.

Run as root:
```
curl -sSL https://get.docker.com | sh
apt install -y python3-venv python3-pip git
```
#### OS X prep
- Install Docker Desktop, increase memory and disk space in settings -> Resources

#### Fetch the tool
`git clone https://github.com/dotCMS/dotcms-utilities.git`

#### Run the tool - Option 1: Use vanilla python virtualenv
```bash
python3 -m venv mysqlmigrate
source mysqlmigrate/bin/activate
pip install -r dotcms-utilities/mysql_to_postgres/requirements.txt
cd dotcms-utilities/mysql_to_postgres/invoke
invoke migrate -m /absolute/path/to/mysqldump.sql
deactivate # exit virtualenv
```
#### Run the tool - Option 2: Use pipx and poetry
[Install pipx](https://pypa.github.io/pipx/) then
```bash
pipx install poetry
cd dotcms-utilities/mysql_to_postgres/invoke
poetry install --no-root
poetry run invoke migrate -m /absolute/path/to/mysqldump.sql
```

## Usage
```bash
invoke migrate -m /absolute/path/to/mysqldump.sql
```

```bash
Usage: inv[oke] migrate -m /path/to/mysqldump.sql

Docstring:
  Convert the provided mysql dump file to dotCMS 21.06 Postgres pg_dump file

Required Options:
  -m STRING, --mysqldump-file=/path/to/mysqldump.sql

Optional Options:
  -p [STRING], --pg-dump-file=/path/to/output/pgdump.sql.gz
```
[Invoke docs](https://www.pyinvoke.org/) 

Invoke is akin to `make`


## Restrictions
- delete `DROP/CREATE DATABASE` lines from mysqldump file, or use `mysqldump --no-create-db`
- `invoke` command must be run from the directory containing the `tasks.py` file - `dotcms_mysql_to_pg`
- increase `retry_interval` and `retry_attempts` in `tasks.py` for large DBs, else the script will give up while the import is in progress
-- a 16G mysqldump file with ~1M contentlet rows took about 2.25 hours on my newish mac


## Script workflow
Each run of the script creates a new temp dir which contains docker-compose.yml and other files.

Different docker services are added/removed as needed.

1. import mysqldump file to clean mysql server
2. run raw mysql commands to prepare for the migration
3. start dotCMS 21.06 on mysql db to run needed db migrations, then stop dotCMS
4. run pgloader to copy mysql db to postgres db
5. start dotCMS 21.06 on postgres db to ensure dotCMS runs
6. save a local pg_dump file

Inspect the running containers as it progresses to follow along.

You must manully delete the created temp dir(s) and prune docker volumes/networks/etc when finished.

## Notes
Thanks to [pgloader](https://pgloader.readthedocs.io/en/latest/) for doing the heavy lifting. 

https://github.com/dimitri/pgloader/issues/994

https://pgloader.readthedocs.io/en/latest/ref/mysql.html#default-mysql-casting-rules 
