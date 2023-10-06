import os
import sys
from pathlib import Path
from tempfile import mkdtemp
from time import sleep

import rich
from invoke import task

import templates, utils

# Bump these a lot for big DBs!
retry_interval = 15 # seconds
retry_attempts = 400 # very large db's will need this increased

dotcms_port = 8082
workdir = mkdtemp(prefix="dotcms_migrate_")
workdir_basedir = workdir.split('/')[-1]


template = templates.Template(
        username="dbuser", 
        dbname="dotcms",
        password="dbpassword",
        workdir=workdir,
    )

class MigrationException(Exception):
    pass


result = os.uname()
if result.machine != 'x86_64':
    rich.print(":x: The 'pgloader' Docker image is only supported on Intel hardware, bailing...")
    sys.exit()

@task(optional=["pg_dump_file"])
def migrate(c, mysqldump_file, pg_dump_file=None):
    """ Convert the provided mysql dump file to dotCMS 21.06 Postgres pg_dump file """
    assert mysqldump_file.startswith("/"), "Provide absolute, not relative, path to mysqldump file"
    try:
        if pg_dump_file is None:
            pg_dump_file = Path(workdir) / "dotcms-21.06-postgres.sql.gz"
        else:
            pg_dump_file = Path(pg_dump_file)
        # import provided mysqldump file
        print("---------------------------------------------------")
        rich.print(f":keycap_1:  loading mysqldump file: {mysqldump_file}")
        compose_file = template_all_dbs(mysqldump_file)
        c.run(f"cp {compose_file} {compose_file}-dbs")
        start_docker(c, compose_file)
        sleep(5)
        # check if mysql loaded dotcms content
        print("waiting for mysql to load mysqldump file")
        mysql_query_content()
        print("cleaning up mysql db")
        utils.mysql_post_import(template.username, template.password,)
        print("---------------------------------------------------")
        rich.print(f":keycap_2:  start dotcms 21.06 on mysql to execute migrations")
        template_dotcms_mysql()
        c.run(f"cp {compose_file} {compose_file}-dotcms-mysql")
        start_docker(c, compose_file)
        # wait for dotcms to complete migrations
        utils.check_dotcms_appconfiguration(port=dotcms_port, attempts=retry_attempts, interval=retry_interval)
        # stop dotcms and remove dotcms service from compose file
        stop_container(c, f"{workdir_basedir}_dotcms_mysql_1")
        print("---------------------------------------------------")
        # run pgloader 
        rich.print(f":keycap_3:  running pgloader to convert mysql -> postgres")
        template.write_pgloader_compose()
        c.run(f"cp {compose_file} {compose_file}-pgloader")
        start_docker(c, compose_file)
        sleep(10)
        print("waiting for pgloader to complete")
        postgres_query_content()
        pgloader_cid = get_cid_from_container_name(c, f"{workdir_basedir}_pgloader_1")
        if pgloader_cid:
            c.run(f"docker logs {pgloader_cid}")
        utils.postgres_post_import(template.username, template.password)
        print("stop containers")
        stop_docker(c, compose_file, hide="both")
        print("---------------------------------------------------")
        rich.print(f":keycap_4:  Start dotcms 21.06 on converted postgres db")
        template_dotcms_postgres()
        c.run(f"cp {compose_file} {compose_file}-dotcms-postgres")
        start_docker(c, compose_file)
        utils.check_dotcms_appconfiguration(port=dotcms_port, attempts=retry_attempts, interval=retry_interval)
        stop_container(c, f"{workdir_basedir}-dotcms_postgres-1")
        print("---------------------------------------------------")
        rich.print(f":keycap_5:  Dump postgres database")
        pg_cid = get_cid_from_container_name(c, f"{workdir_basedir}_postgres_1")
        c.run(f"docker exec -i {pg_cid} pg_dump --no-owner --clean --no-password -h localhost -U dbuser dotcms -f /tmp/db.sql")
        c.run(f"docker exec -i {pg_cid} gzip /tmp/db.sql")
        c.run(f"rm -f {pg_dump_file}")
        c.run(f"docker cp {pg_cid}:/tmp/db.sql.gz {pg_dump_file}")
        rich.print(f":keycap_6:  [bold]Here is your postgres sql file:")
        c.run(f"ls -lh {pg_dump_file}")
        print(f"\nDone! For reference, all docker compose files are in {workdir_basedir}")
        c.run(f"docker exec -i {pg_cid} rm -f /tmp/db.sql.gz")
    except Exception as e:
        utils.fail_msg("error encountered")
        print(e)
    stop_docker(c, compose_file, hide="both")


@task
def start_docker(c, compose_file, hide=None):
    c.run(f"docker compose -f {compose_file} up -d --build", hide=hide)
    rich.print(":arrow_up: docker compose up")

@task
def stop_docker(c, compose_file, hide=None):
    c.run(f"docker compose -f {compose_file} down", hide=hide)
    rich.print(":arrow_down: docker compose down")

def get_cid_from_container_name(c, container_name):
    """ deal with "slash/underscore" issues in container names """
    container_name = container_name.replace("-", ".").replace("_", ".")
    command = f"docker ps | grep '{container_name}' " + "| awk '{print $1}'"
    response = c.run(command)
    return response.stdout.strip()

def stop_container(c, container_name):
    print(f"Stopping container {container_name}...")
    cid = get_cid_from_container_name(c, container_name)
    c.run(f"docker stop {cid}")
    print(f"Stopped ")

def template_all_dbs(mysqldump_file):
    """
    create docker-compose.yml running
    postgres, mysql, and opensearch
    """
    template.mysqldump_dotcms=mysqldump_file
    return template.write_dbs_compose()

def template_dotcms_mysql():
    """ create docker-compose.yml running dotcms on mysql """
    return template.compose_dotcms_mysql()

def template_dotcms_postgres():
    """ create docker-compose.yml running dotcms on postgres """
    return template.compose_dotcms_postgres()

def mysql_query_content():
    """ confirm mysql db has dotcms content """
    count = 1
    while count <= retry_attempts:
        sleep(retry_interval)
        contentlet_count = utils.mysql_query_content(
            template.username,
            template.password,
        )
        if contentlet_count:
            return True
        rich.print(f"   attempt [yellow]{count}[/yellow] of {retry_attempts}")
        count += 1
    raise MigrationException("mysldump data does not appear to be imported in mysql")


def postgres_query_content():
    """ confirm postgres db has dotcms content """
    count = 1
    while count <= retry_attempts:
        sleep(retry_interval)
        contentlet_count = utils.postgres_query_content(
            template.username,
            template.password,
        )
        if contentlet_count:
            return True
        rich.print(f"   attempt [yellow]{count}[/yellow] of {retry_attempts}")
        count += 1
    raise MigrationException("data does not appear to be imported in postgres")

