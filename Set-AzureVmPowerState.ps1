Function Set-AzureVmPowerState {
    <#
        .SYNOPSIS
        Function "Set-AzureVmPowerState" to change the power state of an Azure Vm.

        .DESCRIPTION
        Author: Pwd9000 (pwd9000@hotmail.co.uk)
        PSVersion: 5.1

        This is a simple function that will, based on a parameter switch ON/OFF determine if an Azure Vm is already powered "on" or "off"
        and change the power state of the Virtual Machine to what is specified in the "power" parameter selected by the user running the function

        .EXAMPLE
        $credentials = Get-Credential
        $TenantId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
        Login-AzureRmAccount -TenantId $TenantId -Credential $credentials
        Set-AzureVmPowerState -VMName Contoso1 -ResourceGroupName WestUSRG -SubscriptionName "My Subscription Name" -Power ON -Verbose

        Azure Virtual Machine Name "Contoso1" in ResourceGroup "WestUSRG" will be powered on (if not powered on already)

		.EXAMPLE
        $credentials = Get-Credential
        $TenantId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
        Login-AzureRmAccount -TenantId $TenantId -Credential $credentials
        Set-AzureVmPowerState -VMName Contoso2 -ResourceGroupName EastUSRG -SubscriptionName "My Subscription Name" -Power OFF Verbose

        Azure Virtual Machine Name "Contoso2" in ResourceGroup "EastUSRG" will be powered off and deallocated (if not powered off and deallocated already)
        An additional check is done to also force deallocate any machines which are powered off already, but not deallocated.

        .EXAMPLE
        $credentials = Get-Credential
        $TenantId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
        Login-AzureRmAccount -TenantId $TenantId -Credential $credentials
        $Vms = "Contoso1", "Contoso2", "Contoso3"
        $Resourcegroupname = "WestUSRG"
        $SubscriptionName "My Subscription Name"
        Foreach ($Vm in $Vms) {
            Set-AzureVmPowerState -VmName $Vm -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -Power OFF -Verbose
        }

        Every Vm specified in the array $Vms will be checked and if they are (powered on) OR (powered off but not deallocated) and will be force deallocated.

        .PARAMETER VmName
        Mandatory Parameter.
        Specify the Virtual Machine name to use in the function. <String>
        
        .PARAMETER ResourceGroupName
        Mandatory Parameter.
		Specify the Resource group name to use in the function. <String>

        .PARAMETER SubscriptionName
        Mandatory Parameter.
        Specify the Subscription Name. <String>
        
        .PARAMETER Power
        Mandatory Parameter.
		Specify the wanted power state of a Virtual Machine. <String>
    #>

    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$VmName,

        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$SubscriptionName,

        [Parameter(Mandatory)]
        [ValidateSet("ON", "OFF")]
        [String]$Power
    )

    #Connect to the Subscription that the VM is in if not connected already
    $MySubName = Get-AzureRmContext | select-Object name
    If ($MySubName -notmatch $SubscriptionName) {
        Select-AzureRmSubscription -SubscriptionName $SubscriptionName
    }

    #Check Vm current powerstate
    $VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -VmName $VmName -Status
    Foreach ($VMStatus in $VM.Statuses) {
        If ($VMStatus.Code.CompareTo("ProvisioningState/succeeded") -ne 0) {
            $VMStatusDetail = $VMStatus.DisplayStatus

            #Power machine ON if machines is OFF (Parameter taken from switch)
            If ($Power -eq "ON") {
                If (($VMStatusDetail -eq "VM stopped") -or ($VMStatusDetail -eq "VM deallocated")) {
                    Write-Verbose "[$VmName] powerstate: [$VMStatusDetail]. Powering ON....."
                    Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VmName
                }
                Else {
                    Write-Verbose "[$VmName] is already powered up and running."
                }
                #Power machine OFF and deallocate if machines is ON or deallocate if machine is powered OFF already but not deallocated (Parameter taken from switch)
            }
            Else {
                If (($VMStatusDetail -eq "VM stopped") -or ($VMStatusDetail -eq "VM running")) {
                    Write-Verbose "[$VmName] powerstate: [$VMStatusDetail]. Turning machine OFF and deallocating...."
                    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
                }
                Else {
                    Write-Verbose "[$VmName] is already powered off and deallocated."
                }
            }
        }
    }
}