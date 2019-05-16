#Affiche les informations du Bios
$bios = Get-WmiObject Win32_Bios
$name = $bios.Name
$version = $bios.Version
Write-Output $z"cet ordinateur utilise le bios"$name" , "$version

#Ouvre le bloc-note et arrète tout les processus lancé par ce dernier
notepad.exe
$process = Get-WmiObject -Query "Select * from win32_Process where name='notepad.exe'"
echo $process.SessionId ; $process.ExecutablePath
Stop-Process -name "notepad"

#
$sessionEnv = Get-WmiObject -Query "Select * from Win32_service where name='SessionEnv'"
echo "id : ",$sessionEnv.ProcessId "status :",$sessionEnv.Status

#Liste le nombre de service lancé par la machine
$nb = 0
$service = Get-WmiObject Win32_service
ForEach($item in $service)
{
   $nb = $nb +1
}
echo $nb

#Affiche les services lancé et ceux arrété
$running = Get-WmiObject -Query "Select * from win32_service where state = 'Running'"
$stopped = Get-WmiObject -Query "Select * from win32_service where state = 'Stopped'"
$nbServiceRunning = 0
$nbServiceStopped = 0
ForEach ($item in $running)
{
    $nbServiceRunning = $nbServiceRunning + 1
}
ForEach ($item in $stopped)
{
    $nbServiceStopped = $nbServiceStopped + 1
}
echo $nbServiceRunning ; $nbServiceStopped

#Vérifier l'existence d'un service
echo "Saississer le service dont vous voulez vérrifier l'existence"
$verif = Read-Host
$verifService = Get-WmiObject -Query "Select * from win32_service where Name = '$verif'"
if (!$verifService)
{
    Write-Host "Le service"$verif" n'existe pas"
}
else
{
    echo $verifService
}

#Affiche le nom du driver du 3e disque
$Driver = Get-WmiObject Win32_logicalDisk -Filter DriveType=3
echo $Driver


#Affiche l'espace libre sur le disque
$Driver = Get-WmiObject Win32_logicalDisk
$tableau = @($Driver.FreeSpace)
$espaceLibre = 0
ForEach($item in $tableau)
{
    $espaceLibre = $espaceLibre + $item
}
For($ind = 1; $ind -le 3; $ind++)
{
    $espaceLibre = $espaceLibre / 1024
}
echo $z"L'espace Libre est de "$espaceLibre" GO"