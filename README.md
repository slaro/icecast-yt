# Icecast + youtube-dl Stream

## Install

```bash
git clone https://github.com/slaro/icecast-yt.git
cd icecast-yt
sudo ./setup.sh

sudo add_stream 'https://www.youtube.com/watch?v=5qap5aO4i9A' 'lofi/study'
sudo add_stream 'https://www.youtube.com/watch?v=DWcJFNfaw9c' 'lofi/chill'
```

## Resources

- [How to update Icecast metadata](https://icecast.org/docs/icecast-latest/admin-interface.html)
  - For some reason I found this information hard to find when I didn't know what exactly I was looking for, so replicating metadata URL below:
    - `http://user:pass@server.com:8000/admin/metadata?mount=/mystream&mode=updinfo&song=whatever`
- [Very similar use case, much inspiration taken](https://github.com/meyerlasse/twitch-audio-restreamer)
- [cURL: How to URL encode data parameters](https://stackoverflow.com/a/2027690)

  ```bash
  curl -G \
      --data-urlencode "p1=value 1" \
      --data-urlencode "p2=value 2" \
      http://example.com
  ```
