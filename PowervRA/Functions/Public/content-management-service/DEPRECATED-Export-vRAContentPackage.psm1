﻿function Export-vRAContentPackage {
<#
    .SYNOPSIS
    Export a vRA Content Package
    
    .DESCRIPTION
    Export a vRA Content Package
    
    .PARAMETER Id
    Specify the ID of a Content Package

    .PARAMETER Name
    Specify the Name of a Content Package

    .PARAMETER Path
    The resulting path. If this parameter is not passed the action will be exported to
    the current working directory.

    .INPUTS
    System.String

    .OUTPUTS
    System.IO.FileInfo
    
    .EXAMPLE
    Export-vRAContentPackage -Id "b2d72c5d-775b-400c-8d79-b2483e321bae" -Path C:\Packages\ContentPackage01.zip

    .EXAMPLE
    Export-vRAContentPackage -Name "ContentPackage01" -Path C:\Packages\ContentPackage01.zip

    .EXAMPLE
    Get-vRAContentPackage | Export-vRAContentPackage

    .EXAMPLE
    Get-vRAContentPackage -Name "ContentPackage01" | Export-vRAContentPackage -Path C:\Packages\ContentPackage01.zip

#>
[CmdletBinding(DefaultParameterSetName="ById")][OutputType('System.IO.FileInfo')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,         

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Path

    )

    Begin {

        Write-Warning -Message "This command is deprecated and will be removed in a future release. Please use Export-vRAPackage instead."

        # --- Test for vRA API version
        xRequires -Version 7.0

        function internalWorkings ($InternalContentPackage, $InternalId, $InternalPath) {
            
            $Headers = @{

                "Authorization" = "Bearer $($Global:vRAConnection.Token)";
                "Accept"="application/zip";
                "Content-Type" = "Application/zip";

            }
            
            $FileName = "$($InternalContentPackage.Name).zip"

            if (!$InternalPath) {

                Write-Verbose -Message "Path parameter not passed, exporting to current directory."
                $FullPath = "$($(Get-Location).Path)\$($FileName)"

            }
            else {

                Write-Verbose -Message "Path parameter passed."
                
                if ($InternalPath.EndsWith("\")) {

                    Write-Verbose -Message "Ends with"

                    $InternalPath = $InternalPath.TrimEnd("\")

                }
                
                $FullPath = "$($InternalPath)\$($FileName)"
            }

            # --- Run vRA REST Request
            $URI = "/content-management-service/api/packages/$($InternalId)"

            Invoke-vRARestMethod -Method GET -Headers $Headers -URI $URI -OutFile $FullPath -Verbose:$VerbosePreference

            # --- Output the result
            Get-ChildItem -Path $FullPath
        }
    }

    Process {

        try {    

            switch ($PsCmdlet.ParameterSetName) {
            
                'ByName' {

                    foreach ($ContentPackageName in $Name) {

                        $ContentPackage = Get-vRAContentPackage -Name $ContentPackageName
                        $Id = $ContentPackage.Id

                        internalWorkings -InternalContentPackage $ContentPackage -InternalId $Id -InternalPath $Path                   
                    }
                }
                'ById' {

                    foreach ($ContentPackageId in $Id){

                        $ContentPackage = Get-vRAContentPackage -Id $ContentPackageId

                        internalWorkings -InternalContentPackage $ContentPackage -InternalId $ContentPackageId -InternalPath $Path
                    }
                }
            }
        }
        catch [Exception]{

            throw
        }
    }
}