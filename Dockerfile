FROM kalilinux/kali-rolling

RUN apt update && \
    apt upgrade -y && \
    apt install ca-certificates curl git jq dnsutils golang fierce theharvester grepcidr -y && \
    rm -rf /var/lib/apt/lists/*

COPY tools_install.sh /tmp
RUN ["chmod", "+x", "/tmp/tools_install.sh"]

COPY start.sh /
RUN ["chmod", "+x", "/start.sh"]

RUN /tmp/tools_install.sh

CMD [ "/start.sh" ]