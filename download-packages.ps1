# Monitoring Components Download Script
# Support Windows PowerShell 5.1+ and PowerShell Core 6+

param(
    [string]$DownloadPath = ".\package",
    [switch]$Force = $false,
    [switch]$SkipExisting = $true
)

# Set error handling
$ErrorActionPreference = "Stop"

# Create download directory
if (-not (Test-Path $DownloadPath)) {
    Write-Host "Creating directory: $DownloadPath" -ForegroundColor Green
    New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
}

# Define download configuration
$packages = @(
    @{
        Name = "Grafana"
        Version = "12.0.1"
        Url = "https://dl.grafana.com/oss/release/grafana-12.0.1.linux-amd64.tar.gz"
        Filename = "grafana-12.0.1.linux-amd64.tar.gz"
        Size = "~175MB"
    },
    @{
        Name = "Prometheus"
        Version = "3.4.1"
        Url = "https://github.com/prometheus/prometheus/releases/download/v3.4.1/prometheus-3.4.1.linux-amd64.tar.gz"
        Filename = "prometheus-3.4.1.linux-amd64.tar.gz"
        Size = "~112MB"
    },
    @{
        Name = "Node Exporter"
        Version = "1.9.1"
        Url = "https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz"
        Filename = "node_exporter-1.9.1.linux-amd64.tar.gz"
        Size = "~11MB"
    },
    @{
        Name = "MySQL Exporter"
        Version = "0.17.2"
        Url = "https://github.com/prometheus/mysqld_exporter/releases/download/v0.17.2/mysqld_exporter-0.17.2.linux-amd64.tar.gz"
        Filename = "mysqld_exporter-0.17.2.linux-amd64.tar.gz"
        Size = "~9MB"
    },
    @{
        Name = "Loki"
        Version = "3.4.0"
        Url = "https://github.com/grafana/loki/releases/download/v3.4.0/loki-linux-amd64.zip"
        Filename = "loki-linux-amd64.zip"
        Size = "~35MB"
    },
    @{
        Name = "Promtail"
        Version = "3.4.0"
        Url = "https://github.com/grafana/loki/releases/download/v3.4.0/promtail-linux-amd64.zip"
        Filename = "promtail-linux-amd64.zip"
        Size = "~30MB"
    },
    @{
        Name = "Tempo"
        Version = "2.8.0"
        Url = "https://github.com/grafana/tempo/releases/download/v2.8.0/tempo_2.8.0_linux_amd64.tar.gz"
        Filename = "tempo_2.8.0_linux_amd64.tar.gz"
        Size = "~57MB"
    }
)

# Display package information
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Monitoring Components Download Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Download Path: $DownloadPath" -ForegroundColor Yellow
Write-Host "Will download the following packages:" -ForegroundColor Yellow
foreach ($pkg in $packages) {
    Write-Host "  - $($pkg.Name) v$($pkg.Version) ($($pkg.Size))" -ForegroundColor White
}
Write-Host "==========================================" -ForegroundColor Cyan

# Ask for user confirmation
if (-not $Force) {
    $confirm = Read-Host "Continue with download? (y/N)"
    if ($confirm -notmatch "^[yY]") {
        Write-Host "Download cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Download function
function Download-File {
    param(
        [string]$Url,
        [string]$FilePath,
        [string]$Name
    )
    
    try {
        Write-Host "Downloading $Name..." -ForegroundColor Green
        Write-Host "  URL: $Url" -ForegroundColor Gray
        Write-Host "  Target: $FilePath" -ForegroundColor Gray
        
        # Prepare web request parameters
        $webRequestParams = @{
            Uri = $Url
            OutFile = $FilePath
            UseBasicParsing = $true
        }
        
        # Add progress display if supported (PowerShell 6+)
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $webRequestParams.Add('PassThru', $true)
        }
        
        # Set user agent
        $webRequestParams.Add('UserAgent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
        
        # Execute download
        $response = Invoke-WebRequest @webRequestParams
        
        if (Test-Path $FilePath) {
            $fileSize = (Get-Item $FilePath).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            Write-Host "  Download completed: $fileSizeMB MB" -ForegroundColor Green
        } else {
            throw "File does not exist after download"
        }
    }
    catch {
        Write-Error "Failed to download $Name : $($_.Exception.Message)"
        throw
    }
}

# Start downloading
$downloadCount = 0
$skipCount = 0
$errorCount = 0

foreach ($pkg in $packages) {
    $filePath = Join-Path $DownloadPath $pkg.Filename
    
    # Check if file already exists
    if ((Test-Path $filePath) -and $SkipExisting -and -not $Force) {
        $existingSize = (Get-Item $filePath).Length
        $existingSizeMB = [math]::Round($existingSize / 1MB, 2)
        Write-Host "Skipping $($pkg.Name): File already exists ($existingSizeMB MB)" -ForegroundColor Yellow
        $skipCount++
        continue
    }
    
    try {
        Download-File -Url $pkg.Url -FilePath $filePath -Name "$($pkg.Name) v$($pkg.Version)"
        $downloadCount++
    }
    catch {
        Write-Host "Download failed: $($pkg.Name)" -ForegroundColor Red
        $errorCount++
        
        # Clean up partial download
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
            Write-Host "  Cleaned up partial download" -ForegroundColor Gray
        }
    }
    
    # Add short delay to avoid server pressure
    Start-Sleep -Milliseconds 500
}

# Display download results
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Download Summary:" -ForegroundColor Cyan
Write-Host "  Successfully downloaded: $downloadCount packages" -ForegroundColor Green
Write-Host "  Skipped files: $skipCount packages" -ForegroundColor Yellow
Write-Host "  Failed downloads: $errorCount packages" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Cyan

# Display download directory contents
if (Test-Path $DownloadPath) {
    Write-Host "Download directory contents:" -ForegroundColor Yellow
    Get-ChildItem $DownloadPath | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  $($_.Name) - $sizeMB MB" -ForegroundColor White
    }
}

if ($errorCount -gt 0) {
    Write-Host "Note: $errorCount packages failed to download, please check network connection or download manually" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All packages downloaded successfully!" -ForegroundColor Green
    exit 0
} 