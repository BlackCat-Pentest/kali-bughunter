#!/bin/python3

import os
from pymongo import MongoClient
import tldextract
import subprocess
import json
import datetime


def banner():
    print("  _  __     _ _        ____              _    _             _           ")
    print(" | |/ /    | (_)      |  _ \            | |  | |           | |          ")
    print(" | ' / __ _| |_ ______| |_) |_   _  __ _| |__| |_   _ _ __ | |_ ___ _ __")
    print(" |  < / _` | | |______|  _ <| | | |/ _` |  __  | | | | '_ \| __/ _ \ '__|")
    print(" | . \ (_| | | |      | |_) | |_| | (_| | |  | | |_| | | | | ||  __/ |  ")
    print(" |_|\_\__,_|_|_|      |____/ \__,_|\__, |_|  |_|\__,_|_| |_|\__\___|_|  ")
    print("                                    __/ |                               ")
    print("                                   |___/                 Raphael Sander ")
    print("")


def db_connection():
    mongodb_host = "172.22.96.1"

    client = MongoClient(f"mongodb://{mongodb_host}/")
    db = client["bugbounty"]

    return db


def subfinder(domain):

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), "starting subfinder")

    subdomain_sum = 0

    command = subprocess.run(["subfinder", "-all", "-d", domain, "-silent", "-json"], capture_output=True, text=True)
    lines = command.stdout.strip().split("\n")
    
    for line in lines:
        subdomain_json = json.loads(line)
        
        db.subdomains.update_one(
            {
                "subdomain": subdomain_json['host']
            },
            {
                "$set": {
                    "subdomain": subdomain_json['host'],
                    "domain": subdomain_json['input']
                },
                "$addToSet": {
                    "source": subdomain_json['source']
                }
            },
            upsert=True
        )

        subdomain_sum += 1
    
    db.tasks.update_one(
        {
            "domain": domain
        },
        {
            "$set": {
                "domain": domain
            },
            "$addToSet": {
                "done": "subfinder"
            }
        },
        upsert=True
    )

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), f"subfinder found {subdomain_sum} subdomains")


def puredns(domain):

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), "starting puredns")

    subdomain_sum = 0

    command = subprocess.run(["puredns",
                              "bruteforce", "wordlists/dns.txt",
                              "--resolvers", "wordlists/resolvers.txt",
                              domain,
                              "--rate-limit", "10",
                              "--rate-limit-trusted", "10",
                              "--quiet"
                             ], capture_output=True, text=True)
    
    lines = command.stdout.strip().split("\n")
    
    for line in lines:
        subdomain = line

        db.subdomains.update_one(
            {
                "subdomain": subdomain
            },
            {
                "$set": {
                    "subdomain": subdomain,
                    "domain": domain
                },
                "$addToSet": {
                    "source": "puredns"
                }
            },
            upsert=True
        )

        subdomain_sum += 1
    
    db.tasks.update_one(
        {
            "domain": domain
        },
        {
            "$set": {
                "domain": domain
            },
            "$addToSet": {
                "done": "puredns"
            }
        },
        upsert=True
    )

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), f"puredns found {subdomain_sum} subdomains")


def gau(domain):

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), "starting gau")

    url_sum = 0

    command = subprocess.run(["gau", "--json", "--subs", domain], capture_output=True, text=True)
    lines = command.stdout.strip().split("\n")
    
    for line in lines:
        url_json = json.loads(line)

        url = url_json['url']
        
        extract = tldextract.extract(url)
        domain_extract = extract.registered_domain
        subdomain_extract = '.'.join(part for part in extract if part)
        
        db.urls.update_one(
            {
                "url": url
            },
            {
                "$set": {
                    "url": url,
                    "domain": domain_extract,
                    "subdomain": subdomain_extract
                },
                "$addToSet": {
                    "source": "gau"
                }
            },
            upsert=True
        )

        url_sum += 1
    
    db.tasks.update_one(
        {
            "domain": domain
        },
        {
            "$set": {
                "domain": domain
            },
            "$addToSet": {
                "done": "gau"
            }
        },
        upsert=True
    )

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), f"gau found {url_sum} urls")

    subdomains = set([url['subdomain'] for url in db.urls.find({"source": "gau", "domain": domain})])
    subdomains = list(subdomains)

    subdomains_sum = len(subdomains)

    for subdomain in subdomains:
        db.subdomains.update_one(
            {
                "subdomain": subdomain
            },
            {
                "$set": {
                    "subdomain": subdomain,
                    "domain": domain
                },
                "$addToSet": {
                    "source": "gau"
                }
            },
            upsert=True
        )

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), f"gau found {subdomains_sum} subdomains")


def dnsx(domain):

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), "starting dnsx")

    subdomains = db.subdomains.find({"domain": domain})

    subdomain_list = ""
    subdomain_dnsx_sum = 0
    
    for subdomain in subdomains:
        subdomain_list = subdomain_list + "\n" + subdomain['subdomain']
    
    command = subprocess.run(["dnsx", "-json", "-silent", "-rate-limit", "10", "-threads", "1"], capture_output=True, text=True, input=subdomain_list)
    lines = command.stdout.strip().split("\n")
    
    for line in lines:
        subdomain_dnsx_json = json.loads(line)
        subdomain_dnsx_json["subdomain"] = subdomain_dnsx_json.pop("host")

        db.subdomains.update_one(
            {
                "subdomain": subdomain_dnsx_json["subdomain"]
            },
            {
                "$set": subdomain_dnsx_json,
                "$addToSet": {
                    "source": "dnsx"
                }
            },
            upsert=True
        )

        subdomain_dnsx_sum += 1
    
    db.tasks.update_one(
        {
            "domain": domain
        },
        {
            "$set": {
                "domain": domain
            },
            "$addToSet": {
                "done": "dnsx"
            }
        },
        upsert=True
    )

    print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), f"dnsx resolve {subdomain_dnsx_sum} subdomains")


if __name__ == '__main__':

    db = db_connection()
    
    tasks = db.tasks.find()
    
    for task in tasks:

        domain = task['domain']
        done = task['done']

        print(datetime.datetime.now().strftime("%Y/%m/%dT%H:%M:%S"), "domain:", domain)

        if "subfinder" not in done:
            subfinder(domain)
        
        if "puredns" not in done:
            puredns(domain)

        if "gau" not in done:
            gau(domain)
        
        if "dnsx" not in done:
            dnsx(domain)
