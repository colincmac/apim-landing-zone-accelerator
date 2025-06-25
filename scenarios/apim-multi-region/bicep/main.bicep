metadata name = 'API Management Service Multi-Region Deployment'
metadata description = 'This module deploys an API Management Service. The default deployment is set to use a Premium SKU to align with Microsoft WAF-aligned best practices. In most cases, non-prod deployments should use a lower-tier SKU.'
targetScope = 'subscription'

import * as helpers from './modules/helpers.bicep'
import { apimRegionalSettings } from './modules/types.bicep'

// Parameters
@description('A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param workloadName string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string

@description('The host for the Application Gateway. Example - api.contoso.com. This will be prefixed with the environment and location for each APIM Gateway region.')
param appGatewayHost string

@description('The password for the TLS certificate for the Application Gateway.  The pfx file needs to be copied to scenarios/apim-baseline/bicep/gateway/certs/appgw.pfx')
param certKey string = 'placeholder'
param certData string = 'placeholder'

@description('Set to selfsigned if self signed certificates should be used for the Application Gateway. Set to custom and copy the pfx file to scenarios/apim-baseline/bicep/gateway/certs/appgw.pfx if custom certificates are to be used')
@allowed([
  'selfsigned'
  'custom'
])
param appGatewayCertType string

param primaryApim apimRegionalSettings

param secondaryApim apimRegionalSettings

@description('Enable sending usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true
var telemetryId = 'ab1e5729-7452-41b2-9fbb-945cc51d9cd0-${primaryApim.location}-apim-lza-multiregion'


param publisherEmail string = 'apimgmt-noreply@mail.windowsazure.com'
param publisherName string = 'az-amorg-x-001'

// Non-required parameters

param diagnosticSettings array = [
  {
    eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
    eventHubName: '<eventHubName>'
    storageAccountResourceId: '<storageAccountResourceId>'
    workspaceResourceId: '<workspaceResourceId>'
  }
]

param loggers array = [
  {
    credentials: {
      instrumentationKey: '<instrumentationKey>'
    }
    description: 'Logger to Azure Application Insights'
    isBuffered: false
    loggerType: 'applicationInsights'
    name: 'logger'
    resourceId: '<resourceId>'
  }
]

param policies array = [
  {
    format: 'xml'
    value: '<policies> <inbound> <rate-limit-by-key calls=\'250\' renewal-period=\'60\' counter-key=\'@(context.Request.IpAddress)\' /> </inbound> <backend> <forward-request /> </backend> <outbound> </outbound> </policies>'
  }
]

param tags object = {
  Environment: 'Non-Prod'
  'hidden-title': 'This is visible in the resource name'
  Role: 'DeploymentValidation'
}


// Resource Names
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

module apimPrimary 'br/public:avm/res/api-management/service:0.9.1' = {
  name: resourceNames.apimPrimary
  scope: resourceGroup(apimRG.name)
  params: {
    name: resourceNames.apimPrimary
    tags: tags
    enableTelemetry: enableTelemetry
    location: primaryApim.location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: primaryApim.sku.?name
    additionalLocations: [
      {
        location: secondaryApim.location
        sku: secondaryApim.sku
        virtualNetworkConfiguration: {
          subnetResourceId: ''
        }
        availabilityZones: secondaryApim.?availabilityZones
      }
    ]
  }
} 

