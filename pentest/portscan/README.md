# ScanPorts
a simple, Scapy-based port scanning tool
authored by Charles Christensen

## Usage
python3 ScanPorts.py [OPTIONS]

## Options
#### -h, --help, -?
Display this help message
#### -t, --target
Specify the hosts to target. Accepts single IP address, CIDR range, or multiline text file
#### -p, --port
Specify the ports to scan. Accepts ranges and comma-seperated values. Defaults to KNOWN.
Addtional options: KNOWN (for top 20 ports), ALL (for all ports), and RESERVED (for commonly reserved ports)
#### -m, --method
Specify method of port scan. Accepts comma-seperated TCP, UDP, or ICMP. Defaults to TCP.
#### -d, --delay
Specify the timeout delay in seconds for each scan. Defaults to 2 seconds.
#### -s, --source
Specify the port that the scan should originate from. Defaults to RAND.
Additional options: RAND (randomly select a 1024+ port), MIRROR (mirror the port that the scan is going to)    
