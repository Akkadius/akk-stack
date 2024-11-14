FROM debian:12-slim

ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

RUN apt-get update -yqq && \
    groupadd -g ${PGID} backup-cron && \
    useradd -u ${PUID} -g backup-cron -m backup-cron -G backup-cron && \
    usermod -p "*" backup-cron

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    cron \
    libssl-dev \
    make \
    tzdata \
    sudo \
    inotify-tools \
    mariadb-client \
    zip \
    unzip

#######################################################################
# add backup-cron to sudoers
#######################################################################
RUN echo "backup-cron ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

#######################################################################
# default shell
#######################################################################
RUN chsh -s /bin/bash backup-cron

#############################################
# dropbox uploader
#############################################
RUN curl "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o /bin/dropbox_uploader.sh \
    && chmod +x /bin/dropbox_uploader.sh

COPY --chown=backup-cron init-entrypoint.sh /bin/init-entrypoint.sh

RUN chmod +x /bin/init-entrypoint.sh

WORKDIR /home/backup-cron/

USER backup-cron

ENTRYPOINT init-entrypoint.sh
