FROM mariadb:latest

LABEL maintainer="Akkadius <akkadius1@gmail.com>"
COPY my.cnf /etc/mysql/conf.d/my.cnf

ARG INNODB_BUFFER_POOL_SIZE="256MB"

RUN echo "[mysqld]" >> /etc/mysql/conf.d/my.cnf && \
	echo "innodb_buffer_pool_size  = ${INNODB_BUFFER_POOL_SIZE}" >> /etc/mysql/conf.d/my.cnf

EXPOSE 3306
