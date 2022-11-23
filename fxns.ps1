

### -----------------------------------------
### Functions
### -----------------------------------------

function Remove-IllegalChars([string]$str) {
	$illegalCharsArr = [System.IO.Path]::GetInvalidFileNameChars()
	$illegalChars = [RegEx]::Escape(-join $illegalCharsArr)
	$ret = [regex]::Replace($str, "[${illegalChars}]", '_')
	$ret = $ret -replace "\[","_" -replace "\]","_"

	return $ret
}

function Give-FileType([string]$filename) {
	$substrs = $filename -split '\.'
	return $substrs[$substrs.length - 1]
}



### -----------------------------------------
### END
### -----------------------------------------