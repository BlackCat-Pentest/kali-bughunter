#!/bin/bash

LOGDIR="/results/$DOMAIN"
mkdir -p $LOGDIR

## Notify Configuration
mkdir -p /root/.config/notify/

cat << EOF > /root/.config/notify/provider-config.yaml
telegram:
  - id: "tel"
    telegram_api_key: "${TELEGRAM_API_KEY}"
    telegram_chat_id: "${TELEGRAM_CHAT_ID}"
    telegram_format: "{{data}}"
EOF

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Starting Automation" | notify -silent

## DNS Enumeration

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] DNS Enumeration Starting" | notify -silent

if $DNS_BRUTE
then
  fierce --domain $DOMAIN --subdomain-file /wordlists/dns.txt | grep Found | awk '{print $2}' | sed 's/.$//' | anew $LOGDIR/dns.txt > /dev/null
fi

theHarvester -d $DOMAIN -s -v -r -n -c | grep "$DOMAIN" | cut -d":" -f1 | anew $LOGDIR/dns.txt > /dev/null
subfinder -d $DOMAIN -silent | anew $LOGDIR/dns.txt > /dev/null

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] DNS enumeration found $(cat $LOGDIR/dns.txt | wc -l) subdomains" | notify -silent

find $LOGDIR/dns.txt -size 0 -print -delete > /dev/null

## Gau/WaybackURLs

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Gau and Waybackurls Starting" | notify -silent

gau $DOMAIN | anew $LOGDIR/links.txt > /dev/null
waybackurls $DOMAIN | anew $LOGDIR/links.txt > /dev/null
find $LOGDIR/links.txt -size 0 -print -delete > /dev/null

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Gau and Waybackurls found $(cat $LOGDIR/links.txt | wc -l) links" | notify -silent

## HTTPX

cat $LOGDIR/dns.txt | httpx -silent | anew $LOGDIR/http_and_https.txt > /dev/null

## Git Exposed

if $GOOP
then
  echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Starting Git Exposed with Goop" | notify -silent

  mkdir -p $LOGDIR/goop && cd $LOGDIR/goop
  cat $LOGDIR/http_and_https.txt | cut -d"/" -f3 | xargs -I@ sh -c 'goop @' > /dev/null
  echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Goop found $(ls -1 $LOGDIR/goop | wc -l) probable repositories" | notify -silent
fi

## Nuclei

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Starting Nuclei" | notify -silent

nuclei -list $LOGDIR/links.txt -nc -rl $NUCLEI_RATE_LIMIT -severity low,medium,high,critical,unknown -silent | notify -silent |& tee -a $LOGDIR/nuclei.txt
nuclei -list $LOGDIR/http_and_https.txt -nc -rl $NUCLEI_RATE_LIMIT -severity low,medium,high,critical,unknown -silent | notify -silent |& tee -a $LOGDIR/nuclei.txt
find $LOGDIR/nuclei.txt -size 0 -print -delete > /dev/null

## Finish

echo "[$DOMAIN] [$(date "+%d-%m-%y %H:%M")] Finish" | notify -silent
