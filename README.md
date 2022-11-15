# Kali BugHunter

This project is about of a develop of a container with some tools and scripts to improve your bug bounty.

## List of tools

- fff
- airixss
- freq
- goop
- hakrawler
- httprobe
- meg
- haklistgen
- haktldextract
- hakcheckurl
- tojson
- gowitness
- rush
- naabu
- hakcheckurl
- shuffledns
- rescope
- gron
- html-tool
- chaos
- gf
- qsreplace
- Amass
- ffuf
- assetfinder
- github-subdomains
- cf-check
- waybackurls
- nuclei
- anew
- notify
- mildew
- dirdar
- unfurl
- shuffledns
- httpx
- github-endpoints
- dnsx
- subfinder
- gauplus
- subjs
- jsubfinder
- Gxss
- gospider
- crobat
- dalfox
- puredns
- cariddi
- interactsh-client
- kxss
- getJS
- hakrevdns

- fierce
- theHarvester

## Environments Variables

| Variables         | Type                  | Example                                       |
| ----------------- | --------------------- | --------------------------------------------- |
| DOMAIN            | string                | target.com                                    |
| TELEGRAM_API_KEY  | string                | 987654321:a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r |
| TELEGRAM_CHAT_ID  | string                | 123456789                                     |
| GOOP              | bool (true \| false)  | true                                          |
| DNS_BRUTE         | bool (true \| false)  | false                                         |
| NUCLEI_RATE_LIMIT | int                   | 100                                           |
| HAKRAWLER         | bool (true \| false)  | true                                          |
| GOSPIDER          | bool (true \| false)  | true                                          |
| HTTPX_RATE_LIMIT  | int                   | 90                                            |
| AKAMAI_FILTER     | bool (true \| false)  | false                                         |
| NUCLEI_FULL       | bool (true \| false ) | true                                          |

## Building

```bash
docker build -t kali-bughunter .
```

## Running

```bash
docker run -it --rm --name kali-bughunter \
    -v $(pwd)/results:/results \
    -v $(pwd)/wordlists:/wordlists \
    --env-file .env kali-bughunter
```

### All in One

Running all env files in the env folder in parallel:

```bash
docker build -t kali-bughunter .
for x in env/*.env
do
  docker run --rm -d --name kali-bughunter-$(echo $x | cut -d"." -f1 | cut -d"/" -f2) \
    -v $(pwd)/results:/results \
    -v $(pwd)/wordlists:/wordlists \
    --env-file $x kali-bughunter
done
```

*Make sure that you machine has resources to run all the containers that will be created by env files.*

---

Running all env files in the env folder with only four containers in parallel per time:

```bash
docker build -t kali-bughunter .
ls -1 env/ | xargs -I@ -P4 sh -c 'docker run --rm \
    --name kali-bughunter-$(echo @ | cut -d"." -f1 | cut -d"/" -f2) \
    -v $(pwd)/results:/results \
    -v $(pwd)/wordlists:/wordlists \
    --env-file env/@ kali-bughunter'
```

---

Running five containers in parallel using a list of bugbounties that pay bounty:

```bash
sudo apt update && sudo apt install jq -y
docker build -t kali-bughunter .
wget https://raw.githubusercontent.com/projectdiscovery/public-bugbounty-programs/master/chaos-bugbounty-list.json -O chaos-bugbounty-list.json
cat chaos-bugbounty-list.json | jq -r '.programs[] | select(.bounty==true) | .domains[]' | \
  shuf | xargs -I@ -P5 sh -c 'docker run --rm --name kali-bughunter-$(echo @ | cut -d"." -f1 | cut -d"/" -f2) \
    -v $(pwd)/results:/results \
    -v $(pwd)/wordlists:/wordlists \
    -e DOMAIN=@ \
    -e TELEGRAM_API_KEY=<TELEGRAM_API_KEY> \
    -e TELEGRAM_CHAT_ID=<TELEGRAM_CHAT_ID> \
    -e GOOP=false \
    -e DNS_BRUTE=false \
    -e NUCLEI_RATE_LIMIT=5 \
    -e HAKRAWLER=false \
    -e GOSPIDER=false \
    -e HTTPX_RATE_LIMIT=10 \
    -e AKAMAI_FILTER=true \
    -e NUCLEI_FULL=false \
    kali-bughunter'
```

## Project Path Structure

```text
📂env (Enviroment file, each one to diferent domain)
📂results
 ┗ 📂<DOMAIN>
   ┣ 📂goop (Git Exposed with goop)
   ┃  ┗ 📜goopignore.txt (List of domains to ignore in goop)
   ┣ 📜dns.txt (All subdomains found)
   ┣ 📜http_and_https.txt (All subdomains with HTTP [:80] and HTTPS [:443] accessible)
   ┗ 📜open-redirect.txt (All possible open redirect found)
📂wordlists
 ┣ 📜akamai_ipv4_CIDRs.txt (Akamai IPv4 list)
 ┣ 📜akamai_ipv6_CIDRs.txt (Akamai IPv6 list)
 ┣ 📜chaos-bugbounty-list.json (BugBounty programs)
 ┗ 📜dns.txt (Wordlist to DNS brute force)
📜.gitignore (Files and folder that not be send to the Git repositorie)
📜Dockerfile (Instructions to build docker images)
📜README.md (This documentation)
📜start.sh (Entrypoint script that run when start the kali-bughunter container)
📜tools_install.sh (Script to install the all tools into the kali-bughunter image in the build)
```

## Wordlists Origin

### Akamai

Information: <https://techdocs.akamai.com/property-mgr/docs/origin-ip-access-control>  
File: <https://techdocs.akamai.com/property-manager/pdfs/akamai_ipv4_ipv6_CIDRs-txt.zip>

### DNS

<https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/bitquark-subdomains-top100000.txt>

### Chaos BugBounty

<https://raw.githubusercontent.com/projectdiscovery/public-bugbounty-programs/master/chaos-bugbounty-list.json>

### DNS Resolvers

<https://public-dns.info/nameservers.txt>
