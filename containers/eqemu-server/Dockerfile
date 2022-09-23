FROM debian:11-slim

LABEL maintainer="Akkadius <akkadius1@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

ENV TZ=US/Central

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
	libsodium-dev \
	libssl-dev \
	lua5.1 \
	make \
	mariadb-client \
	minizip \
	ninja-build \
	net-tools \
	openssh-server \
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
# cpan modules
#############################################
RUN yes '' | sudo perl -MCPAN -e 'install Switch' && sudo perl -MCPAN -e 'install Net::Telnet'

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
