/* -------------------------------------------------------------------------- */
/*                              PUBLIC TYPES                                  */
/* -------------------------------------------------------------------------- */
@export()
@description('A resource type.')
type resourceTypeType= 'resourceGroup' | 'virtualNetwork' | 'subnet' | 'networkSecurityGroup' | 'routeTable' | 'applicationGateway' | 'privateEndpoint' | 'networkInterface' | 'keyVault' | 'apiManagement' | 'keyVaultKey' | 'userManagedIdentity' | 'virtualMachine' | 'firewall' | 'firewallPolicy' | 'firewallPolicyRuleGroup' | 'bastion' | 'publicIp' | 'logAnalyticsWorkspace' | 'containerRegistry' | 'virtualNetworkLink' | 'webApplicationFirewall' | 'privateLinkService' | 'frontDoor'

@export()
@description('Azure location type.')
type locationType = 'australiacentral' | 'australiacentral2' | 'australiaeast' | 'australiasoutheast' | 'brazilsouth' | 'brazilsoutheast' | 'canadacentral' | 'canadaeast' | 'centralindia' | 'centralus' | 'centraluseuap' | 'eastasia' | 'eastus' | 'eastus2' | 'francecentral' | 'francesouth' | 'germanynorth' | 'germanywestcentral' | 'israelcentral' | 'italynorth' | 'japaneast' | 'japanwest' | 'jioindiacentral' | 'jioindiawest' | 'koreacentral' | 'koreasouth' | 'northcentralus' | 'northeurope' | 'norwayeast' | 'norwaywest' | 'polandcentral' | 'qatarcentral' | 'southafricanorth' | 'southafricawest' | 'southcentralus' | 'southeastasia' | 'southindia' | 'swedencentral' | 'switzerlandnorth' | 'switzerlandwest' | 'uaecentral' | 'uaenorth' | 'uksouth' | 'ukwest' | 'westcentralus' | 'westeurope' | 'westindia' | 'westus' | 'westus2' | 'westus3'

@export()
@description('Regional API Management deployment type.')
type apiManagementDeploymentType = {
  sku: string
  capacity: int
  location: locationType
  apimName: string
  apimSubnetId: string
  publisherEmail: string
  publisherName: string

}

@export()
@description('The type of an API Management service additional location.')
type apimRegionalSettings = {
  @sys.description('Required. The location name of the additional region among Azure Data center regions.')
  location: locationType

  @sys.description('Optional. Public Standard SKU IP V4 based IP address to be associated with Virtual Network deployed service in the location. Supported only for Premium SKU being deployed in Virtual Network.')
  publicIpAddressResourceId: string?

  @sys.description('Required. SKU properties of the API Management service.')
  sku: {
    @sys.description('Required. Capacity of the SKU (number of deployed units of the SKU). For Consumption SKU capacity must be specified as 0.')
    capacity: int

    @sys.description('Optional. Name of the Sku.')
    name: ('Basic' | 'BasicV2' | 'Consumption' | 'Developer' | 'Premium' | 'Standard' | 'StandardV2' | null)
  }

  @sys.description('Optional. A list of availability zones denoting where the resource needs to come from.')
  availabilityZones: (1 | 2 | 3)[]?
}
