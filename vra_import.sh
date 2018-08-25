#!/usr/bin/env bash

#The MIT License (MIT)
#Copyright (c) 2018 Intel Corporation
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
#to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
#and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
#WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# vRA initial configuration automation v0.5, 25.07.2018


if [ $# -ne 3 ]; then
  echo "Usage: $0 <vRA FQDN> <vRA Admin> <tenant>"
  exit 1
fi

### Configuration

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

#################

# get vra FQDN $1
if [[ $1 =~ ^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$ ]]; then
        vRA=$1
else
        echo "You must specify proper hostname for vRA appliance"
        exit
fi


# get vra admin $2
if [[ $2 =~ ^[a-zA-Z0-9]{1,20}$ ]]; then
        vraadmin=$2
else
        echo "You must specify proper username for vRA administrator"
        exit
fi


# get tenant $3
if [[ $3 =~ ^[a-zA-Z0-9.]{1,20}$ ]]; then
        tenant=$3
else
        echo "You must specify proper tenant for vRA deployment"
        exit
fi


# get password
while ! grep -q -P '^(?!.* )(?=.*[A-Z])(?=.*[[:punct:]])(?=.*[0-9])(?=.*[a-z]).{8,30}$' <<<"$password"
do
        read -r -s -p "Please enter the vRA administrator password: " password
done

# get auth token from vRA REST
token=$(curl --insecure -H "Accept: application/json" -H 'Content-Type: application/json' --data "{\"username\":\"$vraadmin\",\"password\":\"$password\",\"tenant\":\"$tenant\"}" https://$vRA/identity/api/tokens | python -c "import sys, json; print json.load(sys.stdin)['id']")

#give your vraadmin software architect role
curl --insecure -X PUT -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/identity/api/authorization/tenants/$tenant/principals/$vraadmin@$tenant/roles/SOFTWARE_SERVICE_SOFTWARE_ARCHITECT/

# vRA initial config

# get computeResource

computeResource=$(curl --insecure -X POST -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/reservation-service/api/data-service/schema/Infrastructure.Reservation.Virtual.vSphere/default/computeResource/values -d "{}") 
computeResource=$(echo $computeResource | python -c "import sys,json; print json.dumps(json.load(sys.stdin)['values'][0]['underlyingValue'])")


#create Business Group(Subtenant) for DBaaS
curl --insecure -X POST -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/identity/api/tenants/vsphere.local/subtenants -d "{
  \"@type\": \"Subtenant\",
  \"name\": \"$subtenantname\",
  \"description\": \"Example business group for DBaaS application\",
  \"tenant\": \"$tenant\",
  \"extensionData\": {
    \"entries\": [
      {
        \"key\": \"iaas-machine-prefix\",
        \"value\": {
          \"type\": \"string\",
          \"value\": \"\"
        }
      },
      {
        \"key\": \"iaas-ad-container\",
        \"value\": {
          \"type\": \"string\",
          \"value\": \"\"
        }
      },
      {
        \"key\": \"iaas-manager-emails\",
        \"value\": {
          \"type\": \"string\",
          \"value\": \"$adminemail\"
        }
      }
    ]
  }
}"

subtenant=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/identity/api/tenants/vsphere.local/subtenants | python -c "import sys, json; obj = json.load(sys.stdin); subtenant=filter(lambda x: x['name'] == '$subtenantname', obj['content'])[0]; print(subtenant['id'])")
#get user password
while ! grep -q -P '^(?!.* )(?=.*[A-Z])(?=.*[[:punct:]])(?=.*[0-9])(?=.*[a-z]).{8,30}$' <<<"$userpassword"
do
        read -r -s -p "Please enter the password for the new user account: " userpassword
done

#create user
curl --insecure -X POST -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/identity/api/tenants/vsphere.local/principals -d "{
  \"@type\": \"User\",
  \"firstName\": \"$firstname\",
  \"lastName\": \"$lastname\",
  \"emailAddress\": \"$useremail\",
  \"description\": \"User that will able be to request imported blueprints\",
  \"locked\": \"false\",
  \"disabled\": \"false\",
  \"password\": \"$userpassword\",
  \"principalId\": {
    \"domain\": \"$tenant\",
    \"name\": \"$user\"
  },
  \"tenantName\": \"$tenant\",
  \"name\": \"$user\"
}"


#assign this user to subtenant consumer role
curl -X POST --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/identity/api/tenants/vsphere.local/subtenants/$subtenant/roles/CSP_CONSUMER/principals/ -d "[{\"domain\": \"$tenant\",\"name\": \"$user\"}]"


#create vRealize Orchestrator endpoint
curl --insecure -X POST -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/endpoint-configuration-service/api/endpoints -d "{
   \"extensionData\":{
      \"entries\":[
         {
            \"key\":\"password\",
            \"value\":{
               \"type\":\"secureString\",
               \"value\": \"$password\"
            }
         },
         {
            \"key\":\"address\",
            \"value\":{
               \"type\":\"string\",
               \"value\":\"https://$vRA/vco\"
            }
         },
         {
            \"key\":\"priority\",
            \"value\":{
               \"type\":\"integer\",
               \"value\":\"1\"
            }
         },
         {
            \"key\":\"username\",
            \"value\":{
               \"type\":\"string\",
               \"value\":\"administrator\"
            }
         }
      ]
   },
   \"associations\":[

   ],
   \"typeId\":\"vCO\",
   \"typeDisplayName\":\"vRealize Orchestrator\",
   \"tenantable\":false,
   \"id\":\"\",
   \"@type\":\"Endpoint\",
   \"name\":\"vRO Endpoint\",
   \"version\":0,
   \"description\":\"\",
   \"uri\":\"\",
   \"tenantId\":null,
   \"trustThumbprint\":null,
   \"createdDate\":null,
   \"lastUpdated\":null,
   \"capabilities\":null
}"


# create storage reservations

reservationStorages=$(curl --insecure -X POST -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/reservation-service/api/data-service/schema/Infrastructure.Reservation.Virtual.vSphere/default/reservationStorages/values -d "{\"dependencyValues\":{\"entries\":[{\"key\":\"computeResource\",\"value\": $computeResource }]}}")
reservationStorages=$(echo $reservationStorages | \
  python -c "import sys,json; \
             obj=filter(lambda x: x['label'] == '$storage', json.load(sys.stdin)['values'])[0]['underlyingValue']; \
             obj['values']['entries'].append({'key':'storageReservationPriority','value':{'type':'integer','value': 1}});\
             obj['values']['entries'].append({'key':'storageEnabled', 'value':{'type': 'boolean', 'value':'true'}});\
             obj['values']['entries'].append({'key':'storageReservedSizeGB', 'value':{'type': 'integer', 'value':'$storage_reserve_gb'}});\
             print json.dumps(obj)")

# populate network reservations

# create external and nat network profile

curl --insecure -X POST -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/iaas-proxy-provider/api/network/profiles -d "{
  \"@type\": \"ExternalNetworkProfile\",
  \"name\": \"$external_name\",
  \"isHidden\": false,
  \"definedRanges\": [
    {
      \"name\": \"default\",
      \"description\": \"\",
      \"beginIPv4Address\": \"$external_begin_ipv4\",
      \"endIPv4Address\": \"$external_end_ipv4\",
      \"state\": \"UNALLOCATED\"
    }
  ],
  \"profileType\": \"EXTERNAL\",
  \"subnetMask\": \"$external_subnetmask\",
  \"gatewayAddress\": \"$external_gateway\",
  \"primaryDnsAddress\": \"$external_dns1\",
  \"secondaryDnsAddress\": \"$external_dns2\"
}"

networkProfile=$(curl --insecure -H "Accept:application/json" -H "Authorization: Bearer $token" https://$vRA/iaas-proxy-provider/api/network/profiles)
external_id=$(echo $networkProfile | python -c \
  "import sys, json; \
   obj=json.load(sys.stdin); \
   print filter(lambda x: x['name'] == '$external_name', obj['content'])[0]['id']")

curl --insecure -X POST -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/iaas-proxy-provider/api/network/profiles -d "{
  \"@type\": \"NATNetworkProfile\",
  \"name\": \"$nat_name\",
  \"isHidden\": false,
  \"definedRanges\": [
    {
      \"name\": \"default\",
      \"description\": \"\",
      \"beginIPv4Address\": \"$nat_begin_ipv4\",
      \"endIPv4Address\": \"$nat_end_ipv4\",
      \"state\": \"UNALLOCATED\"
    }
  ],
  \"profileType\": \"NAT\",
  \"natType\": \"ONETOMANY\",
  \"subnetMask\": \"$nat_subnetmask\",
  \"gatewayAddress\": \"$nat_gateway\",
  \"primaryDnsAddress\": \"$nat_dns1\",
  \"secondaryDnsAddress\": \"$nat_dns2\",
  \"externalNetworkProfileId\": \"$external_id\",
  \"externalNetworkProfileName\": \"$external_name\"
}"

reservationNetworks=$(curl --insecure -X POST -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/reservation-service/api/data-service/schema/Infrastructure.Reservation.Virtual.vSphere/default/reservationNetworks/values -d "{\"dependencyValues\":{\"entries\":[{\"key\":\"computeResource\",\"value\": $computeResource }]}}")

reservationNetworks=$(echo $reservationNetworks | python -c "import sys,json; print json.dumps(filter(lambda x: x['label'] == '$network', json.load(sys.stdin)['values'])[0]['underlyingValue'])")

reservationNetworks=$(echo $reservationNetworks | python -c \
  "import sys, json; \
   obj=json.load(sys.stdin); \
   obj['values']['entries'].append({'key': 'networkProfile', 'value': {'type': 'entityRef', 'classId': 'Network', 'id': '$external_id', 'label': '$external_name', 'componentId': None}}); \
   print json.dumps(obj)")

# create memory reservation

reservationMemory=$(curl --insecure -X POST -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/reservation-service/api/data-service/schema/Infrastructure.Reservation.Virtual.vSphere/default/reservationMemory/values -d "{\"dependencyValues\":{\"entries\":[{\"key\":\"computeResource\",\"value\": $computeResource }]}}")

reservationMemory=$(echo $reservationMemory | python -c \
  "import sys,json; \
   obj=json.load(sys.stdin); \
   obj['values'][0]['underlyingValue']['values']['entries'].append({'key':'memoryReservedSizeMb', 'value': {'type': 'integer', 'value': '$memory_reserve_mb'}}); \
   print json.dumps(obj['values'][0]['underlyingValue'])")

#create Reservation
curl --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/reservation-service/api/reservations -d  "{
  \"id\": null,
  \"@type\": \"complex\",
  \"name\": \"$subtenantname Reservation\",
  \"reservationTypeId\": \"Infrastructure.Reservation.Virtual.vSphere\",
  \"tenantId\": \"$tenant\",
  \"subTenantId\": \"$subtenant\",
  \"enabled\": true,
  \"priority\": 1,
  \"alertPolicy\": {
    \"enabled\": false,
    \"alerts\": [
      {
        \"referenceResourceId\": \"storage\",
        \"alertPercentLevel\": 80
      },
      {
        \"referenceResourceId\": \"memory\",
        \"alertPercentLevel\": 80
      },
      {
        \"referenceResourceId\": \"cpu\",
        \"alertPercentLevel\": 80
      },
      {
        \"referenceResourceId\": \"machine\",
        \"alertPercentLevel\": 80
      }
    ],
    \"recipents\": null,
    \"emailBgMgr\": true,
    \"frequencyReminder\": 0
  },
  \"extensionData\" : {
    \"@type\": \"complex\",
    \"entries\": [
      {
        \"key\": \"reservationStorages\",
        \"value\": {
          \"type\": \"multiple\",
          \"empty\": \"false\",
          \"elementTypeId\": \"COMPLEX\",
          \"items\": [
            $reservationStorages
          ]
        }
      },
      {
        \"key\": \"computeResource\",
        \"value\": $computeResource
      },
      {
        \"key\": \"reservationMemory\",
        \"value\": $reservationMemory
      },
      {
      \"key\" : \"vCNSTransportZone\",
      \"value\" : {
        \"type\" : \"entityRef\",
        \"classId\" : \"NetworkScope\",
        \"id\" : \"1\",
        \"componentId\" : null,
        \"label\" : \"tzone\",
        \"typeId\" : \"ENTITY_REFERENCE\",
        \"list\" : false
      }
      },
      {
        \"@type\": \"complex\",
        \"key\": \"reservationNetworks\",
        \"value\": {
          \"@type\": \"complex\",
          \"type\": \"multiple\",
          \"empty\" : false,
          \"elementTypeId\" : \"COMPLEX\",
          \"items\" : [
            $reservationNetworks
          ]
        }
      }
    ]
  }
}"

# --------------------------

# upload vRO package via REST
curl --insecure -u administrator:$password -H "Content-Type: multipart/form-data" https://$vRA/vco/api/content/packages -F "file=@com.intel.dbaas.demo.package"
curl --insecure -s -H "Content-Type: multipart/form-data" -H "Authorization: Bearer $token" https://$vRA/content-management-service/api/packages -F "file=@vra_blueprints.zip"

#create service DBaaS:

curl --insecure -X POST -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/services -d "{
    \"description\":\"\",
    \"name\":\"DBaaS\",
    \"organization\":{
        \"tenantRef\":\"$tenant\"
    },
    \"owner\":{
        \"value\":\"$firstname $lastname\",
        \"tenantName\":\"$tenant\",
        \"ref\":\"$user@$tenant\",
        \"type\":\"USER\"
    },
    \"status\":\"ACTIVE\"

}"


#create entitlement DBaaS:

curl --insecure -X POST -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/entitlements -d "{
    \"description\":\"\",
    \"entitledCatalogItems\":[
    ],
    \"entitledResourceOperations\":[
    ],
    \"entitledServices\":[
    ],
    \"lastUpdatedBy\":\"\",
    \"name\":\"DBaaS\",
    \"organization\":{
        \"tenantRef\":\"$tenant\",
        \"subtenantRef\":\"$subtenant\"
    },
    \"principals\":[
    ],
    \"status\":\"ACTIVE\",
    \"localScopeForActions\":true,
    \"allUsers\":true

}"
#get ID of all blueprints, software compontents and resource actions for DBaaS
entid=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/entitlements | python -c "import sys, json; obj = json.load(sys.stdin); entid=filter(lambda x: x['name'] == 'DBaaS', obj['content'])[0]; print(entid['id'])")
app=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/available | python -c "import sys, json; obj = json.load(sys.stdin); app=filter(lambda x: x['name'] == 'App', obj['content'])[0]; print(app['id'])")
mariadbapp=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/available | python -c "import sys, json; obj = json.load(sys.stdin); mariadbapp=filter(lambda x: x['name'] == 'MariaDB', obj['content'])[0]; print(mariadbapp['id'])")
wordpress=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/available | python -c "import sys, json; obj = json.load(sys.stdin); wordpress=filter(lambda x: x['name'] == 'Wordpress', obj['content'])[0]; print(wordpress['id'])")
mariadb=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/available | python -c "import sys, json; obj = json.load(sys.stdin); mariadb=filter(lambda x: x['name'] == 'MariaDB for CentOS7', obj['content'])[0]; print(mariadb['id'])")
sftp=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/available | python -c "import sys, json; obj = json.load(sys.stdin); sftp=filter(lambda x: x['name'] == 'SFTP', obj['content'])[0]; print(sftp['id'])")
dbrestore=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/resourceOperations?limit=100 | python -c "import sys, json; obj = json.load(sys.stdin); dbrestore=filter(lambda x: x['name'] == 'DB: Restore', obj['content'])[0]; print(dbrestore['id'])")
dbbackup=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/resourceOperations?limit=100 | python -c "import sys, json; obj = json.load(sys.stdin); dbbackup=filter(lambda x: x['name'] == 'DB: Backup', obj['content'])[0]; print(dbbackup['id'])")
service=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/services | python -c "import sys, json; obj = json.load(sys.stdin); service=filter(lambda x: x['name'] == 'DBaaS', obj['content'])[0]; print(service['id'])")

#populate entitlement with those parts of DBaaS
curl --insecure -X PUT -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/entitlements/$entid -d "{
  \"description\": \"\",
  \"entitledCatalogItems\": [
    {
      \"active\": true,
      \"catalogItemRef\": {
        \"id\": \"$app\",
        \"label\": \"App\"
      },
      \"catalogItemRequestable\": true,
      \"hidden\": false
    },
    {
      \"active\": true,
      \"catalogItemRef\": {
        \"id\": \"$mariadb\",
        \"label\": \"MariaDB for CentOS7\"
      },
      \"catalogItemRequestable\": false,
      \"hidden\": true
    },
    {
      \"active\": true,
      \"catalogItemRef\": {
        \"id\": \"$mariadbapp\",
        \"label\": \"MariaDB\"
      },
      \"catalogItemRequestable\": true,
      \"hidden\": false
    },
    {
      \"active\": true,
      \"catalogItemRef\": {
        \"id\": \"$sftp\",
        \"label\": \"SFTP\"
      },
      \"catalogItemRequestable\": false,
      \"hidden\": true
    },
    {
      \"active\": true,
      \"catalogItemRef\": {
        \"id\": \"$wordpress\",
        \"label\": \"Wordpress\"
      },
      \"catalogItemRequestable\": false,
      \"hidden\": true
    }
  ],
  \"entitledResourceOperations\": [
    {
      \"active\": true,
      \"externalId\": \"vsphere.local!::!962ef453-da9e-4f2c-9ee1-6737cd621730\",
      \"resourceOperationRef\": {
        \"id\": \"$dbbackup\",
        \"label\": \"DB: Backup\"
      },
      \"resourceOperationType\": \"ACTION\",
      \"targetResourceTypeRef\": {
        \"id\": \"Infrastructure.Virtual\",
        \"label\": \"Virtual Machine\"
      }
    },
    {
      \"active\": true,
      \"externalId\": \"vsphere.local!::!997e3e41-fc2e-42ba-87a8-d3aa639b21f8\",
      \"resourceOperationRef\": {
        \"id\": \"$dbrestore\",
        \"label\": \"DB: Restore\"
      },
      \"resourceOperationType\": \"ACTION\",
      \"targetResourceTypeRef\": {
        \"id\": \"Infrastructure.Virtual\",
        \"label\": \"Virtual Machine\"
      }
    }
  ],
  \"entitledServices\": [
    {
      \"active\": true,
      \"serviceRef\": {
        \"id\": \"$service\",
        \"label\": \"DBaaS\"
      }
    }
  ],
  \"id\": \"$entid\",
  \"name\": \"DBaaS\",
  \"organization\": {
    \"tenantRef\": \"$tenant\",
    \"tenantLabel\": \"$tenant\",
    \"subtenantRef\": \"$subtenant\",
    \"subtenantLabel\": \"$subtenantname\"
  },
  \"principals\": [
    
  ],
  \"priorityOrder\": 1,
  \"status\": \"ACTIVE\",
  \"statusName\": \"Active\",
  \"localScopeForActions\": true,
  \"allUsers\": true,
  \"version\": 0
}"
#assign blueprints to specific service
putapp=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/$app |  
python -c "import sys,json; \
             obj=json.load(sys.stdin); \
             obj['serviceRef']={'id': '$service'}; \
             print json.dumps(obj)" )
curl -X PUT --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/catalogItems/$app -d "$putapp"

putmariaapp=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/$mariadbapp |  
python -c "import sys,json; \
             obj=json.load(sys.stdin); \
             obj['serviceRef']={'id': '$service'}; \
             print json.dumps(obj)" )
curl -X PUT --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/catalogItems/$mariadbapp -d "$putmariaapp"

putmaria=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/$mariadb |   
python -c "import sys,json; \
             obj=json.load(sys.stdin); \
             obj['serviceRef']={'id': '$service'}; \
             print json.dumps(obj)" )
curl -X PUT --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/catalogItems/$mariadb -d "$putmaria"

putsftp=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/$sftp |   
python -c "import sys,json; \
             obj=json.load(sys.stdin); \
             obj['serviceRef']={'id': '$service'}; \
             print json.dumps(obj)" )
curl -X PUT --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/catalogItems/$sftp -d "$putsftp"

putwordpress=$(curl --insecure -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" https://$vRA/catalog-service/api/catalogItems/$wordpress |   
python -c "import sys,json; \
             obj=json.load(sys.stdin); \
             obj['serviceRef']={'id': '$service'}; \
             print json.dumps(obj)" )
curl -X PUT --insecure -H "Accept:application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/catalog-service/api/catalogItems/$wordpress -d "$putwordpress"





