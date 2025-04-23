#!/bin/bash
targetDir=$HOME/.local/share/PollyMC
mkdir -p $targetDir
pushd $targetDir

    if [ ! -f "PollyMC-Linux-x86_64.AppImage" ]; then
        # download pollymc
        wget https://github.com/fn2006/PollyMC/releases/download/8.0/PollyMC-Linux-x86_64.AppImage
        chmod +x PollyMC-Linux-x86_64.AppImage
    fi

    if [ ! -f "jdk-17.0.12/bin/java" ]; then
        # download java 17
        curl https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz | tar xz
    fi

    if [ ! -f pollymc.cfg ]; then
        # create pollymc.cfg
        sed 's/^            //' <<________EOF > pollymc.cfg
            [General]
            ApplicationTheme=system
            ConfigVersion=1.2
            FlameKeyShouldBeFetchedOnStartup=false
            IconTheme=pe_colored
            JavaPath=jdk-17.0.12/bin/java
            Language=en_US
            LastHostname=$HOSTNAME
            MaxMemAlloc=4096
            MinMemAlloc=512
________EOF
    fi

    # create the 4 game instances
    for i in {1..4}; do
        mkdir -p "instances/1.20.1-$i/.minecraft/mods" "instances/1.20.1-$i/.minecraft/config"
        pushd "instances/1.20.1-$i"

            if [ ! -f ".minecraft/mods/framework-forge-1.20.1-0.7.12.jar" ]; then
                # download framework
                if [ -f "../1.20.1-1/.minecraft/mods/framework-forge-1.20.1-0.7.12.jar" ]; then
                    cp "../1.20.1-1/.minecraft/mods/framework-forge-1.20.1-0.7.12.jar" ".minecraft/mods/framework-forge-1.20.1-0.7.12.jar"
                else
                    wget -O ".minecraft/mods/framework-forge-1.20.1-0.7.12.jar" https://mediafilez.forgecdn.net/files/5911/986/framework-forge-1.20.1-0.7.12.jar
                fi
            fi

            if [ ! -f ".minecraft/mods/controllable-forge-1.20.1-0.21.7-release.jar" ]; then
                # download controllable
                if [ -f "../1.20.1-1/.minecraft/mods/controllable-forge-1.20.1-0.21.7-release.jar" ]; then
                    cp "../1.20.1-1/.minecraft/mods/controllable-forge-1.20.1-0.21.7-release.jar" ".minecraft/mods/controllable-forge-1.20.1-0.21.7-release.jar"
                else
                    wget -O ".minecraft/mods/controllable-forge-1.20.1-0.21.7-release.jar" https://raw.githubusercontent.com/ArnoldSmith86/minecraft-splitscreen/refs/heads/main/controllable-forge-1.20.1-0.21.7-release.jar
                fi
            fi

            if [ ! -f ".minecraft/options.txt" ]; then
                echo -e "onboardAccessibility:false\nskipMultiplayerWarning:true" > .minecraft/options.txt
            fi

            if [ ! -f ".minecraft/config/controllable-client.toml" ]; then
                # create controllable-client.toml
                sed 's/^                    //' <<________________EOF > ".minecraft/config/controllable-client.toml"
                    [client]
                    [client.options]
                    autoSelectIndex = $((i-1)).0
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
                    name=1.20.1-$i
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
                                "cachedVersion": "1.20.1",
                                "important": true,
                                "uid": "net.minecraft",
                                "version": "1.20.1"
                            },
                            {
                                "cachedName": "Forge",
                                "cachedRequires": [
                                    {
                                        "equals": "1.20.1",
                                        "uid": "net.minecraft"
                                    }
                                ],
                                "cachedVersion": "47.4.0",
                                "uid": "net.minecraftforge",
                                "version": "47.4.0"
                            }
                        ],
                        "formatVersion": 1
                    }
________________EOF
            fi

        popd
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
    wget https://raw.githubusercontent.com/ArnoldSmith86/minecraft-splitscreen/refs/heads/main/minecraft.sh
    chmod +x minecraft.sh

    # add the launch wrapper to Steam
    if ! grep -q local/share/PollyMC/minecraft ~/.steam/steam/userdata/*/config/shortcuts.vdf; then
        steam -shutdown
        while pgrep -F ~/.steam/steam.pid; do
            sleep 1
        done
        [ -f shortcuts-backup.tar.xz ] || tar cJf shortcuts-backup.tar.xz ~/.steam/steam/userdata/*/config/shortcuts.vdf
        curl https://raw.githubusercontent.com/ArnoldSmith86/minecraft-splitscreen/refs/heads/main/add-to-steam.py | python
        nohup steam &
    fi
popd
