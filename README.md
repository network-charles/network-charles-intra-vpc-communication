# network-charles-intra-vpc-communication

### **[LAB1 Objective]
(https://community.aviatrix.com/t/60htb4c/cloud-solution-architect-engineer-interview-questions-and-lab-for-career-growth#lab1-objective)**

1. Create 5 VPCs in an AWS Region
2. Create one small instance in each Prod, Shared, and Dev VPC (so a total of three)
3. Make sure that these three VMs can ping each other using Private IPs
4. Use native peering to connect those VPCs
5. Deploy a Palo Alto VM in Transit VPC
6. Make sure you can access Palo Alto VM using its public IP address from your desktop/laptop
7. Make sure all 3 instances (in Prod, Shared, and Dev VPCs) can ping the Palo Alto ping using its private IP address
8. Make sure your instances in Prod, Shared, and Dev VPC which are private can ping any Internet site (like [aviatrix.com](http://aviatrix.com/) or github.com) using the Palo Alto Firewall
9. Make sure the instance in Management VPC can ping any Internet site (such as [aviatrix.com](http://aviatrix.com/) or gitbub.com) using the AWS Internet GW (IGW) deployed inside the Management VPC

### ALGORITHM
1. Create 5 VPCs
2. Management VPC (10.0.0.0/24)
    1. A default route table is created for the VPC 
        1. A default local route table is added for inter-vpc connection
    2. Create subnet 10.0.0.0/25 in your preferred AZ, maybe EU-west-2a
        1. Associate subnet to the route table of the Management VPC. No need to create subnet-specific route tables for inter-subnet route connections.
        2. A network-ACL is created for security at the subnet level on default
    3. Create an Internet Gateway in Management VPC
        1. Add a new subnet public route (0.0.0.0/0) in the route table to be destined to the Internet Gateway
    4. Add the following rules to the default security group behind the Nitro Card of the VPC physical host where the instance will be launched in
        1. Outbound
            1. protocol type = all
            2. destination = 0.0.0.0/0
        2. Inbound
            1. protocol types = SSH, ICMP
            2. source = my IP, 10.0.0.0/24 or 0.0.0.0/0
3. Prod, Shared, and Dev VPC
    1. Prod = 10.0.1.0/24, Shared = 10.0.2.0/24, Dev = 10.0.3.0/24
    2. Add the following rules to the default security group behind the Nitro Card of the VPC physical host where the instance will be launched in
        1. Outbound
            1. protocol type = all
            2. destination = 0.0.0.0/0
        2. Inbound
            1. protocol types = SSH and ICMP
                1. source = 10.0.0.0/24
4. Transit VPC 
    1. Transit VPC = 10.0.4.0/23
        1. Transit_Public_Subnet = 10.0.4.0/24 
        2. Transit_Private_Subnet = 10.0.5.0/24
    2. Add the following rules to the default security group behind the Nitro Card of the VPC physical host where the instance will be launched in
        1. Outbound
            1. protocol type = all
            2. destination = 0.0.0.0/0
        2. Inbound
            1. protocol types = SSH and ICMP
                1. source = 10.0.0.0/24
            2. Protocol types = HTTPS and SSH
                1. source = 0.0.0.0/1
    
5. Create a VPC peerings (management = 10.0.0.0/25, prod = 10.0.1.0/25, dev = 10.0.3.0/24, shared = 10.0.2.0/25)
    1. Management-to-Prod VPC peering (management = 10.0.0.0/25, prod = 10.0.1.0/25) +
        1. In the default Management VPC route table, add a route destined to Prod subnet with a next hop to this VPC Peering in the default Management VPC route table.
        2. In the default, Prod VPC route table, add a return route destined to the Management subnet, with the next hop to this VPC peering
        3. In the default Production route table, add a return route destined to the Management subnet, with a next hop of this VPC peering
    2. Management-to-Dev VPC peering +
        1. In the default Management VPC route table add a route destined to this Dev subnet with a next hop to this VPC Peering
        2. In the default, Dev VPC route table, add a return route destined to the Management subnet, with the next hop to this VPC peering
        3. Add a route destined to the internet via the Palo Alto Instance
    3. Management-to-Shared VPC peering +
        1. In the default Management VPC route table add a route destined to this Shared subnet with a next hop to this VPC Peering 
        2. In the default, Shared VPC route table, add a return route destined to the Management subnet, with the next hop to this VPC peering
    4. Shared-to-Prod VPC Peering (shared = 10.0.2.0/25, prod = 10.0.1.0/24) +
        1. In the default Shared VPC route table add a route destined to this Prod subnet with a next hop to this VPC Peering 
        2. In the default Prod VPC route table, add a return route destined to the Shared subnet, with the next hop to this VPC peering
    5. Shared-to-Dev VPC Peering +
        1. In the default Shared VPC route table add a route destined to this Dev subnet with a next hop to this VPC Peering
        2. In the default Dev VPC route table, add a return route destined to the Shared subnet, with the next hop to this VPC peering
    6. Transit-to-Prod VPC Peering +
        1. In the default Transit VPC route table add a route destined to this Prod subnet with a next hop to this VPC Peering
        2. In the default, Prod VPC route table, add a return route destined to the Transit management subnet, with the next hop to this VPC peering
    7. Transit-to-Shared VPC Peering +
        1. In the default Transit VPC route table add a route destined to this Shared subnet with a next hop to this VPC Peering
        2. In the default Shared VPC route table, add a return route destined to the Transit management subnet, with the next hop to this VPC peering
    8. Transit-to-Dev VPC Peering +
        1. In the default Transit VPC route table add a route destined to this Shared subnet with a next hop to this VPC Peering
        2. In the default Dev VPC route table, add a return route destined to the Transit subnet, with the next hop to this VPC peering
6. Download Solar Putty
    1. Generate key pair via the Puttygen, replace key downloaded from AWS. Use version 2 when saving the key
        1. Key > Parameter for saving key file > version 2
    2. Add the key to the Pageant
    3. Access your Linux instance,and feel free to SSH-Hop
7. Launch Palo Alto Firewall
    1. Use new ssh key
    2. ssh into machine
        1. Use these commands
            1. configure
            2. set mgt-config users admin password
            3. commit
    3. Sign to the firewall via [https://publicIP](https://publicIP) 
    4. Create a new public ENI in the Transit_Public_Subnet and attach it to the firewall
        1. Disable source/destination check for the ENI 
        2. Go to Ethernet1/1 in the GUI of PA-VM
            1. Network > Ethernet > Ethernet1/1
                1. Change interface type to layer 3
                2. Go to IPv4 settings
                    1. Change mode to DHCP
                3. Go to config
                    1. Assign to virtual router “default”
                    2. Add a “Public” security zone
    5. Create a private ENI in the Transit_Private_Subnet and attach it to the firewall
        1. Disable source/destination check for the ENI 
        2. Go to Ethernet1/2 in the GUI of PA-VM
            1. Network > Ethernet > Ethernet1/2
                1. Change interface type to layer 3
                2. Go to IPv4 settings
                    1. Change mode to DHCP
                    2. Disable “Automatically creating a default route”
                3. Go to config
                    1. Assign to virtual router “default”
                    2. Add a “Private” zone
