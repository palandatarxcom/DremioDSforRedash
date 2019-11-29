FROM ubuntu:18.04
MAINTAINER Brian Holman <bholman@dezota.com>

ENV DEBIAN_FRONTEND=noninteractive

# Set default timezone
RUN ln -fs /usr/share/zoneinfo/America/Denver /etc/localtime

# Ensure everything is up-to-date
RUN apt-get update --fix-missing && \
    apt-get -y upgrade

# Install System Packages
RUN apt-get -y update && \
    apt install -y python-pip python-dev nginx curl build-essential pwgen sudo wget nodejs npm && \
    apt install -y libffi-dev libssl-dev libmysqlclient-dev libpq-dev freetds-dev libsasl2-dev && \
    apt install -y xmlsec1 && \
    apt install -y postgresql redis-server && \
    apt install -y supervisor

# Create Redash User
RUN adduser --system --no-create-home --disabled-login --gecos "" redash

ENV REDASH_BASE_PATH=/opt/redash
ENV REDASH_BRANCH="master"
ENV REDASH_VERSION=5.0.0-beta
ENV LATEST_URL="https://github.com/getredash/redash/archive/v${REDASH_VERSION}.tar.gz"
ENV VERSION_DIR="$REDASH_BASE_PATH/redash-${REDASH_VERSION}"
ENV REDASH_TARBALL=/tmp/redash.tar.gz
ENV FILES_BASE_URL=https://raw.githubusercontent.com/getredash/redash/${REDASH_BRANCH}/setup/ubuntu/files

# Create Directories
RUN mkdir -p $REDASH_BASE_PATH && \
    chown redash $REDASH_BASE_PATH && \
    sudo -u redash wget "$FILES_BASE_URL/env" -O $REDASH_BASE_PATH/.env

# Extract Redash Sources
RUN sudo -u redash wget "$LATEST_URL" -O "$REDASH_TARBALL" && \
    sudo -u redash tar -C "$REDASH_BASE_PATH" -xvf "$REDASH_TARBALL" && \
    ln -nfs "$VERSION_DIR" $REDASH_BASE_PATH/current && \
    ln -nfs $REDASH_BASE_PATH/.env $REDASH_BASE_PATH/current/.env

# Install Python Packages
RUN pip install --upgrade pip==9.0.3 && \
    pip install setproctitle && \
    pip install -r $REDASH_BASE_PATH/current/requirements.txt && \
    pip install -r $REDASH_BASE_PATH/current/requirements_all_ds.txt

# Create Database
RUN service postgresql start && \
    sed -i -- 's/::1//g' /etc/redis/redis.conf && \
    service redis-server start && \
    sudo -u postgres createuser redash --no-superuser --no-createdb --no-createrole && \
    sudo -u postgres createdb redash --owner=redash && \
    cd $REDASH_BASE_PATH/current && \
    sudo -u redash bin/run ./manage.py database create_tables

# Install Node.js Packages and build assets
RUN apt-get install -y git && \
    cd $REDASH_BASE_PATH/current && \
    npm install && \
    npm run build && \
    chown -R redash $REDASH_BASE_PATH

# Setup Supervisor
RUN wget -O /etc/supervisor/conf.d/redash.conf "$FILES_BASE_URL/supervisord.conf"

# Setup nginx
RUN rm /etc/nginx/sites-enabled/default && \
    wget -O /etc/nginx/sites-available/redash "$FILES_BASE_URL/nginx_redash_site" && \
    ln -nfs /etc/nginx/sites-available/redash /etc/nginx/sites-enabled/redash

# Setup postfix
ENV REDASH_MAIL_SERVER="localhost"
ENV REDASH_MAIL_PORT="25"
RUN echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections && \
    apt-get install -y postfix
COPY main.cf /etc/postfix/main.cf
RUN newaliases

COPY env $REDASH_BASE_PATH/.env
COPY run.sh /run.sh

# Added ODBC Support for Dremio with updated Dezota Driver
RUN apt-get install -y alien unixodbc unixodbc-dev && \
    wget https://download.dremio.com/odbc-driver/1.3.19.1052/dremio-odbc-1.3.19.1052-1.x86_64.rpm && \
    alien -i --scripts dremio-odbc-1.3.19.1052-1.x86_64.rpm && \
    rm -f dremio-odbc-1.3.19.1052-1.x86_64.rpm && \
    pip install pyodbc pandas && \
    wget -O $REDASH_BASE_PATH/current/redash/query_runner/dremio_odbc.py "https://raw.githubusercontent.com/Dezota/DremioDSforRedash/master/dremio_odbc.py" && \
    wget -O $REDASH_BASE_PATH/current/client/dist/images/db-logos/dremio_odbc.png "https://raw.githubusercontent.com/Dezota/DremioDSforRedash/master/dremio_odbc.png" && \
    wget -O $REDASH_BASE_PATH/current/client/app/assets/images/db-logos/dremio_odbc.png "https://raw.githubusercontent.com/Dezota/DremioDSforRedash/master/dremio_odbc.png"

# Added support for Snowflake Data Source
RUN pip install snowflake-connector-python

RUN touch /firstime && \
    chmod +x /run.sh && \
    apt-get -y clean && \
    apt-get -q -y autoremove && \
    rm -f $REDASH_TARBALL && \
    rm -rf /tmp/* && \
    rm -rf /var/log/supervisor/*

EXPOSE 80

CMD ["/run.sh"]
