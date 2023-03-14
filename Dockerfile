# docker base image for BGP table generator
# credit to evil routers for the idea: http://evilrouters.net/2009/08/21/getting-bgp-routes-into-dynamips-with-video/

FROM ubuntu:xenial

# basic setup
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y --no-install-recommends \
    install telnet curl openssh-client nano vim-tiny mtr iputils-ping build-essential \
    libssl-dev libffi-dev git net-tools software-properties-common wget iproute2 \
    zlib1g-dev libbz2-dev perl
RUN rm -rf /var/lib/apt/lists/* 
RUN cpan install "Net::BGP" 

# BGPDump
RUN mkdir -p /opt/bgp
WORKDIR /opt/bgp/
RUN wget http://www.ris.ripe.net/source/bgpdump/libbgpdump-1.6.0.tgz
RUN tar -zxvf libbgpdump-1.6.0.tgz
WORKDIR /opt/bgp/libbgpdump-1.6.0/
RUN ./configure 
RUN make
RUN cp bgpdump /usr/local/bin

# BGPSimple
WORKDIR /opt/bgp/
RUN git clone https://github.com/fatred/bgpsimple.git
RUN cp /opt/bgp/bgpsimple/bgp_simple.pl /opt/bgp/

# BGP Route data
WORKDIR /opt/bgp
RUN wget http://data.ris.ripe.net/rrc01/latest-bview.gz
RUN zcat latest-bview.gz | bgpdump -m - > latest-routes

EXPOSE 179/tcp
EXPOSE 22/tcp
    
VOLUME [ "/root", "/usr", "/opt" ]
CMD [ "bash", "-c", "cd /opt/bgp/; exec /opt/bgp/bgp_simple.pl -myas $MYAS -myip `ip route get 8.8.8.8 | head -1 | cut -d' ' -f8` -peerip $PEERIP -peeras $PEERAS -v -p latest-routes" ]
