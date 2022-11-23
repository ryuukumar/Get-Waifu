

### -----------------------------------------
### Includes
### -----------------------------------------

. "$PSScriptRoot\fxns.ps1"



### -----------------------------------------
### Preferences
### -----------------------------------------

${savedir}="./"
${twtaccess}="none"

if (test-path ".\prefs.json") {
	$prefs = get-content .\prefs.json | convertfrom-json
	$savedir = $prefs.savedir
	$twtaccess = $prefs.twtaccess
}

if ($twtaccess -eq "none") {
	write-host "No access to twitter API!!"
	if (-not($prefs)) {
		pause
	}
	exit
}



### -----------------------------------------
### Functions
### -----------------------------------------

function Display-Size([string]$file) {
	[int]$img_size=((get-item "$file").length)
	if ($img_size -lt 1024) {
		write-host " [Size: ${img_size} bytes]"
	}
	else {
		if ($img_size / 1024 -lt 1024) {
			[int]${kbimg}=${img_size}/1024
			[string]${bytes}=[string]::Format('{0:N0}',${img_size})
			write-host " [Size: ${kbimg} KB (${bytes} bytes)]"
		}
		else {
			[string]${bytes}=[string]::Format('{0:N0}',${img_size})
			[string]${mbytes}=[string]::Format('{0:N}',${img_size}/(1024*1024))
			write-host " [Size: ${mbytes} MB (${bytes} bytes)]"
		}
	}
}

function Img-Id([string]$link) {
	if ($link.contains("redd.it")) {
		[string]${ret}=((select-string -allmatches -pattern "[A-Za-z0-9_-]{13}\.[a-z]{2,4}" -inputobject ${link}).matches.value | out-string)
		$ret = $ret.substring(0, $ret.length - 2)
		return $ret
	}
	else {
		if ($link.contains("imgur.com")) {
			[string]${ret}=((select-string -allmatches -pattern "[A-Za-z0-9_-]{7}\.[a-z]{2,4}" -inputobject ${link}).matches.value | out-string)
			$ret = $ret.substring(0, $ret.length - 2)
			return $ret
		}
	}

	return ""
}

function Vid-Id([string]$link) {
	[string]${ret}=((select-string -allmatches -pattern "/[A-Za-z0-9_-]{13}/" -inputobject ${link}).matches.value | out-string)
	$ret = $ret.substring(1, $ret.length - 4)
	return $ret
}

function Remove-TailLink([string]$tweet) {
	$substrs = $tweet -split ' '

	if($substrs.length -eq 1) {
		return "untitled"
	}

	$ret = $substrs[0]
	for ([int]$i=1; $i -lt ($substrs.length - 1); $i++) {
		$ret += " " + $substrs[$i]
	}
	return $ret
}



### -----------------------------------------
### I. Get sauce
### -----------------------------------------

[string]$id = ""

if (!$args[0]) {
	write-host "Please give me the sauce too!!"
	write-host "Run this command <<IN TERMINAL>> (not command prompt) as:`n`n`t./twtget.ps1 <sauce>`n"
	write-host "The sauce is the link to your post which you want saved."
	write-host "Which means you type:`n`n`t./redditget.ps1 `"https://www.reddit.com/r/HuTao_Mains/comments/xyflar/...`"`n`n"
	pause
	exit
}
else {
	$id = (Select-String -Pattern "[0-9]{18,}" -InputObject $args[0]).Matches.Value | Out-String
	$id = $id.substring(0, $id.length - 2)
}

if (-not($id)) {
	write-host "Received faux link."
	exit
}



### -----------------------------------------
### II. Ask API to give us the payload
### -----------------------------------------

$request = (invoke-webrequest "https://api.twitter.com/2/tweets?ids=${id}&expansions=attachments.media_keys&media.fields=media_key,type,url,variants&tweet.fields=author_id" -headers @{"Authorization"="Bearer ${twtaccess}"}).content | convertfrom-json

$request.includes.media.variants[$request.includes.media.variants.length - 1] | ConvertTo-Json
$author_id = $request.data.author_id
$title = Remove-TailLink (Remove-IllegalChars ($request.data.text))

if($title.length -gt 20) {
	# U+2026 -> ellipsis (three dots)
	$title = $title.substring(0, 20) + [char]0x2026
}
#$title

$authordeets = (Invoke-WebRequest "https://api.twitter.com/2/users?ids=${author_id}" -headers @{"Authorization"="Bearer ${twtaccess}"}).content | ConvertFrom-Json
$author = Remove-IllegalChars ($authordeets.data.userName)

[int]$imgcount = $request.includes.media.length
[int]$i = 1

foreach ($content in $request.includes.media) {
	[string]$filetype = ""
	[string]$url = ""

	if ($content.type.contains("video")) {
		$filetype = ($content.variants[$content.variants.length - 1].content_type -split '/')[1]
		$url = $content.variants[$content.variants.length - 1].url
	}
	else {
		$filetype = Give-FileType($content.url)
		$url = $content.url.substring(0, ($content.url.length - ($filetype.length + 1))) + "?format=${filetype}&name=orig"
	}
	
	$filename = $title + " by " + $author + " on Twitter"

	if ($imgcount -gt 1) {
		$filename += " (image " + $i + ")"
	}

	if (Test-Path ("${savedir}$($filename + "." + $filetype)")) {
		$newfilename = ""
		$iter = 2
		do {
			$newfilename = $title + " by " + $author + " on Twitter"
			if ($imgcount -gt 1) {
				$newfilename += " (image " + $i + ")"
			}
			$newfilename += " (" + $iter + ")"
			$iter++
		} while (
			test-path("${savedir}$($newfilename + "." + $filetype)")
		)
		$filename = $newfilename
	}

	$filename += "." + $filetype
	
	invoke-webrequest -outfile "${savedir}${filename}" $url
	Write-Output "${savedir}${filename}" | out-file "./files.txt" -append -Encoding utf8

	$i++
}

write-host "Downloaded images."



### -----------------------------------------
### END
### -----------------------------------------