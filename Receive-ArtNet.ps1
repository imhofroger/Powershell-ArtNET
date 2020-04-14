function Receive-ArtNet{
<#
  .SYNOPSIS
    Receive-ArtNet
    
  .NOTES
    Name: Receive-ArtNet
    Author: Roger Imhof
    Created: 14.04.2020

  .DESCRIPTION 
    
  .PARAMETER localIP
	Local IP Address for use as ArtNET Receiver IP in Quotes

  .PARAMETER ArtNetUniverse
	The ArtNET Universe

  .PARAMETER Channel
	DMX Channel
	
  .PARAMETER Value
	Value for the DMX Channel between 0 and 255
	
  .PARAMETER Tolerance
	Extend the Value Range. If Value 50 and the Tolerance 2, DMX Value are now from 48 to 52.
	Its easyer to Handle.
		
  .OUTPUTS
    True or False
  .INPUTS
    
  .EXAMPLE
	Receive-ArtNet -localIP "192.168.19.110" -Channel 1 -Value 50 -Verbose
#>

[CmdletBinding(SupportsShouldProcess = $True)]
param (
	[Parameter(Mandatory=$true)]$localIP,
	[Parameter(Mandatory=$false)][int]$ArtNetUniverse = 0,
	[Parameter(Mandatory=$true)][int]$Channel,
	[Parameter(Mandatory=$true)][int]$Value,
	[Parameter(Mandatory=$false)][int]$Tolerance = 1
)

############ Variable definition and Setup ##############
$ArtNetHeader = 0x41, 0x72, 0x74, 0x2d, 0x4e, 0x65, 0x74, 0x00
$ArtNetPort = 6454
$anUniverse = [System.Text.StringBuilder]::new($Bytes.Length * 2)
############

if ($localIP){
	Write-Verbose "ArtNet IP are $localIP"
}

# ArtNET Universe convert to HEX Value
if ($ArtNetUniverse){
  Try{
	$anUniverse.AppendFormat("{0:x2}", $ArtNetUniverse) | Out-Null
	$ArtNetUniverse = "0x"+$anUniverse.ToString()
	Write-Verbose " ArtNet Universe is $ArtNetUniverse"
  } Catch {
	Write-Error "Cannot set ArtNET Universe take default Universe 0"
  }
} else {
	$anUniverse.AppendFormat("{0:x2}", 0) | Out-Null
	$ArtNetUniverse = "0x"+$anUniverse.ToString()
	Write-Verbose "Take default ArtNet Universe $ArtNetUniverse"
}

# Why minus 1 from Channel, all Channels are stored in a Array and an array goas from 0 to X. Array Position 10 are DMX Address 11!
if ($Channel){
	Write-Verbose "Listen to DMX Channel $Channel"
	$Channel = $Channel - 1
}

if ($Value){
	Write-Verbose "Defined DMX Value are $Value"
}

if ($Tolerance){
	Write-Verbose "Tolerance set to $Tolerance"
} else {
	[int]$Tolerance = 1
	Write-Verbose "Take default Tolerance $Tolerance"
}

# Applaying Tolerance
$ValueMAX = $Value + $Tolerance
$ValueMIN = $Value - $Tolerance

Write-Verbose "Value with Tolerance are between $ValueMIN and $ValueMAX"

$udpClient = New-Object system.Net.Sockets.Udpclient($ArtNetPort)
$RemoteIpEndPoint = New-Object System.Net.IPEndPoint([system.net.IPAddress]::Parse($localIP)  , $ArtNetPort);

try{
	While ($true) {
		$data=$udpclient.receive([ref]$RemoteIpEndPoint)
		#Write-Verbose -Message "Receiving Data"
		if(!(compare -ReferenceObject $data[0..7] -DifferenceObject $ArtNetHeader) -and ($data.count -eq 530))
		{
			#Write-Verbose -Message "Data Mach"
			if($data[14] -eq $ArtNetUniverse)
			{
				$DMX = $data[18..530]
				Write-Verbose "Value are: $($DMX[$Channel])"
				if ($DMX[$Channel] -ge $ValueMIN -and $DMX[$Channel] -le $ValueMAX)
				{
					Write-Verbose -Message "Yeahman!!!"
					$udpClient.Close()
					Write-Verbose "Closed!"
					return $true;
					break;
				}
			}
		}
	}
}
catch {
	Write-Error $_
	return $false;
}

}