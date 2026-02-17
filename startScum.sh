#!/usr/bin/env bash
set -e
EXECUTABLE=/scum/SCUM/Binaries/Win64/SCUMServer.exe
SAVE_MOUNT="/scum_saved"
GAME_SAVE_DIR="/scum/SCUM/Saved"

_terminate() {
  echo "Caught TERM signal!"
  echo "Stopping Scum"
  wineserver -k -w
  echo "Scum stopped"
  exit 0
}

trap _terminate HUP INT QUIT TERM

if [[ ${GAME_MAX_PLAYER} =~ ^[0-9]+$ ]]; then
  MAX_PLAYER_PARAM=" -MaxPlayers=${GAME_MAX_PLAYER}"
fi

if [[ ${GAME_SERVER_PORT} =~ ^[0-9]+$ ]]; then
  SERVER_PORT_PARAM=" -port=${GAME_SERVER_PORT}"
fi

if [ "${GAME_NO_BATTLEYE}" = true ]; then
  NO_BATTLEYE_PARAM=" -nobattleye"
fi

if [ "$GAME_UPDATE" = true ] || [ -z "$(find "/${USER_NAME}/SCUM" -mindepth 1 -maxdepth 1 | head -n 1)" ] ; then
  echo "Start game update..."
  if [ -z "$(find "/${USER_NAME}/.steam/" -maxdepth 0 -empty)" ] ; then
    mkdir "/${USER_NAME}/.steam/"
  fi
  steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "/${USER_NAME}" +login anonymous +app_update \
           "${APP_ID}" validate +quit
  echo "Game update done"
fi

if [ ! -d "${SAVE_MOUNT}" ]; then
    echo "WARNING: $SAVE_MOUNT not found, creating local folder..."
    mkdir -p "${SAVE_MOUNT}"
fi

if [ -d "${GAME_SAVE_DIR}" ] && [ ! -L "${GAME_SAVE_DIR}" ]; then
    echo "#### WARNING!!: Found physical save folder. Backing-up to ${SAVE_MOUNT}.bak. If you need the data, please ensure to copy to your host!! ####"
    mkdir -p "${SAVE_MOUNT}.bak"
    mv "$GAME_SAVE_DIR"/. "/${USER_NAME}/${SAVE_MOUNT}.bak/"
    echo "Moved old folder!"
fi

if [ ! -L "$GAME_SAVE_DIR" ]; then
    ln -s "$SAVE_MOUNT" "$GAME_SAVE_DIR"
fi

echo "Starting Scum Dedicated Server"
wine "${EXECUTABLE}" -log"${NO_BATTLEYE_PARAM}""${MAX_PLAYER_PARAM}""${SERVER_PORT_PARAM}"

WINE_PID=$!
wait "$WINE_PID"
