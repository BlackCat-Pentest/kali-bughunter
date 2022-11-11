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

## Variables

LOGDIR="/results/$DOMAIN"
dns_file="$LOGDIR/dns.txt"
links_file="$LOGDIR/links.txt"
http_and_https_file="$LOGDIR/http_and_https.txt"

## Result Folder

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

## Starting Automation

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Starting Automation"

## DNS Enumeration

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] DNS Enumeration Starting"

if $DNS_BRUTE
then
  fierce --domain $DOMAIN --subdomain-file /wordlists/dns.txt 2> /dev/null | \
    grep Found | \
    awk '{print $2}' | \
    sed 's/.$//' | \
    anew $LOGDIR/dns.txt &> /dev/null
fi

theHarvester -d $DOMAIN -s -v -r -n -c | grep "$DOMAIN" | cut -d":" -f1 | anew $LOGDIR/dns.txt &> /dev/null
subfinder -d $DOMAIN -silent | anew $LOGDIR/dns.txt &> /dev/null

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] DNS enumeration found $(cat $LOGDIR/dns.txt | wc -l) subdomains"

find $LOGDIR/dns.txt -size 0 -print -delete &> /dev/null

## Akamai IP Filter

if $AKAMAI_FILTER
then
  dns_file="$LOGDIR/dns_no_akamai.txt"
  links_file="$LOGDIR/links_no_akamai.txt"
  http_and_https_file="$LOGDIR/http_and_https_no_akamai.txt"

  for dns in $(cat $LOGDIR/dns.txt)
  do
    ipv4_cidrs=$(dig +short $dns | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if grepcidr -f wordlists/akamai_ipv4_CIDRs.txt <(echo $ipv4_cidrs) > /dev/null
    then
      echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$dns] Akamai IP"
    else
      echo $dns | anew $dns_file > /dev/null
    fi
  done
  sleep 2
fi

## Gau

for dns in $(cat $dns_file)
do
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$dns] Gau Starting"
  gau $dns 2> /dev/null | anew $links_file &> /dev/null
done

## WaybackURLs

for dns in $(cat $dns_file)
do
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Waybackurls Starting"
  waybackurls $DOMAIN 2> /dev/null | anew $links_file &> /dev/null
done

## GoSpider

for dns in $(cat $dns_file)
do
  if $GOSPIDER
  then
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$dns] GoSpider Starting"

    gospider -s "https://$dns" -c 10 -d 0 -k 1 -q --sitemap -a 2> /dev/null | \
      grep -v "aws-s3" | \
      sed "s/\[url\] - \[code-200\] - //g" | \
      egrep "https://$dns|http://$dns" | \
      egrep -v "=https://$dns|=http://$dns" | \
      anew $links_file &> /dev/null
  fi
done

## Hakrawler

for dns in $(cat $dns_file)
do
  if $HAKRAWLER
  then
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$dns] Hakrawler Starting"

    echo "https://$dns" | \
      hakrawler -d 99 -u -t 1 2> /dev/null | \
      egrep "https://$dns|http://$dns" | \
      egrep -v "=https://$dns|=http://$dns" | \
      anew $links_file &> /dev/null
  fi
done

## Links

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Gau, WaybackURLs, Hakrawler and GoSpider found $(cat $links_file | wc -l) links"
find $links_file -size 0 -print -delete &> /dev/null

## Open Redirect

cat $links_file | \
  grep -a -i \=http | \
  qsreplace 'http://evil.com' | \
  while read host
  do
    curl -s -L "$host" -I | \
      grep "evil.com" -q && \
      nuclei -u "$host" -nc -t /root/nuclei-templates/vulnerabilities/generic/open-redirect.yaml -rl $NUCLEI_RATE_LIMIT -silent |& \
      tee -a $LOGDIR/open-redirect.txt | \
      notify -silent
  done

find $LOGDIR/open-redirect.txt -size 0 -print -delete &> /dev/null

## HTTPX

cat $dns_file | httpx -rl $HTTPX_RATE_LIMIT -silent 2> /dev/null | anew $http_and_https_file &> /dev/null

## Git Exposed

if $GOOP
then
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Starting Git Exposed with Goop"

  mkdir -p $LOGDIR/goop && cd $LOGDIR/goop
  cat $http_and_https_file | cut -d"/" -f3 | anew -d goopignore.txt | xargs -I@ sh -c 'goop @' &> /dev/null
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Goop found $(ls -1 $LOGDIR/goop | wc -l) probable repositories"
fi

## Nuclei

if $NUCLEI_FULL
then
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Starting Nuclei"

  nuclei -list $links_file -nc -rl $NUCLEI_RATE_LIMIT -severity low,medium,high,critical,unknown -silent |& \
    tee -a $LOGDIR/nuclei.txt | \
    grep -v "\[unknown\]" | \
    notify -silent

  nuclei -list $http_and_https_file -nc -rl $NUCLEI_RATE_LIMIT -severity low,medium,high,critical,unknown -silent |& \
    tee -a $LOGDIR/nuclei.txt | \
    grep -v "\[unknown\]" | \
    notify -silent

  find $LOGDIR/nuclei.txt -size 0 -print -delete &> /dev/null
fi

## Finish

echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$DOMAIN] Finish"
