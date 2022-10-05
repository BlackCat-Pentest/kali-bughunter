FROM kalilinux/kali-rolling

RUN apt update && \
    apt upgrade -y && \
    apt install ca-certificates curl golang fierce theharvester -y && \
    rm -rf /var/lib/apt/lists/*

COPY tools_install.sh /tmp
COPY start.sh /

RUN /tmp/tools_install.sh

CMD [ "/start.sh" ]