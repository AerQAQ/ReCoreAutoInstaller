#!/system/bin/bash

WHITE='\033[1;37m'
NC='\033[0m'

clear

echo -e "${WHITE}"
echo "__________ _________  "
echo "\\______   \\_   ___ \\ "
echo "|       _//    \\  \\/ "
echo "|    |   \\\\     \\____"
echo "|____|_  / \\______  /"
echo "       \\/         \\/  "
echo -e "${NC}"
echo -e "${WHITE}ReCoreAutoInstaller v1.0${NC}"
echo -e "${WHITE}This shell script is made by AerQAQ${NC}"

get_php_release_year() {
    version="$1"
    major_minor=$(echo "$version" | cut -d. -f1,2)
    
    case "$major_minor" in
        "8.4") echo "2024" ;;
        "8.3") echo "2023" ;;
        "8.2") echo "2022" ;;
        "8.1") echo "2021" ;;
        "8.0") echo "2020" ;;
        "7.4") echo "2019" ;;
        "7.3") echo "2018" ;;
        "7.2") echo "2017" ;;
        "7.1") echo "2016" ;;
        "7.0") echo "2015" ;;
        "5.6") echo "2014" ;;
        "5.5") echo "2013" ;;
        "5.4") echo "2012" ;;
        "5.3") echo "2009" ;;
        "5.2") echo "2006" ;;
        "5.1") echo "2005" ;;
        "5.0") echo "2004" ;;
        "4."*) echo "2000" ;;
        *) echo "未知" ;;
    esac
}

extract_php_version_from_binary() {
    php_file="$1"
    
    if command -v strings > /dev/null 2>&1; then
        version_strings=$(strings "$php_file" 2>/dev/null | grep -iE "PHP[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+")
        if [ -n "$version_strings" ]; then
            echo "$version_strings" | head -1
            return 0
        fi
    fi
    
    if command -v grep > /dev/null 2>&1; then
        grep_result=$(grep -oaE "PHP[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+" "$php_file" 2>/dev/null | head -1)
        if [ -n "$grep_result" ]; then
            echo "$grep_result"
            return 0
        fi
    fi
    
    return 1
}

verify_php() {
    php_file="$1"
    
    if [ ! -f "$php_file" ]; then
        echo -e "\n${WHITE}错误: 文件 '$php_file' 不存在${NC}"
        return 1
    fi
    
    if [ ! -x "$php_file" ]; then
        echo -e "\n${WHITE}警告: 文件没有执行权限，正在添加...${NC}"
        chmod +x "$php_file"
    fi
    
    echo -e "\n${WHITE}正在验证PHP文件: $php_file${NC}"
    
    version_info=$(extract_php_version_from_binary "$php_file")
    
    if [ -n "$version_info" ]; then
        php_version=$(echo "$version_info" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
        if [ -n "$php_version" ]; then
            release_year=$(get_php_release_year "$php_version")
            echo -e "${WHITE}✓ 找到PHP版本: $php_version${NC}"
            echo -e "${WHITE}✓ 发布年份: $release_year${NC}"
            return 0
        fi
    fi
    
    if "$php_file" -v 2>/dev/null | grep -q "PHP"; then
        version=$("$php_file" -v 2>/dev/null | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
        if [ -n "$version" ]; then
            release_year=$(get_php_release_year "$version")
            echo -e "${WHITE}✓ 找到PHP版本: $version${NC}"
            echo -e "${WHITE}✓ 发布年份: $release_year${NC}"
            return 0
        fi
    fi
    
    echo -e "\n${WHITE}无法确定PHP版本信息，但文件存在且有执行权限${NC}"
    return 0
}

select_php_path() {
    echo -e "\n${WHITE}请输入PHP路径:${NC}"
    echo -e "${WHITE}例如: /data/user/0/com.termux/files/home/php7.3.16${NC}"
    echo -n "${WHITE}路径: ${NC}"
    read input_path
    
    input_path=$(printf "%s" "$input_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$input_path" ]; then
        echo -e "\n${WHITE}未输入路径${NC}"
        return 1
    fi
    
    if verify_php "$input_path"; then
        PHP_TEMP_PATH="$input_path"
        echo -e "\n${WHITE}PHP路径已设置 (仅本次使用)${NC}"
        return 0
    else
        echo -e "\n${WHITE}PHP验证失败${NC}"
        return 1
    fi
}

while true; do
    echo ""
    echo -e "${WHITE}[1] 下载服务端${NC}"
    echo -e "${WHITE}[2] 启动服务器${NC}"
    echo -e "${WHITE}[3] 选择PHP路径${NC}"
    echo -e "${WHITE}[4] 退出${NC}"
    echo ""
    echo -n "请选择 [1-4]: "
    
    read choice
    
    case $choice in
        1)
            echo -e "\n${WHITE}正在获取版本列表...${NC}"
            sleep 1
            
            TAGS=$(curl -s https://api.github.com/repos/AerQAQ/ReCore/releases | grep -o '"tag_name": "[^"]*"' | sed 's/"tag_name": "//g' | sed 's/"//g')
            
            if [ -z "$TAGS" ]; then
                echo -e "\n${WHITE}没有找到可用版本或网络连接失败${NC}"
                echo -e "\n${WHITE}按回车继续...${NC}"
                read dummy
                continue
            fi
            
            echo -e "${WHITE}Please select a version:${NC}"
            echo ""
            
            echo "$TAGS" > ./recore_tags.txt
            
            index=1
            while read tag; do
                if [ -n "$tag" ]; then
                    echo -e "${WHITE}[$index] $tag${NC}"
                    index=$((index + 1))
                fi
            done < ./recore_tags.txt
            
            echo ""
            echo -n "请输入版本序号: "
            read version_choice
            
            if ! echo "$version_choice" | grep -q '^[0-9]\+$'; then
                echo -e "\n${WHITE}无效的选择！请输入数字${NC}"
                rm -f ./recore_tags.txt
                echo -e "\n${WHITE}按回车继续...${NC}"
                read dummy
                continue
            fi
            
            selected_tag=""
            current_index=1
            while read tag; do
                if [ -n "$tag" ]; then
                    if [ $current_index -eq $version_choice ]; then
                        selected_tag="$tag"
                        break
                    fi
                    current_index=$((current_index + 1))
                fi
            done < ./recore_tags.txt
            
            rm -f ./recore_tags.txt
            
            if [ -z "$selected_tag" ]; then
                echo -e "\n${WHITE}无效的序号！${NC}"
                echo -e "\n${WHITE}按回车继续...${NC}"
                read dummy
                continue
            fi
            
            echo -e "\n${WHITE}正在下载 $selected_tag ...${NC}"
            
            mkdir -p ~/ReCore
            cd ~/ReCore
            
            file_version="$selected_tag"
            if echo "$selected_tag" | grep -q '[0-9][a-zA-Z]'; then
                file_version=$(echo "$selected_tag" | sed 's/\([0-9]\)\([a-zA-Z]\)/\1_\2/g')
            fi
            
            DOWNLOAD_URL="https://github.com/AerQAQ/ReCore/releases/download/$selected_tag/ReCore_$file_version.zip"
            OUTPUT_FILE="ReCore_$file_version.zip"
            
            echo -e "${WHITE}下载地址: $DOWNLOAD_URL${NC}"
            echo -e "${WHITE}保存为: $OUTPUT_FILE${NC}"
            
            if wget --no-check-certificate -O "$OUTPUT_FILE" "$DOWNLOAD_URL"; then
                echo -e "\n${WHITE}下载成功！文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)${NC}"
                echo -e "${WHITE}正在解压...${NC}"
                
                if unzip -o "$OUTPUT_FILE"; then
                    echo -e "\n${WHITE}解压成功！服务端已安装到 ~/ReCore 目录${NC}"
                    echo -e "${WHITE}目录内容:${NC}"
                    ls -la
                    rm -f "$OUTPUT_FILE"
                    echo -e "${WHITE}已删除压缩包${NC}"
                else
                    echo -e "\n${WHITE}解压失败！请检查zip文件是否完整${NC}"
                fi
            else
                echo -e "\n${WHITE}下载失败！请检查网络连接或版本是否存在${NC}"
                echo -e "${WHITE}尝试下载: $DOWNLOAD_URL${NC}"
            fi
            
            echo -e "\n${WHITE}按回车继续...${NC}"
            read dummy
            ;;
            
        2)
            echo -e "\n${WHITE}正在启动服务器...${NC}"
            
            if [ ! -d ~/ReCore ]; then
                echo -e "\n${WHITE}未找到服务端目录！请先下载服务端${NC}"
                echo -e "\n${WHITE}按回车继续...${NC}"
                read dummy
                continue
            fi
            
            cd ~/ReCore
            
            USE_PHP=""
            if [ -n "$PHP_TEMP_PATH" ] && [ -f "$PHP_TEMP_PATH" ]; then
                USE_PHP="$PHP_TEMP_PATH"
                echo -e "${WHITE}使用临时指定的PHP: $USE_PHP${NC}"
            elif [ -f ./bin/php ]; then
                USE_PHP="./bin/php"
                echo -e "${WHITE}使用内置PHP: $USE_PHP${NC}"
            elif command -v php &> /dev/null; then
                USE_PHP="php"
                echo -e "${WHITE}使用系统PHP${NC}"
            else
                echo -e "\n${WHITE}未找到PHP！请先选择PHP路径${NC}"
                echo -e "${WHITE}按回车继续...${NC}"
                read dummy
                continue
            fi
            
            if [ -f PocketMine-MP.phar ]; then
                echo -e "${WHITE}启动 PocketMine-MP.phar (优先)...${NC}"
                $USE_PHP PocketMine-MP.phar
            elif [ -f src/pocketmine/PocketMine.php ]; then
                echo -e "${WHITE}启动 src/pocketmine/PocketMine.php...${NC}"
                $USE_PHP src/pocketmine/PocketMine.php
            elif [ -f start.sh ]; then
                echo -e "${WHITE}找到启动脚本 start.sh${NC}"
                echo -e "${WHITE}正在启动...${NC}"
                bash start.sh
            elif [ -f server.jar ]; then
                echo -e "${WHITE}找到服务端文件 server.jar${NC}"
                echo -e "${WHITE}正在启动...${NC}"
                java -jar server.jar
            else
                echo -e "\n${WHITE}未找到可执行的服务端文件！${NC}"
                echo -e "${WHITE}请检查 ~/ReCore 目录${NC}"
            fi
            
            echo -e "\n${WHITE}服务器已停止${NC}"
            echo -e "\n${WHITE}按回车继续...${NC}"
            read dummy
            ;;
            
        3)
            select_php_path
            if [ -n "$PHP_TEMP_PATH" ]; then
                echo -e "\n${WHITE}PHP路径已设置为: $PHP_TEMP_PATH${NC}"
                echo -e "${WHITE}注意: 此设置仅本次有效，重启脚本后需要重新选择${NC}"
            fi
            ;;
            
        4)
            echo -e "\n${WHITE}退出程序...${NC}"
            sleep 1
            clear
            exit 0
            ;;
            
        *)
            echo -e "\n${WHITE}错误：无效的选择！请输入1、2、3或4${NC}"
            sleep 1
            ;;
    esac
done