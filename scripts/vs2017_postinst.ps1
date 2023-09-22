param (
    [Parameter(Mandatory=$true)][string]$output_dir
)

If ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $programFilesX86= ${env:ProgramFiles(x86)}
} Else {
    $programFilesX86= $env:ProgramFiles
}

echo "finishing installation"
C:\Users\vagrant\AppData\Local\Temp\chocolatey\visualcpp-build-tools\15.0.26228.20170424\vs_BuildTools.exe --passive --wait --norestart --add Microsoft.VisualStudio.Component.Roslyn.Compiler --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.CoreBuildTools --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.VC.CoreBuildTools --add Microsoft.VisualStudio.Component.Static.Analysis.Tools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.Windows10SDK.17763 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.TestTools.BuildTools --add Microsoft.Net.Component.4.6.1.SDK --add Microsoft.Net.Component.4.6.1.TargetingPack --add Microsoft.VisualStudio.Component.VC.CLI.Support --add Microsoft.VisualStudio.Workload.VCTools
$vcvars32="`"$programFilesX86\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars32.bat`""
$vcvars64="`"$programFilesX86\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat`""
# There's a bug in this version of the msvc installer where choco will exit before the installer is done.
# We have to wait until everything is done.
Start-Sleep 100
Wait-Process -Name "setup"
echo "done finishing installation"
#wait for the vcvars file to appear
$testFile = $vcvars32 -replace '"'
while (!(Test-Path $testFile)) {
    echo "waiting for $testFile"
    Start-Sleep 10
}


echo "vcvars32 $vcvars32"
echo "vcvars64 $vcvars64"

mkdir -Force "$output_dir"
echo "---------"
cmd /c "dir C:\vagrant\msvc15\snapshots"
echo "---------"

$vcvars32_export="$output_dir\vcvars32.txt"
echo "exporting $vcvars32_export"
cmd /c "$vcvars32 && set > $vcvars32_export"

$vcvars64_export="$output_dir\vcvars64.txt"
echo "exporting $vcvars64_export"
cmd /c "$vcvars64 && set > $vcvars64_export"

refreshenv
