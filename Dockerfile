FROM debian:jessie
MAINTAINER Alan LaMielle <alan.lamielle+github@gmail.com>

ADD http://repos.sensuapp.org/apt/pubkey.gpg /tmp/sensu-pubkey.gpg

RUN apt-key add /tmp/sensu-pubkey.gpg \
 && echo 'deb http://repos.sensuapp.org/apt sensu main' > /etc/apt/sources.list.d/sensu.list \
 && apt-get update \
 && apt-get install -y sensu
