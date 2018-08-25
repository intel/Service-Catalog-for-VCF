To export content from vRA:
1. List and note ids:
   curl --insecure -s -H"Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/content-management-service/api/contents
   curl --insecure -s -H"Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/content-management-service/api/contents\?page\=2 # for second page etc.
2. Create package:
   curl --insecure -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vrat/content-management-service/api/packages-d'{"name" : "DBaaS", "description" : "Package for demo purposes", "contents" : [ "14cb53b6-7bad-4521-bfb1-528c960de0db", "660380d1-2673-4803-a7ac-1cf336468c0a", "fe8ebb41-d078-4574-b81e-b23461f4c8a1" ]}'
3. Wait until package is ready, check this with:
   curl --insecure -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" https://$vRA/content-management-service/api/packages
   
   E.g. output:

   {"links":[],"content":[{"@type":"Package","id":"9719b297-4fd4-4b9c-a3cf-2b8030e2c249","name":"DBaaS","description":"Package for demo purposes","tenantId":"vsphere.local","subtenantId":null,"contents":["660380d1-2673-4803-a7ac-1cf336468c0a","14cb53b6-7bad-4521-bfb1-528c960de0db","fe8ebb41-d078-4574-b81e-b23461f4c8a1"],"createdDate":"2018-05-29T14:45:04.238Z","lastUpdated":"2018-05-29T14:45:04.238Z","version":0}],"metadata":{"size":20,"totalElements":1,"totalPages":1,"number":1,"offset":0}}

4. Save package as zip:
   curl --insecure -s -H "Accept: application/zip" -H "Authorization: Bearer $token" https://$vRA/content-management-service/api/packages/9719b297-4fd4-4b9c-a3cf-2b8030e2c249 -o package.zip