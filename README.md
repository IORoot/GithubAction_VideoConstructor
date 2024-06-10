# Github Actions to Search Youtube

Will return a JSON array of Youtube Video URLS.

## Actions

### yt-dlp_search_query

This uses the [yt-dlp](https://github.com/yt-dlp/yt-dlp) project to return 
results based on a youtube query url.

#### Parameters

```bash
upper_limit:
    description: 'Number of videos to find'     
    required: true
search_query:
    description: 'yt-dlp search query'  
    required: true
return_webhook:
    description: 'Make.com webhook url to send data back to'
    required: true
```



# Github Action for posting to YouTube Channel

## To change youtube channel to post on:

1. Download the client_secret.json
2. use the command line:
```bash
./youtubeuploader -secrets client_secret.json -filename video.mp4
```
3. This will open oAUTH and ask for user details
4. It will then ask you the youtube channel to post on.
5. A new `request.token` file will be generated.
6. Base64 encode for the github action.
```bash
base64 -i request.token -o request.token.b64
base64 -i client_secret.json -o client_secret.b64
```
7. Upload to Github under the Settings > Secrets > Actions as:
    - CLIENT_SECRETS_B64
    - REQUEST_TOKEN_B64