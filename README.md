DISCONTINUATION OF PROJECT.

This project will no longer be maintained by Intel.

Intel has ceased development and contributions including, but not limited to, maintenance, bug fixes, new releases, or updates, to this project. 

Intel no longer accepts patches to this project.

If you have an ongoing need to use this project, are interested in independently developing it, or would like to maintain patches for the open source software community, please create your own fork of this project. 
# Service Catalog for VCF* 

Service Catalog for VCF* help user with vRealize Automation configuration tasks, such as preparing endpoint, infrastructure, user and groups administration and catalog management tasks.

It also provides demo DBaaS application with vRealize Orchestrator’s custom actions: backup and restore DB and creates new Business Group and User, that will be able to request this App immediately.

Please, refer to Reference Architecture document for more actual instructions.

*Other names and brands may be claimed as the property of others
## Getting Started
### Prerequisites
Before executing *vra_import.sh* script, there are few configuration settings that need to be edited inside this script, after following comments:

* #subtenant and user - name of the Business Group, admin email and new user details
*	#storage - settings including name of datastore - *storage* and storage quota in GB for vRA reservation - *storage_reserve_gb* 
*	#network – name of External network port group in VCF
*	#External network profile – pool of External network that will be reserved for vRA, subnet mask, default gateway and DNS servers
*	#NAT network profile – pool of the network behind NSX Edge deployment 
*	#memory – memory quota in MB for vRA reservation - *memory_reserve_mb*

```
# subtenant and user:
subtenantname="Business Group 1"
adminemail="bgadmin@test.com"
user="testuser"
useremail="testuser@test.com"
firstname="first"
lastname="last"

# storage:
storage="vsanDatastore"
storage_reserve_gb="1000"

# network
network="vRack-DPortGroup-External"

# External network profile
external_name="External"
external_begin_ipv4="100.64.2.50"
external_end_ipv4="100.64.2.100"
external_subnetmask="255.255.0.0"
external_gateway="100.64.0.1"
# change to your preferred DNS servers
external_dns1="100.64.0.1"
external_dns2="100.65.0.5"

# NAT network profile
nat_name="NAT"
nat_begin_ipv4="172.16.0.2"
nat_end_ipv4="172.16.0.254"
nat_subnetmask="255.255.255.0"
nat_gateway="172.16.0.1"
# change to your preferred DNS servers
nat_dns1="100.64.0.1"
nat_dns2="100.65.0.5"

# memory:
memory_reserve_mb=256000
```
Also make sure you gave the execute permission for *vra_import.sh* file: 
```
chmod +x vra_import.sh
```
### Running the script
When all is set up, you can now execute main script vra_import.sh with 3 arguments, which are used to obtain HTTP bearer token from vRA identity service
```
./vra_import.sh <vRA address > <vRAuser> <tenant>
```
*	vRA address - domain name of vRA appliance load balancer eg. *vra-lb.vcf.example.com*
*	vRAuser - tenant administrator of vRealize Automation – default is *configurationadmin*
*	tenant - tenant created in vRealize Automation – default is *vsphere.local*

Later on, script will require two additional user inputs: vRA tenant administrator’s password, which is used to obtain HTTP bearer token and specifying the password for new Web Admin user that will be created. 

Please, note that password must:

*	Be at least 8 characters long
*	Contain at least one digit
*	Contain at least one uppercase letter
*	Contain at least one lowercase letter
*	Contain at least one special character


## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

Curl MIT license:
COPYRIGHT AND PERMISSION NOTICE

Copyright (c) 1996 - 2018, Daniel Stenberg, <daniel@haxx.se>.

All rights reserved.

Permission to use, copy, modify, and distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright
notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not
be used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization of the copyright holder.

PSF LICENSE AGREEMENT FOR PYTHON 3.7.0:
1. This LICENSE AGREEMENT is between the Python Software Foundation ("PSF"), and
   the Individual or Organization ("Licensee") accessing and otherwise using Python
   3.7.0 software in source or binary form and its associated documentation.

2. Subject to the terms and conditions of this License Agreement, PSF hereby
   grants Licensee a nonexclusive, royalty-free, world-wide license to reproduce,
   analyze, test, perform and/or display publicly, prepare derivative works,
   distribute, and otherwise use Python 3.7.0 alone or in any derivative
   version, provided, however, that PSF's License Agreement and PSF's notice of
   copyright, i.e., "Copyright © 2001-2018 Python Software Foundation; All Rights
   Reserved" are retained in Python 3.7.0 alone or in any derivative version
   prepared by Licensee.

3. In the event Licensee prepares a derivative work that is based on or
   incorporates Python 3.7.0 or any part thereof, and wants to make the
   derivative work available to others as provided herein, then Licensee hereby
   agrees to include in any such work a brief summary of the changes made to Python
   3.7.0.

4. PSF is making Python 3.7.0 available to Licensee on an "AS IS" basis.
   PSF MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED.  BY WAY OF
   EXAMPLE, BUT NOT LIMITATION, PSF MAKES NO AND DISCLAIMS ANY REPRESENTATION OR
   WARRANTY OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE
   USE OF PYTHON 3.7.0 WILL NOT INFRINGE ANY THIRD PARTY RIGHTS.

5. PSF SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF PYTHON 3.7.0
   FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS AS A RESULT OF
   MODIFYING, DISTRIBUTING, OR OTHERWISE USING PYTHON 3.7.0, OR ANY DERIVATIVE
   THEREOF, EVEN IF ADVISED OF THE POSSIBILITY THEREOF.

6. This License Agreement will automatically terminate upon a material breach of
   its terms and conditions.

7. Nothing in this License Agreement shall be deemed to create any relationship
   of agency, partnership, or joint venture between PSF and Licensee.  This License
   Agreement does not grant permission to use PSF trademarks or trade name in a
   trademark sense to endorse or promote products or services of Licensee, or any
   third party.

8. By copying, installing or otherwise using Python 3.7.0, Licensee agrees
   to be bound by the terms and conditions of this License Agreement.

JSON MIT license:
Copyright (c) 2002 JSON.org

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
