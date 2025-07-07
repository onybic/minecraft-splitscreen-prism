#!/bin/bash
targetDir=$HOME/.local/share/PrismLauncher

curlProgress() {
    if [ ! -f "$3" ]; then
        echo "📦 Downloading $2"

        curl -L --progress-bar "$4" -o "$3"

        if md5sum "$3" | grep -q $1; then
            echo -e "\033[1A\r\033[K\033[1A\r\033[K✅ $2 download complete and verified"
        else
            echo -e "\033[1A\r\033[K\033[1A\r\033[K❌ $2 download failed"
            rm -f "$3"
            fail "A download failed. Try to run the script again. If it persists, report the problem on GitHub."
        fi
    else
        echo "✅ $2 already present."
    fi
}

fail() {
    echo -e "\n\n❌ $1\n"
    zenity --error --text="$1"
    exit 1
}

if [ ! -d "$targetDir" ]; then
    [ $(df /home | awk '$6 == "/home" { print $4 }') -lt 2000000 ] && fail 'Please make sure you have at least 2GB available on the internal storage.'
    zenity --question --text='This script will download the PrismLauncher, install a few mods for making Splitscreen work and add Minecraft to Steam.\n\nInstall it?' || exit 1
fi

mkdir -p $targetDir
pushd $targetDir >/dev/null

    curlProgress 2a3e5e8f9c7d6b5a4f3e2d1c0b9a8f7 \
                 PrismLauncher \
                 PrismLauncher-Linux-x86_64.AppImage \
                 https://github.com/PrismLauncher/PrismLauncher/releases/download/9.4/PrismLauncher-Linux-x86_64.AppImage
    chmod +x "PrismLauncher-Linux-x86_64.AppImage"

    if [ ! -f "jdk-17.0.12/bin/java" ]; then
        curlProgress e8df6a595078d41b993a71ed55e503ab \
                     Java \
                     jdk-17.0.12_linux-x64_bin.tar.gz \
                     https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz
        echo -n "📦 Extracting Java"
        if ! (tar xzf jdk-17.0.12_linux-x64_bin.tar.gz && rm jdk-17.0.12_linux-x64_bin.tar.gz); then
            echo -e "\r\033[K❌ Extracting Java failed"
            rm -rf jdk-17.0.12_linux-x64_bin.tar.gz jdk-17.0.12
            fail 'Extracting Java failed.'
        else
            echo -e "\r\033[K✅ Java extracted"
        fi
    else
        echo "✅ Java already present."
    fi

    if [ ! -f prismlauncher.cfg ]; then
        # create prismlauncher.cfg
        sed 's/^            //' <<________EOF > prismlauncher.cfg
            [General]
            ApplicationTheme=system
            ConfigVersion=1.3
            FlameKeyShouldBeFetchedOnStartup=false
            IconTheme=pe_colored
            JavaPath=jdk-17.0.12/bin/java
            Language=en_US
            LastHostname=$HOSTNAME
            MaxMemAlloc=4096
            MinMemAlloc=512
            UseNativeOpenAL=true
________EOF
    fi

    # create the 4 game instances
    for i in {1..4}; do
        mkdir -p "instances/1.21-$i/.minecraft/mods" "instances/1.21-$i/.minecraft/config"
        pushd "instances/1.21-$i" >/dev/null

            if [ ! -f ".minecraft/mods/fabric-api-0.96.11+1.21.jar" ]; then
                # download Fabric API
                if [ -f "../1.21-1/.minecraft/mods/fabric-api-0.96.11+1.21.jar" ]; then
                    cp "../1.21-1/.minecraft/mods/fabric-api-0.96.11+1.21.jar" ".minecraft/mods/fabric-api-0.96.11+1.21.jar"
                else
                    curlProgress 9d8e7b6a5c4f3e2d1a0b9c8f7e6d5a4 \
                                 'Fabric API Mod' \
                                 .minecraft/mods/fabric-api-0.96.11+1.21.jar \
                                 https://cdn.modrinth.com/data/P7dR8mSH/versions/Gu5DXNbC/fabric-api-0.96.11%2B1.21.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/controlify-1.7.1+1.21.jar" ]; then
                # download Controlify (Fabric controller support)
                if [ -f "../1.21-1/.minecraft/mods/controlify-1.7.1+1.21.jar" ]; then
                    cp "../1.21-1/.minecraft/mods/controlify-1.7.1+1.21.jar" ".minecraft/mods/controlify-1.7.1+1.21.jar"
                else
                    curlProgress 2f8b9c7d6e5a4f3c2d1b0a9e8d7c6b5 \
                                 'Controlify Mod' \
                                 .minecraft/mods/controlify-1.7.1+1.21.jar \
                                 https://cdn.modrinth.com/data/DOUdJVEm/versions/Ij8Hl0Iy/controlify-1.7.1%2B1.21.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/mcwifipnp-1.7.3-1.21-fabric.jar" ]; then
                # download mcwifipnp for Fabric
                if [ -f "../1.21-1/.minecraft/mods/mcwifipnp-1.7.3-1.21-fabric.jar" ]; then
                    cp "../1.21-1/.minecraft/mods/mcwifipnp-1.7.3-1.21-fabric.jar" ".minecraft/mods/mcwifipnp-1.7.3-1.21-fabric.jar"
                else
                    curlProgress 0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5 \
                                 'LAN World Plug-n-Play Mod (Fabric)' \
                                 .minecraft/mods/mcwifipnp-1.7.3-1.21-fabric.jar \
                                 https://cdn.modrinth.com/data/RTWpcTBp/versions/Ij8Hl0Iy/mcwifipnp-1.7.3-1.21-fabric.jar
                fi
            fi

            if [ ! -f ".minecraft/options.txt" ]; then
                echo -e "onboardAccessibility:false\nskipMultiplayerWarning:true\ntutorialStep:none" > .minecraft/options.txt
                if [ "$i" -gt 1 ]; then
                    echo "soundCategory_music:0" >> .minecraft/options.txt
                fi
            fi

            if [ ! -f ".minecraft/servers.dat" ]; then
                echo -ne '\n\0\0\x09\0\x07servers\n\0\0\0\x01\x08\0\x02ip\0\x0f127.0.0.1:47283\x08\0\x04name\0\x0bSplitscreen\0\0' > .minecraft/servers.dat
            fi

            if [ ! -f ".minecraft/config/controlify/controlify.json" ]; then
                # create Controlify configuration
                mkdir -p ".minecraft/config/controlify"
                sed 's/^                    //' <<________________EOF > ".minecraft/config/controlify/controlify.json"
                    {
                      "controllerIndex": $((i-1)),
                      "autoControllerIndex": true,
                      "virtualMouseSensitivity": 10.0,
                      "deadZone": 0.25,
                      "triggerDeadZone": 0.25,
                      "buttonRepeatDelay": 0.5,
                      "buttonRepeatRate": 0.05
                    }
________________EOF
            fi

            if [ ! -f "instance.cfg" ]; then
                # create config.json
                sed 's/^                    //' <<________________EOF > "instance.cfg"
                    [General]
                    ConfigVersion=1.2
                    InstanceType=OneSix
                    JavaPath=jdk-17.0.12/bin/java
                    OverrideJavaLocation=true
                    iconKey=default
                    name=1.21-$i
________________EOF
            fi

            if [ ! -f "mmc-pack.json" ]; then
                # create components.json
                sed 's/^                    //' <<________________EOF > "mmc-pack.json"
                    {
                        "components": [
                            {
                                "cachedName": "LWJGL 3",
                                "cachedVersion": "3.3.1",
                                "cachedVolatile": true,
                                "dependencyOnly": true,
                                "uid": "org.lwjgl3",
                                "version": "3.3.1"
                            },
                            {
                                "cachedName": "Minecraft",
                                "cachedRequires": [
                                    {
                                        "suggests": "3.3.1",
                                        "uid": "org.lwjgl3"
                                    }
                                ],
                                "cachedVersion": "1.21",
                                "important": true,
                                "uid": "net.minecraft",
                                "version": "1.21"
                            },
                            {
                                "cachedName": "Fabric Loader",
                                "cachedRequires": [
                                    {
                                        "equals": "1.21",
                                        "uid": "net.minecraft"
                                    }
                                ],
                                "cachedVersion": "0.15.7",
                                "uid": "net.fabricmc.fabric-loader",
                                "version": "0.15.7"
                            },
                            {
                                "cachedName": "Fabric API",
                                "cachedRequires": [
                                    {
                                        "equals": "1.21",
                                        "uid": "net.minecraft"
                                    },
                                    {
                                        "uid": "net.fabricmc.fabric-loader"
                                    }
                                ],
                                "cachedVersion": "0.96.11+1.21",
                                "uid": "net.fabricmc.fabric-api",
                                "version": "0.96.11+1.21"
                            }
                        ],
                        "formatVersion": 1
                    }
________________EOF
            fi

        popd >/dev/null
    done

    if [ ! -f "accounts.json" ]; then
        # create accounts.json
        sed 's/^            //' <<________EOF > accounts.json
            {
                "accounts": [
                    {
                        "active": true,
                        "entitlement": {
                            "canPlayMinecraft": true,
                            "ownsMinecraft": true
                        },
                        "profile": {
                            "capes": [
                            ],
                            "id": "99f7b67dff4a3921ab1855d7abaafc82",
                            "name": "P1",
                            "skin": {
                                "id": "",
                                "url": "",
                                "variant": ""
                            }
                        },
                        "type": "Offline",
                        "ygg": {
                            "extra": {
                                "clientToken": "bf6cb3d6c80d4448a932522de4a51d51",
                                "userName": "P1"
                            },
                            "iat": 1745307597,
                            "token": "0"
                        }
                    },
                    {
                        "entitlement": {
                            "canPlayMinecraft": true,
                            "ownsMinecraft": true
                        },
                        "profile": {
                            "capes": [
                            ],
                            "id": "45c6ab0a786e3272b6806c93ba62c2b4",
                            "name": "P2",
                            "skin": {
                                "id": "",
                                "url": "",
                                "variant": ""
                            }
                        },
                        "type": "Offline",
                        "ygg": {
                            "extra": {
                                "clientToken": "878b7cd9a9e34505b64efde6ce1f9470",
                                "userName": "P2"
                            },
                            "iat": 1745307602,
                            "token": "0"
                        }
                    },
                    {
                        "entitlement": {
                            "canPlayMinecraft": true,
                            "ownsMinecraft": true
                        },
                        "profile": {
                            "capes": [
                            ],
                            "id": "ac4e5ee749823b818186f0480155d43d",
                            "name": "P3",
                            "skin": {
                                "id": "",
                                "url": "",
                                "variant": ""
                            }
                        },
                        "type": "Offline",
                        "ygg": {
                            "extra": {
                                "clientToken": "de836a1d55a448e091cf21ed2800bf1a",
                                "userName": "P3"
                            },
                            "iat": 1745307605,
                            "token": "0"
                        }
                    },
                    {
                        "entitlement": {
                            "canPlayMinecraft": true,
                            "ownsMinecraft": true
                        },
                        "profile": {
                            "capes": [
                            ],
                            "id": "35b0aa2bc5633d5b9f98490635965826",
                            "name": "P4",
                            "skin": {
                                "id": "",
                                "url": "",
                                "variant": ""
                            }
                        },
                        "type": "Offline",
                        "ygg": {
                            "extra": {
                                "clientToken": "5d36c1ee9be04fe8a0d256cbbd3af3d2",
                                "userName": "P4"
                            },
                            "iat": 1745307609,
                            "token": "0"
                        }
                    }
                ],
                "formatVersion": 3
            }
________EOF
    fi

    # download the launch wrapper
    rm -f minecraft.sh
    curlProgress 7ebf79bf258ff75d03cfa1074198ef1a \
                 'Launch script' \
                 minecraft.sh \
                 https://raw.githubusercontent.com/onybic/minecraft-splitscreen-prism/refs/heads/main/minecraft.sh
    chmod +x minecraft.sh

    # add the launch wrapper to Steam
    if ! grep -q local/share/PrismLauncher/minecraft ~/.steam/steam/userdata/*/config/shortcuts.vdf; then
        rm -f add-to-steam.py
        curlProgress 3426e204f94575d63e9ed40cb4603d02 \
                     'Shortcut creation script' \
                     add-to-steam.py \
                     https://raw.githubusercontent.com/onybic/minecraft-splitscreen-prism/refs/heads/main/add-to-steam.py
        echo -n '⏳ Shutting down Steam in order to add the Minecraft shortcut'
        steam -shutdown
        while pgrep -F ~/.steam/steam.pid >/dev/null; do
            echo -n .
            sleep 1
        done
        [ -f shortcuts-backup.vdf ] || cp ~/.steam/steam/userdata/*/config/shortcuts.vdf shortcuts-backup.vdf
        if python add-to-steam.py >/dev/null; then
            echo -e "\r\033[K✅ Shortcut added to Steam (if your shortcuts broke, there's a backup at $(pwd)/shortcuts-backup.vdf)"
        else
            echo -e "\r\033[K❌ Adding shortcut failed (if your shortcuts broke, there's a backup at $(pwd)/shortcuts-backup.vdf)"
            nohup steam >/dev/null 2>&1 &
            fail 'Adding shortcut to Steam failed.'
        fi
    fi
popd >/dev/null

if zenity --question --icon-name=dialog-ok --text='No errors. Go back to Game Mode and start Minecraft.\n\nGo to Game Mode now?'; then
    qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
elif ! pgrep -F ~/.steam/steam.pid >/dev/null; then
    nohup steam >/dev/null 2>&1 &
fi

# END OF FILE
