configuration TestConfig
{
    $installRoot = 'c:\elkInstall\'
    $downloadroot = 'c:\elkTempDownload\'

    $elasticZipLocation = Join-Path $downloadroot 'elastic.zip'
    $elasticUnpacked = Join-Path $installRoot 'elasticsearch'
    $elasticDownloadUri = 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.4.zip'

    $kibanaZipLocation = Join-Path $downloadroot 'kibana.zip'
    $kibanaUnpacked = Join-Path $installRoot 'kibana'
    $kibanaDownloadUri = 'https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-windows.zip'

    $javaZipLocation = Join-Path $downloadroot 'jre.tar.gz'
    $javaUnpackLocation = Join-Path $installRoot 'jre'
    $javaFolder =  Join-Path $javaUnpackLocation 'jdk1.8.0_40'
    #$javaDownloadUri = 'http://download.processing.org/java/jre-8u31-windows-x64.tar.gz' #Using mirror as Oracle don't allow unattended downloads
    $javaDownloadUri = 'http://www-lry.ciril.net/client/java/server-jre-8u40-windows-x64.tar.gz'

    $nssmZipLocation = Join-Path $downloadroot 'nssm.zip'
    $nssmUnpackLocation = Join-Path $installRoot 'nssmkibana'
    $nssmDownloadUri = 'https://nssm.cc/release/nssm-2.24.zip'

    $7zipUnpackLocations = Join-Path $downloadroot '7zip.zip'

    Import-DscResource -Module xPSDesiredStateConfiguration
    Import-DscResource -Module cElasticsearch
    node ("localhost")
    {
        LocalConfigurationManager
        {
            DebugMode = 'All'
        }

        #####
        #Downlaod and set env variable for JRE
        #####

        xRemoteFile JREDownload
        {
            DestinationPath = $javaZipLocation
            Uri = $javaDownloadUri
            UserAgent = "DSCScript"
        }

        c7zip JREUnzip
        {
            DependsOn = "[xRemoteFile]JREDownload"
            ZipFileLocation = $javaZipLocation
            UnzipFolder = $javaUnpackLocation
        }

        Environment SetJREEnviromentVar
        {
            Name = "JAVA_HOME"
            Ensure = "Present"
            Path = $false
            Value = $javaFolder
            DependsOn = "[c7zip]JREUnzip"
        }

        #####
        #Download and install elasticsearch
        #####

        xRemoteFile ElasticDownloadZip
        {
            DestinationPath = $elasticZipLocation
            Uri = $elasticDownloadUri
            UserAgent = "DSCScript"
        }

        c7zip ElasticUnzip
        {
            DependsOn = "[xRemoteFile]ElasticDownloadZip"
            ZipFileLocation = $elasticZipLocation
            UnzipFolder = $elasticUnpacked
        }

        cElasticsearch ElasticInstall
        {
            DependsOn = @('[Environment]SetJREEnviromentVar', '[c7zip]ElasticUnzip')
            UnzipFolder = $elasticUnpacked
        }

        
        #####
        #Downlaod and Install Kibana, using nssm to host as windows service
        #####

        xRemoteFile NSSMDownloadZip
        {
            DestinationPath = $nssmZipLocation
            Uri = $nssmDownloadUri
            UserAgent = 'DSC Script'
        }


        c7zip NSSMExtractForKibana
        {
            ZipFileLocation = $nssmZipLocation
            UnzipFolder = $nssmUnpackLocation
            DependsOn = "[xRemoteFile]NSSMDownloadZip"
        }

        xRemoteFile KibanaDownloadZip
        {
            DestinationPath = $kibanaZipLocation
            Uri = $kibanaDownloadUri
            UserAgent = "DSCScript"
        }

        c7zip KibanaUnzip
        {
            DependsOn = "[xRemoteFile]KibanaDownloadZip"
            ZipFileLocation = $kibanaZipLocation
            UnzipFolder = $kibanaUnpacked
        }

        cKibana KibanaInstall
        {
            DependsOn = @('[c7zip]KibanaUnzip', '[c7zip]NSSMExtractForKibana')
            UnzipFolder = $kibanaUnpacked
            NssmUnzipFolder = $nssmUnpackLocation
        }
    }
}

TestConfig

Start-DscConfiguration .\TestConfig -wait -verbose -force
