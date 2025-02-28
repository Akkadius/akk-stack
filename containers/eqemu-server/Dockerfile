FROM debian:12-slim

LABEL maintainer="Akkadius <akkadius1@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID=${PUID}
ARG PGID=1000
ENV PGID=${PGID}

ENV TZ=US/Central

ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++

RUN apt-get update -yqq && \
    groupadd -g ${PGID} eqemu && \
    useradd -u ${PUID} -g eqemu -m eqemu -G eqemu && \
    usermod -p "*" eqemu

RUN apt-get update && apt-get install -y \
	bash \
	build-essential \
	cmake \
	cpp \
	ccache \
	clang \
	curl \
	cron \
	debconf-utils \
	default-libmysqlclient-dev \
	g++ \
	gcc \
	gdb \
	git \
	git \
	git-core \
	htop \
	iputils-ping \
	iproute2 \
	inotify-tools \
	jq \
	libio-stringy-perl \
	libjson-perl \
	liblua5.1 \
	liblua5.1-dev \
	libluabind-dev \
	libmysql++ \
	libperl-dev \
	libdbd-mysql-perl \
	libsodium-dev \
	libssl-dev \
	lua5.1 \
	nano \
	tmux \
	make \
	mariadb-client \
	minizip \
	ninja-build \
	net-tools \
	openssh-server \
	rsyslog \
	logrotate \
	sudo \
	telnet \
	zip \
	unzip \
	uuid-dev \
	wget \
	zlib1g-dev \
	vim

#######################################################################
# node
#######################################################################
RUN apt-get update && apt-get install -y curl sudo gnupg nodejs npm \
	&& npm install -g nodemon \
	&& npm install -g mocha

#######################################################################
# add eqemu to sudoers
#######################################################################
RUN echo "eqemu ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

#######################################################################
# default shell
#######################################################################
RUN chsh -s /bin/bash eqemu

#############################################
# install eqemu-perl
#############################################
RUN mkdir -p /opt/eqemu-perl && \
	mkdir -p /tmp/eqemu-perl && \
	chown eqemu:eqemu /opt/eqemu-perl -R && \
    # downloading from github this way is slow, so we pull from a release
	# cd /tmp && wget -q https://github.com/Perl/perl5/archive/refs/tags/v5.32.1.tar.gz -O perl.tar.gz && \
	cd /tmp && wget -q https://github.com/EQEmu/Server/releases/download/v1.2/perl5-5.32.1.tar.gz -O perl.tar.gz && \
	cd /tmp && tar -xzf perl.tar.gz --strip-components=1 -C /tmp/eqemu-perl && \
	cd /tmp/eqemu-perl && ./Configure -des -Dprefix=/opt/eqemu-perl -Dusethreads -Dusemultiplicity -Duse64bitall -Dnoextensions -Duseshrplib 1> /dev/null && \
	cd /tmp/eqemu-perl && make -j$(nproc) 1> /dev/null && \
	# cd /opt/eqemu-perl && make -j$(shell nproc) test_harness
	cd /tmp/eqemu-perl && make -j$(nproc) install 1> /dev/null && \
	rm -rf /tmp/perl.tar.gz && \
	rm -rf /tmp/eqemu-perl && \
	# install DBI and DBD::mysql
	yes | /opt/eqemu-perl/bin/perl -MCPAN -e 'install App::cpanminus'

RUN /opt/eqemu-perl/bin/cpanm --notest DBI && \
    /opt/eqemu-perl/bin/cpanm --notest DBD::mysql@4.046_01 && \
    /opt/eqemu-perl/bin/cpanm --notest JSON && \
    /opt/eqemu-perl/bin/cpanm --notest Data::Dumper && \
    /opt/eqemu-perl/bin/cpanm --notest File::Find && \
    /opt/eqemu-perl/bin/cpanm --notest File::Path && \
    /opt/eqemu-perl/bin/cpanm --notest List::Util && \
    /opt/eqemu-perl/bin/cpanm --notest Switch && \
    /opt/eqemu-perl/bin/cpanm --notest Net::Telnet && \
    /opt/eqemu-perl/bin/cpanm -n Module::Refresh && \
    chown eqemu:eqemu -R /opt/eqemu-perl/

#############################################
# logrotate
#############################################

COPY logrotate.conf /etc/logrotate.d/var-log

# Create a cron job to run logrotate at midnight
RUN echo "0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf" > /etc/cron.d/logrotate

# Give execute permissions to cron job file
RUN chmod 0644 /etc/cron.d/logrotate

# Ensure cron runs on container start
RUN crontab /etc/cron.d/logrotate

# Make sure that ssh auth log is created and owned by eqemu
RUN touch /var/log/auth.log && \
    chown eqemu:eqemu /var/log/auth.log

#############################################
# entrypoint script
#############################################
COPY --chown=eqemu:eqemu ./entrypoint.pl /bin/entrypoint.pl
RUN chmod +x /bin/entrypoint.pl

#############################################
# user
#############################################
USER eqemu
WORKDIR /home/eqemu

ENTRYPOINT ["/bin/bash", "-c", "entrypoint.pl; /bin/bash"]
