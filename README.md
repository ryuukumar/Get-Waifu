# Get-Waifu
PowerShell code to pull all sorts of media off websites, reliably, and in the best possible quality.

## Disclaimer
This is a script in its VERY early stages. I *cannot* guarantee this working on ANY other setup than mine. If you really, *really* want this to work on your PC, ping me incase setup goes wrong.

## Setting this up

### Prerequirements
This has only been tested on Windows 11, but should work on Windows 10 too.

Make sure you have Windows Terminal (not command prompt) installed. This will take care of the PowerShell requirements. This has been tested with PS5, so you may have limited success with other versions. Type ```$PSVersionTable``` in Windows Terminal or a PowerShell command prompt to find what version you're running.

You will also require an additional PowerShell module PowerHTML. If you run `telegram.ps1`, it will try to install it for you, but in case it goes wrong, try running it with admin privileges or finding and installing the package yourself:

```powershell
Install-Module PowerHTML -ErrorAction Stop
```

### Setting up preferences
Extract the GitHub download to the folder of your choice, and run `telegram.ps1`. It will spew an error message saying it cannot find `prefs.json`, and then make one for you in the same folder you placed the scripts. Go ahead and open up that file, and fill in whatever you need. Here's a guide on what to fill in where:

- `lastchecked`, `token`, `authuname`, `chat_id` are all used by `telegram.ps1`. Leave these alone for now, as telegram bot functionality is not supported yet.
- `utchours` is a value describing your UTC timezone. For instance, my timezone is UTC+5:30, so I would fill in this variable as 5.5. This is used for saving log messages.
- `logpath` is the path where your logs will be saved. In double quotes, type in the FULL path to where you want the log file to be, as well as the name of the log file.
- `savedir` is where the media you download will be saved. In double quotes, type in the FULL path to where you want your files, **end it with a `/`**, and leave it at that.
  - For example, if I want my files to be saved in `C:/sauce`, then I would type this: `"C:/sauce/"`
- `makejpg` decides if .png files will be converted to .jpg after they are downloaded. Set it to true if you want this to happen.
- `twtaccess` is the bearer token of your (optional) Twitter API access details. For now, you will not be able to download Twitter media if you personally do not have access to the API. I will work on changing this in the coming months.

### Running the damn thing
Now, make a file called `list.txt` in the same folder as the script. Here, paste links that you want downloaded, with one link per line.

Here's a list of domains I support:

| Domain | Support |
| --- | --- |
| Reddit | Works for most relevant use cases |
| Pixiv | Illustrations and manga only |
| Twitter | Works if you have access to the API |
| Imgur | Only as a link in a Reddit post |
| YouTube | No |
| Instagram | No |
| Others | No |

Once you've placed your links inside `list.txt`, go ahead and run `get.ps1`. It is advisable to run it in Windows Terminal so you can monitor any issues that pop up. To do this, open Windows Terminal in the working folder, and run:

```powershell
./get.ps1
```

This will start up the script and it will now try to download the files from the list.

## Running modules individually
This script is designed in such a way that each domain has a separate module that deals with downloads from that particular site. It is also possible to run these modules standalone, and as long as the generated `prefs.json` is located in the same folder, it will save it to the same directory.

Here is a guide on how to run each module:

- **Pixiv:** Take your link and extract the tailing 8-9 digits. For instance, for `https://www.pixiv.net/en/artworks/102295136`, you would get the numbers `102295136`. Now, you can run the module as so:
```powershell
./pixivget.ps1 number-here
```
- **Reddit:** For this, simply pass the link to the post within quotes as an argument.
```powershell
./redditget.ps1 "link-here"
```
- **Twitter:** This works exactly like pixiv. Here, it will be a number with more than 15 digits. It's going to be located right after `status/` in the link. Make sure you select ONLY the number.
```powershell
./twtget.ps1 number-here
```

The modules can only scan one link per execute, so if you have multiple links, you're better off using `get.ps1`.

## What's the buzz with `telegram.ps1`?
This script can link up with a Telegram bot which saves links you send it to links.txt. Now, this is a functionality that will not work unless you  conveniently happen to have access to a Telegram bot.

I don't know if I will ever roll this out to GitHub for people to use. It's something I will consider only if this project gains some significant traction, which it won't.

Since this script is primarily for my personal use, I will continue adding functionality to this Telegram bot. You can always ping me and I can help you set up your own bot so you can use this script to its full potential.
