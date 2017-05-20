# VM-Series for Microsoft Azure

This is a repository for Azure Resoure Manager (ARM) templates to deploy VM-Series Next-Generation firewall from Palo Alto Networks in to the Azure public cloud.

[VM-Series in Azure Marketplace] (https://azure.microsoft.com/en-us/marketplace/?term=vm-series):

- Bring Your Own License - [BYOL](https://azure.microsoft.com/en-us/marketplace/partners/paloaltonetworks/vmseries-ngfwbyol/)
- Pay-As-You-Go (PAYG) Hourly [Bundle 1] (https://azure.microsoft.com/en-us/marketplace/partners/paloaltonetworks/vmseries-ngfwbundle1/) and [Bundle 2] (https://azure.microsoft.com/en-us/marketplace/partners/paloaltonetworks/vmseries-ngfwbundle2/)

**Documentation**

- [Technical documentation](https://www.paloaltonetworks.com/documentation/71/virtualization/virtualization/set-up-the-vm-series-firewall-in-azur)
- [VM-Series Datasheet](https://www.paloaltonetworks.com/products/secure-the-network/virtualized-next-generation-firewall/vm-series-for-azure)
- [Deploying ARM Templates](https://azure.microsoft.com/en-us/documentation/articles/resource-group-template-deploy/#deploy-with-azure-cli)

**NOTE:**
- Deploying ARM templates requires some expertise and customization of the ARM JSON template. Please review the basic structure of ARM templates.
- Most of the templates in this repository typically use the BYOL version of VM-Series. If you want to use a different SKU then you can edit the azureDeploy.json template to set the `"imageSku"` variable to use `"byol"`, `"bundle1"` or `"bundle2"`:
```javascript
"imagePublisher": "paloaltonetworks",
"imageSku":       "byol",
"imageOffer" :    "vmseries1",
```
- By default, if `"imageVersion"` is not specified then the latest PAN-OS version available in Azure Marketplace is used (equivalent to writing `"imageVersion": "latest"`). To use a specific PAN-OS version available in the Azure Marketplace, set it as `"imageVersion": "7.1.0"`.
- Before you use the custom ARM templates here, you must first deploy the related VM from the Azure Marketplace into the intended/destination Azure location. This enables programmatic access (i.e. template-based deployment) to deploy the VM from Azure Marketplace. You can then delete the Marketplace-based deployment if you don't need it.
- For example, if you plan to use a custom ARM template to deploy a BYOL VM of VM-Series into Australia-East, then first deploy the BYOL VM from Marketplace into Australia. This is needed only the first time. You can then delete this VM and its related resources. Now your ARM templates, from GitHub or via CLI, will work.
- The older Marketplace listing [VM-Series (BYOL) Solution Template] (https://azure.microsoft.com/en-us/marketplace/partners/paloaltonetworks/vmseriesbyol-template2template2-3nic-3subnetbyol/) is deprecated; please do not use this template. Use the above listings in the Marketplace.
