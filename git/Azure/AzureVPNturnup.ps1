$GatewayRG = "VPNresourcegroup"
$Gatewayvnet = "GatewayVNET"
$AddressSpace = "10.22.0.0/16"
$LocalSiteName = "LocalSiteNameName"
$LocalGatewayRG = "VPNresourcegroup"
$Location = "East US 2"
$LocalGatewayIP = "75.141.179.42"
$LocalAddressPrefixes = '10.20.130.0/24'
$GatewaySubnet = "10.22.255.0/27"
$GatewayPIP = "GatewayPIPName"
$GatewayConfigName = "GatewayConfig"
$vnetGateway = "vnetGatewayName"
$vnetGatewayRG = "VPNresourcegroup"
$GatewaySku = "Basic"
$VPNtype = "PolicyBased"
$VPNRG = "VPNresourcegroup"
$VPNConnectionName = "AzureVPN"
$PreSharedKey = "Tote2830"


            [parameter(Mandatory=$True)][string] $GatewayRG,  #could be combined
            [parameter(Mandatory=$True)][string] $Gatewayvnet,
            [parameter(Mandatory=$True)][string] $AddressSpace,
            [parameter(Mandatory=$True)][string] $LocalSiteName,
            [parameter(Mandatory=$True)][string] $LocalGatewayRG, #could be combined
            [parameter(Mandatory=$True)][string] $Location,
            [parameter(Mandatory=$True)][string] $LocalGatewayIP,
            [parameter(Mandatory=$True)][array]  $LocalAddressPrefixes,
            [parameter(Mandatory=$True)][string] $GatewayPIP,
            [parameter(Mandatory=$True)][string] $GatewayConfigName,
            [parameter(Mandatory=$True)][string] $vnetGateway,
            [parameter(Mandatory=$True)][string] $vnetGatewayRG, #could be combined
            [parameter(Mandatory=$True)][string] $GatewaySku,
            [parameter(Mandatory=$True)][string] $VPNtype,
            [parameter(Mandatory=$True)][string] $VPNConnectionName,
            [parameter(Mandatory=$True)][string] $VPNRG,  #could be combined
            [parameter(Mandatory=$True)][string] $PreSharedKey

<#
# Create a virtual network, Gateway Subnet and Subnets
New-AzureRmResourceGroup -Name $GatewayRG -Location $Location
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $GatewaySubnet
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet22130' -AddressPrefix '10.22.130.0/24'
New-AzureRmVirtualNetwork -Name $Gatewayvnet -ResourceGroupName $GatewayRG `
    -Location $Location -AddressPrefix $AddressSpace -Subnet $subnet1, $subnet2
#>


<# Add a Gateway Subnet to a VNET you have already created
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $GatewayRG -Name $Gatewayvnet
Add-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $GatewaySubnet -VirtualNetwork $vnet
Set-AzureRmVirtualNetwork -VirtualNetwork $Gatewayvnet
#>

# Add Local Network Gateway and Address Prefix(es)
New-AzureRmLocalNetworkGateway -Name $LocalSiteName -ResourceGroupName $LocalGatewayRG `
    -Location $location -GatewayIpAddress $LocalGatewayIP -AddressPrefix @($LocalAddressPrefixes) #need to test this

# Request a Public IP Address for the VPN Gateway
$gwpip= New-AzureRmPublicIpAddress -Name $GatewayPIP -ResourceGroupName $GatewayRG -Location $Location -AllocationMethod Dynamic

# Create the Gateway IP addressing configuration
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $GatewayRG -Name $Gatewayvnet
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GatewayConfigName -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id

# Create the Virtual Network Gateway
New-AzureRmVirtualNetworkGateway -Name $vnetGateway -ResourceGroupName $vnetGatewayRG `
    -Location $Location -IpConfigurations $gwipconfig -GatewayType Vpn `
    -VpnType $VPNtype -GatewaySku $GatewaySku

# Use the this IP address to configure your on-premises VPN Device 
$AzureVPNGateway = Get-AzureRmPublicIpAddress -Name $GatewayPIP -ResourceGroupName $GatewayRG

# Set the Variables for the VPN Connection
$GatewayConnect = Get-AzureRmVirtualNetworkGateway -Name $vnetGateway -ResourceGroupName $vnetGatewayRG
$LocalConnect = Get-AzureRmLocalNetworkGateway -Name $LocalSiteName -ResourceGroupName $LocalGatewayRG

# Create the VPN Connection
New-AzureRmVirtualNetworkGatewayConnection -Name $VPNConnectionName -ResourceGroupName $VPNRG `
    -Location $Location -VirtualNetworkGateway1 $GatewayConnect -LocalNetworkGateway2 $LocalConnect `
    -ConnectionType IPsec -RoutingWeight 10 -SharedKey $PreSharedKey