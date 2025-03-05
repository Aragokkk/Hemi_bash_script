#!/bin/bash

#!/bin/bash

echo "=================================================================================="
echo "███████╗██████╗ ██╗██████╗ ██╗████████╗"
echo "██╔════╝██╔══██╗██║██╔══██╗██║╚══██╔══╝"
echo "███████╗██████╔╝██║██████╔╝██║   ██║   "
echo "╚════██ ██╔═══╝ ██║██╔══██╗██║   ██║   "
echo "███████╗██║     ██║██║  ██║██║   ██║   "
echo "╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝   ╚═╝   "
echo "=================================================================================="

echo "=================================================================================="
echo "██╗  ██╗███████╗███╗   ███╗██╗"
echo "██║  ██║██╔════╝████╗ ████║██║"
echo "███████║█████╗  ██╔████╔██║██║"
echo "██╔══██║██╔══╝  ██║╚██╔╝██║██║"
echo "██║  ██║███████╗██║ ╚═╝ ██║██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
echo "=================================================================================="


# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Изменение комиссии${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"
echo -e "${CYAN}5) Проверка логов (выход из логов CTRL+C)${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in

    1)     
        echo -e "${BLUE}Устанавливаем ноду Hemi...${NC}"
        sudo apt-get update -y && sudo apt upgrade -y && sudo apt-get install make screen build-essential unzip lz4 gcc git jq -y

        echo  "Устанавливаем гo"
        sudo rm -rf /usr/local/go
        curl -Ls https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
        eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

        echo "Выкачиваем репозиторий проекта:"
        wget https://github.com/hemilabs/heminetwork/releases/download/v0.11.5/heminetwork_v0.11.5_linux_amd64.tar.gz   
        tar -xvf heminetwork_v0.11.5_linux_amd64.tar.gz
        rm -rf heminetwork_v0.11.5_linux_amd64.tar.gz
        cd heminetwork_v0.11.5_linux_amd64/

        echo "Создаем кошелек:"
	./keygen -secp256k1 -json -net="testnet" > "$HOME/heminetwork_v0.11.5_linux_amd64/popm-address.json"
	echo -e "${RED}Сохраните эти данные в надежное место:${NC}"
	cat "$HOME/heminetwork_v0.11.5_linux_amd64/popm-address.json"
	echo -e "${PURPLE}Ваш pubkey_hash — это ваш tBTC адрес, на который нужно запросить тестовые токены в Discord проекта.${NC}"

	echo -e "${YELLOW}Введите ваш приватный ключ:${NC} "
	read POPM_PRIVATE_KEY
	echo "export POPM_PRIVATE_KEY=$POPM_PRIVATE_KEY" >> ~/.bashrc

	echo -e "${YELLOW}Введите Комиссию:${NC} "
	read POPM_STATIC_FEE
	echo "export POPM_STATIC_FEE=$POPM_STATIC_FEE" >> ~/.bashrc
	echo "export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> ~/.bashrc
	source ~/.bashrc
	eval "export POPM_PRIVATE_KEY=$POPM_PRIVATE_KEY"
	eval "export POPM_STATIC_FEE=$POPM_STATIC_FEE"

        echo "Создаем сервисный файл:"
sudo tee /etc/systemd/system/hemid.service > /dev/null <<EOF
[Unit]
Description=Hemi
After=network.target

[Service]
User=$USER
Environment="POPM_BTC_PRIVKEY=$POPM_PRIVATE_KEY"
Environment="POPM_STATIC_FEE=$POPM_STATIC_FEE"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
WorkingDirectory=/root/heminetwork_v0.11.5_linux_amd64
ExecStart=/root/heminetwork_v0.11.5_linux_amd64/popmd
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

        echo "Запускаем сервис:"
        sudo systemctl daemon-reload
	sudo systemctl enable hemid
	sudo systemctl restart hemid

        ;;

    2)
        echo -e "${BLUE}Обновляем ноду Hemi...${NC}"
        cd heminetwork_v0.11.5_linux_amd64/ 
        cp popm-address.json /root/popm-address.json 
        sudo systemctl stop hemid 

        cd 

        wget https://github.com/hemilabs/heminetwork/releases/download/v0.11.5/heminetwork_v0.11.5_linux_amd64.tar.gz
        tar -xvf heminetwork_v0.11.5_linux_amd64.tar.gz 
        rm heminetwork_v0.11.5_linux_amd64.tar.gz 
        mv heminetwork_v0.11.5_linux_amd64/ /root/hemi 
        cp popm-address.json /root/hemi 
        rm -rf heminetwork_v0.11.5_linux_amd64/ 
        nano /etc/systemd/system/hemid.service 

        #меняем тут вот эти две строки: 
        WorkingDirectory=/root/hemi 
        ExecStart=/root/hemi/popmd сохраняем, выходим 

        sudo systemctl enable hemid 
        sudo systemctl daemon-reload 
        sudo systemctl start hemid

        ;;

    3)
        echo -e "${YELLOW}Укажите новое значение комиссии (минимум 50):${NC}"
        read NEW_FEE
        sed -i "s/^POPM_STATIC_FEE=.*/POPM_STATIC_FEE=$NEW_FEE/" /etc/systemd/system/hemid.service
        sed -i "s/^export POPM_STATIC_FEE=.*/export POPM_STATIC_FEE=$NEW_FEE/" ~/.bashrc
        source ~/.bashrc
        sleep 1

        # Перезапуск сервиса Hemi
        sudo systemctl daemon-reload
        sudo systemctl restart hemid

        ;;

    4)
        echo -e "${BLUE}Удаление ноды Hemi...${NC}"
        # Находим все сессии screen, содержащие "hemi"
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        # Если сессии найдены, удаляем их
        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Завершение сессий screen с идентификаторами: $SESSION_IDS${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}Сессии screen для ноды Hemi не найдены, продолжаем удаление${NC}"
        fi

        # Остановка и удаление сервиса Hemi
        sudo systemctl stop hemi.service
        sudo systemctl disable hemi.service
        sudo rm /etc/systemd/system/hemi.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки с названием, содержащим "hemi"
        echo -e "${BLUE}Удаляем файлы ноды Hemi...${NC}"
        rm -rf *hemi*

        echo -e "${GREEN}Нода Hemi успешно удалена!${NC}"

        ;;

    5)
        sudo journalctl -u hemid -f --no-hostname -o cat

        ;;


    *)
        echo "❌ Ошибка: Неверный выбор! Попробуйте снова."
        ;;

esac
