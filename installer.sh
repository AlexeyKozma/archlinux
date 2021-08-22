#!/usr/bin/env bash
# main_() - Основная точка входа и выхода из процесса установки.
# fis_() - Функциональная система установки (functional install system). Пока fis_() != 1 процесс не завершён.
# arr_filters - Имеет прямое отношение к fis_().
# arr_interface_default - по умолчанию
# sudo parted -l --machine | grep /dev/s.. | cut -b 1-8

declare -a arr_filters
declare -A arr_interface_default
declare -A arr_install
arr_install=(['lang']="en_US.UTF-8" ['country']="US" ['label_b']="boot" ['label_r']="root")
boot_dialog() {
    DIALOG_RESULT=$(whiptail --clear --backtitle " Arch Linux" "$@" 3>&1 1>&2 2>&3)
    DIALOG_CODE=$?
}

testing_() {
    boot_dialog --title "Example Dialog" --msgbox "$1" 8 78
    return 0
}

set_mirror_list_() {
        curl -s "https://archlinux.org/mirrorlist/?country=${arr_install['country']}&protocol=http&protocol=https&ip_version=4" >/etc/pacman.d/mirrorlist && \
        sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    return 0
}

d_mount_() {
    if [[ ${arr_install['type_table']} == "GPT" ]]; then
        lebel_all=$(parted -sm "${arr_install['st_disk']}" print | cut -d ':' -f 1,6)
        label_boot=$(echo $lebel_all | grep boot)
        label_root=$(echo $lebel_all | grep root)
        #mkdir -p /mnt/boot/efi
        #mount "${arr_install['st_disk']}""$(label_boot:1)" mnt/boot/efi
        echo "AAAAAAAAAAAA"
        sleep 10
    fi  
    return 0
}

e_of_blocks_() {
    local res=0
    if [[ -n ${arr_install['st_disk']} ]]; then
        if [[ ${arr_install['type_table']} == "GPT" ]]; then
            parted --script "${arr_install['st_disk']}" -- mklabel gpt \
                mkpart "${arr_install['label_b']}" fat32 1MiB 512MiB \
                set 1 esp on \
                mkpart "${arr_install['label_r']}" ext4 512MiB -1 2>/dev/null
            sleep 1
        elif [[ ${arr_install['type_table']} == "MBR" ]]; then
            parted --script "${arr_install['st_disk']}" -- mklabel msdos \
                mkpart primary ext4 64s -1s \
                set 1 boot on 2>/dev/null
            sleep 1
        else
            echo "No type!"
            sleep 1
            res=1
        fi
    else
        echo "Please, select a disk"
        sleep 1
        res=1
    fi
    return $res
}

p_installing_() {
    install_list=(e_of_blocks_ set_mirror_list_)
    {
        for ((i = 0; i < ${#install_list[@]}; i++)); do
            ${install_list["$i"]}
            progress=$(("$i" + 1))
            echo "$progress"
            sleep 1
        done
    } | boot_dialog --gauge "Please wait while installing" 6 60 0
    return 0
}

select_disks_() {
    disks_all=$(parted -lms 2>/dev/null | cut -d ':' -f 1,2 | grep -e /dev/s.\[a-x\])
    items=$(echo "$disks_all" | cut -d ':' -f 1)
    options=()
    for item in $items; do
        options+=("$item" "")
    done
    boot_dialog --title "Disks" --menu "$disks_all" 20 60 10 "${options[@]}"
    return 0
}

d_manager_() {
    case $1 in
    1)
        select_disks_
        arr_install['st_disk']="$DIALOG_RESULT"
        ;; # which disk should I use?
    2)
        select_gpt_mbr_
        arr_install['type_table']="$DIALOG_RESULT"
        ;;
    *) ;;

    esac
    return 0
}

disks_() {
    boot_dialog --title "Disks" --menu "" 20 60 10 \
        "1" "${arr_interface_default['sad']}" \
        "2" "${arr_interface_default['std']}" \
        "3" "${arr_interface_default['qt']}"
    return 0
}

select_gpt_mbr_() {
    boot_dialog --title "Type table" --radiolist \
        "Please, select type table: " 15 60 4 \
        "GPT" "type" ON \
        "MBR" "type" OFF
    return 0
}

select_pattern_() {

    return 0
}

set_lang_def_() {
    case $1 in
    0)
        arr_interface_default=(['mn']="Main menu" ['lang']="Language" ['npc']="Hostname"
            ['pfr']="Password for root" ['pfu']="Password for user" ['qt']="Quit"
            ['sl']="Select language" ['en']="English" ['ru']="Russian" ['pre']="re-entry"
            ['nur']="UserName" ['dl']="Disk layout" ['std']="Select type table" ['sad']="Select a disk" ['m_i_s']="Install system" ['test']="Testing")
        ;;
    1)
        arr_install=(['lang']="ru_RU.UTF-8" ['country']="RU")
        arr_interface_default=(['mn']="Главное меню" ['lang']="Язык" ['qt']="Выход" ['sl']="Выбор языка" ['en']="Английский"
            ['ru']="Русский" ['npc']="Имя пк" ['nur']="Имя пользователя" ['pfr']="Пароль для root"
            ['pfu']="Пароль для пользователя" ['pre']="повторный ввод" ['dl']="Разметка диска" ['std']="Выбор типа таблицы"
            ['sad']="Выбор диска" ['m_i_s']="Установка системы" ['test']="Тестирование")
        ;;
    esac
    return 0
}

select_lang_() {
    boot_dialog --title "${arr_interface_default['sl']}" --menu "" 10 60 2 \
        "1" "${arr_interface_default['en']}" \
        "2" "${arr_interface_default['ru']}"
    if [[ $? ]]; then
        set_lang_def_ $(("$DIALOG_RESULT" - 1))
    fi
    return 0
}

menu_meager() {
    case $1 in
    1) select_lang_ ;;
    2)
        boot_dialog --title "" --inputbox "\n${arr_interface_default['npc']}\n" 10 60
        arr_install['npc']="$DIALOG_RESULT"
        ;;
    3)
        boot_dialog --title "" --inputbox "\n${arr_interface_default['nur']}\n" 10 60
        arr_install['nur']="$DIALOG_RESULT" arr_install['nur_f']="true"
        ;;
    4)
        boot_dialog --title "" --passwordbox "\n${arr_interface_default['pfr']}\n" 10 60
        arr_install['pfr']="$DIALOG_RESULT"
        boot_dialog --title "" --passwordbox "\n${arr_interface_default['pfr']} ${arr_interface_default['pre']}\n" 10 60
        if [[ ${arr_install['pfr']} == "$DIALOG_RESULT" ]]; then
            arr_install['pfr_f']="true"
        fi
        ;;
    5)
        boot_dialog --title "" --passwordbox "\n${arr_interface_default['pfu']}\n" 10 60
        arr_install['pfu']="$DIALOG_RESULT"
        boot_dialog --title "" --passwordbox "\n${arr_interface_default['pfu']} ${arr_interface_default['pre']}\n" 10 60
        if [[ ${arr_install['pfu']} == "$DIALOG_RESULT" ]]; then
            arr_install['pfu_f']="true"
        fi
        ;;
    6)
        disks_
        d_manager_ "$DIALOG_RESULT"
        ;;
    7) testing_ "${d_mount_}";;    
    8) p_installing_ ;;
    *) exit ;;
    esac
    return 0
}

menu_main() {
    if [[ ${#arr_interface_default[@]} -eq 0 ]]; then
        set_lang_def_ 0
    fi
    boot_dialog --title "${arr_interface_default['mn']}" --menu "" 20 60 10 \
        "1" "${arr_interface_default['lang']} [${arr_install['lang']:0:2}]" \
        "2" "${arr_interface_default['npc']} [${arr_install['npc']}]" \
        "3" "${arr_interface_default['nur']}" \
        "4" "${arr_interface_default['pfr']}" \
        "5" "${arr_interface_default['pfu']}" \
        "6" "${arr_interface_default['dl']} [${arr_install['st_disk']}],[${arr_install['type_table']}]" \
        "7" "${arr_interface_default['test']}" \
        "8" "${arr_interface_default['m_i_s']}" \
        "9" "${arr_interface_default['qt']}"
    return 0
}

main_() {
    while [[ true ]]; do
        clear
        menu_main
        if [[ $? ]]; then
            menu_meager "$DIALOG_RESULT"
        fi
    done
    return 0
}

main_
