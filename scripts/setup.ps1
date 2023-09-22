If ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $programFilesX86= ${env:ProgramFiles(x86)}
} Else {
    $programFilesX86= $env:ProgramFiles
}

# no sleeping
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0

# no windows updates
Stop-Service -Force -NoWait -Name wuauserv
set-service wuauserv -startup disabled
get-wmiobject win32_service -filter "name='wuauserv'"

# set strong cryptography on 32 bit .Net Framework (version 4 and above)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
# set strong cryptography on 64 bit .Net Framework (version 4 and above)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord


choco install -y gnuwin32-coreutils.install
$env:Path= "$programFilesX86\GnuWin32\bin;$env:Path"
[Environment]::SetEnvironmentVariable("Path", "$env:Path", "Machine")
refreshenv

choco install -y diffutils fd 7zip.install zip unzip which
which diff
which fd
which sort

# regdiff (sadly not in choco)
$regdiffName="regdiff-4.3"
$regdiffArchive="$regdiffName.7z"
$regdiffArchivePath="C:\Windows\Temp\$regdiffArchive"
$regdiffUrl="http://p-nand-q.com/download/$regdiffArchive"
echo $regdiffUrl
(New-Object System.Net.WebClient).DownloadFile($regdiffUrl, $regdiffArchivePath)
$regdiffHash = (Get-FileHash $regdiffArchivePath -Algorithm MD5).Hash
$regdiffExpectedHash = "E5F910DA1EF3402653EAB4D4D8DC428F"
echo checking hashes $regdiffHash =? $regdiffExpectedHash
If ($regdiffHash -eq $regdiffExpectedHash) {
    7z x $regdiffArchivePath
    cp $regdiffName/* C:\ProgramData\chocolatey\bin\
    rm -r -fo $regdiffArchivePath
    rm -r -fo $regdiffName
    which regdiff
}  Else {
    echo "ERROR: regdiff hash doesn't match!"
}
