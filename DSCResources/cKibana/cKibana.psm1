function Get-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $UnzipFolder,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $NssmUnzipFolder

  )

  Write-Verbose "Start Get-TargetResource"

  #Needs to return a hashtable that returns the current
  #status of the configuration component
  $Configuration = @{
    UnzipFolder = $UnzipFolder
    NssmUnzipFolder = $NssmUnzipFolder
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
    $UnzipFolder,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $NssmUnzipFolder
  )

  Write-Verbose "Start Set-TargetResource"

  #Name of Service
  $kibanaServiceName = "KibanaNSSM"

  #Find the Bat file the runs kibana
  $serviceBatLoction = Get-ChildItem -Path $UnzipFolder -Filter kibana.bat -Recurse | Select -first 1

  #Get the non-sucky-service-manager exe
  $nssmExeLoction = Get-ChildItem -Path $NssmUnzipFolder -Filter nssm.exe -Recurse | ?{ $_.Directory.Name-eq "win64"}

  if ($nssmExeLoction.Count -ne 1)
  {
    throw "Failed to find NSSM.exe has likely changed its install method or Zip structure"
  }

  #Check we're not already installed
  $serviceObject = get-service | ?{$_.Name -like "*$kibanaServiceName*"}
  if ($serviceObject)
  {
    #Remove if we are
    $logRemoveFilePath = Join-Path $UnzipFolder "RemoveLog.txt"
    $removeArgs = "remove $kibanaServiceName confirm"
    Start-Process $nssmExeLoction.FullName $removeArgs -RedirectStandardOutput $logRemoveFilePath -Wait

    #Wait for intall as service manager can be nice and laggy
    Start-Sleep -s 2
  }



  #Create a service, using nssm, to host kibana
  $logFilePath = Join-Path $UnzipFolder "InstallLog.txt"
  $installArgs = "install $kibanaServiceName $($serviceBatLoction.FullName)"
  Start-Process $nssmExeLoction.FullName $installArgs -RedirectStandardOutput $logFilePath -Wait


  #Wait for intall
  Start-Sleep -s 2

  $serviceObject = get-service | ?{$_.Name -like "*KibanaNSSM*"}

  #Check the service appeared
  if ($serviceObject.Count -ne 1)
  {
    throw "Service failed to install correctly"
  }
  else
  {
    Write-Verbose "Service Present on machine (may have already been installed)"
    Write-Verbose "$($serviceObject | Format-List | Out-String)"
  }

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
    $UnzipFolder,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $NssmUnzipFolder
  )

  Write-Verbose "Start Test-TargetResource"

  $serviceObject = get-service | ?{$_.Name -like "*$kibanaServiceName*"}

  if ($serviceObject)
  {
    Write-Verbose "Service not present on machine"
    Return $false
  }

  Return $true
}


Export-ModuleMember -Function *-TargetResource
