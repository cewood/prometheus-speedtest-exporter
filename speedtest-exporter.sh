#!/bin/bash

if [ -n "$DEBUG" ];
then
  set -x
fi

# printMetric name description type value
function printMetric {
    echo "# HELP $1 $2"
    echo "# TYPE $1 $3"

    if [ -n "$SERVER_IDS" ];
    then
      echo "$1{server_id=\"$5\"} $4"
    else
      echo "$1 $4"
    fi
}

# shellcheck disable=SC2034
while IFS=$'\t' read -r servername serverid latency jitter packetloss download upload downloadedbytes uploadedbytes share_url; do
    printMetric "speedtest_latency_ms" "Latency" "gauge" "$latency" "$serverid"
    printMetric "speedtest_jittter_ms" "Jitter" "gauge" "$jitter" "$serverid"
    printMetric "speedtest_download_bytes" "Download Speed" "gauge" "$download" "$serverid"
    printMetric "speedtest_download_bps" "Download Speed" "gauge" "$(echo "$download * 8" | bc)" "$serverid"
    printMetric "speedtest_upload_bytes" "Upload Speed" "gauge" "$upload" "$serverid"
    printMetric "speedtest_upload_bps" "Upload Speed" "gauge" "$(echo "$upload * 8" | bc)" "$serverid"
    printMetric "speedtest_downloadedbytes_bytes" "Downloaded Bytes" "gauge" "$downloadedbytes" "$serverid"
    printMetric "speedtest_uploadedbytes_bytes" "Uploaded Bytes" "gauge" "$uploadedbytes" "$serverid"
done < <(/usr/local/bin/speedtest --accept-license --accept-gdpr -f tsv "$(test -n "$1" && echo "--server-id=$1")")
