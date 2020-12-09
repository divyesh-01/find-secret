#!/bin/sh
echo "enter the directory name where you want to save the output"
read output
mkdir $output
echo "enter the domain name\n"
read domain
clear
echo "finding endpoint through github\n"
echo "it can take a while.......\n"
python3 /usr/bin/github-endpoints.py -d $domain -t <your-github-token> >> $output/end-github.txt

echo "enter the subdomains files within this directory \n" 
echo "txt file should contains *.example.com \n"
read sub_filename
echo "fetching from alienvault...." 
cat $sub_filename | xargs -n1 -i{}  curl -s "https://otx.alienvault.com/otxapi/indicator/hostname/url_list/{}?limit=500&page=1"|jq '.url_list[].url' | sed 's/"//g' >> $output/alien.txt

clear
echo "fetching from gospider....\n" 
echo "it may take some time \n"

cat $sub_filename| httpx --silent --follow-redirects -threads 400 --status-code | grep "200" | awk {print'$1'} >> $output/live_sub.txt
for i in $(cat $output/live_sub.txt);do echo "gospider running at" $i | tee -a $output/gosp.txt && gospider -s $i -d 3 -c 300 >> $output/gosp.txt ;done;
echo "fetching from hakrawler ....\n"
for i in $(cat $output/live_sub.txt);do echo "hakrawler running at" $i && timeout 5m  hakrawler -plain -linkfinder  -depth 5 -url $i >> $output/hackr.txt;done;


cat $output/alien.txt $output/hackr.txt $output/gosp.txt $output/end-github.txt | anew >> $output/part1.txt
clear
echo "output saved to $output directory, go and check"
cd $output/
rm alien.txt hackr.txt end-github.txt gosp.txt 
cd ..

echo "running subjs...\n"

subjs -i $output/live_sub >> $output/subjs.txt
echo "running waybackurls...\n"
cat $output/live_sub.txt | waybackurls | anew >> $output/wayback.txt
echo "running galer...\n"
cat $output/live_sub.txt | galer -o $output/galer.txt
echo "running gau...\n"
cat $output/live_sub.txt | gau >> $output/gau-url.txt

cat $output/subjs.txt $output/wayback.txt $output/galer.txt $output/gau-url.txt | anew >> $output/part2.txt
rm $output/subjs.txt $output/wayback.txt $output/galer.txt $output/gau-url.txt

cat $output/part1.txt $output/part2.txt | anew >> $output/all_endpoint.txt
rm $output/part1.txt $output/part2.txt

cat $output/all_endpoint.txt | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | grep "\.js" | anew | sed 's/"//g' >> $output/all_js.txt
echo "finding secrets...\n"

for i in $(cat $output/all_js.txt); do python3 ~/Desktop/tool/secretfind/secretfinder/SecretFinder.py -i $i -o cli >> $output/secret.txt;done;
