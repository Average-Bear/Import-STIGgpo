# Import-STIGgpo
Please, ensure you backup all of your own GPOs (see my Backup-GPO script) before executing anything; use at your own risk... you are liable for any and all negative effects of this script.

Line 31 -- Enter your GPO backups directory here.

Unzip the DISA STIG GPO Package files. When selecting a folder for the parameter $STIGPath, choose the parent directory of the STIG you will be importing or, create a variable with these same values to pass into $STIGPath prior to launching the script.

[E.G.] 

       C:\April 2018 DISA STIG GPO Package\DoD Windows FireWall v1r7

       C:\April 2018 DISA STIG GPO Package\DoD Windows 10 v1r13
       
       C:\April 2018 DISA STIG GPO Package\DoD Windows Server 2016 MS and DC v1r14
       
       C:\April 2018 DISA STIG GPO Package\DoD Windows Defender Antivirus STIG v1r4
       

This script will generate Migration Tables for ALL existing GPOs, as a back solution. They will be stored in a directory named as the date of execution. You will be prompted to select a Migration Table. Only choose a Migration Table if it is required, that is up to you to figure out. 

You will be prompted with all of the selected GPO names that you will be importing. All user and computers settings are split purposely by DISA. It will generate separate GPOs accordingly. 

This does not link GPOs for testing, it ONLY assists in the import process into Group Policy Objects. It is now up to you to test and set inheritance properly.
