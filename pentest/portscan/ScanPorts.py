#-------------------------------------------------------------
 # 
 #   .SYNOPSIS
 #   ScanPorts - a simple, Scapy-based port scanning tool
 #   
 #   .NOTES
 #   Author: Charles Christensen
 #   Required Dependencies: python3, scapy, python-magic
 #   
#-------------------------------------------------------------

#==========================================
#  PARMETERS / VARIABLES
#==========================================

# Import libraries.
import scapy.all as scapy   # scapy
import netaddr              # netaddr
import magic                # python-magic, python-magic-bin
import sys                  # n/a
import os                   # n/a

# Define variables.
KNOWN_PORTS = [21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080]
HELP_MSG = '''
SYNOPSIS
    ScanPorts - a simple, Scapy-based port scanning tool
                authored by Charles Christensen

USAGE
    python3 ScanPorts.py [OPTIONS]

OPTIONS
    -h, --help, -?
        Display this help message
    -t, --target
        Specify the hosts to target. Accepts single IP address, CIDR range, or multiline text file
    -p, --port
        Specify the ports to scan. Accepts ranges and comma-seperated values. Defaults to KNOWN.
        Addtional options: KNOWN (for top 20 ports), ALL (for all ports), and RESERVED (for commonly reserved ports)
    -m, --method
        Specify method of port scan. Accepts comma-seperated TCP, UDP, or ICMP. Defaults to TCP.
    -d, --delay
        Specify the timeout delay in seconds for each scan. Defaults to 2 seconds.
    -s, --source
        Specify the port that the scan should originate from. Defaults to RAND.
        Additional options: RAND (randomly select a 1024+ port), MIRROR (mirror the port that the scan is going to)
    
'''
targets = set()
ports = set(KNOWN_PORTS)
methods = set(["tcp"])
delay = 2
source = "RAND"

#==========================================
#  FUNCTIONS
#==========================================

# Print out colorful CLI messages.
def CustomPrint(message, color="WHITE", newline=True):
    
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    
    if color == "GREEN":
        print(GREEN, end='')
    if color == "YELLOW":
        print(YELLOW, end='')
    if color == "RED":
        print(RED, end='')
    if color == "WHITE":
        print(ENDC, end='')
    
    print(message, end='')
    
    if newline:
        print(ENDC)
    else:
        print(ENDC, end='')

# Check if string is valid IP.
def IsIP(text):
    try:
        netaddr.IPAddress(text)
    except:
        return False
    return True

# Ping an IP address.
def PingHost(host,_timeout):
    pkt = scapy.IP(dst=host)/scapy.ICMP()
    rply = scapy.sr1(pkt, verbose=0, timeout=_timeout)
    CustomPrint(" -  \t\tPING\t", "WHITE", False)
    if rply is None:
        CustomPrint("unsuccessful", "RED")
    else:
        CustomPrint("successful", "GREEN")

# Check if TCP port is open.
# Source <https://resources.infosecinstitute.com/port-scanning-using-scapy/>
def ScanTcpPort(dst_host,dst_port,src_port,_timeout):
    pkt = scapy.IP(dst=dst_host)/scapy.TCP(sport=src_port,dport=dst_port,flags="S")
    rply = scapy.sr1(pkt, verbose=0, timeout=_timeout)
    CustomPrint(" -  \t\t" + str(dst_port) + "/t\t", "WHITE", False)
    if rply is None:
        CustomPrint("closed", "RED")
    elif rply.getlayer(scapy.TCP).flags == 0x12:
        pkt = scapy.IP(dst=dst_host)/scapy.TCP(sport=src_port,dport=dst_port,flags="R")
        rply = scapy.sr1(pkt, verbose=0, timeout=_timeout)
        CustomPrint("open", "GREEN")
    elif rply.getlayer(scapy.TCP).flags == 0x14:
        CustomPrint("closed", "RED")
    elif (str(rply.getlayer(scapy.ICMP).type) == 3) and (int(rply.getlayer(ICMP).code) in [1,2,3,9,10,13]):
        CustomPrint("filtered", "YELLOW")

# Check if UDP port is open.
def ScanUdpPort(dst_host,dst_port,src_port,_timeout):
    pkt = scapy.IP(dst=dst_host)/scapy.UDP(sport=src_port,dport=dst_port)
    rply = scapy.sr1(pkt, verbose=0, timeout=_timeout)
    CustomPrint(" -  \t\t" + str(dst_port) + "/u\t", "WHITE", False)
    if rply is None:
        CustomPrint("closed", "RED")
    else:
        CustomPrint("open", "GREEN")

def GenerateSourcePort(source, port):
    if type(source) == "<class 'int'>":
        return int(source)
    if source == "MIRROR":
        return int(port)
    if source == "RAND":
        return int(scapy.RandShort())

#==========================================
#  MAIN
#==========================================

# Check CLI parameters.
params = sys.argv.copy()
params[0] = ""
if len(params) < 3:
    CustomPrint("ERROR! Target host not specified. (Use '--help' for more information.)", "RED")
    sys.exit()

# Parse CLI parameters.
index = 0
for param in params:
    param = param.lower()
    
    # Help flag.
    if (param == "-h") or (param == "--help") or ("?" in param):
        CustomPrint(HELP_MSG, "GREEN")
        sys.exit()
    
    # Target host flag.
    if (param == "-t") or (param == "--target") or (param == "--targets"):
        
        # Extract IP addresses from text file.
        if os.path.isfile(params[index+1]):
            filepath = params[index+1]
            filetype = magic.Magic(mime=True)
            if filetype.from_file(filepath) != "text/plain":
                CustomPrint("ERROR! Invalid targets file. Must be a multi-line text file. <" + params[index+1] + ">", "RED")
                sys.exit()
            try:
                filestream = open(filepath, "r")
                line = filestream.readline().strip()
                while line:
                    if IsIP(line):
                        targets.add(line)
                    else:
                        CustomPrint("WARNING! Excluding invalid IP address from scan. <" + line + ">", "YELLOW")
                    line = filestream.readline().strip()
            except:
                CustomPrint("ERROR! Unable to open targets file.", "RED")
                sys.exit()
            finally:
                filestream.close()
        
        # Extract IP addresses from CIDR range.
        elif "/" in params[index+1]:
            try:
                netaddr.IPNetwork(params[index+1])
            except:
                CustomPrint("ERROR! Invalid CIDR range. <" + params[index+1] + ">", "RED")
                sys.exit()
            for ip in netaddr.IPNetwork(params[index+1]):
                targets.add(str(ip))
        
        # Add a single IP address.
        else:
            if IsIP(params[index+1]):
                targets.add(params[index+1])
            else:
                CustomPrint("ERROR! Invalid IP address. <" + params[index+1] + ">", "RED")
                sys.exit()
        
        if len(targets) > 0:
            params[index] = ""
            params[index+1] = ""
    
    # Target ports flag.
    if (param == "-p") or (param == "--port") or (param == "--ports"):
        ports = set()
        raw_ports = params[index+1].lower().split(",")
        for raw_port in raw_ports:
            if "-" in raw_port:
                raw_port_range = raw_port.split("-")
                for num in range(int(raw_port_range[0]), int(raw_port_range[1])+1):
                    ports.add(int(num))
            elif raw_port == "all":
                for num in range(0, 65536):
                    ports.add(int(num))
            elif (raw_port == "reserved") or (raw_port == "privileged"):
                for num in range(0, 1024):
                    ports.add(int(num))
            elif (raw_port == "known") or (raw_port == "top"):
                for known_port in KNOWN_PORTS:
                    ports.add(int(known_port))
            else:
                ports.add(int(raw_port))
        
        if len(ports) > 0:
            params[index] = ""
            params[index+1] = ""
    
    # Port scan type flag.
    if (param == "-m") or (param == "--method") or (param == "--methods"):
        methods = set()
        raw_methods = params[index+1].lower().split(",")
        for raw_type in raw_methods:
            if (raw_type == "tcp") or (raw_type == "udp") or (raw_type == "icmp"):
                methods.add(raw_type)
            elif raw_type == "ping":
                methods.add("icmp")
            else:
                CustomPrint("WARNING! Excluding invalid port scan type. <" + raw_type + ">.", "YELLOW")
        
        if len(methods) > 0:
            params[index] = ""
            params[index+1] = ""
    
    # Delay/timeout flag.
    if (param == "-d") or (param == "--delay"):
        delay = int(params[index+1])
        params[index] = ""
        params[index+1] = ""
    
    # Source port flag.
    if (param == "-s") or (param == "--source"):
        try:
            source = int(params[index+1])
        except:
            if (params[index+1].lower() == "rand") or (params[index+1].lower() == "rnd") or (params[index+1].lower() == "random"):
                source = "RAND"
            elif (params[index+1].lower() == "mirror"):
                source = "MIRROR"
            else:
                CustomPrint("ERROR! Invalid source port specified. <" + params[index+1] + ">.", "RED")
                sys.exit()
        
        if source != "":
            params[index] = ""
            params[index+1] = ""
            
    index = index + 1

# Verify CLI parameters.
for param in params:
    if param != "":
        CustomPrint("ERROR! Invalid parameter. <" + param + ">", "RED")
        sys.exit()
if len(targets) < 1:
    CustomPrint("ERROR! No valid IP targets specified.", "RED")
    sys.exit()
if len(ports) < 1:
    CustomPrint("ERROR! No valid ports specified.", "RED")
    sys.exit()
if len(methods) < 1:
    CustomPrint("ERROR! No valid port scan methods specified.", "RED")
    sys.exit()

# Format input for scanning.
targets = sorted(targets)
ports = sorted(ports)

# Perform stealth scanning.
CustomPrint("")
for host in targets:
    CustomPrint(host)
    if "icmp" in methods:
        PingHost(host, delay)
    for port in ports:
        if "tcp" in methods:
            src = GenerateSourcePort(source, port)
            ScanTcpPort(host, port, src, delay)
        if "udp" in methods:
            src = GenerateSourcePort(source, port)
            ScanUdpPort(host, port, src, delay)
    CustomPrint("")
