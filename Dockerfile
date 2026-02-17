FROM melle2/wine-steamcmd-ubuntu:24.04-3

ENV USER_NAME=scum \
    APP_ID=3792580 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US
ENV USER_HOME=/home/${USER_NAME}

ARG USER_ID=7010
ARG GROUP_ID=7010

RUN groupadd -g ${GROUP_ID} ${USER_NAME} && useradd -d ${USER_HOME} -u ${USER_ID} -g ${GROUP_ID} -m ${USER_NAME}
ADD startScum.sh ${USER_HOME}

RUN apt update && apt install -y winetricks && \
    mkdir /${USER_NAME} && chmod 744 ${USER_HOME}/startScum.sh && \
    chown ${USER_NAME}:${USER_NAME} ${USER_HOME}/startScum.sh /${USER_NAME}

USER ${USER_NAME}
WORKDIR /${USER_NAME}
ENV WINEDEBUG=fixme-all,err+all
ENV XDG_RUNTIME_DIR="/tmp/runtime-scum"

RUN mkdir -p ${XDG_RUNTIME_DIR} && chmod 700 ${XDG_RUNTIME_DIR} && chown ${USER_ID}:${GROUP_ID} ${XDG_RUNTIME_DIR} && \
    wineboot -i && wineserver -w && \
    wine reg delete "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\winebth" /f && wineserver -k && \
    xvfb-run -a winetricks -q vcrun2017 d3dcompiler_47 crypt32 && \
    rm -R /home/scum/.cache/*

SHELL ["/bin/sh", "-c"]
ENTRYPOINT exec ${USER_HOME}/startScum.sh
#ENTRYPOINT ["tail", "-f", "/dev/null"]

EXPOSE 7779
