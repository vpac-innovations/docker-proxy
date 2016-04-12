FROM ubuntu:xenial

MAINTAINER Alex Fraser <alex@vpac-innovations.com.au>

# Install base dependencies.
WORKDIR /root
RUN export DEBIAN_FRONTEND=noninteractive TERM=linux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dpkg-dev \
        iproute2 \
        iptables \
        libssl-dev \
        net-tools \
        patch \
        squid-langpack \
        ssl-cert \
    && apt-get source -y squid3 squid-langpack \
    && apt-get build-dep -y squid3 squid-langpack
#    rm -rf /var/lib/apt/lists/* \
#        /etc/apt/apt.conf.d/30proxy \

# Customise and build Squid, because the official build has no SSL support.
# It's silly, but run dpkg-buildpackage again if it fails the first time. This
# is needed because sometimes the `configure` script is busy when building in
# Docker after autoconf sets its mode +x.
COPY squid3.patch mime.conf /root/
RUN export SQUID_VERSION_FULL=$(apt-cache policy squid3 | grep Candidate \
        | head -n1 | egrep -o '\S+$') \
    && export SQUID_VERSION=$(echo ${SQUID_VERSION_FULL} | egrep -o '^[^-]+') \
    && cd squid3-${SQUID_VERSION} \
    && patch -p1 < /root/squid3.patch \
    && export NUM_PROCS=`grep -c ^processor /proc/cpuinfo` \
    && (dpkg-buildpackage -b -j${NUM_PROCS} \
        || dpkg-buildpackage -b -j${NUM_PROCS}) \
    && export DEBIAN_FRONTEND=noninteractive TERM=linux \
    && (dpkg -i \
            ../squid-common_${SQUID_VERSION_FULL}_*.deb \
            ../squid_${SQUID_VERSION_FULL}_*.deb \
        || apt-get -yf install) \
    && mkdir -p /etc/squid/ssl_cert \
    && cat /root/mime.conf >> /usr/share/squid/mime.conf

COPY squid.conf /etc/squid/squid.conf
COPY start_squid.sh squid_url_rewrite.py /usr/local/bin/

VOLUME /var/spool/squid /etc/squid/ssl_cert
EXPOSE 3128 3129 3130

CMD ["/usr/local/bin/start_squid.sh"]
