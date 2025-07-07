#!/bin/bash
targetDir=$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher

curlProgress() {
    if [ ! -f "$2" ]; then
        echo "📦 Downloading $1"
        curl -L --progress-bar "$3" -o "$2"
        echo -e "\033[1A\r\033[K\033[1A\r\033[K✅ $1 download complete"
    else
        echo "✅ $1 already present."
    fi
}

fail() {
    echo -e "\n\n❌ $1\n"
    zenity --error --text="$1"
    exit 1
}

# Check for Flatpak installation
if ! command -v flatpak &> /dev/null; then
    fail "Flatpak is not installed. Please install Flatpak first:\nsudo pacman -S flatpak"
fi

if [ ! -d "$targetDir" ]; then
    [ $(df /home | awk '$6 == "/home" { print $4 }') -lt 2000000 ] && fail 'Please make sure you have at least 2GB available on the internal storage.'
    zenity --question --text='This script will install PrismLauncher via Flatpak, configure mods for splitscreen, and add Minecraft to Steam.\n\nInstall it?' || exit 1
fi

mkdir -p $targetDir
pushd $targetDir >/dev/null

    # INSTALL PRISM LAUNCHER AS FLATPAK
    echo "🔧 Configuring Flatpak"
    if ! flatpak remote-list | grep -q flathub; then
        echo "➕ Adding Flathub repository"
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak update --appstream --user
    fi

    echo "🔧 Installing PrismLauncher via Flatpak"
    if ! flatpak list --app | grep -q org.prismlauncher.PrismLauncher; then
        echo "⏳ Installing PrismLauncher (this may take several minutes)..."
        flatpak install flathub org.prismlauncher.PrismLauncher -y --user || {
            echo "❌ Flatpak installation failed. Trying alternative method..."
            flatpak remote-info flathub org.prismlauncher.PrismLauncher || fail "Cannot access Flathub repository"
            flatpak install flathub org.prismlauncher.PrismLauncher -y --user || fail 'Failed to install PrismLauncher Flatpak'
        }
    fi

    if ! flatpak run org.prismlauncher.PrismLauncher --version; then
        fail "PrismLauncher installation verification failed"
    fi
    echo "✅ PrismLauncher Flatpak installed"

    if [ ! -f "jdk-21.0.3/bin/java" ]; then
        curlProgress Java \
                     jdk-21.0.3_linux-x64_bin.tar.gz \
                     https://download.oracle.com/java/21/archive/jdk-21.0.3_linux-x64_bin.tar.gz
        echo -n "📦 Extracting Java"
        if ! (tar xzf jdk-21.0.3_linux-x64_bin.tar.gz && rm jdk-21.0.3_linux-x64_bin.tar.gz); then
            echo -e "\r\033[K❌ Extracting Java failed"
            rm -rf jdk-21.0.3_linux-x64_bin.tar.gz jdk-21.0.3
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
            JavaPath=jdk-21.0.3/bin/java
            Language=en_US
            LastHostname=$HOSTNAME
            MaxMemAlloc=4096
            MinMemAlloc=512
            UseNativeOpenAL=true
________EOF
    fi

    # create the 4 game instances
    for i in {1..4}; do
        mkdir -p "instances/1.21.5-$i/.minecraft/mods" "instances/1.21.5-$i/.minecraft/config" "instances/1.21.5-$i/.minecraft/resourcepacks" "instances/1.21.5-$i/.minecraft/shaderpacks"
        pushd "instances/1.21.5-$i" >/dev/null

            if [ ! -f ".minecraft/mods/fabric-api-0.128.1+1.21.5.jar" ]; then
                # download Fabric API
                if [ -f "../1.21.5-1/.minecraft/mods/fabric-api-0.128.1+1.21.5.jar" ]; then
                    cp "../1.21.5-1/.minecraft/mods/fabric-api-0.128.1+1.21.5.jar" ".minecraft/mods/fabric-api-0.128.1+1.21.5.jar"
                else
                    curlProgress 'Fabric API Mod' \
                                 .minecraft/mods/fabric-api-0.128.1+1.21.5.jar \
                                 https://cdn.modrinth.com/data/P7dR8mSH/versions/aQqNHHfZ/fabric-api-0.128.1%2B1.21.5.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/controlify-2.1.2+1.21.5-fabric.jar" ]; then
                # download Controlify (Fabric controller support)
                if [ -f "../1.21.5-1/.minecraft/mods/controlify-2.1.2+1.21.5-fabric.jar" ]; then
                    cp "../1.21.5-1/.minecraft/mods/controlify-2.1.2+1.21.5-fabric.jar" ".minecraft/mods/controlify-2.1.2+1.21.5-fabric.jar"
                else
                    curlProgress 'Controlify Mod' \
                                 .minecraft/mods/controlify-2.1.2+1.21.5-fabric.jar \
                                 https://cdn.modrinth.com/data/DOUdJVEm/versions/Mkmd0W2y/controlify-2.1.2%2B1.21.5-fabric.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/yet_another_config_lib_v3-3.7.1+1.21.5-fabric.jar" ]; then
                # download YetAnotherConfigLib
                if [ -f "../1.21.5-1/.minecraft/mods/yet_another_config_lib_v3-3.7.1+1.21.5-fabric.jar" ]; then
                    cp "../1.21.5-1/.minecraft/mods/yet_another_config_lib_v3-3.7.1+1.21.5-fabric.jar" ".minecraft/mods/yet_another_config_lib_v3-3.7.1+1.21.5-fabric.jar"
                else
                    curlProgress 'YetAnotherConfigLib' \
                                 .minecraft/mods/yet_another_config_lib_v3-3.7.1+1.21.5-fabric.jar \
                                 https://cdn.modrinth.com/data/1eAoo2KR/versions/Fp5lATXW/yet_another_config_lib_v3-3.7.1%2B1.21.5-fabric.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/mcwifipnp-1.9.0-1.21.5-fabric.jar" ]; then
                # download mcwifipnp for Fabric
                if [ -f "../1.21.5-1/.minecraft/mods/mcwifipnp-1.9.0-1.21.5-fabric.jar" ]; then
                    cp "../1.21.5-1/.minecraft/mods/mcwifipnp-1.9.0-1.21.5-fabric.jar" ".minecraft/mods/mcwifipnp-1.9.0-1.21.5-fabric.jar"
                else
                    curlProgress 'LAN World Plug-n-Play Mod (Fabric)' \
                                 .minecraft/mods/mcwifipnp-1.9.0-1.21.5-fabric.jar \
                                 https://cdn.modrinth.com/data/RTWpcTBp/versions/oIbAxjEl/mcwifipnp-1.9.0-1.21.5-fabric.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/iris-fabric-1.8.11+mc1.21.5.jar" ]; then
                # download Iris for Fabric
                if [ -f "../1.21.5-1/.minecraft/mods/iris-fabric-1.8.11+mc1.21.5.jar" ]; then
                    cp "../1.21.5-1/.minecraft/mods/iris-fabric-1.8.11+mc1.21.5.jar" ".minecraft/mods/iris-fabric-1.8.11+mc1.21.5.jar"
                else
                    curlProgress 'Iris (Fabric)' \
                                 .minecraft/mods/iris-fabric-1.8.11+mc1.21.5.jar \
                                 https://cdn.modrinth.com/data/YL57xq9U/versions/U6evbjd0/iris-fabric-1.8.11%2Bmc1.21.5.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/sodium-fabric-0.6.12+mc1.21.5.jar" ]; then
                # download Sodium for Fabric
                if [ -f "../1.21.5-1/.minecraft/mods/sodium-fabric-0.6.12+mc1.21.5.jar" ]; then
                    cp "../1.21.5-1/.minecraft/mods/sodium-fabric-0.6.12+mc1.21.5.jar" ".minecraft/mods/sodium-fabric-0.6.12+mc1.21.5.jar"
                else
                    curlProgress 'Sodium (Fabric)' \
                                 .minecraft/mods/sodium-fabric-0.6.12+mc1.21.5.jar \
                                 https://cdn.modrinth.com/data/AANobbMI/versions/fVbw1C7i/sodium-fabric-0.6.12%2Bmc1.21.5.jar
                fi
            fi

            if [ ! -f ".minecraft/resourcepacks/Dramatic Skys Demo 1.5.3.35.zip" ]; then
                resource_pack="Dramatic Skys Demo 1.5.3.35.zip"
                source_path="../1.21.5-1/.minecraft/resourcepacks/$resource_pack"
                dest_path=".minecraft/resourcepacks/$resource_pack"

                if [ -f "$source_path" ]; then
                    echo "📦 Copying Dramatic Skys from first instance"
                    cp -- "$source_path" "$dest_path"
                else
                    curlProgress 'Dramatic Skys' \
                                 "$dest_path" \
                                 https://cdn.modrinth.com/data/2YyNMled/versions/3kR3A2kE/Dramatic%20Skys%20Demo%201.5.3.35.zip
                fi
            fi

            if [ ! -f ".minecraft/resourcepacks/FreshAnimations_v1.9.4.zip" ]; then
                # download Dramatic Skys
                if [ -f "../1.21.5-1/.minecraft/resourcepacks/FreshAnimations_v1.9.4.zip" ]; then
                    cp "../1.21.5-1/.minecraft/resourcepacks/FreshAnimations_v1.9.4.zip" ".minecraft/resourcepacks/FreshAnimations_v1.9.4.zip"
                else
                    curlProgress 'FreshAnimations_v1' \
                                 .minecraft/resourcepacks/FreshAnimations_v1.9.4.zip \
                                 https://cdn.modrinth.com/data/50dA9Sha/versions/9LtDLleW/FreshAnimations_v1.9.4.zip
                fi
            fi

            if [ ! -f ".minecraft/shaderpacks/ComplementaryUnbound_r5.5.1.zip" ]; then
                # download Complementary Unbound
                if [ -f "../1.21.5-1/.minecraft/shaderpacks/ComplementaryUnbound_r5.5.1.zip" ]; then
                    cp "../1.21.5-1/.minecraft/shaderpacks/ComplementaryUnbound_r5.5.1.zip" ".minecraft/shaderpacks/ComplementaryUnbound_r5.5.1.zip"
                else
                    curlProgress 'Complementary Unbound' \
                                 .minecraft/shaderpacks/ComplementaryUnbound_r5.5.1.zip \
                                 https://cdn.modrinth.com/data/R6NEzAwj/versions/1ng9gVp7/ComplementaryUnbound_r5.5.1.zip
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

            if [ ! -f "instance.cfg" ]; then
                # create config.json
                sed 's/^                    //' <<________________EOF > "instance.cfg"
                    [General]
                    ConfigVersion=1.3
                    InstanceType=OneSix
                    JavaPath=jdk-21.0.3/bin/java
                    OverrideJavaLocation=true
                    iconKey=default
                    name=1.21.5-$i
________________EOF
            fi

            if [ ! -f "mmc-pack.json" ]; then
                # create components.json
                sed 's/^                    //' <<________________EOF > "mmc-pack.json"
                    {
                        "components": [
                            {
                                "cachedName": "LWJGL 3",
                                "cachedVersion": "3.3.3",
                                "cachedVolatile": true,
                                "dependencyOnly": true,
                                "uid": "org.lwjgl3",
                                "version": "3.3.3"
                            },
                            {
                                "cachedName": "Minecraft",
                                "cachedRequires": [
                                    {
                                        "suggests": "3.3.3",
                                        "uid": "org.lwjgl3"
                                    }
                                ],
                                "cachedVersion": "1.21.5",
                                "important": true,
                                "uid": "net.minecraft",
                                "version": "1.21.5"
                            },
                            {
                                "cachedName": "Fabric Loader",
                                "cachedRequires": [
                                    {
                                        "equals": "1.21.5",
                                        "uid": "net.minecraft"
                                    }
                                ],
                                "cachedVersion": "0.16.14",
                                "uid": "net.fabricmc.fabric-loader",
                                "version": "0.16.14"
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
    curlProgress 'Launch script' \
                 minecraft.sh \
                 https://raw.githubusercontent.com/onybic/minecraft-splitscreen-prism/refs/heads/main/minecraft.sh
    chmod +x minecraft.sh

    # add the launch wrapper to Steam
    if ! grep -q "PrismLauncher/minecraft" ~/.steam/steam/userdata/*/config/shortcuts.vdf; then
        rm -f add-to-steam.py
        curlProgress 'Shortcut creation script' \
                     add-to-steam.py \
                     https://raw.githubusercontent.com/onybic/minecraft-splitscreen-prism/refs/heads/main/add-to-steam.py
        echo "⏳ Attempting to shut down Steam..."
        steam steam://exit >/dev/null 2>&1

        max_attempts=5
        attempt=1
        while pgrep -F ~/.steam/steam.pid >/dev/null && [ $attempt -le $max_attempts ]; do
            echo -n "."
            sleep 1
            ((attempt++))
        done

        if pgrep -F ~/.steam/steam.pid >/dev/null; then
            echo -e "\r\033[K❌ Steam didn't shut down properly. Killing process..."
            pkill -F ~/.steam/steam.pid
            sleep 2
        else
            echo -e "\r\033[K✅ Steam shut down successfully"
        fi

        [ -f shortcuts-backup.vdf ] || cp ~/.steam/steam/userdata/*/config/shortcuts.vdf shortcuts-backup.vdf

        if python add-to-steam.py; then
            echo -e "\r\033[K✅ Shortcut added to Steam (if your shortcuts broke, there's a backup at $(pwd)/shortcuts-backup.vdf)"
        else
            echo -e "\r\033[K❌ Adding shortcut failed (if your shortcuts broke, there's a backup at $(pwd)/shortcuts-backup.vdf)"
            fail 'Adding shortcut to Steam failed.'
        fi
        echo "♻️ Restarting Steam..."
        nohup steam >/dev/null 2>&1 &
    fi
popd >/dev/null

if zenity --question --icon-name=dialog-ok --text='No errors. Go back to Game Mode and start Minecraft.\n\nGo to Game Mode now?'; then
    qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
elif ! pgrep -F ~/.steam/steam.pid >/dev/null; then
    nohup steam >/dev/null 2>&1 &
fi

# END OF FILE
