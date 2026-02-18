# SCUM Dedicated Server Docker Image
This Docker image provides a streamlined way to run a SCUM Dedicated Server on Linux using Wine and SteamCMD. It features automatic installation, easy updates, and persistent save management.

## 🚀 Quick Start
**BEFORE USING THIS IMAGE WITH AN EXISTING WORLD, CREATING A BACKUP IS HIGHLY RECOMMENDED!!!**<br>
To get your server running quickly, follow these steps:

1. **Prepare Host Folders:**
   Create the directories on your host machine to store game data, saves, and Steam metadata:
   ```bash
   sudo mkdir -p /srv/games/scum/{game,saves,steam_data}
   ```
2. **Set Permissions:**
   Due to security reasons, the container runs as a specific user (`scum`) with **UID 7010** and **GID 7010**. You must grant this user ownership of your host folders:
   ```bash
   sudo chown -R 7010:7010 /srv/games/scum
   ```
3. **Launch with Docker Compose:**
   Create a `docker-compose.yml` (see below) and run `docker-compose up -d`.

## ⚙️ Configuration

### Environment Variables
Adjust these variables in your deployment to customize the server behavior:

| Variable           | Description                                                     | Default |
|:-------------------|:----------------------------------------------------------------|:--------|
| `GAME_MAX_PLAYER`  | Maximum number of players allowed on the server (Max: 128).     | `64`    |
| `GAME_SERVER_PORT` | The query port for Steam's server browser.                      | `7779`  |
| `GAME_UPDATE`      | Set to `true` to check for and install game updates on startup. | `false` |
| `GAME_NO_BATTLEYE` | Disables BattlEye anti-cheat protection if set to `true`.       | `false` |

### Volume Mapping
To ensure your data is not lost when the container is re-created, map these volumes:
* **`/scum`**: The directory for game binaries.
* **`/scum_saved`**: Your world data, profiles, and configuration files.
* **`/home/scum/.local/share/Steam`**: SteamCMD metadata to avoid missing (initially installed) Steam data if container is deleted.

## 🏗️ Deployment Methods

### Docker Compose (Recommended)

```yaml
services:
  scum-server:
    image: melle2/scum-dedicated-server:latest
    container_name: scum-server
    restart: unless-stopped
    ports:
      - "7777-7779:7777-7779/udp"
      - "7777:7777/tcp"
      - "7779:7779/tcp"
    environment:
      - GAME_MAX_PLAYER=50
      - GAME_UPDATE=true
      - GAME_SERVER_PORT=7779
    volumes:
      - /srv/games/scum/game:/scum
      - /srv/games/scum/saves:/scum_saved
      - /srv/games/scum/steam_data:/home/scum/.local/share/Steam
```

### Docker CLI

```sh
docker run -d \
  --name scum-server \
  -p 7777-7779:7777-7779/udp \
  -p 7777:7777/tcp \
  -v /srv/games/scum/game:/scum \
  -v /srv/games/scum/saves:/scum_saved \
  melle2/scum-dedicated-server:latest
```

## 🔍 Technical Details

### Base image
The base image is using Ubuntu 24.04 LTS and Wine 11.0.

### Save Data Protection
The startup script includes logic to prevent accidental data loss:
* It checks for physical files in the game's internal save directory (`/scum/SCUM/Saved`).
* If found, it backs them up to `/scum/scum_saved.bak` before creating a symbolic link to your persistent `/scum_saved` mount.<br>
  **Important:** Check the container logs (`docker logs scum_ds`) to see if this backup occurred.
  **Warning:** This backup folder lives *inside* the container's temporary storage. You must copy it to your host machine before deleting the container, or those files will be lost forever!<br>
<br>
**BEFORE USING THIS IMAGE WITH AN EXISTING WORLD, CREATING A BACKUP IS HIGHLY RECOMMENDED!!!**

### Save Data Non-Protection
While the directory `/scum/SCUM/Saved` is backed up if it exists, `/scum_saved` isn't. If you don't mount a folder from your host, the save files will **only exist in the container's temporary volume!!** 

### DLL Signature Verification
SCUM performs a strict integrity check on startup to prevent cheating. In many Wine environments, this fails with the error DllIntegrityCompromised, which disables multiplayer.<br>
This image is specifically pre-configured with libraries like `crypt32` to pass this check. Changing the base image or removing included winetricks may cause this check to fail. **It took me days of testing to find the right setup.** Hence, better don't touch!<br>
Full error message:
```
LogTemp: Warning: Dll Verification result: -2146762496
LogSCUM: DLL signature verification failed, disabling multiplayer
LogSCUM: UConZGameInstance::AddMultiplayerDisabledReason: DllIntegrityCompromised
Message dialog closed, result: Ok, title: Message, text: Not all dll signatures are verified!
```

## 📖 Troubleshooting
* **Permissions**: If the server fails to start, double-check that the host folders are owned by UID 7010.
* **Initial Setup**: The first run will take a while time as it downloads the server files (~13GB) via SteamCMD.
* **Ports**: Ensure ports 7777-7779 (UDP/TCP) are open in your system firewall and forwarded on your router.
* **Logs**: View the server output by running `docker logs -f scum-server`
* **Container Hangs After Update**: Occasionally, if you update the docker-compose.yml file, the container may hang during the first startup attempt. If this happens, simply stop and start the container again without making further changes to the file. This usually clears any initialization locks.
* **DLL Signature Verification Failed**: If you see `LogSCUM: DLL signature verification failed, disabling multiplayer` in your logs:
  * This setup is verified to work on the current image version. If you are building your own version of this image, ensure you are including `crypt32` via winetricks and using a compatible Wine version (Wine 10.0+).

## 📦 GitHub
The source code is available at https://github.com/melle2/scum-ds.

## 📦 DockerHub
Docker Image is available at https://hub.docker.com/repository/docker/melle2/scum-dedicated-server.
`docker pull melle2/scum-dedicated-server`

## ⚠️ Disclaimer
Use at your own risk. This project is provided "as is" without any warranty of any kind.
* I am not responsible for any data loss, corrupted save files, or server downtime resulting from the use of this image.
* It is **highly recommended** to perform regular backups of your /scum_saved directory on the host machine.
* By using this image, you acknowledge that you are responsible for maintaining your own data integrity.

## 🤝 Contributing
Found a bug or have a feature request? Feel free to open an issue or submit a Pull Request!
