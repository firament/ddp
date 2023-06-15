# TCP/IP details

## Ip address ranges - IPV4
| RFC 1918 name | IP address range              | Number of addresses | Largest CIDR block (subnet mask) | Host ID size | Mask bits | Classful description[Note 1]    |
| ------------- | ----------------------------- | ------------------- | -------------------------------- | ------------ | --------- | ------------------------------- |
| 24-bit block  | 10.0.0.0 – 10.255.255.255     | 16777216            | 10.0.0.0/8 (255.0.0.0)           | 24 bits      | 8 bits    | single class A network          |
| 20-bit block  | 172.16.0.0 – 172.31.255.255   | 1048576             | 172.16.0.0/12 (255.240.0.0)      | 20 bits      | 12 bits   | 16 contiguous class B networks  |
| 16-bit block  | 192.168.0.0 – 192.168.255.255 | 65536               | 192.168.0.0/16 (255.255.0.0)     | 16 bits      | 16 bits   | 256 contiguous class C networks |

### 
| Class | From        | To              | Count |
| ----- | ----------- | --------------- | ----- |
| A     | 10.0.0.0    | 10.255.255.255  |       |
| B     | 172.16.0.0  | 172.31.255.255  |       |
| C     | 192.168.0.0 | 192.168.255.255 |       |

***

## Port numbers
|   From |     To | Usage                    | Count  |
| -----: | -----: | ------------------------ | ------ |
|      0 |  1,023 | well-known ports         | 1024   |
|  1,024 | 49,151 | user server applications | 48,128 |
| 49,152 | 65,535 | clients                  | 16,384 |

***
