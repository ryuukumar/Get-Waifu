
## Preferences

[bool]${makejpg} = $true
${savedir} = "./"
[psobject]$prefs = @()

# Save your list of links in list.txt

function save-log([string]$message) {
	$logpath = $prefs.logpath
	if (-not(test-path "$logpath")) {
		new-item "$logpath"
	}

	[string]$date = (get-date)
	$date = "[" + $date + "]: "
	$message = "[get.ps1] " + $date + $message
	add-content -path "$logpath" -value "$message"
}

${globalstart} = $(get-date)

write-host -nonewline "GET.PS1`n`n---------------`n`n"

if (test-path ".\prefs.json") {
	write-host -nonewline "Loading preferences... "
	$prefs = get-content .\prefs.json | convertfrom-json
	$savedir = $prefs.savedir
	$makejpg = $prefs.makejpg
	write-host "done"
}

write-host -nonewline "Loading list.txt..."

$file = get-content .\list.txt

if($file.length -eq 0) {
	write-host "error - list.txt not found or empty`nPlease ensure list.txt is in the same directory as this script."
	if ($prefs) {
		save-log ("found no new messages.")
	}
	exit
}

write-host "done"

write-host -nonewline "Looking for valid links... "

$links = @()

foreach ($line in $file) {
	if ($line.contains("pixiv.net") -or $line.contains("reddit.com") -or $line.contains("twitter.com")) {
		$links += $line
	}
}

[int]$linksnum = $links.length
write-host "found ${linksnum} links."

if ($linksnum -eq 0) {
	write-host "Error: no valid links found in list.txt."
	if($prefs) {
		save-log ("found new message(s) but no new links.")
	}
	else {
		pause
	}
	exit
}

echo "Starting downloads."
echo "`n`n-------------------------------`n`n"

if ($prefs) { save-log ("found ${linksnum} new links to download.") }

[int]$i = 1
foreach ($line in $links) {
	$starttime = $(get-date)
	echo "[Request ${i} of ${linksnum}]"
	if ($line.contains("pixiv.net")) {
		[string]$url=(Select-String -Pattern "https://www.pixiv.net/en/\w{3,}/\d{8,10}" -inputobject "$line").Matches.Value | Out-String
		$url = $url.substring(0, $url.length - 2)
		[string]$sauce=(Select-String -Pattern "\d{8,10}" -inputobject ${url}).Matches.Value | Out-String
		$sauce = $sauce.substring(0, $sauce.length - 2)
		.\pixivget.ps1 "$sauce" bot
		$elapsedtime = $(get-date) - $starttime
		[int]$seconds = $elapsedtime.totalseconds
		echo "`n`nCompleted request in ${seconds} sec."
		echo "`n`n-------------------------------`n`n"
		if ($prefs) { save-log ("completed link ${i} of ${linksnum}") }
		$i++
		continue
	}
	if ($line.contains("reddit.com")) {
		[string]$url=(Select-String -Pattern "https://www.reddit.com/[ru]/[A-Za-z0-9_-]{1,}/[A-Za-z0-9_-]{1,}/[A-Za-z0-9_-]{1,}/" -inputobject "$line").Matches.Value | Out-String
		$url = $url.substring(0, $url.length - 2)
		.\redditget.ps1 "${url}"
		$elapsedtime = $(get-date) - $starttime
		[int]$seconds = $elapsedtime.totalseconds
		echo "`n`nCompleted request in ${seconds} sec."
		echo "`n`n-------------------------------`n`n"
		if ($prefs) { save-log ("completed link ${i} of ${linksnum}") }
		$i++
		continue
	}
	if ($line.contains("twitter.com")) {
		[string]$url=(Select-String -Pattern "twitter.com/[A-Za-z0-9_-]{1,}/[A-Za-z0-9_-]{1,}/[0-9]{18,}" -inputobject "$line").Matches.Value | Out-String
		$url = $url.substring(0, $url.length - 2)
		.\twtget.ps1 "${url}"
		$elapsedtime = $(get-date) - $starttime
		[int]$seconds = $elapsedtime.totalseconds
		echo "`n`nCompleted request in ${seconds} sec."
		echo "`n`n-------------------------------`n`n"
		if ($prefs) { save-log ("completed link ${i} of ${linksnum}") }
		$i++
		continue
	}
	if ($prefs) { save-log ("failed link ${i} of ${linksnum}") }
	$i++
}

if (${makejpg}) {
	$starttime = $(get-date)
	echo "Beginning PNG -> JPG conversion... "
	echo "(You can disable this behaviour by changing the preferences in get.ps1)"

	foreach ($file in (ls "${savedir}*.png")) {
		$filename = $file.name.substring(0, $file.name.length - 4)
		write-host -nonewline "Converting ${filename}.png... "
		magick convert "${savedir}${filename}.png" -quality 100 "${savedir}${filename}.jpg"
		remove-item "${savedir}${filename}.png"
		write-host "done."
	}

	$elapsedtime = $(get-date) - $starttime
	[int]$seconds = $elapsedtime.totalseconds
	echo "`n`nCompleted conversion in ${seconds} sec."
	echo "`n`n-------------------------------`n`n"
	if ($prefs) { save-log ("finished PNG -> JPG conversion") }
}

$globalelapsedtime = $(get-date) - $globalstart
[int]$globalseconds = $globalelapsedtime.totalseconds
write-host "Completed! (in ${globalseconds} seconds)"