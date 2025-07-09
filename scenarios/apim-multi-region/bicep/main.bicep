metadata name = 'API Management Service Multi-Region Deployment'
metadata description = 'This module deploys an API Management Service. The default deployment is set to use a Premium SKU to align with Microsoft WAF-aligned best practices. In most cases, non-prod deployments should use a lower-tier SKU.'
targetScope = 'subscription'

import * as helpers from './modules/helpers.bicep'
import { apimRegionalSettings } from './modules/types.bicep'

// Parameters
@description('Required. A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param workloadName string = 'wdgtst01'

@description('Required. The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string = 'dev'

// @description('Required. The host for the Application Gateway. Example - api.contoso.com. This will be prefixed with the environment and location for each APIM Gateway region.')
// param appGatewayHost string

// @description('Optional. The password for the TLS certificate for the Application Gateway.  The pfx file needs to be copied to scenarios/apim-baseline/bicep/gateway/certs/appgw.pfx')
// param certKey string = 'placeholder'
// param certData string = 'placeholder'

// @description('Set to selfsigned if self signed certificates should be used for the Application Gateway. Set to custom and copy the pfx file to scenarios/apim-baseline/bicep/gateway/certs/appgw.pfx if custom certificates are to be used')
// @allowed([
//   'selfsigned'
//   'custom'
// ])
// param appGatewayCertType string

@description('Required. The configuration for the API Management Service primary region.')
param primaryApim apimRegionalSettings = {location: 'eastus2', sku: {name: 'Premium', capacity: 2}}

param secondaryApim apimRegionalSettings = {location: 'centralus', sku: {name: 'Premium', capacity: 2}}

@description('Enable sending usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = false

param publisherEmail string = 'apimgmt-noreply@mail.windowsazure.com'
param publisherName string = 'az-amorg-x-001'

// Non-required parameters

// param diagnosticSettings array = [
//   {
//     eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
//     eventHubName: '<eventHubName>'
//     storageAccountResourceId: '<storageAccountResourceId>'
//     workspaceResourceId: '<workspaceResourceId>'
//   }
// ]

// param loggers array = [
//   {
//     credentials: {
//       instrumentationKey: '<instrumentationKey>'
//     }
//     description: 'Logger to Azure Application Insights'
//     isBuffered: false
//     loggerType: 'applicationInsights'
//     name: 'logger'
//     resourceId: '<resourceId>'
//   }
// ]

// param policies array = [
//   {
//     format: 'xml'
//     value: '<policies> <inbound> <rate-limit-by-key calls=\'250\' renewal-period=\'60\' counter-key=\'@(context.Request.IpAddress)\' /> </inbound> <backend> <forward-request /> </backend> <outbound> </outbound> </policies>'
//   }
// ]

param tags object = {
  Environment: 'Non-Prod'
  'hidden-title': 'This is visible in the resource name'
  Role: 'DeploymentValidation'
}


// Variables
var nsgRules = loadJsonContent('./modules/nsgrules.json')
var primaryVnetAddressPrefix = '10.0.0.0/16'
var secondaryVnetAddressPrefix = '10.1.0.0/16'
var primarySubnets = [
  {
    name: 'apim'
    addressPrefix: cidrSubnet(primaryVnetAddressPrefix, 24, 0)
    nsgRules: nsgRules.apim
  }
  {
    name: 'appgw'
    addressPrefix: cidrSubnet(primaryVnetAddressPrefix, 24, 1)
    nsgRules: nsgRules.appgw
  }
  {
    name: 'pe-services'
    addressPrefix: cidrSubnet(primaryVnetAddressPrefix, 24, 2)
    nsgRules: nsgRules['pe-services']
  }
  {
    name: 'workloads'
    addressPrefix: cidrSubnet(primaryVnetAddressPrefix, 24, 3)
    nsgRules: nsgRules.workloads
  }
]
var secondarySubnets = [
  {
    name: 'apim'
    addressPrefix: cidrSubnet(secondaryVnetAddressPrefix, 24, 0)
    nsgRules: nsgRules.apim
  }
  {
    name: 'appgw'
    addressPrefix: cidrSubnet(secondaryVnetAddressPrefix, 24, 1)
    nsgRules: nsgRules.appgw
  }
  {
    name: 'pe-services'
    addressPrefix: cidrSubnet(secondaryVnetAddressPrefix, 24, 2)
    nsgRules: nsgRules['pe-services']
  }
  {
    name: 'workloads'
    addressPrefix: cidrSubnet(secondaryVnetAddressPrefix, 24, 3)
    nsgRules: nsgRules.workloads
  }
]

var resourceNames = {
  networkingRg: helpers.generateResourceName('resourceGroup', workloadName, environment, primaryApim.location, '-networking', null)
  sharedRg: helpers.generateResourceName('resourceGroup', workloadName, environment, primaryApim.location, '-shared', null)
  apimRg: helpers.generateResourceName('resourceGroup', workloadName, environment, primaryApim.location, '-apim', null)
  
  // Primary
  apimPrimary: helpers.generateResourceName('apiManagement', workloadName, environment, primaryApim.location, null, null)
  vnetPrimary: helpers.generateResourceName('virtualNetwork', workloadName, environment, primaryApim.location, null, null)
  appGwPrimary: helpers.generateResourceName('applicationGateway', workloadName, environment, primaryApim.location, null, null)
  
  // Secondary
  vnetSecondary: helpers.generateResourceName('virtualNetwork', workloadName, environment, secondaryApim.location, null, null)
  apimSecondary: helpers.generateResourceName('apiManagement', workloadName, environment, secondaryApim.location, null, null)
  appGwSecondary: helpers.generateResourceName('applicationGateway', workloadName, environment, secondaryApim.location, null, null)
}

module networkingRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: uniqueString(deployment().name, resourceNames.networkingRg)
  params: {
    name: resourceNames.networkingRg
    location: primaryApim.location
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module sharedRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: resourceNames.sharedRg
  params: {
    name: resourceNames.sharedRg
    location: primaryApim.location
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module apimRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: resourceNames.apimRg
  params: {
    name: resourceNames.apimRg
    location: primaryApim.location
    tags: tags
    enableTelemetry: enableTelemetry
  }
}

module primaryNsgs 'br/public:avm/res/network/network-security-group:0.5.1' = [for item in primarySubnets: {
  name: '${item.name}-primary-nsg-deploy'
  scope: resourceGroup(resourceNames.networkingRg)
  dependsOn:[
    networkingRG
  ]
  params:{
    name: '${item.name}-primary-nsg'
    location: primaryApim.location
    tags: tags
    enableTelemetry: enableTelemetry
    securityRules: item.nsgRules
  }
}]

module secondaryNsgs 'br/public:avm/res/network/network-security-group:0.5.1' = [for item in secondarySubnets: {
  name: '${item.name}-secondary-nsg'
  scope: resourceGroup(resourceNames.networkingRg)
  dependsOn:[
    networkingRG
  ]
  params:{
    name: '${item.name}-secondary-nsg'
    location: secondaryApim.location
    tags: tags
    enableTelemetry: enableTelemetry
    securityRules: item.nsgRules
  }
}]

var primarySubnetDefinitions = [for item in primarySubnets: {
  name: item.name
  addressPrefix: item.addressPrefix
  networkSecurityGroupResourceId: resourceId(subscription().subscriptionId, resourceNames.networkingRg, 'Microsoft.Network/networkSecurityGroups', '${item.name}-primary-nsg')
}]
module vnetPrimary 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: '${resourceNames.vnetPrimary}-vnet-deploy'
  scope: resourceGroup(resourceNames.networkingRg)
  dependsOn: [
    primaryNsgs
  ]
  params: {
    addressPrefixes: array(primaryVnetAddressPrefix)
    subnets: primarySubnetDefinitions
    name: resourceNames.vnetPrimary
    location: primaryApim.location
  }
}

var secondarySubnetDefinitions = [for item in secondarySubnets: {
  name: item.name
  addressPrefix: item.addressPrefix
  networkSecurityGroupResourceId: resourceId(subscription().subscriptionId, resourceNames.networkingRg, 'Microsoft.Network/networkSecurityGroups', '${item.name}-secondary-nsg')
}]
module vnetSecondary 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: '${resourceNames.vnetSecondary}-vnet-deploy'
  scope: resourceGroup(resourceNames.networkingRg)
  dependsOn: [
    secondaryNsgs
  ]
  params: {
    addressPrefixes: array(secondaryVnetAddressPrefix)
    subnets: secondarySubnetDefinitions
    name: resourceNames.vnetSecondary
    location: secondaryApim.location
  }
}

module apimPrimary 'br/public:avm/res/api-management/service:0.9.1' = {
  name: resourceNames.apimPrimary
  scope: resourceGroup(resourceNames.apimRg)
  dependsOn: [
    vnetPrimary
    vnetSecondary
  ]
  params: {
    name: resourceNames.apimPrimary
    tags: tags
    enableTelemetry: enableTelemetry
    location: primaryApim.location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: any(primaryApim.sku.?name) // only supporting a subset of skus for multi-region
    skuCapacity: secondaryApim.sku.?capacity
    virtualNetworkType: 'External'
    subnetResourceId: vnetPrimary.outputs.subnetResourceIds[0]//resourceId(subscription().id, resourceNames.networkingRg, 'Microsoft.Network/virtualNetworks/subnets', resourceNames.vnetPrimary, primarySubnets[0].name)
    additionalLocations: [
      {
        location: secondaryApim.location
        sku: {
          name: secondaryApim.sku.?name 
          capacity: secondaryApim.sku.?capacity
        } 
        virtualNetworkConfiguration: {
          subnetResourceId: vnetSecondary.outputs.subnetResourceIds[0]//resourceId(subscription().id, resourceNames.networkingRg, 'Microsoft.Network/virtualNetworks/subnets', resourceNames.vnetSecondary, secondarySubnets[0].name)
        }
        availabilityZones: secondaryApim.?availabilityZones
      }
    ]
  }
} 

