configuration cDownloadConfig
{
	Import-DSCResource -Module cGripDevDSC
	
    node("localhost")
    {
        LocalConfigurationManager
        {
            DebugMode = 'ForceModuleImport'
        }
		
		cSimpleDownloader DownloadBingHomepage
		{
			#RemoteFileLocation = "http://download.oracle.com/otn-pub/java/jdk/8u45-b15/server-jre-8u45-windows-x64.tar.gz"
			RemoteFileLocation = "http://bing.com"
  			DestinationPath = "c:\temp\jre.tar.gz"
			CookieName = "oraclelicense"
    		CookieValue = "accept-securebackup-cookie"
    		CookieDomain = ".oracle.com"
		}
	}
}

cDownloadConfig

Start-DSCConfiguration .\cDownloadConfig -wait -verbose -force