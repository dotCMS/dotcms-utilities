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

## Quickstart
Requires 
* python >= 3.8
* Current Docker engine or Docker desktop

  Must provide `docker compose` command, see https://docs.docker.com/compose/migrate/

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

#### Run the tool - Option 1: Use vanilla python virtualenv
```bash
python3 -m venv mysqlmigrate
cd mysqlmigrate
source bin/activate
git clone https://github.com/dotCMS/dotcms-utilities.git
pip install -r dotcms-utilities/mysql_to_postgres/requirements.txt
```
Then run a `tox` test to check your installation:
```
cd dotcms-utilities/mysql_to_postgres
tox -e py310
```
or run it on a mysqldump file you provide:
```
cd dotcms-utilities/mysql_to_postgres/invoke
invoke migrate /absolute/path/to/mysqldump.sql
deactivate # exit virtualenv
```
#### Run the tool - Option 2: Use pipx and poetry
[Install pipx](https://pypa.github.io/pipx/) then
```bash
pipx install poetry
git clone https://github.com/dotCMS/dotcms-utilities.git
cd dotcms-utilities/mysql_to_postgres/invoke
poetry install --no-root
```
Then run a `tox` test to check your installation:
```
cd dotcms-utilities/mysql_to_postgres
poetry run tox -e py310
```
or run it on a mysqldump file you provide:
```
cd dotcms-utilities/mysql_to_postgres/invoke
poetry run invoke migrate /absolute/path/to/mysqldump.sql
exit
```

Note: `invoke` commands must be run from the `invoke` directory

## Usage
```bash
invoke migrate /absolute/path/to/mysqldump.sql
```
[Invoke docs](https://www.pyinvoke.org/) 

**increase `retry_interval` and `retry_attempts` in [tasks.py](https://github.com/dotCMS/dotcms-utilities/blob/main/mysql_to_postgres/invoke/tasks.py) for large DBs**, else the script will time out while the import is in progress
- a 16G mysqldump file with ~1M contentlet rows took about 2.25 hours on my newish mac

## Restrictions
- `pgloader` Docker image requires Intel hardware
- delete `DROP/CREATE DATABASE` lines from mysqldump file, or use `mysqldump --no-create-db`
- `invoke` command must be run from the directory containing the `tasks.py` file - `dotcms_mysql_to_pg`

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
