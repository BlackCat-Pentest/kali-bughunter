#!/bin/bash

# tools install
go env -w GOBIN=/usr/bin/
go env -w GOPATH=/tmp/go/

go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/projectdiscovery/notify/cmd/notify@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/d3mondev/puredns/v2@latest

## install massdns
### puredns prerequisites
git clone https://github.com/blechschmidt/massdns.git /tmp/massdns
cd /tmp/massdns
make
make install

# update nuclei templates
nuclei -ut

# clean cache
go clean --cache
rm -rf /tmp/*
rm -rf /root/.cache/*
