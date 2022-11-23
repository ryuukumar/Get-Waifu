# RUN THIS WITH RPIXGET.PS1 (if you want multiple webpages)

# syntax: ./pixivget.ps1 <sauce>
# The sauce is just the 8 or 9-digit code at the end of the pixiv link.
# i.e.: https://www.pixiv.net/en/artworks/100457246 -> sauce is 100457246


### -----------------------------------------
### Includes
### -----------------------------------------

. "$PSScriptRoot\fxns.ps1"



### -----------------------------------------
### Preferences
### -----------------------------------------

${savedir} = "./"

if (test-path ".\prefs.json") {
	$prefs = get-content .\prefs.json | convertfrom-json
	$savedir = $prefs.savedir
}



### -----------------------------------------
### Functions
### -----------------------------------------

function Display-Size([string]$file) {
	[int]$img_size=((get-item "$file").length)
	if ($img_size -lt 1024) {
		Write-Host " [Size: ${img_size} bytes]"
	}
	else {
		if ($img_size / 1024 -lt 1024) {
			[int]${kbimg}=${img_size}/1024
			[string]${bytes}=[string]::Format('{0:N0}',${img_size})
			Write-Host " [Size: ${kbimg} KB (${bytes} bytes)]"
		}
		else {
			[string]${bytes}=[string]::Format('{0:N0}',${img_size})
			[string]${mbytes}=[string]::Format('{0:N}',${img_size}/(1024*1024))
			Write-Host " [Size: ${mbytes} MB (${bytes} bytes)]"
		}
	}
}



### -----------------------------------------
### I. Get sauce
### -----------------------------------------

if (!$args[1]) {
	Clear-Host
}

[string]$url = ""

if (!$args[0]) {
	Write-Output "Please give me the sauce too!!"
	Write-Output "Run this command <<IN TERMINAL>> (not command prompt) as:`n`n`t./pixivget.ps1 <sauce>`n"
	Write-Output "The sauce is just the 8 or 9-digit code at the end of the pixiv link.`ni.e.: https://www.pixiv.net/en/artworks/100457246 -> sauce is 100457246"
	Write-Output "Which means you type:`n`n`t./pixivget.ps1 100457246`n`n"
	pause
	exit
}
else {
	$url = $args[0]
	Write-Output "Downloading from www.pixiv.net/en/artworks/$url"
}



### -----------------------------------------
### II. Download HTML
### -----------------------------------------

if (Test-Path $url) {
	Write-Output "Found leftover HTML; perhaps you ran into an error? [premonition intensifies]"
	Remove-Item $url
}

write-host -nonewline "Downloading metadata... "
$html = (Invoke-WebRequest "www.pixiv.net/en/artworks/${url}").content
write-host "done"

# Remove newlines for parsehtml to work
$mergedhtml = $($html -join ", ")
$metatags = ($mergedhtml | convertfrom-html).selectnodes("//html/head/meta")



### -----------------------------------------
### III. Search for images
### -----------------------------------------

[string]$img_url = ""
[int]$pagecount = 0

# Usually meta tag no. 26 but I'm doing this in case pixiv decides to update their HTML (read: fuck me over)
foreach ($metag in $metatags) {
	if ($metag.attributes.value -eq "preload-data") {
		$img_url = ($metag.attributes[2].value | convertfrom-json).illust.$url.urls.original
		$pagecount = ($metag.attributes[2].value | convertfrom-json).illust.$url.pagecount
	}
}

[int]$img_name_length = $url.length + 7
[string]$img_name=$img_url.substring($img_url.length - $img_name_length, $img_name_length)



### -----------------------------------------
### IV. Download images
### -----------------------------------------

for ($i=0; $i -lt $pagecount; $i++) {
	$filetype = $img_name.substring($img_name.length - 4, 4)
	$illusttitle = (($metag.attributes[2].value | convertfrom-json).illust.$url.illustTitle)
	$artistname = (($metag.attributes[2].value | convertfrom-json).illust.$url.userName)
	if ($pagecount -gt 1) {
		$filename = $illusttitle + " by " + $artistname + " on Pixiv (image " + [int]($i + 1) + ")" + $filetype
	}
	else {
		$filename = $illusttitle + " by " + $artistname + " on Pixiv" + $filetype
	}
	
	$filename = remove-illegalchars ($filename)

	if(Test-Path("${savedir}${filename}")) {
		$newfilename = ""
		$iter = 2
		do {
			if ($pagecount -gt 1) {
				$newfilename = $illusttitle + " by " + $artistname + " on Pixiv (image " + [int]($i + 1) + ") (" + $iter + ")" + $filetype
			}
			else {
				$newfilename = $illusttitle + " by " + $artistname + " on Pixiv (" + $iter + ")" + $filetype
			}
			$newfilename = Remove-IllegalChars($newfilename)
			$iter++
		} while (
			Test-Path("${savedir}${newfilename}")
		)
		$filename = $newfilename
	}

	$round_img_name = $url + "_p" + $i + $filetype
	$round_img_url = $img_url.substring(0, $img_url.length - 5) + $i + $img_name.substring($img_name.length - 4, 4)
	
	write-host -nonewline "Downloading ${filename}... "
	try {
		Invoke-WebRequest -Headers @{'Referer' = 'https://www.pixiv.net'} -OutFile "${savedir}${filename}" ${round_img_url}
		Write-Output "${savedir}${filename}" | out-file "./files.txt" -append -Encoding utf8
	}
	catch {
		if ($_.Exception.Response.StatusCode.Value__ -eq 404) {
			write-host "failed - ${round_img_name} does not exist."
			Break
		}
	}
	write-host -nonewline "done"
	display-size("${savedir}${filename}")
}
Write-Output "${i} images found, collected and downloaded."
$img_name = ${savedir} + ${img_name}



### -----------------------------------------
### V. Clean up
### -----------------------------------------

if (!$args[1]) {
	Write-Output "`n`n"
}



### -----------------------------------------
### END
### -----------------------------------------