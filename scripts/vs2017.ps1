param (
    [Parameter(Mandatory=$true)][string]$output_dir
)

If ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $programFilesX86= ${env:ProgramFiles(x86)}
} Else {
    $programFilesX86= $env:ProgramFiles
}
#choco install -y vcbuildtools -ia "/Full"
choco install -y visualcpp-build-tools --version 15.0.26228.20170424

