#!/bin/sh

echo "enter the domain name\n"
read domain
clear
echo "finding endpoint through github\n"
echo "it can take a while.......\n"
python3 /usr/bin/github-endpoints.py -d $domain -t <your github token> >> end-github.txt

echo "enter the subdomains files within this directory \n"
echo "txt file should contains *.example.com \n"
read sub_filename
cat $sub_filename | xargs -n1 -i{}  curl -s "https://otx.alienvault.com/otxapi/indicator/hostname/url_list/{}?limit=500&page=1"|jq '.url_list[].url' | sed 's/"//g' | tee alien-endpoint.txt

cat $sub_filename | httpx --silent --follow-redirects -threads 400 | xargs -I% -P10 sh -c 'hakrawler -plain -linkfinder -depth 5 -url % ' | anew | tee ans.txt
cat $sub_filename | httpx --silent --follow-redirects -threads 400 --status-code | grep "200" | tee live_sub.txt
gospider -S live_sub.txt -d 3 -c 300 | tee ans2.txt

