// import * as msRest from "@azure/ms-rest-js"
// import * as msRestNodeAuth from "@azure/ms-rest-nodeauth"
// import { StorageManagementClient, StorageManagementModels, StorageManagementMappers } from "@azure/arm-storage"

// const subscriptionId = process.env["AZURE_SUBSCRIPTION_ID"]

// msRestNodeAuth.interactiveLogin().then((creds) => {
//   const client = new StorageManagementClient(creds, subscriptionId);
//   client.operations.list().then((result) => {
//     console.log("The result is:");
//     console.log(result);
//   });
// }).catch((err) => {
//   console.error(err);
// });

// Microsoft.Web / sites / functions
// https://docs.microsoft.com/pl-pl/javascript/api/azure-arm-website/FunctionEnvelope?view=azure-node-latest#files
// https://github.com/azure/azure-sdk-for-node/tree/master/lib/services/websiteManagement2