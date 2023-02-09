FROM akkadius/eqemu-server:v11

USER root

ENV GO_VERSION 1.19.1

#############################################
# install dependencies
#############################################
RUN apt-get update && apt-get install -y \
    tree \
    wget \
    procps \
    default-jre \
 && rm -rf /var/lib/apt/lists/*

#############################################
# install go
#############################################
RUN cd /tmp && wget --quiet https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
	&& tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && rm -rf /tmp/*

#############################################
# set go env vars
# https://golang.org/doc/code.html
#############################################
ENV GOPATH=/home/eqemu
ENV GOROOT=/usr/local/go/
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
ENV CGO_ENABLED 0

USER eqemu


#############################################
# download go utilities
# air   - Go project hot reload
# packr - Pack filesystem into go binary
#############################################
RUN go install github.com/cosmtrek/air@latest
RUN go install github.com/gobuffalo/packr/packr@v1.30.1
RUN go install github.com/swaggo/swag/cmd/swag@v1.8.5
RUN go install github.com/google/wire/cmd/wire@latest

#############################################
# node
#############################################
RUN sudo npm install @openapitools/openapi-generator-cli -g

WORKDIR /home/eqemu