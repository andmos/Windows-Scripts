    #requires -Version 2.0
    #
    # Example 1:
    # Get-PrivateKeyPath CN=DO_NOT_TRUST_FiddlerRoot -StoreName My -StoreScope CurrentUser
    # Example 2:
    # Get-PrivateKeyPath D359ECDC338CFDDCE86DDDA99BE36286BAE2018A
    function Get-PrivateKeyPath
    {
            param
            (
                    [Parameter(Mandatory = $true, Position = 0)]
                    [string]
                    $CertificateInput,
                   
                    [string]
                    [ValidateSet('TrustedPublisher','Remote Desktop','Root','REQUEST','TrustedDevices','CA','Windows Live ID Token
Issuer','AuthRoot','TrustedPeople','AddressBook','My','SmartCardRoot','Trust','Disallowed')]
                    $StoreName = 'My',
                   
                    [string]
                    [ValidateSet('LocalMachine','CurrentUser')]
                    $StoreScope = 'CurrentUser'
            )
            begin
            {
                    Add-Type -AssemblyName System.Security
            }
           
            process
            {
                    if ($CertificateInput -match "^CN=") {
                            # Common name given
                            # Extract thumbprint(s) of possible certificate(s) with matching common name
                            $MatchingThumbprints = Get-ChildItem cert:\$StoreScope\$StoreName |
                                                    Where-Object { $_.Subject -match "^" + $CertificateInput + ",?" } |
                                                    Select-Object Thumbprint
                    } else {
                            # Assuming thumbprint
                            # Create array of hashes, similar to output of Select-Object
                            $MatchingThumbprints = @(@{"Thumbprint" = $CertificateInput})
                    }
                    if ($MatchingThumbprints.count -eq 0) {
                            write-error ("Could not find any matching certificates.") -ErrorAction:Stop
                    }
                   
                    $CertificateStore = new-object
System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreLocation]$StoreScope)
                    $CertificateStore.open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadOnly")
                    $CertCollection = $CertificateStore.Certificates
                    Foreach ($Thumbprint in $MatchingThumbprints) {
                            $MatchingCertificates =
$CertCollection.Find([System.Security.Cryptography.X509Certificates.X509FindType]"FindByThumbprint", $Thumbprint.Thumbprint,
$false)
                            $stat = $?
                            if ($stat -eq $false -or $MatchingCertificates.count -eq 0) {
                                    write-error ("Internal error: Could not find certificate by thumbprint " +
$Thumbprint.Thumbprint) -ErrorAction:Stop
                            }
                           
                            Foreach ($Certificate in $MatchingCertificates) {
                                    if ($Certificate.PrivateKey -eq $null) {
                                            Write-Error ("Certificate doesn't have Private Key") -ErrorAction:Stop
                                    }
     
                                    Switch ($StoreScope)
                                    {
                                            "LocalMachine" { $PrivateKeysPath =
[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData) +
"\Microsoft\Crypto\RSA\MachineKeys"        }
                                            "CurrentUser" { $PrivateKeysPath =
[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData) + "\Microsoft\Crypto\RSA" }
                                    }
     
                                    $PrivateKeyPath = $PrivateKeysPath + "\" +
$Certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
                                    $PrivateKeyPath
                            }
                    }
            }
     
            end
            {
            }
    }

