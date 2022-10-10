#!/bin/bash

## Banner

echo "  _  __     _ _        ____              _    _             _            ";
echo " | |/ /    | (_)      |  _ \            | |  | |           | |           ";
echo " | ' / __ _| |_ ______| |_) |_   _  __ _| |__| |_   _ _ __ | |_ ___ _ __ ";
echo " |  < / _\` | | |______|  _ <| | | |/ _\` |  __  | | | | '_ \| __/ _ \ '__|";
echo " | . \ (_| | | |      | |_) | |_| | (_| | |  | | |_| | | | | ||  __/ |   ";
echo " |_|\_\__,_|_|_|      |____/ \__,_|\__, |_|  |_|\__,_|_| |_|\__\___|_|   ";
echo "                                    __/ |                                ";
echo "                                   |___/                 Raphael Sander  ";
echo ""

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

echo "[$(date "+%d-%m-%y %H:%M:%S")] [$DOMAIN] Starting Automation" | notify -silent

## DNS Enumeration

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] DNS Enumeration Starting" | notify -silent

if $DNS_BRUTE
then
  fierce --domain $DOMAIN --subdomain-file /wordlists/dns.txt | grep Found | awk '{print $2}' | sed 's/.$//' | anew $LOGDIR/dns.txt > /dev/null
fi

theHarvester -d $DOMAIN -s -v -r -n -c | grep "$DOMAIN" | cut -d":" -f1 | anew $LOGDIR/dns.txt > /dev/null
subfinder -d $DOMAIN -silent | anew $LOGDIR/dns.txt > /dev/null

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] DNS enumeration found $(cat $LOGDIR/dns.txt | wc -l) subdomains" | notify -silent

find $LOGDIR/dns.txt -size 0 -print -delete > /dev/null

## Gau

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Gau Starting"
gau $DOMAIN | anew $LOGDIR/links.txt &> /dev/null

## WaybackURLs

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Waybackurls Starting"
waybackurls $DOMAIN | anew $LOGDIR/links.txt &> /dev/null

## Hakrawler

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Hakrawler Starting"

echo "https://$DOMAIN" | \
  hakrawler -d 99 -u | \
  egrep "https://$DOMAIN|http://$DOMAIN" | \
  egrep -v "=https://$DOMAIN|=http://$DOMAIN" | \
  anew $LOGDIR/links.txt &> /dev/null

## Links

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Gau, WaybackURLs and Hakrawler found $(cat $LOGDIR/links.txt | wc -l) links"
find $LOGDIR/links.txt -size 0 -print -delete > /dev/null

## HTTPX

cat $LOGDIR/dns.txt | httpx -silent | anew $LOGDIR/http_and_https.txt > /dev/null

## Git Exposed

if $GOOP
then
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Starting Git Exposed with Goop" | notify -silent

  mkdir -p $LOGDIR/goop && cd $LOGDIR/goop
  cat $LOGDIR/http_and_https.txt | cut -d"/" -f3 | xargs -I@ sh -c 'goop @' > /dev/null
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Goop found $(ls -1 $LOGDIR/goop | wc -l) probable repositories" | notify -silent
fi

## Nuclei

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Starting Nuclei" | notify -silent

nuclei -list $LOGDIR/links.txt -nc -rl $NUCLEI_RATE_LIMIT -severity low,medium,high,critical,unknown -silent | notify -silent |& tee -a $LOGDIR/nuclei.txt
nuclei -list $LOGDIR/http_and_https.txt -nc -rl $NUCLEI_RATE_LIMIT -severity low,medium,high,critical,unknown -silent | notify -silent |& tee -a $LOGDIR/nuclei.txt
find $LOGDIR/nuclei.txt -size 0 -print -delete > /dev/null

## Finish

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Finish" | notify -silent
