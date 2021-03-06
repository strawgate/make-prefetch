Make Prefetch
===

This is a tool to generate [prefetch](https://developer.bigfix.com/action-script/reference/download/prefetch.html) statements for downloads in BigFix ActionScript.

## Parameters

Generate a prefetch for a local file:

Get-Prefetch.ps1
   -Path <String>
   -Name <String>

Generate a prefetch for a file from a web server (http://)

Get-Prefetch.ps1
   -URL <String>
   -Name <String>


## Using a URL argument

Suppose you want to create a prefetch statement to download [this picture of Hodor](http://i.imgur.com/YAUeUOG.jpg).

To download it as `hodor.jpg`, you can use the `-name` argument:

    & .\get-prefetch -name hodor.jpg -url http://i.imgur.com/YAUeUOG.jpg

This will output the prefetch statement as `hodor.jpg` on the client.

    prefetch hodor.jpg sha1:ce842e0af799f2ba476511c8fbfdc3bf89612dd0 size:57656 http://i.imgur.com/YAUeUOG.jpg sha256:74f69205a016a3896290eae03627e15e8dfeba812a631b5e0afca140722a322b

## Using a file argument

Suppose you have already downloaded 
[this picture of Hodor](http://i.imgur.com/YAUeUOG.jpg) and you want to create a
prefetch statement for it.

To do this, run `& .\get-prefetch` on the file to generate a prefetch statement:

    & .\get-prefetch -Path hodor.jpg -name hodor.jpg

This will output a prefetch statement with `http://REPLACEME` as the URL:

    prefetch hodor.jpg sha1:ce842e0af799f2ba476511c8fbfdc3bf89612dd0 size:57656 http://REPLACEME sha256:74f69205a016a3896290eae03627e15e8dfeba812a631b5e0afca140722a322b
