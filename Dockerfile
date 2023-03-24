FROM rockylinux:9

LABEL MAINTAINER Square Factory

WORKDIR /app

COPY grendel /app
COPY run.sh /app
RUN chmod +x run.sh
CMD ["./run.sh"]