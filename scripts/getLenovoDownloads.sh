#!/usr/bin/env sh

curl --silent --fail --http1.1 \
	--header 'Referer: https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-x-series-laptops/thinkpad-x13s-type-21bx-21by/downloads/driver-list/' \
	'https://pcsupport.lenovo.com/us/en/api/v4/downloads/drivers?productId=laptops-and-netbooks%2Fthinkpad-x-series-laptops%2Fthinkpad-x13s-type-21bx-21by' \
	--header 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0' \
| jq '[ .body.DownloadItems[] | { Summary, Title, Files: [.Files | sort_by(.Version) | .[] | { Name, TypeString, SHA256, Priority, URL, Version, Date }] } ]'
