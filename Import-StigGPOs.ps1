<#
.SYNOPSIS
    Import GPOs from DISA for STIG compliance. 

.DESCRIPTION
    Import GPOs from DISA for STIG compliance. 

.PARAMETER STIGPath
    Parent STIG directory (e.g. C:\STIGS\DoD Windows 10 v1r13)

.PARAMETER MigrationTablePath
    Desired Migration Table

.NOTES
    Author: JBear 5/24/2018
#>

[Cmdletbinding(SupportsShouldProcess)]
param(

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter STIG Directory")]
    [String[]]$STIGPath = $null,

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter Desired Migration Table")]
    [String[]]$MigrationTablePath = $null,

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter Desired Domain")]
    [String[]]$Domain = (Get-ADDomainController).Domain,
    
    [Parameter(DontShow)]
    [String]$GPOPath = "\\FileShare01\IT\Documents\GPO Backup"
)

if($STIGPath -eq $null) {

    Add-Type -AssemblyName System.Windows.Forms

    $Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $Result = $Dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }))

    if($Result -eq 'OK') {

        Try {
      
            $STIGPath = $Dialog.SelectedPath
        }

        Catch {

            $STIGPath = $null
	        Break
        }
    }

    else {

        #Shows upon cancellation of Save Menu
        Write-Host -ForegroundColor Yellow "Notice: No file(s) selected."
        Break
    }
}

function Import-STIGasGPO {
[Cmdletbinding(SupportsShouldProcess)]
Param()

    foreach($Path in $STIGPath) {

        $BaseFile = (Get-ChildItem "$Path\GPOs").FullName

        if(!([String]::IsNullOrWhiteSpace($BaseFile))) {

            if($MigrationTablePath -eq $null) {

                Add-Type -AssemblyName System.Windows.Forms

                $Dialog2 = New-Object System.Windows.Forms.OpenFileDialog
                $Dialog2.InitialDirectory = "$GPOPath\MigrationTables"
                $Dialog2.Title = "Select Migration Table (Not Required)"
                $Dialog2.Filter = "Migration Tables (*.migtable)|*.migtable"        
                $Dialog2.Multiselect=$false
                $Result2 = $Dialog2.ShowDialog((New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }))

                if($Result2 -eq 'OK') {

                    Try {
      
                        $MigrationTablePath = $Dialog2.FileNames
                    }

                    Catch {

                        $MigrationTablePath = $null
                    }
                }

                else {

                    $MigrationTablePath = $null

                    #Shows upon cancellation of Save Menu
                    Write-Host -ForegroundColor Yellow "Notice: No Migration Table Selected."
                }
            }

            foreach($Base in $BaseFile) {
    
                [XML]$XML = (Get-Content "$Base\Backup.xml")
                $GPOName = $((Select-XML -XML $XML -XPath "//*").Node.DisplayName.'#cdata-section')

                if(!([String]::IsNullOrWhiteSpace($MigrationTablePath))) { 

                    Import-GPO -Domain $($Domain) -MigrationTable $MigrationTablePath -BackupGpoName $GPOName -TargetName $GPOName -Path "$Path\GPOS" -CreateIfNeeded
                }

                else {
                
                    Import-GPO -Domain $($Domain) -BackupGpoName $GPOName -TargetName $GPOName -Path "$Path\GPOS" -CreateIfNeeded
                }
            }
        }
    }
}

function Generate-MigrationTables {
[Cmdletbinding(SupportsShouldProcess)]
Param(
    
    [Parameter(DontShow)]
    [String]$Date = (Get-Date -Format yyyyMMdd),

    [Parameter(DontShow)]
    [String]$BackupPath = "$GPOPath\GPOs\$(( Get-ChildItem "$($GPOPath)\GPOs" |  Sort -Descending LastWriteTime | Select Name )[0].Name )"
)
    
    if(!(Test-Path "$GPOPath\MigrationTables\$Date")) {
        
        New-Item -ItemType Directory -Path "$GPOPath\MigrationTables\$Date" | Out-Null
    }

    $GPM =  New-Object -ComObject gpmGMT.gpm
    $Constants = $GPM.GetConstants()

    $GPBackup = $GPM.GetBackupDir("$BackupPath")
    $GPSearch = $GPM.CreateSearchCriteria()
    $BackupList = $GPBackup.SearchBackups($GPSearch)

    Write-Host -ForegroundColor Yellow "`nGenerating Updated Migration Tables..."

    foreach($GPO in $BackupList) {
        
        $MigrationTable = $GPM.CreateMigrationTable()

        $MigPath = "$GPOPath\MigrationTables\$Date\$($GPO.GPODisplayName.Replace("\",'').Replace("/",'').Replace(".",'').Replace(",",'').Replace("*",'')).migtable"
        $Security = $Constants.ProcessSecurity
        $MigrationTable.Add($Security,$GPO)

        $MigrationTable.Save($MigPath)
    }
}

foreach($Path in $STIGPath) {

    $STIGImport = "[Importing] $(Split-Path $Path -Leaf)"

    if(!([String]::IsNullOrWhiteSpace($MigrationTablePath))) {
    
        $MigrationFiles = "| Using $MigrationTablePath"
    }

    Write-Host -ForegroundColor Yellow "`n$STIGImport $MigrationFiles"
}

#Call Generate-MigrationTables function
Generate-MigrationTables

#Call main function; supports -WhatIf
Import-STIGasGPO