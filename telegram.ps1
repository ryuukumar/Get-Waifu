$prefs = new-object psobject

$cmdlist = "file"

function save-log([string]$message) {
	$logpath = $prefs.logpath
	if (-not(test-path "$logpath")) {
		new-item "$logpath"
	}

	[string]$date = (get-date)
	$date = "[" + $date + "]: "
	$message = "[telegram.ps1] " + $date + $message
	add-content -path "$logpath" -value "$message"
}

function send-msg([string]$message) {
	$replymsg = new-object psobject
	$replymsg | add-member -membertype noteproperty 'chat_id' -value "$($prefs.chat_id)"
	$replymsg | add-member -membertype noteproperty 'text' -value "${message}"
	$replymsg | add-member -membertype noteproperty 'parse_mode' -value "HTML"
	$response = Invoke-RestMethod -Method Post -Uri ($URL +'/sendMessage') -Body ([System.Text.Encoding]::UTF8.GetBytes($($replymsg | ConvertTo-Json))) -ContentType "application/json"
}

function Format-Filesize([int]$length) {
	if ($length -lt 1024) {
		return [string]::Format('{0:N0}',${length}) + " bytes"
	}
	else {
		if ($length / 1024 -lt 1024) {
			[string]${kbimg}=[string]::Format('{0:N0}',${length}/1024) + "KB"
			return ${kbimg}
		}
		else {
			[string]${mbytes}=[string]::Format('{0:N}',${length}/(1024*1024)) + "MB"
			return ${mbytes}
		}
	}
}

function Get-Filesize([string]$file) {
	return format-filesize((get-item "$file").length)
}

function Get-Filename([string]$path) {
	$pathcomponents = $path -split '/'
	return $pathcomponents[$pathcomponents.length - 1]
}

function Is-Cmd([string]$suspect) {
	$susargs = $suspect -split ' '
	if ($cmdlist.contains($susargs[0])) {
		return $true
	}
	return $false
}

function Parse-Cmd([string]$input) {
	$inargs = $input -split ' '
	switch ($inargs[0]) {
		"file" {
			if ($inargs.length -lt 3) {
				send-msg ("Incorrect command syntax: ")
			}
			$reqfile = $inargs[1]
			$reqprop = $inargs[2]
			send-msg ("Sending property " + $reqprop + " of file " + $reqfile)
		}
		Default {}
	}
}

cls
echo "TELEGRAM.PS1"

If (-not (Get-Module -ErrorAction Ignore -ListAvailable PowerHTML)) {
	write-host -nonewline "Installing required modules... "
	Install-Module PowerHTML -ErrorAction Stop
	write-host "done."
}
Import-Module -ErrorAction Stop PowerHTML

if (test-path ".\prefs.json") {
	$prefs = get-content .\prefs.json | convertfrom-json
}
else
{
	echo "Could not find prefs.json. Creating one with default parameters."
	$prefs | add-member -membertype noteproperty 'lastchecked' -value 0
	$prefs | add-member -membertype noteproperty 'token' -value "none"
	$prefs | add-member -membertype noteproperty 'chat_id' -value 0
	$prefs | add-member -membertype noteproperty 'utchours' -value 0
	$prefs | add-member -membertype noteproperty 'authuname' -value "none"
	$prefs | add-member -membertype noteproperty 'logpath' -value "none"
	$prefs | add-member -membertype noteproperty 'savedir' -value "none"
	$prefs | add-member -membertype noteproperty 'makejpg' -value $false
	$prefs | add-member -membertype noteproperty 'twtaccess' -value "none"
	$prefs | convertto-json | out-file prefs.json
	echo "prefs.json created. Please update the token for the program to work properly."
	pause
	exit
}

$url='https://api.telegram.org/bot{0}' -f $prefs.token
<#
if (-not(Test-Connection "telegram.org" -Quiet)) {
	save-log ("No internet connection (or Telegram servers are down.)")
	exit
}#>

$lastchecked_date = (get-date 01.01.1970).addseconds($prefs.lastchecked)
$lastchecked_date = $lastchecked_date.addhours($prefs.utchours)

save-log ("telegram.ps1 started successfully.")

echo "Last updated ${lastchecked_date}"

$links = @()
$inmessages=invoke-restmethod -method get -uri ($url +'/getUpdates') -erroraction stop

foreach ($msg in $inmessages.result.message) {
	if ($msg.date -gt $prefs.lastchecked) {
		if ($msg.chat.username -eq $prefs.authuname) {
			write-host -nonewline "Found authorized message: "
			echo $msg.text
			if (-not(Is-Cmd($msg.text))){
				$links += $msg.text
			}
			else {
				Parse-Cmd($msg.text)
			}
			
		}
		$prefs.lastchecked = $msg.date
	}
}

[int]$amt = $links.length
save-log ("${amt} new messages.")

if ($amt -eq 0) {
	echo "All caught up!"
	save-log ("quitting due to lack of jobs.")
	exit
}

send-msg ("Found ${amt} unread message(s)")

$links | out-file list.txt

write-host "Starting up get.ps1`n`n+===============+`n`n"

.\get.ps1

echo "`n`n+===============+`n`nAll caught up!"

save-log ("completed job.")

if (test-path ".\files.txt") {
	[string]$statmsg = "Saved "
	$savedfiles = @()
	$filestxt = get-content ".\files.txt"
	[int]$totalsize = 0

	foreach ($line in $filestxt) {
		$savedfiles += $line
	}

	$statmsg += $savedfiles.length

	$statmsg += " file(s)."

	foreach ($file in $savedfiles) {
		$statmsg += "`n"
		$filename = Get-Filename ($file)
		$statmsg += "- <code>" + $filename + "</code>: "
		if ($file.substring($file.length-4, 4) -eq ".png") {
			$file = $file.substring(0, $file.length-4) + ".jpg"
		}
		$statmsg += get-filesize($file)
		$totalsize += (get-item "$file").length
	}

	$statmsg += "`nStored "
	$statmsg += format-filesize($totalsize)
	$statmsg += " of content in <code>"
	$statmsg += $prefs.savedir.substring(0, $prefs.savedir.length - 1)
	$statmsg += "</code>"
	
	echo "$statmsg"

	send-msg($statmsg)

	clear-content ".\files.txt"
}

$prefs | convertto-json | out-file .\prefs.json