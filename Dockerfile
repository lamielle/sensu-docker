FROM debian:jessie
MAINTAINER Alan LaMielle <alan.lamielle+github@gmail.com>

EXPOSE 4567
ENV PATH /opt/sensu/embedded/bin:$PATH

ADD http://repos.sensuapp.org/apt/pubkey.gpg /tmp/sensu-pubkey.gpg

RUN apt-key add /tmp/sensu-pubkey.gpg \
 && echo 'deb http://repos.sensuapp.org/apt sensu main' > /etc/apt/sources.list.d/sensu.list \
 && apt-get update \
 && apt-get install -y sensu ntp unzip build-essential \
 && gem install --no-rdoc --no-ri influxdb hipchat \
 && apt-get remove -y build-essential \
 && apt-get autoremove -y


ADD https://github.com/sensu/sensu-community-plugins/archive/master.zip /opt/sensu/
RUN cd /opt/sensu && unzip master.zip && rm master.zip && \
    mv sensu-community-plugins-master/extensions /etc/sensu && \
    mv sensu-community-plugins-master/handlers   /etc/sensu && \
    mv sensu-community-plugins-master/mutators   /etc/sensu && \
    mv sensu-community-plugins-master/plugins    /etc/sensu && \
    rm -R sensu-community-plugins-master
ADD http-metrics.rb /etc/sensu/plugins/
