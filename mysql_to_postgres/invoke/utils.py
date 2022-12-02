from time import sleep
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from http.client import RemoteDisconnected

import mysql.connector
import psycopg2
import rich

def success_msg(msg):
    rich.print(f":white_check_mark: {msg}")

def fail_msg(msg):
    rich.print(f":x: {msg}")

def check_dotcms_appconfiguration(port=8082, interval=15, attempts=60) -> bool:
    """
    checks for healthy server response from dotCMS
    """
    url = f"http://127.0.0.1:{port}/api/v1/appconfiguration"
    print(f"checking for a success response from {url}, will try for {int((interval * attempts)/60)} minutes")
    count = 0
    while count <= attempts:
        sleep(interval)
        try:
            response = urlopen(Request(url))
        except HTTPError as e:
            msg = f"HTTP error code: {e.code}"
        except URLError as e:
            msg = f"Unable to reach server: {e.reason}"
        except RemoteDisconnected:
            msg = "Remote end closed connection without response"
        except Exception as e:
            print(" Unexpected exception in check_dotcms_appconfiguration():")
            print(e)
            print(" Optimistically proceeding")
        else:
            success_msg("dotcms is healty")
            return True
        count += 1
        print(f"  failed, attempt {count} of {attempts}")
    fail_msg("cannot reach dotcms")
    return False

def mysql_query_content(
    username, 
    password,
    host="127.0.0.1",
    db="dotcms"
    ):
    count = None
    config = {
        'user': username,
        'password': password,
        'host': host,
        'database': db,
        'raise_on_warnings': True,
    }
    query = ("SELECT COUNT(*) FROM contentlet")
    try:
        cnx = mysql.connector.connect(**config)
        cursor = cnx.cursor()
        cursor.execute(query)

        for result in cursor:
            count = int(result[0])
            if count:
                success_msg(f"mysql query: '{query}' == [green]{count}")
        cursor.close()
        cnx.close()
    except Exception as e:
        fail_msg(f"Error querying mysql server: '{query}'")
        print(f"   {e}")
    return count


def postgres_query_content(
        username, 
        password,
        host="127.0.0.1",
        db="dotcms"
    ):
    count = None
    query = ("SELECT COUNT(*) FROM contentlet;")
    try:
        with psycopg2.connect(f"dbname={db} user={username} password={password} host={host}") as cnx:
            with cnx.cursor() as cursor:
                cursor.execute(query)
                for result in cursor.fetchall():
                    count = int(result[0])
                    if count:
                        success_msg(f"postgres query: '{query}' == [green]{count}")
    except Exception as e:
        fail_msg(f"Error querying postgres server: '{query}'")
        print(f"   {e}")
    return count

def postgres_post_import(
        username, 
        password,
        host="127.0.0.1",
        db="dotcms"
    ):
    """
    rename schema from "dotcms" to "public"

    most primary keys in mysql don't have correct names so pgloader assigns a name to primary key indexes like:
        address: idx_16386_primary
        adminconfig: idx_16392_primary
    these need to be renamed to:
        "{table_name}_pkey"
    """
    for query in (
        "ALTER SCHEMA public RENAME TO public_old;",
        "ALTER SCHEMA dotcms RENAME TO public;"
    ):
        postgres_query(username, password, query, host=host, db=db)

    ## special cases: these tables don't use "_pkey" suffix naming convention
    for table, postgres_key in (
        ("notification", "pk_notification"),
        ("system_event", "pk_system_event"),
        ("workflow_action_step", "pk_workflow_action_step"),
    ):
        query = "SELECT constraint_name FROM information_schema.table_constraints WHERE table_schema = 'public' "
        query += f" AND constraint_type = 'PRIMARY KEY'  AND table_name = '{table}';"
        primary_key = postgres_query(username, password, query, host=host, db=db, print_success=False)[0][0]
        query = f"ALTER TABLE {table} RENAME CONSTRAINT {primary_key} TO {postgres_key};"
        postgres_query(username, password, query, host=host, db=db)

    ## end special cases, rename the remaining pkeys to "{table_name}_pkey"
    query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'  AND table_catalog = 'dotcms';"
    tables = [table[0] for table in postgres_query(username, password, query, host=host, db=db, print_success=False)]
    for table in tables:
        query = "SELECT constraint_name FROM information_schema.table_constraints WHERE table_schema = 'public' "
        query += f" AND constraint_type = 'PRIMARY KEY'  AND table_name = '{table}';"
        primary_keys = [pk[0] for pk in postgres_query(username, password, query, host=host, db=db, print_success=False)]
        for primary_key in primary_keys:
            if primary_key.startswith("idx_") and primary_key.endswith("_primary"):
                query = f"ALTER TABLE {table} RENAME CONSTRAINT {primary_key} TO {table}_pkey;"
                postgres_query(username, password, query, host=host, db=db)

def postgres_query(
        username, 
        password,
        query,
        host="127.0.0.1",
        db="dotcms",
        print_success=True,
    ):
    results = None
    query = query.strip()
    try:
        with psycopg2.connect(f"dbname={db} user={username} password={password} host={host}") as cnx:
            with cnx.cursor() as cursor:
                cursor.execute(query)
                # fetch results only for SELECT
                if query.upper().startswith("SELECT"):
                    results = [result for result in cursor.fetchall()]
                if print_success:
                    success_msg(f"postgres query: '{query}'")
    except (psycopg2.errors.DuplicateTable,) as e:
        print(f"Ignoring pg error:  {e}")
    return results

def mysql_post_import(
        username, 
        password,
        host="127.0.0.1",
        db="dotcms"
    ):
    """
    pglaoder casts mysql tinyint(1) -> postgres boolean
    these columns in dotcms mysql are tinyint(4) but used as boolean, 
    so we modify them before running pgloader
    """
    count = None
    config = {
        'user': username,
        'password': password,
        'host': host,
        'database': db,
        'raise_on_warnings': True,
    }
    alter_tables = {
        "company": (
            "`autologin` tinyint(1)", 
            "`strangers` tinyint(1)",
        ),
        "portlet": (
            "`narrow` tinyint(1)", 
            "`active_` tinyint(1)",
        ),
        "publishing_end_point": (
            "`enabled` tinyint(1)", 
            "`sending` tinyint(1)",
        ),
        "sitesearch_audit": (
            "`incremental` tinyint(1) NOT NULL", 
            "`all_hosts` tinyint(1) NOT NULL", 
            "`path_include` tinyint(1) NOT NULL",
        ),
        "user_": (
            "`passwordencrypted` tinyint(1)", 
            "`passwordreset` tinyint(1)", 
            "`male` tinyint(1)", 
            "`dottedskins` tinyint(1)", 
            "`roundedskins` tinyint(1)", 
            "`agreedtotermsofuse` tinyint(1)", 
            "`active_` tinyint(1) ",
        ),
    }
    delete_from = (
        "analytic_summary",
        "analytic_summary_404",
        "analytic_summary_content",
        "analytic_summary_pages",
        "analytic_summary_period",
        "analytic_summary_referer",
        "analytic_summary_visits",
        "analytic_summary_workstream",
        "analytic_summary",
        "clickstream",
        "clickstream_404",
        "clickstream_request",
        "cluster_server",
        "cluster_server_action",
        "cluster_server_uptime",
        "cms_roles_ir",
        "dist_reindex_journal",
        "dot_cluster",
        "fileassets_ir",
        "folders_ir",
        "htmlpages_ir",
        "indicies",
        "notification",
        "publishing_bundle_environment",
        "publishing_bundle",
        "publishing_pushed_assets",
        "publishing_queue",
        "publishing_queue_audit",
        "schemes_ir",
        "sitelic",
        "structures_ir",
        "system_event",
    )
    # tuple of tuples: ( (query, comment), ...)
    missing_migrations = (
        ("CREATE INDEX workflow_idx_action_step ON workflow_action(step_id);", "dotCMS < 5.x may be missing this index"),
    )


    cnx = mysql.connector.connect(**config)
    cursor = cnx.cursor()
    for table in delete_from:
        try:
            query = f"DELETE FROM `{table}`;"
            cursor.execute(query)
            success_msg(query)
        except Exception as e:
            fail_msg(f"Error querying mysql server: '{query}'")
            print(f"   {e}")
    for table, queries in alter_tables.items():
        for modify in queries:
            try:
                query = f"ALTER TABLE `{table}` MODIFY {modify};"
                cursor.execute(query)
                success_msg(query)
            except Exception as e:
                fail_msg(f"Error querying mysql server: '{query}'")
                print(f"   {e}")
    for query, comment in missing_migrations:
        try:
            print(f"# {comment}")
            cursor.execute(query)
            success_msg(query)
        except Exception as e:
            fail_msg(f"Error querying mysql server: '{query}'")
            print(f"   {e}")
    cursor.close()
    cnx.close()
