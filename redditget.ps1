

### -----------------------------------------
### Includes
### -----------------------------------------

. "$PSScriptRoot\fxns.ps1"



### -----------------------------------------
### Preferences
### -----------------------------------------

${savedir}="./"

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
		Write-Output " [Size: ${img_size} bytes]"
	}
	else {
		if ($img_size / 1024 -lt 1024) {
			[int]${kbimg}=${img_size}/1024
			[string]${bytes}=[string]::Format('{0:N0}',${img_size})
			Write-Output " [Size: ${kbimg} KB (${bytes} bytes)]"
		}
		else {
			[string]${bytes}=[string]::Format('{0:N0}',${img_size})
			[string]${mbytes}=[string]::Format('{0:N}',${img_size}/(1024*1024))
			Write-Output " [Size: ${mbytes} MB (${bytes} bytes)]"
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

function Give-FileType([string]$filename) {
	$substrs = $filename -split '\.'
	return $substrs[$substrs.length - 1]
}



### -----------------------------------------
### I. Get sauce
### -----------------------------------------

[string]$url = ""

if (!$args[0]) {
	write-host "Please give me the sauce too!!"
	write-host "Run this command <<IN TERMINAL>> (not command prompt) as:`n`n`t./redditget.ps1 <sauce>`n"
	write-host "The sauce is the link to your post which you want saved."
	write-host "Which means you type:`n`n`t./redditget.ps1 `"https://www.reddit.com/r/HuTao_Mains/comments/xyflar/...`"`n`n"
	pause
	exit
}
else {
	$url = (Select-String -Pattern "https://www.reddit.com/[ru]/[A-Za-z0-9_-]{1,}/[A-Za-z0-9_-]{1,}/[A-Za-z0-9_-]{1,}/" -InputObject $args[0]).Matches.Value | Out-String
}

write-host "Downloading from ${url}"



### -----------------------------------------
### II. Download JSON
### -----------------------------------------

if (Test-Path "meta.json") {
	write-host "Found leftover JSON; perhaps you ran into an error? [premonition intensifies]"
	Remove-Item "meta.json"
}

${url} = $url.substring(0, $url.length - 1) + ".json"

write-host -nonewline "Downloading metadata... "
invoke-webrequest -outfile meta.json ${url}
write-host -nonewline "done"
display-size ("meta.json")



### -----------------------------------------
### III. Download content
### -----------------------------------------

$metadata = get-content -raw meta.json | convertfrom-json


## Get title and author name

$posttitle = Remove-IllegalChars ($metadata.data.children[0].data.title)
$postauthor = Remove-IllegalChars ($metadata.data.children[0].data.author)

if($posttitle.length -gt 20) {
	# U+2026 -> ellipsis (three dots)
	$posttitle = $posttitle.substring(0, 20) + [char]0x2026
}


## Check for gallery

if ($metadata.data.children.data.is_gallery -eq $true)
{
	write-host "Gallery detected."
	$list = @()
	$i = 1
	$metadata.data.children.data.gallery_data.items | foreach-object {
		$list += $_.media_id
	}
	$list | foreach-object {
		$type = ($metadata.data.children.data.media_metadata.$_.m).substring(6,3)
		$img_url = $metadata.data.children.data.media_metadata.$_.s.u
		#${img_url} = $posttitle + " by " + $postauthor + " on Reddit (image " + $i + ")." + $type
		$img_url
		${filename} = $_ + "." + $type
		$filename
		write-host -nonewline "Downloading image... "
		invoke-webrequest -headers @{'Referer' = 'https://www.reddit.com'} -outfile "${savedir}${filename}" "${img_url}"
		write-host -nonewline "done"
		display-size("${savedir}${filename}")
		Write-Output "${savedir}${filename}" | out-file "./files.txt" -append -Encoding utf8
		$i++
	}
	return
}


## Check for video/GIF

if ($metadata.data.children.data.is_video -eq $true) {
	if ($metadata.data.children.data.secure_media.reddit_video.is_gif -eq $true) {
		write-host "GIF detected."
		${vid_url} = $metadata.data.children.data.secure_media.reddit_video.fallback_url
		${filename} = $posttitle + " by " + $postauthor + " on Reddit"

		ffmpeg -i "${vid_url}" -hide_banner -y "${savedir}${filename}.gif"
		write-host -nonewline "Downloaded GIF."
		display-size("${savedir}${filename}.gif")
		Write-Output "${savedir}${filename}.gif" | out-file "./files.txt" -append -Encoding utf8
		return
	}

	write-host "Video detected."
	${vid_url} = $metadata.data.children.data.secure_media.reddit_video.fallback_url
	${filename} = $posttitle + " by " + $postauthor + " on Reddit"

	ffmpeg -i "${vid_url}" -hide_banner -c:v libx264 -y "${savedir}${filename}.mkv"
	write-host -nonewline "Downloaded video."
	display-size("${savedir}${filename}.mkv")
	Write-Output "${savedir}${filename}.mkv" | out-file "./files.txt" -append -Encoding utf8
	return
}


## Previous checks failed, so it's gotta be an image

${img_url} = $metadata.data.children.data.url_overridden_by_dest
${filetype} = Give-FileType(Img-Id($img_url))
${filename} = $posttitle + " by " + $postauthor + " on Reddit"

write-host -nonewline "Downloading image... "
invoke-webrequest -headers @{'Referer' = 'https://www.reddit.com'} -outfile "${savedir}${filename}.${filetype}" "${img_url}"
write-host -nonewline "done"
display-size("${savedir}${filename}.${filetype}")
Write-Output "${savedir}${filename}.${filetype}" | out-file "./files.txt" -append -Encoding utf8



### -----------------------------------------
### IV. Clean up
### -----------------------------------------

remove-item "meta.json"



### -----------------------------------------
### END
### -----------------------------------------
