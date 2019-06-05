#Fonction de connexion à une base de donnée
Function Connect-MySQL([string]$user, [string]$pass, [string]$MySQLHost, [string]$database) { 
    # Load MySQL .NET Connector Objects 
    [void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data") 
    # Open Connection 
    #uid = nom du compte mysql, pwd = mot de passe
    $connStr = "server= " + $MySQLHost + ";port=3306;uid= " + $user + " ;pwd= " + $pass + " ;database= " + $database + ";Pooling=FALSE" 
    try {
        $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr) 
        $conn.Open()
    } catch [System.Management.Automation.PSArgumentException] {
        write-host "Unable to connect to MySQL server, do you have the MySQL connector installed..?"
        write-host $_
        Exit
    } catch {
        write-host "Unable to connect to MySQL server..."
        write-host $_.Exception.GetType().FullName
        write-host $_.Exception.Message
        write-host $connStr
        exit
    }
    write-host "Connected to MySQL database $MySQLHost\$database"
    
    return $conn 
}

#Fonction pour Insert/Update/Delette
function Execute-MySQLNonQuery($conn, [string]$query) { 
  $command = $conn.CreateCommand()                  # Create command object
  $command.CommandText = $query                     # Load query into object
  $RowsInserted = $command.ExecuteNonQuery()        # Execute command
  $command.Dispose()                                # Dispose of command object
  if ($RowsInserted) { 
    return $RowInserted 
  } else { 
    return $false 
  } 
}

#Fonction pour Select
function Execute-MySQLQuery($conn, [string]$query) { 
  # NonQuery - Insert/Update/Delete query where no return data is required
  $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $conn)    # Create SQL command
  $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)      # Create data adapter from query command
  $dataSet = New-Object System.Data.DataSet                                    # Create dataset
  $dataAdapter.Fill($dataSet, "data")                                          # Fill dataset from data adapter, with name "data"              
  $cmd.Dispose()
  return $dataSet.Tables["data"]                                               # Returns an array of results
}

#Connexion à la BDD ga2019
Write-Host "Veuillez vous rentrer vos identifiants"
$login = Read-Host "Identifiant"
$mdp = Read-Host "Mot de passe" #-AsSecureString
$database = "ga2019"
$MySQLHost = Read-host "Veuillez saisir l'adresser IP de votre Serveur de base de donnée"
$conn = Connect-MySQL $login $mdp $MySQLHost $database
clear
Write-Host "
 ____ ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ ____ 
||G |||a |||m |||e |||r |||' |||s |||       |||A |||s |||s |||e |||m |||b |||l |||y ||
||__|||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\| 
"
$relance = "o"
do
{
    #Séléction de l'action
    $action = Read-Host "Veuillez séléctionner l'action souhaiter `n-1 : Création de compte`n-2 : Suppression de compte`n`nVotre choix"
    if ($action -eq 1)
    #Création de compte 
    {
        #Récupération des informations de la table jeux
        $query = "SELECT * FROM jeux;"
        $result = Execute-MySQLQuery  $conn $query
        Write-Host "Veuillez séléctionner le jeu pour lequel vous souhaiter créer des comptes"
        #Affichage des identifiants et nom des jeux enregistré dans la table jeux
        foreach($jeu in $result)
        {
            $idJeu = $jeu.id
            $nomJeu = $jeu.nom
            if ($idjeu -notlike "")
            {
                Write-Host "-$idJeu : $nomJeu"
            }
        }
        $jeuChoisi = Read-Host "`nVotre choix"
        #Récupération des informations de la table joueurs donc le jeu correspond à celui rentrer précédement
        $query = "SELECT pseudo, mdp, nom FROM joueurs JOIN jeux on idJeux = jeux.id WHERE idJeux = $jeuChoisi"
        $result = Execute-MySQLQuery $conn $query
        #Création des comptes pour chaque joueurs d'un même jeu
        #Compteur du nombre de compte créé
        $nbCompteCree = 0
        foreach($joueur in $result)
        {
            $login = $joueur.pseudo
            $mdp = $joueur.mdp
            $nom = $login
            $nomJeu = $joueur.nom
            if ($login -notlike "")
            {
                New-LocalUser $login -Password (ConvertTo-SecureString $mdp -AsPlainText -Force) -FullName $nom -Description "Joueur $nomJeu"
                Write-Host "Création d'un compte local pour le joueur " $nom
                Write-Host "Ecriture de l'action de création d'un compte dans les logs`n"
                $nbCompteCree++
                #INSERT d'un log dans la base de donnée
                $date = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
                $nomPC = $env:COMPUTERNAME
                $ecran = Get-WmiObject win32_desktopMonitor | Select-Object name 
                $cpu = Get-WmiObject win32_processor | Select-Object name
                $cg = Get-WmiObject win32_videoController | Select-Object name
                $data = "Création compte " + $nom + " sur la machine " + $nomPC + " pour le jeu " + $nomJeu + "avec le matériel correspondant :`n-écran : " + $ecran + 
                ",`n-Processeur : " + $cpu + ",`n-Carte graphique : " + $cg + ", -Matériel Réseau : "
                $carteReseau = Get-WmiObject win32_networkadapter | Select-Object name
                foreach($carte in $carteReseau)
                {
                    if($carte -notlike "@{Name=Alias}")
                    {
                        $data = $data + "`n-" + $carte
                    }
                }
                $data = $data + "`n`nLes périphérique de la machine : "
                $lesPeriph = Get-PSDrive | Select-Object name
                foreach($periph in $lesPeriph)
                {
                    if($periph -notlike "@{Name=Alias}")
                    {
                        $data = $data + "-" + $periph + ", "
                    }
                }
                $query = "INSERT INTO logs(action, date, data) VALUES ('Création du compte','$date','$data');"
                $Rows = Execute-MySQLNonQuery $conn $query
            }
        }
        #Utilisation du compteur et affichage
        #Création d'aucun compte
        if($nbCompteCree -eq 0)
        {
            Write-Host "Aucun compte n'as été créé"
        }
        else
        {
            #Création d'un seul compte
            if($nbCompteCree -eq 1)
            {
                Write-Host $nbCompteCree "compte à été créé"
            }
            else
            #Création de plusieurs 
            {
                Write-Host $nbCompteCree "comptes ont été créés"
            }
        }
        $relance = Read-Host "`nVoulez-vous relancer le script (saisisser o si vous le voulez)"
        write-host ""
    }
    else
    {
        #Supression de compte
        If ($action -eq 2)
        {
            #Récupération des informations de la table jeux
            $query = "SELECT * FROM jeux;"
            $result = Execute-MySQLQuery  $conn $query
            Write-Host "Veuillez séléctionner le jeu pour lequel vous souhaiter créer des comptes"
            #Affichage des identifiants et nom des jeux enregistré dans la table jeux
            foreach($jeu in $result)
            {
                $idJeu = $jeu.id
                $nomJeu = $jeu.nom
                if ($idJeu -notlike "")
                {
                    Write-Host "-$idJeu : $nomJeu"
                }
            }
            $jeuChoisi = Read-Host "`nVotre choix"
            #Récupération des informations de la table joueurs donc le jeu correspond à celui rentrer précédement
            $query = "SELECT pseudo, mdp, nom FROM joueurs JOIN jeux on idJeux = jeux.id WHERE idJeux = $jeuChoisi"
            $result = Execute-MySQLQuery $conn $query
            #Suppression des comptes pour chaque joueurs d'un même jeu
            #Compteur du nombre de compte supprimer
            $nbJoueurSup = 0
            foreach($joueur in $result)
            {
                $nom = $joueur.pseudo
                $nomJeu = $joueur.nom
                if ($nom -notlike "")
                {
                    Remove-LocalUser -Name $nom
                    Write-Host "Suppression du compte du joueur $nom"
                    Write-Host "Ecriture de l'action de suppression dans les logs`n"
                    $nbJoueurSup++
                    #INSERT d'un log dans la base de donnée
                    $date = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
                    $nomPC = $env:COMPUTERNAME
                    $ecran = Get-WmiObject win32_desktopMonitor | Select-Object name 
                    $cpu = Get-WmiObject win32_processor | Select-Object name
                    $cg = Get-WmiObject win32_videoController | Select-Object name
                    $data = "Supression du compte " + $nom + " sur la machine " + $nomPC + " pour le jeu " + $nomJeu + "avec le matériel correspondant :`n-écran : " + $ecran + 
                    ",`n-Processeur : " + $cpu + ",`n-Carte graphique : " + $cg + ", -Matériel Réseau : "
                    $carteReseau = Get-WmiObject win32_networkadapter | Select-Object name
                    foreach($carte in $carteReseau)
                    {
                        if($carte -notlike "@{Name=Alias}")
                        {
                            $data = $data + "`n-" + $carte
                        }
                    }
                    $data = $data + "`n`nLes périphérique de la machine : "
                    $lesPeriph = Get-PSDrive | Select-Object name
                    foreach($periph in $lesPeriph)
                    {
                        if($periph -notlike "@{Name=Alias}")
                        {
                            $data = $data + "-" + $periph + ", "
                        }
                    }
                    $insert = "INSERT INTO logs(action,date,data) VALUES ('Suppression de compte','$date','$data');"
                    $Rows = Execute-MySQLNonQuery $conn $insert
                }
            }
            #Utilisation du compteur et affichage
            #Création d'aucun compte
            if($nbJoueurSup -eq 0)
            {
                Write-Host "Aucun compte de Joueurs n'as été supprimer"
            }
            else
            {
                if($nbJoueurSup -eq 1)
                #Création d'un seul compte
                {
                    Write-Host $nbjoueurSup  " compte à été supprimer"
                }
                else
                #Création de plusieur compte
                {
                    Write-Host $nbjoueurSup  " comptes ont été supprimer"
                }
            }
            $relance = "n"
        }
        $relance = Read-Host "`nVoulez-vous relancer le script (saisisser o si vous le voulez)"
        write-host ""
    }
} until ($relance -notlike "o")