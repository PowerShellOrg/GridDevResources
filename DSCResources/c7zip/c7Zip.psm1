function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name

    )

    Write-Verbose "Start Get-TargetResource"

    CheckChocoInstalled

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
    }

    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )
    Write-Verbose "Start Set-TargetResource"

    CheckChocoInstalled

    if (-not (IsPackageInstalled $Name))
    {
        InstallPackage $Name
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    Write-Verbose "Start Test-TargetResource"

    CheckChocoInstalled

    if (-not (IsPackageInstalled $Name))
    {
        Return $false
    }

    Return $true
}




Export-ModuleMember -Function *-TargetResource
