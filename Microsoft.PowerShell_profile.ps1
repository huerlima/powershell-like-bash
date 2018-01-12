# Author: Oscar Koller
# Date: January 2018
# 
# To get best bash-kind experience in MS PowerShell (at least version 3), do the following:
#    * Use https://conemu.github.io/ as console and set it up to use powershell
#    * Save this script as $env:UserProfile\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#    * Install Scoop: 
#       PS> iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
#    * Install 
#       PS> scoop install wget vim touch sed rsync python perl pdftk ln less jq iconv imagemagick gawk findutils file ffmpeg curl coreutils
#    * Install PowerShell Community Extensions
#       PS> Install-Module Pscx



# history file name
$HistoryFile = Join-Path (Split-Path $Profile -Parent) history.csv

# save global history on exit
Register-EngineEvent PowerShell.Exiting -SupportEvent -Action {
    Get-History -Count $MaximumHistoryCount | Export-Csv $HistoryFile
}

# load global history
if (Test-Path $HistoryFile) {
    Import-Csv $HistoryFile | Add-History
}

# bash-style tab
Set-PSReadlineKeyHandler -Key Tab -Function Complete

# ctrl+d = exit
Set-PSReadlineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

# ltr: show dir content ordered by time
Function ltr {
    #[CmdletBinding()]
    #  Param($arg)    ?
    Get-ChildItem $args | Sort-Object -Property LastWriteTime
};

# convenient shortcut to ls -a
Set-Alias l dir

# bash style which
New-Alias which get-command

# ls should only display names
Function ls {
    (Get-ChildItem).name
};
 
# show or search global history
Function ghglobal {
    if ($args.Count -eq 0) {
        Get-History
    } else {
        Get-History | Select-String $args
    }
};

# call gh or gh <word> to show history in current path or search it
Function gh {
    if ($args.Count -eq 0) {
        cat .history.$env:UserName
    } else {
        cat .history.$env:UserName | Select-String -Pattern $args | ? {$_.Line.trim() -ne "" } 
    }
};

# call meld to compare files
Function meld {
    Start-Process -FilePath "C:\Program Files (x86)\Meld\Meld.exe" -ArgumentList $args
};

# start bash.exe in a new window, in the current path
Function bash {
    #$currentBashPath = $((Get-Location).Path |sed -e 's,\\,/,g' -e 's,^\([a-zA-Z]\):,/mnt/\L\1,g')
    ConEmu64.exe -run bash.exe
};

# start windows explorer in current path
Function e {
    start .
};

# Set-Alias grep Select-String

Function head {
    echo "reminder: select -first 10"
}

# delete standard aliases to enable more powerful functions with the same name
del alias:ls
del alias:mv
del alias:cd
Set-Alias mv mv.exe

# global stack to store prompt path
[System.Collections.Stack]$GLOBAL:dirStack = @()
$GLOBAL:oldDir = ''
$GLOBAL:prevOldDir = ''
$GLOBAL:addToStack = $true

# alter the prompt
function prompt
{
    #alter prompt appearance
    Write-Host ($(get-date -format "yymmdd HH:mm ") ) -NoNewline -foregroundcolor White
    Write-Host ($env:UserName + "@" + $env:ComputerName) -NoNewline -ForegroundColor Yellow
    Write-Host (" " + $(pwd)) -foregroundcolor White -nonewline
    
    #add folder tracking to be able to go back to last path with "cd -"
    $GLOBAL:nowPath = (Get-Location).Path
    if(($nowPath -ne $oldDir) -AND $GLOBAL:addToStack){
        $GLOBAL:dirStack.Push($oldDir)
        $prevOldDir = $oldDir
        $GLOBAL:oldDir = $nowPath
    }
    $GLOBAL:AddToStack = $true
    
    #add saving commands into .history.username in path where command was executed
    if ($prevOldDir -ne '') {
         $histpath=$prevOldDir
    } else {
         $histpath = (Get-Location).Path
    }
    Get-History | select -last 1  | Add-Content $histpath\.history.$env:UserName
    
    return "`n"
}

# allow to go to previous dir
function BackOneDir{
    $lastDir = $GLOBAL:dirStack.Pop()
    cd $lastDir
}

# implement bash-style "cd" (allow to go back to last path with "cd -" and go to user profile with "cd")
Function cd {
    if ($args.Count -eq 0) {
        Set-location $env:UserProfile
    } elseIf ( $args[0] -eq "-" ) {
        BackOneDir
    } else {
        Set-location $args[0]
    }
}

#Clear-Host