function Get-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $UnzipFolder

  )

  Write-Verbose "Start Get-TargetResource"

  #Needs to return a hashtable that returns the current
  #status of the configuration component
  $Configuration = @{
    UnzipFolder = $UnzipFolder
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
    $UnzipFolder
  )

  Write-Verbose "Start Set-TargetResource"

  $serviceBatLoction = Get-ChildItem -Path $UnzipFolder -Filter service.bat -Recurse
  if ($serviceBatLoction.Count -ne 1)
  {
    throw "Failed to find service install bat file Elasticsearch has likely changed its install method"
  }
  else
  {
    #Change dir to installer location
    cd $serviceBatLoction.Directory.FullName
  }

  #Run installer logging out to verbosse
  $logFilePath = Join-Path $UnzipFolder "InstallLog.txt"
  Start-Process $serviceBatLoction.FullName "install" -RedirectStandardOutput $logFilePath -Wait
  Write-Verbose "Install output logged to $logFilePath"

  #Wait for the install to take place
  Start-Sleep -s 1

  $serviceInstalledCorrectly = IsElasticsearchServiceInstalled

  if (-not $serviceInstalledCorrectly)
  {
    throw "Service failed to install correctly"
  }

  #Get service
  $serviceObject = get-service | ?{$_.Name -like "*Elasticsearch*"}

  #Set it up to start automatically and Start it, if needed
  if ($serviceObject.Status -eq "Stopped")
  {
    $serviceObject.Start()
  }

  $serviceObject | Set-Service -StartupType Automatic
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
    $UnzipFolder
  )

  Write-Verbose "Start Test-TargetResource"

  if (-not (IsElasticsearchServiceInstalled))
  {
    Write-Verbose "Service not present on machine"
    Return $false
  }

  Return $true
}

Function IsElasticsearchServiceInstalled
{
  $serviceObject = get-service | ?{$_.Name -like "*Elasticsearch*"}

  #Check the service appeared
  if ($serviceObject.Count -ne 1)
  {
    return $false
  }
  else
  {
    Write-Verbose "Service Present on machine (may have already been installed)"
    Write-Verbose "$($serviceObject | Format-List | Out-String)"

    #Check if we need to start it again
    if ($serviceObject.Status -eq "Stopped")
    {
      $serviceObject.Start()
    }
  }

  return $true
}


Export-ModuleMember -Function *-TargetResource
