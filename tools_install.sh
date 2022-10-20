#!/bin/bash

# tools install
go env -w GOBIN=/usr/bin/
go env -w GOPATH=/tmp/go/

go install github.com/tomnomnom/fff@latest
go install github.com/ferreiraklet/airixss@latest
go install github.com/takshal/freq@latest
go install github.com/deletescape/goop@latest
go install github.com/hakluke/hakrawler@latest
go install github.com/tomnomnom/httprobe@latest
go install github.com/tomnomnom/meg@latest
go install github.com/hakluke/haklistgen@latest
go install github.com/hakluke/haktldextract@latest
go install github.com/hakluke/hakcheckurl@latest
go install github.com/tomnomnom/hacks/tojson@latest
go install github.com/sensepost/gowitness@latest
go install github.com/shenwei356/rush@latest
go install github.com/projectdiscovery/naabu/cmd/naabu@latest
go install github.com/hakluke/hakcheckurl@latest
go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install github.com/root4loot/rescope@latest
go install github.com/tomnomnom/gron@latest
go install github.com/tomnomnom/hacks/html-tool@latest
go install github.com/projectdiscovery/chaos-client/cmd/chaos@latest
go install github.com/tomnomnom/gf@latest
go install github.com/tomnomnom/qsreplace@latest
go install github.com/OWASP/Amass/v3/...@latest
go install github.com/ffuf/ffuf@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/gwen001/github-subdomains@latest
go install github.com/dwisiswant0/cf-check@latest
go install github.com/tomnomnom/hacks/waybackurls@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/tomnomnom/anew@latest
go install github.com/projectdiscovery/notify/cmd/notify@latest
go install github.com/daehee/mildew/cmd/mildew@latest
go install github.com/m4dm0e/dirdar@latest
go install github.com/tomnomnom/unfurl@latest
go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/gwen001/github-endpoints@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/bp0lr/gauplus@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/lc/subjs@latest
go install github.com/hiddengearz/jsubfinder@latest
go install github.com/KathanP19/Gxss@latest
go install github.com/jaeles-project/gospider@latest
go install github.com/cgboal/sonarsearch/crobat@latest
go install github.com/hahwul/dalfox/v2@latest
go install github.com/d3mondev/puredns/v2@latest
go install github.com/edoardottt/cariddi/@latest
go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
go install github.com/tomnomnom/hacks/kxss@latest
go install github.com/003random/getJS@latest
go install github.com/hakluke/hakrevdns@latest

## install patterns into gf
mkdir /root/.gf
cp /tmp/go/pkg/mod/github.com/tomnomnom/$(ls /tmp/go/pkg/mod/github.com/tomnomnom/ | grep "gf@")/examples/* /root/.gf/

cd /tmp && git clone https://github.com/1ndianl33t/Gf-Patterns
mv /tmp/Gf-Patterns/*.json ~/.gf

# clean cache
go clean --cache
rm -rf /tmp/*
rm -rf /root/.cache/*

# update nuclei templates
nuclei -ut
