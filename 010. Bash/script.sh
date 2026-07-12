#!/usr/bin/env bash

# Предотвращение запуска нескольких копий скрипта одновременно:
LOCKFILE="/tmp/script.lock"

exec 200>"$LOCKFILE"

flock -n 200 || {
    echo "Скрипт уже выполняется"
    exit 1
}

# Путь к лог-файлу, очистка временного лог-файла для парсинга
# и установка временной метки, с которой начинать парсинг

LOG_FILE_PATH="/var/log/access-4560-644067.log"
> ${LOG_FILE_PATH}.tmp

source ./script.conf 
NEW_TIME_LABEL=$(tail -n 1 ${LOG_FILE_PATH} | awk -F'[][]' '{print $2}')
printf '%s\n' "OLD_TIME_LABEL='$NEW_TIME_LABEL'" > ./script.conf

sed -n "\#${OLD_TIME_LABEL}#,\$p" "${LOG_FILE_PATH}" >> "${LOG_FILE_PATH}.tmp"

# Функция формирования списка IP-адресов
function ip_address()
{
   local ip_list=$(awk '{print $1}' ${LOG_FILE_PATH}.tmp | sort | uniq -c | sort -rn)

   # получить IP, встречающиеся более 5 раз, чтобы не засорять отчет
   local finale_ip_list=$(   
      while read -r count ip; do
         if [ "$count" -ge 5 ]; then
            echo "$count $ip"
         fi
      done <<< "$ip_list"
   )
   echo "$finale_ip_list"
}

# Функция формирования списка запрашиваемых URL
function requested_url()
{
   local url_list=$(awk '{print $7}' ${LOG_FILE_PATH}.tmp | sort | uniq -c | sort -rn)

   # получить URL, встречающиеся более 5 раз, чтобы не засорять отчет
   local finale_url_list=$(   
      while read -r count url; do
         if [ "$count" -ge 5 ]; then
            echo "$count $url"
         fi
      done <<< "$url_list"
   )
   echo "$finale_url_list"
}

# Функция формирования списка ошибок веб-сервера/приложения
function app_errors()
{
   local finale_error_list=$(grep -E "error|crit|alert" ${LOG_FILE_PATH}.tmp)
   echo "$finale_error_list"
}

# Функция формирования списка HTTP-кодов
function http_code()
{
   local finale_http_code_list=$(awk '{print $9}' ${LOG_FILE_PATH}.tmp | sort | uniq -c | sort -rn)
   echo "$finale_http_code_list"
}

# Функция формирования отчета и его отправки по почте
function send_mail()
{
report=$(
cat <<EOF
IP-адреса с наибольшим числом запросов:
$(ip_address)

Запрашиваемые URL с наибольшим числом запросов:
$(requested_url)

Ошибки веб-сервера/приложения:
$(app_errors)

HTTP-коды ответов с указанием их количества:
$(http_code)

System time: $(date --rfc-email)
Обрабатываемый временной диапазон: $OLD_TIME_LABEL - $NEW_TIME_LABEL
EOF
)

echo "$report" | mail -s "Сервер $HOSTNAME - парсинг лога" target@email.com
}

send_mail

