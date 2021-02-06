FROM ubuntu:20.04

LABEL maintainer="Webkul"

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            dirmngr \
            node-less \
            python3-pip  \
	    python3-setuptools \
	    gnupg \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb \
        && apt install ./wkhtmltox.deb -y \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip3 install psycogreen==1.0 \
        && pip3 install pandas

# install latest postgresql-client
RUN set -x; \
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main' > etc/apt/sources.list.d/pgdg.list \
        && export GNUPGHOME="$(mktemp -d)" \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
        && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install -y postgresql-client \
        && rm -rf /var/lib/apt/lists/* \
	&& apt update && apt-get install -y npm \
	&& npm install -g less less-plugin-clean-css \
	&& apt-get install -y node-less

# Install Odoo
ENV ODOO_VERSION 14.0

#This binds to service file.So, take care
ARG ODOO_USER=odoo
ARG ODOO_USER_UID=113
ARG ODOO_USER_GID=121

RUN set -x; \
        groupadd -r -g ${ODOO_USER_GID} ${ODOO_USER} \
        && adduser --system --home=/opt/${ODOO_USER} ${ODOO_USER} --uid ${ODOO_USER_UID} --gid ${ODOO_USER_GID} \
        && apt update && apt-get install -y git libpq-dev libxml2-dev libxslt-dev libffi-dev gcc python3-dev libsasl2-dev python-dev libldap2-dev libssl-dev libjpeg-dev \
        && su - ${ODOO_USER} -s /bin/bash -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch ${ODOO_VERSION} --single-branch ." \
        && mkdir /var/log/odoo \
        && chown ${ODOO_USER}:root /var/log/odoo


COPY ./odoo-server.conf /etc/odoo/
RUN set -x; \
	chown -R ${ODOO_USER} /etc/odoo/ \
	&& chmod 640 /etc/odoo/odoo-server.conf \
        && pip3 install wheel
Run set -x; \
	pip3 install -r /opt/odoo/requirements.txt \
        && pip3 install gevent==20.9.0



#Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && mkdir -p /opt/data-dir \
        && chown -R odoo /opt/data-dir \
        #        && chown -R odoo /opt/${ODOO_USER} \
        && chown -R odoo /mnt/extra-addons

COPY ./entrypoint.sh /
COPY ./run_odoo.sh /

#VOLUME ["/mnt/extra-addons","/opt/data_dir"]

# Expose Odoo services
EXPOSE 8069 8071

# Set default user when running the container
USER ${ODOO_USER}


ENTRYPOINT ["/entrypoint.sh"]
