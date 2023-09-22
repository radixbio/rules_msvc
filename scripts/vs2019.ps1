param (
    [Parameter(Mandatory=$true)][string]$output_dir
 )

If ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $programFilesX86= ${env:ProgramFiles(x86)}
} Else {
    $programFilesX86= $env:ProgramFiles
}

choco install -y visualstudio2019buildtools visualstudio2019-workload-vctools
choco install -y netfx-4.8-devpack

$vcvars32="`"$programFilesX86\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars32.bat`""
$vcvars64="`"$programFilesX86\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat`""

echo "vcvars32 $vcvars32"
echo "vcvars64 $vcvars64"

mkdir -Force "$output_dir"

$vcvars32_export="$output_dir\vcvars32.txt"
echo "exporting $vcvars32_export"
cmd /c "$vcvars32 && set > $vcvars32_export"

$vcvars64_export="$output_dir\vcvars64.txt"
echo "exporting $vcvars64_export"
cmd /c "$vcvars64 && set > $vcvars64_export"

refreshenv
