# `remote-state`
Wrapper for any command which is able to export the state of infrastructure and do a lock during deployment.
Ready for `aws` and `azure`.

### TODO
* separate packages for `azure` and `aws`

### How to use it

### Reads
*https://azure.microsoft.com/pl-pl/blog/announcing-azure-sdk-node-2-preview/

* https://blog.kloud.com.au/2018/08/16/deploying-azure-functions-with-arm-templates/
> Azure Resource Manager (ARM) templates are JSON files that describe the state of a resource group. They typically declare the full set of resources that need to be provisioned or updated. ARM templates are idempotent, so a common pattern is to run the template deployment regularly—often as part of a continuous deployment process—which will ensure that the resource group stays in sync with the description within the template.

