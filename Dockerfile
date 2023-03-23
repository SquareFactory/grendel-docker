FROM rockylinux:9

LABEL MAINTAINER Square Factory

WORKDIR /app

RUN dnf update -y 
RUN dnf install -y -q wget && dnf clean all
RUN wget https://github.com/ubccr/grendel/releases/download/v0.0.8/grendel-0.0.8-amd64.rpm
RUN rpm -ivh grendel-0.0.8-amd64.rpm

COPY run.sh /app
RUN chmod +x run.sh
CMD ["./run.sh"]