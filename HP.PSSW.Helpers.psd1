@{
    RootModule = 'PP.PS.Helpers.psm1'
    ModuleVersion = '0.0.0'
    CompatiblePSEditions = @('Core')
    GUID                 = '47135cee-f3ce-4ac4-8467-f71f2b8e2402'
    Author               = 'HP Inc.'
    CompanyName          = 'HP Development Company, L.P.'
    Copyright            = 'Copyright 2020 HP Development Company, L.P.'
    Description          = 'Some handy utility functions for PowerShell'
    PowerShellVersion = '7.0'
    RequiredModules = @()
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    FunctionsToExport = @(
        'Get-CallerPrefix',
        'Get-CommonParams',
        'Get-ElapsedTime',
        'Get-PathParent'
        'Get-Prefix',
        'Get-PropNoFail',
        'Get-TimeStamp',
        'Get-StartTime',
        'Get-StopTime',
        'Confirm-DirectoryPath',
        'Confirm-FilePath',
        'Confirm-Guid',
        'ConvertTo-Path',
        'ConvertTo-PathArray',
        'ConvertTo-JsonObject',
        'ConvertTo-JsonPath',
        'ConvertTo-UrlEncoded',
        'Write-ErrorMessage'
        , 'Write-ErrorReport'
        , 'Get-PSSDLCTestMode'
        , 'Set-PSSDLCTestMode'
        , 'Clear-PSSDLCTestMode'
        , 'ConvertFrom-RequestException'
        , 'ConvertTo-Hashtable'
        , 'ConvertTo-JsonPatchDocOp'
        # Logging support
        , 'Write-Log'
    )
    CmdletsToExport = @()
    # VariablesToExport = @()
    AliasesToExport = @(
        'callerPrefix',
        'commonParams',
        'elapsedTime',
        'jsonObj',
        'jsonPath',
        'jpdo',
        'p2pa',
        'pa2p',
        'parent'
        'prefix',
        'prop',
        'pso2hash',
        'RESTException',
        'TimeStamp',
        'startTime',
        'stopTime',
        'urlEncode',
        'validateGuid'
    )
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @()
    PrivateData = @{
        PSData = @{
            Tags = @()
            # LicenseUri = ''
            ProjectUri = 'https://github.azc.ext.hp.com/PSSW-DX/sdlc-tools'
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @()
        }
    }
    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''
}