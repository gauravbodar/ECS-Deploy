param (
[Parameter(Mandatory=$true)]
[string]$AccessKeyId,
[Parameter(Mandatory=$true)]
[string]$SecretAccessKey,
[Parameter(Mandatory=$true)]
[string]$AwsProxy,
[Parameter(Mandatory=$false)]
[string]$DeployUser,
[Parameter(Mandatory=$false)]
[string]$DeployPW,
[Parameter(Mandatory=$false)]
[string]$RemoteServer
)

$ErrorActionPreference = "Stop"

#If being executed on Azure DevOps Build Server
if (!$RemoteServer) {
    if (test-path -Path $home\.aws\config) {
        write-output "Found old AWS configuration file ----- REMOVING"
        write-output "Removing"
        Remove-Item $home\.aws\config
        if (!(test-path -Path $home\.aws\config)) {
            write-output "Successfully Removed AWS Config File"
        }
    }
    
    if (test-path -Path $home\.aws\credentials) {
        write-output "Found old AWS credentials file ----- REMOVING"
        Remove-Item $home\.aws\credentials
        if (!(test-path -Path $home\.aws\credentials)) {
            write-output "Successfully Removed AWS credentials File"
        }
    }
    
    New-Item -ItemType Directory -Force -Path $HOME\.aws
    
    Write-Output "[default]
   #Add AWS region
    region = $Region 
    output = json" | out-file -encoding ASCII $HOME\.aws\config
    
    Write-Output "[default]
    aws_access_key_id = $AccessKeyId
    aws_secret_access_key = $SecretAccessKey" | out-file -encoding ASCII $HOME\.aws\credentials
    
    $env:HTTPS_PROXY="$AwsProxy"
}

#If being executed on Remote Server
elseif ($RemoteServer) {
    
    #Check Credentials are supplied
    if ($DeployUser -and $DeployPW) {
        #Setup Credentials for invoke-command 
        $Password = ConvertTo-SecureString -String $DeployPW -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$DeployUser", $Password
        
        Invoke-Command -ComputerName $RemoteServer -Credential $Credentials -ScriptBlock {
            #Remote Params
            $Deployuser = $using:deployuser
            $AccessKeyId = $using:AccessKeyId
            $SecretAccessKey = $using:SecretAccessKey
            $AwsProxy = $using:AwsProxy
            
            #strip domain for $deployuser
            $deployuser = $deployuser.split('\')[1]
            
            $profilepath = "C:\users\$DeployUser"
            if (test-path -Path $profilepath\.aws\config) {
                write-output "Found old AWS configuration file ----- REMOVING"
                write-output "Removing"
                Remove-Item $profilepath\.aws\config
                if (!(test-path -Path $profilepath\.aws\config)) {
                    write-output "Successfully Removed AWS Config File"
                }
            }
            
            if (test-path -Path $profilepath\.aws\credentials) {
                write-output "Found old AWS credentials file ----- REMOVING"
                Remove-Item $profilepath\.aws\credentials
                if (!(test-path -Path $profilepath\.aws\credentials)) {
                    write-output "Successfully Removed AWS credentials File"
                }
            }
            
            New-Item -ItemType Directory -Force -Path $profilepath\.aws
            
            Write-Output "[default]

output = json" | out-file -encoding ASCII $profilepath\.aws\config
            
            Write-Output "[default]
aws_access_key_id = $AccessKeyId
aws_secret_access_key = $SecretAccessKey" | out-file -encoding ASCII $profilepath\.aws\credentials
            
            $env:HTTPS_PROXY="$AwsProxy"
        }
    }
    else {
        write-error "Remote Specified, but not credentials supplied"
    }
}

