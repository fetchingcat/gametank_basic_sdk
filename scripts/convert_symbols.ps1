# Convert DASM symbol file to cc65 map file format for GameTank Emulator
# Usage: .\convert_symbols.ps1 input.sym output.map

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false, Position=1)]
    [string]$OutputFile
)

if (-not $OutputFile) {
    $OutputFile = [System.IO.Path]::ChangeExtension($InputFile, ".map")
}

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

# Read DASM symbol file
$lines = Get-Content $InputFile

# Parse symbols - DASM format: "symbolname    address    (R )"
$symbols = @()
$inSymbolList = $false

foreach ($line in $lines) {
    # Skip header line
    if ($line -match "^---\s*Symbol List") {
        $inSymbolList = $true
        continue
    }
    
    if (-not $inSymbolList) { continue }
    
    # Skip empty lines and lines with dashes
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match "^-+$") { continue }
    
    # Parse symbol line: name, hex address, optional flags
    # Example: "F_gt_cls_byte    c1a0    (R )"
    if ($line -match '^\s*(\S+)\s+([0-9a-fA-F]+)\s*(.*)$') {
        $name = $Matches[1]
        $address = $Matches[2].ToUpper()
        $flags = $Matches[3].Trim()
        
        # Skip symbols that are just dashes or start with dashes
        if ($name -match '^-+$') { continue }
        
        # Skip internal/temporary symbols (start with numbers or have dots followed by numbers)
        if ($name -match '^\d+\.' -or $name -match '^_[A-Z]{2}_\d+') {
            continue
        }
        
        $symbols += [PSCustomObject]@{
            Name = $name
            Address = $address
            Flags = $flags
        }
    }
}

# Sort by address
$symbols = $symbols | Sort-Object { [Convert]::ToInt32($_.Address, 16) }

# Write cc65-style map file
$output = @()
$output += ""
$output += "Exports list by value:"
$output += "------------------------------"

foreach ($sym in $symbols) {
    # cc65 format: name (padded) address flags
    # The emulator parses: name address flags (space separated)
    $paddedName = $sym.Name.PadRight(32)
    $output += "{0} {1}   {2}" -f $paddedName, $sym.Address, "LAB"
}

$output += ""

# Write output file
$output | Out-File -FilePath $OutputFile -Encoding ASCII

Write-Host "Converted $($symbols.Count) symbols"
Write-Host "Output: $OutputFile"
