## Docker

### How to Install Docker on Raspberry Pi OS

```
sudo mkdir -m 0755 -p /etc/apt/keyrings/
sudo wget -O- https://download.docker.com/linux/debian/gpg | gpg --dearmor | sudo tee docker.gpg > /dev/null
sudo chmod 644 docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") InRelease stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

See also [How do I fix the GPG error "NO_PUBKEY"?](https://askubuntu.com/questions/13065/how-do-i-fix-the-gpg-error-no-pubkey).

### How to bind a device file to a container

`docker run --device <path_to_device_file> ... <image>`