using namespace System.Web.HttpUtility
Write-Debug "Module:PSHelpers Loading..."

if (-not (Test-Path variable:global:PSSDLCTestMode)) {
    New-Variable -Scope global -Name PSSDLCTestMode -Value $false
}

#-------------------------------------------------------------------------------###
function Get-PropNoFail {
    <#
    .SYNOPSIS
        [PSHelper] Return a property value without fail. In case of any error
        a $null is returned.
    #>
    [CmdletBinding()]
    param(
        # Object to access property on.
        [Parameter(Mandatory, Position = 0)][AllowNull()][psobject]$InputObject
        # Name of property to access.
        , [Parameter(Mandatory, Position = 1)][AllowEmptyString()][string]$PropertyName
    )
    $CP = commonParams($PSBoundParameters)
    $retVal = $null
    try {
        $retVal = $InputObject.$PropertyName
    }
    catch {
        $e = $_
        Write-Debug "Error accessing property [$($PropertyName)]: $($e.Message)" @CP
    }
    $retVal
}
if (-not (Test-Path alias:prop -PathType Leaf)) {
    New-Alias -Name prop -Value Get-PropNoFail
}
#-------------------------------------------------------------------------------###
function Get-TimeStamp {
    [CmdletBinding()]
    param()
    Get-Date -Format 'o'
}
if (-not (Test-Path alias:TimeStamp -PathType Leaf)) {
    New-Alias -Name TimeStamp -Value Get-TimeStamp
}
#-------------------------------------------------------------------------------###
function Get-StartTime {
    [CmdletBinding()]
    param(
        # Optional prefix message
        [Parameter(Position = 0)][string]$Message = $null
    )
    # Common Parameters from the calling function
    $CP = commonParams($PSBoundParameters)
    if ($Message) { Write-Verbose "$($Message) StopWatch start new $(Get-Date)" @CP }
    [System.Diagnostics.Stopwatch]::StartNew()
}
if (-not (Test-Path alias:startTime -PathType Leaf)) {
    New-Alias -Name startTime -Value Get-StartTime
}

#-------------------------------------------------------------------------------###
function Get-ElapsedTime() {
    [CmdletBinding()]
    param(
        # Stopwatch instance to use.
        [Parameter(Position = 0)][System.Diagnostics.Stopwatch]$StopWatch,
        # Optional prefix message
        [Parameter(Position = 1)]$Message = $null
    )
    # Common Parameters from the calling function
    $CP = commonParams($PSBoundParameters)
    $retValue = $StopWatch.Elapsed.TotalSeconds
    if ($Message) {
        Write-Verbose "$($Message) StopWatch Elapsed time:'$($retValue)' seconds." @CP
    }
    $retValue
}
if (-not (Test-Path alias:elapsedTime -PathType Leaf)) {
    New-Alias -Name elapsedTime -Value Get-ElapsedTime
}

#-------------------------------------------------------------------------------###
function Get-StopTime {
    [CmdletBinding()]
    param(
        # Stopwatch instance to use.
        [Parameter(Position = 0)][System.Diagnostics.Stopwatch]$StopWatch,
        # Optional prefix message.
        [Parameter(Position = 1)][string]$Message = $null,
        # No return value.
        [Parameter()][switch]$NoReturn
    )
    # Common Parameters from the calling function
    $CP = commonParams($PSBoundParameters)
    $retValue = $stopwatch.Elapsed.TotalSeconds
    $stopwatch.Stop() | Out-Null
    if ($Message) {
        Write-Verbose "$($Message) StopWatch Stopped, Elapsed time:'$($retValue)' seconds." @CP
    }
    if (!$NoReturn) { $retValue }
}
if (-not (Test-Path alias:stopTime -PathType Leaf)) {
    New-Alias -Name stopTime -Value Get-StopTime
}

#-------------------------------------------------------------------------------###
function Get-CommonParams {
    <#
    .Synopsis
    From the list of parameters supplied, return a list of any of the
    PS Common Parameters with values.
    #>
    param(
        # List of parameters to consider, typically includes the
        # PSBoundParameters from the calling function
        [Parameter(Mandatory)]$BoundParams
    )
    $cp = @{}
    switch ($BoundParams) {
        { $_.ContainsKey('Debug') } { $cp.Debug = $BoundParams.Debug }
        { $_.ContainsKey('ErrorAction') } { $cp.ErrorAction = $BoundParams.ErrorAction }
        { $_.ContainsKey('ErrorVariable') } { $cp.ErrorVariable = $BoundParams.ErrorVariable }
        { $_.ContainsKey('InformationAction') } { $cp.InformationAction = $BoundParams.InformationAction }
        { $_.ContainsKey('InformationVariable') } { $cp.InformationVariable = $BoundParams.InformationVariable }
        { $_.ContainsKey('OutVariable') } { $cp.OutVariable = $BoundParams.OutVariable }
        { $_.ContainsKey('OutBuffer') } { $cp.OutBuffer = $BoundParams.OutBuffer }
        { $_.ContainsKey('PipelineVariable') } { $cp.PipelineVariable = $BoundParams.PipelineVariable }
        { $_.ContainsKey('Verbose') } { $cp.Verbose = $BoundParams.Verbose }
        { $_.ContainsKey('WarningAction') } { $cp.WarningAction = $BoundParams.WarningAction }
        { $_.ContainsKey('WarningVariable') } { $cp.WarningVariable = $BoundParams.WarningVariable }
    }
    if ($cp.Verbose -and $cp.Debug) {
        Write-Verbose "Verbose wins!" -Verbose
        $cp.Debug = $false
    }
    return $cp
}
if (-not (Test-Path alias:commonParams -PathType Leaf)) {
    New-Alias -Name commonParams -Value Get-CommonParams
}
#-------------------------------------------------------------------------------###
function Get-PSSDLCTestMode {
    [CmdletBinding()]
    param()
    $global:PSSDLCTestMode
}
#-------------------------------------------------------------------------------###
function Set-PSSDLCTestMode {
    [CmdletBinding()]
    param()
    $global:PSSDLCTestMode = $true
    $null = $global:PSSDLCTestMode
}
#-------------------------------------------------------------------------------###
function Clear-PSSDLCTestMode {
    [CmdletBinding()]
    param()
    $global:PSSDLCTestMode = $false; $null = $global:PSSDLCTestMode
}
#-------------------------------------------------------------------------------###
function Get-Prefix() {
    <#
    .Synopsis
        [PSHelper] Compute a prefix useful for logging messages
        prefix style: <caller>[functionName|<Class>.Method]:
        caller is the moduleName|scriptName|class.methodName|Console
    #>
    [CmdletBinding()]
    param(
    )
    # Common Parameters from the calling function
    $CP = commonParams($PSBoundParameters); $null = $CP
    # If the first arg is an object, treat this as a Class.Method function call
    $stack = Get-PSCallStack
    # Only one frame if called from PSShell,
    if ($stack.Length -eq 1) { 
        $prefix = -Join ("[", $Env:SESSIONNAME, "]: ")
        return $prefix 
    }
    $caller = $stack[1].Location
    switch -Regex($caller) {
        '(^.*)(\.)' {
            $caller = $Matches[1] # Module or Script name
        }
        '^<No file>$' {
            $caller = $Env:SESSIONNAME  # Called from Console shell
        }
        Default: { $caller = "Unknown" }
    }
    $function = $stack[1].FunctionName
    # If called from a "method" function, get the class name
    $function = $this ?( -Join ("<", $this.GetType().Name, ">.", $function)) : $function
    $prefix = -Join ($caller, "[", $function, "]: ")
    if ($global:PSSDLCTestMode) { Write-Host "$($prefix)Entry" -ForegroundColor 'Cyan' }
    return $prefix
}
if (-not (Test-Path alias:prefix -PathType Leaf)) {
    New-Alias -Name prefix -Value Get-Prefix
}

#-------------------------------------------------------------------------------###
function Get-CallerPrefix() {
    <#
    .Synopsis
        [PSHelper] Like prefix(), but for the caller of the caller, one more level up the stack
        prefix style: <caller>[functionName|<Class>.Method]:
        caller is the moduleName|scriptName|class.methodName|Console
        If the first arg is an object, treat this as a Class.Method function call
    #>
    $stack = Get-PSCallStack
    # Only one or two frames if called from PSShell,
    if ($stack.Length -le 2) { return $Env:SESSIONNAME }
    $callerOfCaller = $stack[2].Location
    switch -Regex($callerOfCaller) {
        '(^.*)(\.)' {
            $callerOfCaller = $Matches[1] # Module or Script name
        }
        '^<No file>$' {
            $callerOfCaller = $Env:SESSIONNAME  # Called from Console shell
        }
        Default: { $callerOfCaller = "Unknown" }
    }
    $function = $stack[2].FunctionName
    # If called from a "method" function, get the class name
    $function = $this ?( -Join ("<", $this.GetType().Name, ">.", $function)) : $function
    return -Join ($callerOfCaller, "[", $function, "]:")
}
if (-not (Test-Path alias:callerPrefix -PathType Leaf)) {
    New-Alias -Name callerPrefix -Value Get-CallerPrefix
}

#-------------------------------------------------------------------------------###
function ConvertTo-Path {
    param(
        [Parameter(Mandatory = $false)][string[]]$PathArray = @()
    )
    # convert path array to path
    $sep = [IO.Path]::DirectorySeparatorChar
    if ($PathArray) { return $PathArray -join $sep }
    return $sep
}
if (-not (Test-Path alias:pa2p -PathType Leaf)) {
    New-Alias -Name pa2p -Value ConvertTo-Path
}

#-------------------------------------------------------------------------------###
function ConvertTo-PathArray {
    param(
        [Parameter(Mandatory)][string]$Path
    )
    # convert path to path array
    $s = [IO.Path]::DirectorySeparatorChar
    $se = [regex]::Escape($s)
    [string[]]$ret = @()
    if ($Path[0] -eq $s) { $Path = $Path.SubString(1) }
    $Path = $Path.TrimEnd($se)
    [string[]]$ret = $Path -split $se
    # Always return an array, even if just one element, PS converts single element string[] to string
    return , $ret
}
if (-not (Test-Path alias:p2pa -PathType Leaf)) {
    New-Alias -Name p2pa -Value ConvertTo-PathArray
}

#-------------------------------------------------------------------------------###
function Get-PathParent() {
    param(
        [Parameter(Mandatory = $false)][string]$Path
    )
    $pa = p2pa($Path)
    $ppa = $pa[0..($pa.Length - 2)]
    return pa2p($ppa)
}
if (-not (Test-Path alias:parent -PathType Leaf)) {
    New-Alias -Name parent -Value Get-PathParent
}

#-------------------------------------------------------------------------------###
function ConvertTo-JsonPath([string[]]$stringArray) {
    return (ConvertTo-Json $stringArray -Compress)
}
if (-not (Test-Path alias:jsonPath -PathType Leaf)) {
    New-Alias -Name jsonPath -Value ConvertTo-JsonPath
}

#-------------------------------------------------------------------------------###
function ConvertTo-JsonObject([psobject]$obj) {
    return (ConvertTo-Json $obj -Compress)
}
if (-not (Test-Path alias:jsonObj -PathType Leaf)) {
    New-Alias -Name jsonObj -Value ConvertTo-JsonObject
}

#-------------------------------------------------------------------------------###
function Confirm-Guid([string]$guid) {
    try {
        [System.Guid]::Parse($guid) | Out-Null
        $true
    }
    catch {
        $false
    }
}
if (-not (Test-Path alias:validateGuid -PathType Leaf)) {
    New-Alias -Name validateGuid -Value Confirm-Guid
}

#-------------------------------------------------------------------------------###
function ConvertTo-UrlEncoded([string]$inString) {
    $outString = [System.Web.HttpUtility]::UrlEncode($inString)
    return $outString
}
if (-not (Test-Path alias:urlEncode -PathType Leaf)) {
    New-Alias -Name urlEncode -Value ConvertTo-UrlEncoded
}

#-------------------------------------------------------------------------------###
Function Write-ErrorMessage {
    [CmdletBinding(DefaultParameterSetName = 'ErrorMessage')]
    param(
        # Use the supplied error message string as the text of the error output.
        [Parameter(Position = 0, ParameterSetName = 'ErrorMessage', ValueFromPipeline, Mandatory)]
        [string]$errorMessage,
        # Use the supplied ErrorRecord object message string as the text of the output.
        [Parameter(ParameterSetName = 'ErrorRecord', ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]$errorRecord, 
        # If an Exception object is supplied and -Throw, then throw the exception.
        # No error message is output.
        [Parameter(ParameterSetName = 'Exception', ValueFromPipeline)]
        [Exception]$exception
    )
    switch ($PsCmdlet.ParameterSetName) {
        'ErrorMessage' {
            $err = $errorMessage
        }
        'ErrorRecord' {
            $errorMessage = @($error)[0]
            $err = $errorRecord
        }
        'Exception' {
            $errorMessage = $exception.Message
            $err = $exception
        }
    }
    Write-Error -Message $err -ErrorAction Continue
    # $Host.UI.WriteErrorLine($errorMessage)
}
#-------------------------------------------------------------------------------###
Function Write-ErrorReport {
    <#
    .Synopsis
    Handle different cases for reporting an error.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ErrorRecord')]
    param(
        # Use the supplied error message string as the text of the error output.
        [Parameter(Position = 0, ParameterSetName = 'ErrorMessage', Mandatory)]
        [string]$errorMessage,
        # Use the supplied ErrorRecord object message string as the text of the output.
        [Parameter(Position = 0, ParameterSetName = 'ErrorRecord')]
        [System.Management.Automation.ErrorRecord]$errorRecord,
        # If an Exception object is supplied and -Throw, then throw the exception.
        # No error message is output.
        [Parameter(Position = 0, ParameterSetName = 'Exception')]
        [Exception]$exception,
        # A prefix string for the composed error message.
        [Parameter(Position = 1)][string]$prefix = "",
        # A prefix string for the composed error message.
        [Parameter()][switch]$PositionMessage,
        # Switch to control throwing the Exception.
        [Parameter()][switch]$Throw
    )
    switch ($PsCmdlet.ParameterSetName) {
        'errorMessage' {
            Write-ErrorMessage "$($Prefix)$($errorMessage)"
            if ($Throw) { throw $errorMessage }
        }
        'errorRecord' {
            $err = $errorRecord
            $errorMessage = $err.Exception.Message
            $report = "$($Prefix)$($errorMessage)`n"
            if($PositionMessage){$report += $err.InvocationInfo.PositionMessage}
            Write-ErrorMessage $report
            if ($Throw) { throw $err }
        }
        'exception' {
            if ($Throw) { throw $exception }
        }
    }
}

#-------------------------------------------------------------------------------###
Function ConvertFrom-RequestException {
    [CmdletBinding()]
    param(
        [Parameter()][AllowNull()][System.Management.Automation.ErrorRecord]$er, 
        [Parameter()][AllowNull()][hashtable]$response
    ) 
    <# 
        .Synopsis
            Determine error from Invoke-RestMethod Exception
            er: Error Record - Extract useful values for the response
    #>
    if ($null -eq $er) { return $null } # nothing to examine
    if ($null -eq $response) { $response = @{CallerId = callerPrefix } }
    $response.StatusCode = [System.Net.HttpStatusCode]::None

    # More detailed Error message from Ado Services
    $e = $er.Exception
    if ($null -ne $e -and 'Response' -in $e.PSobject.Properties.Name) {
        $response.ExceptionType = $e.GetType().Name
        $response.StatusCode = $e.Response?.StatusCode
        $response.Headers = $e.Response?.Headers
        $response.Length = $e.Response?.Content.Headers.ContentLength
        $response.ContentType = $e.Response?.Content.Headers.ContentType
    }
    if ('ErrorDetails' -in $er.PSobject.Properties.Name) {
        # This is tedious. Many types of exceptions with different properties
        $txt = $er.ErrorDetails.Message # could be json or text
        if (Test-Json $txt -ErrorAction 'SilentlyContinue') {
            $obj = ConvertFrom-Json -InputObject $txt
            if ($response.ExceptionType -eq "HttpResponseException") {
                $response.ErrorMsg = $obj.errorMessages -join ";" 
            }
            else {
                $response.ErrorMsg = $obj.message
                $response.ErrorTypeKey = $obj.typeKey
            }
        }
        else {
            if ($txt -match ".*Basic Authentication Failure.*"){
                $response.ErrorMessage = $matches[0].Trim()
            }
        }
    }
    $msg = "$($response.CallerId)Exception: "
    $msg += "Status=($($response.StatusCode)) $($response.ErrorMessage)"
    Write-Error -Message $msg -ErrorAction Continue
    # Write-Information -Message $msg -InformationAction Continue
    return $response
}
if (-not (Test-Path alias:RESTException -PathType Leaf)) {
    New-Alias -Name RESTException -Value ConvertFrom-RequestException
}
#region Confirm-DirectoryPath Function------------------------------------------###
function Confirm-DirectoryPath {
    <#
    .Synopsis
        [PSHelper] Confirm a directory is present in another directory.
        May create if not existing.
    #>
    param(
        # Name of the directory to confirm or create.
        [Parameter(Mandatory, Position = 0)][string]$Name,
        # Directory in the File System.
        [Parameter()][AllowNull()][string]$Path, 
        # Quit if the child Directory is not present
        [Parameter()][switch]$Quit
    )
    if([string]::IsNullOrEmpty($Path)){$targetDir = $Name}
    else { $targetDir = Join-Path -Path $Path -ChildPath $Name}
    if (-not (Resolve-Path $targetDir -ErrorAction:SilentlyContinue)) {
        if ($Quit) { return $null }
        $targetDir = New-Item -ItemType Directory -Force -Path $targetDir
    }
    [string]$targetDir
}
#endregion Confirm-DirectoryPath Function---------------------------------------###
#region Confirm-FilePath Function-----------------------------------------------###
function Confirm-FilePath {
    <#
    .Synopsis
        [PSHelper] Confirm a file is present in the File System.
    .Outputs
        [bool] return $True if the file is present, $False otherwise.
    #>
    param(
        # Pathname of the file to confirm or create.
        [Parameter(Mandatory, Position = 0)][string]$Path
    )
    [bool] $retValue = $False
    if(-not [string]::IsNullOrEmpty($Path)){
        $fp = Resolve-Path $Path -ErrorAction:SilentlyContinue
        $retValue = ($null -ne $fp) ? $True : $False
    }
    $retValue
}
#endregion Confirm-FilePath Function--------------------------------------------###
#region ConvertTo-Hashtable ----------------------------------------------------###
function ConvertTo-Hashtable {
    param(
        [Parameter(Mandatory)][psobject]$pso 
    ) 
    <#
    .Synopsis
        [PSHelper] Convert PSObject to Hashtable.
    #>
    Write-Verbose '[Start]:: ConvertTo-HashtableFromPsCustomObject'

    $output = @{}; 
    $pso | Get-Member -MemberType *Property | ForEach-Object {
        $output.($_.name) = $pso.($_.name); 
    } 
    
    Write-Verbose '[Exit]:: ConvertTo-HashtableFromPsCustomObject'

    return  $output;
    # source: https://omgdebugging.com/2019/02/25/convert-a-psobject-to-a-hashtable-in-powershell/
}
if (-not (Test-Path alias:pso2hash -PathType Leaf)) {
    New-Alias -Name pso2hash -Value ConvertTo-Hashtable
}
#endregion ConvertTo-Hashtable -------------------------------------------------###
#region ConvertTo-JsonPatchDocOp -----------------------------------------------###
function ConvertTo-JsonPatchDocOp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$Op,
        [Parameter(Mandatory, Position = 1)][string]$Path, 
        [Parameter(Mandatory, Position = 2)][string]$Value 
    ) 
    <#
    .Synopsis
        [PSHelper] Convert values to Json Patch Doc hashtable object
    #>
    $jpdo = @{
        Op    = $Op
        Path  = $Path
        Value = $Value
    }
    return  $jpdo;
}
if (-not (Test-Path alias:jpdo -PathType Leaf)) {
    New-Alias -Name jpdo -Value ConvertTo-JsonPatchDocOp
}
#endregion ConvertTo-JsonPatchDocOp -----------------------------------------------###
