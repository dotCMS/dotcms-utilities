"""
templates for docker-compose and db init files
"""
from pathlib import Path

import utils

class Template:
    def __init__(
        self,
        username=None,
        dbname=None,
        password=None,
        workdir=None,
        mysqldump_dotcms=None,
    ):
        assert username and dbname and password and workdir
        self.username = username
        self.dbname = dbname
        self.password = password
        self.mysqldump_dotcms = mysqldump_dotcms
        self.dotcms_version = "21.06.11_lts_7e8134d"
        # docker volumes and networks
        self.db_net = "db-net"
        self.opensearch_net = "opensearch-net"
        self.pg_volume = "pg-volume"
        self.mysql_volume = "mysql-volume"
        self.cms_volume_mysql = "cms-volume-mysql"
        self.cms_volume_postgres = "cms-volume-postgres"
        self.opensearch_volume = "opensearch-volume"
        # filesystem paths
        self.workdir = Path(workdir)
        self.pgloader_file = "pgload-dotcms.load"
        self.pgloader_file_path = self.workdir / "pgload-dotcms.load"
        self.mysql_init_file = self.workdir / "mysql_init.sql"
        self.compose_file_path = self.workdir / "docker-compose.yml"
        self.dockerfile_path = self.workdir / "Dockerfile"
        self.container_mysqldump_path = "/tmp/dotcms.sql"
        self.container_pgloader_path = "/opt/dotcms.load"
        self.compose_file_path.touch()
        self.mysql_init_file.touch()
        # write files needed to start containers
        self.write_mysql_init_file()

    def write_mysql_init_file(self):
        with open(self.mysql_init_file, "w") as f:
            f.write(
f"""CREATE USER '{self.username}'@'%' IDENTIFIED BY '{self.password}';
CREATE USER '{self.username}'@'localhost' IDENTIFIED BY '{self.password}';
CREATE USER 'user_dotcms'@'%' IDENTIFIED BY '{self.password}';
CREATE DATABASE {self.dbname} default character set = utf8 default collate = utf8_general_ci;
GRANT ALL PRIVILEGES ON {self.dbname}.* TO '{self.username}'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON {self.dbname}.* TO '{self.username}'@'localhost' WITH GRANT OPTION;
USE {self.dbname};
SOURCE {self.container_mysqldump_path};
COMMIT;
"""
            )

    def write_dbs_compose(self):
        """
        write docker-compose database services bits to the compose file 
        """
        dbs = self.compose_all_dbs()
        with open(self.compose_file_path, 'w') as f:
            f.write(dbs)
        utils.success_msg(f"compose file with databases only: {self.compose_file_path}") 
        print(f"    loading mysqldump file {self.mysqldump_dotcms}")
        return str(self.compose_file_path)

    def write_pgloader_compose(self):
        pgloader = self.compose_all_dbs()
        pgloader += self.compose_pgloader()
        with open(self.compose_file_path, 'w') as f:
            f.write(pgloader)

    def compose_head(self):
        return f"""version: '3.5'
networks:
  {self.db_net}:
  {self.opensearch_net}:
volumes:
  {self.pg_volume}:
  {self.mysql_volume}:
  {self.opensearch_volume}:
  {self.cms_volume_mysql}:
  {self.cms_volume_postgres}:
services:"""

    def compose_postgres(self, version=13):
        return f"""
  postgres:
    image: postgres:{version}
    command: postgres -c 'max_connections=400' -c 'shared_buffers=128MB'
    environment:
        POSTGRES_USER: {self.username}
        POSTGRES_DB: {self.dbname}
        POSTGRES_PASSWORD: {self.password}
        PGPASSWORD: {self.password}
    volumes:
      - {self.pg_volume}:/var/lib/postgresql/data
    networks:
      - {self.db_net}
    ports:
      - "5432:5432"
  """

    def compose_mysql(self):
        assert self.mysqldump_dotcms
        return f"""
  mysql:
    image: mysql/mysql-server:5.7
    command: --lower_case_table_names=1 --max_allowed_packet=32M
    environment:
      MYSQL_DATABASE: {self.username}
      MYSQL_ROOT_PASSWORD: {self.password}
      MYSQL_ROOT_HOST: '%'
    volumes:
      - {self.mysql_volume}:/var/lib/mysql
      - {self.mysql_init_file}:/docker-entrypoint-initdb.d/initial.sql
      - {self.mysqldump_dotcms}:{self.container_mysqldump_path}
    networks:
      - {self.db_net}
    ports:
      - "3306:3306"
"""


    def compose_opensearch(self):
        return f"""
  opensearch:
    image: opensearchproject/opensearch:1.3.6
    environment:
      - cluster.name=elastic-cluster
      - discovery.type=single-node
      - data
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xmx1G "
    ulimits:
      memlock:
        soft: -1 # Set memlock to unlimited (no soft or hard limit)
        hard: -1
      nofile:
        soft: 65536 # Maximum number of open files for the opensearch user - set to at least 65536
        hard: 65536
    volumes:
      - {self.opensearch_volume}:/usr/share/opensearch/data
    networks:
      - {self.opensearch_net}
  """

    def compose_all_dbs(self) -> str:
        return self.compose_head() + self.compose_opensearch() + self.compose_mysql() + self.compose_postgres()

    def compose_dotcms_mysql(self):
      compose = self.compose_all_dbs()
      compose += self.compose_dotcms_mysql_service()
      with open(self.compose_file_path, 'w') as f:
          f.write(compose)
      return str(self.compose_file_path)
      
    def compose_dotcms_postgres(self):
      compose = self.compose_all_dbs()
      compose += self.compose_dotcms_postgres_service()
      with open(self.compose_file_path, 'w') as f:
          f.write(compose)
      return str(self.compose_file_path)

    def compose_dotcms_postgres_service(self):
        return f"""
  dotcms_postgres:
    image: dotcms/dotcms:{self.dotcms_version}
    environment:
        CMS_JAVA_OPTS: '-Xmx1g '
        LANG: 'C.UTF-8'
        TZ: 'UTC'
        # 21.06 syntax
        DOT_ES_AUTH_BASIC_PASSWORD: 'admin'
        DOT_ES_ENDPOINTS: 'https://opensearch:9200'
        DOT_INITIAL_ADMIN_PASSWORD: 'admin'
        PROVIDER_DB_DNSNAME: postgres
        PROVIDER_DB_USERNAME: {self.username}
        PROVIDER_DB_PASSWORD: {self.password}
        # >= 22.03 syntax
        DB_BASE_URL: "jdbc:postgresql://postgres/{self.dbname}"
        DB_USERNAME: {self.username}
        DB_PASSWORD: {self.password}
        DOT_DOTCMS_CLUSTER_ID: dotcmspostgres
    depends_on:
      - postgres
      - opensearch
    volumes:
      - {self.cms_volume_postgres}:/data/shared
    networks:
      - {self.db_net}
      - {self.opensearch_net}
    ports:
      - "8082:8082"
"""

    def compose_dotcms_mysql_service(self):
        assert self.mysqldump_dotcms
        return f"""
  dotcms_mysql:
    image: dotcms/dotcms:{self.dotcms_version}
    environment:
        CMS_JAVA_OPTS: '-Xmx1g '
        LANG: 'C.UTF-8'
        TZ: 'UTC'
        DOT_ES_AUTH_BASIC_PASSWORD: 'admin'
        DOT_ES_ENDPOINTS: 'https://opensearch:9200'
        DOT_INITIAL_ADMIN_PASSWORD: 'admin'
        PROVIDER_DB_DRIVER: MYSQL
        PROVIDER_DB_DNSNAME: mysql
        PROVIDER_DB_USERNAME: {self.username}
        PROVIDER_DB_PASSWORD: {self.password}
        DOT_DOTCMS_CLUSTER_ID: dotcmsmysql
    depends_on:
      - mysql
      - opensearch
    volumes:
      - {self.cms_volume_mysql}:/data/shared
    networks:
      - {self.db_net}
      - {self.opensearch_net}
    ports:
      - "8082:8082"
"""

    def compose_pgloader(self):
        return f"""
  pgloader:
    image: dimitri/pgloader:ccl.latest
    command: pgloader --with "batch rows = 100000" --with "preserve index names" mysql://{self.username}:{self.password}@mysql/{self.dbname} pgsql://{self.username}:{self.password}@postgres/{self.dbname}
    depends_on:
      - mysql
      - postgres
    networks:
      - {self.db_net}
""" 
