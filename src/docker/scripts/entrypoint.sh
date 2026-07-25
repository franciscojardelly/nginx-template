#!/bin/bash

function right_str() {
  # $1 - string value
  # $2 - int value
  int_value=${2}  
  str_value=${1} 
  case ${int_value#[-+]} in
    *[!0-9]* | '') echo "" ;;
    * ) echo ${str_value:${#str_value}-${int_value}:int_value} ;;
  esac  
}

function generate_security_file {
  # $1 - environment variable
  sufix=$(right_str "${1}" 5)
  if [[ "${sufix}" != "_TYPE" && "${sufix}" != "_FILE" ]]; then
    decode=""
    value=$(python -c "import os; print(os.getenv('${1}', ''))")
    type=$(python -c "import os; print(os.getenv('${1}_TYPE', ''))")
    file=$(python -c "import os; print(os.getenv('${1}_FILE', ''))")
    mkdir -p ${NGINX_PROXY_SECURITY_DEFAULT_DIR}
    if [ "${type}" == "base64" ]; then
        decode="| base64 --decode"
    fi
    if [[ "${value}" != "" && "${file}" != "" ]]; then
        eval "echo ${value} ${decode} > ${file}"
        chmod -R 7777 ${file}
    fi
  fi
}

function replace_file() {
  # $1 - file
  # $2 - environment variable  
  if [ -f "${1}" ]; then
    cat ${1} | python -c "import sys, os; print(str(sys.stdin.read()).replace('\${${2}}', os.getenv('${2}')))"
  fi
}  

function generate_security_files {
  env_vars=$(printenv | sed 's;=.*;;' | grep "^NGINX_PROXY_SECURITY_" | sort)
  for var_name in $env_vars
  do
    generate_security_file ${var_name}   
  done
}

function replace_files() {
  config_file=/etc/nginx/nginx.conf
  config_file_tmp="${config_file}.tmp.template.backup"
  config_files=$(ls /etc/nginx/conf.d/*.conf 2>/dev/null)
  server_files=$(ls /etc/nginx/server.d/*.conf 2>/dev/null)
  options_files=$(ls /etc/nginx/options.d/*.conf 2>/dev/null)
  env_vars=$(printenv | sed 's;=.*;;' | grep "^NGINX_PROXY_" | sort)
  for var_name in $env_vars
  do
    replace_file "${config_file}" "${var_name}" > $config_file_tmp && cat $config_file_tmp > $config_file  
    for file_src in $config_files
    do
      file_dest="${file_src}.tmp.template.backup"
      replace_file "${file_src}" "${var_name}" > $file_dest && cat $file_dest > $file_src
    done
    for file_src in $server_files
    do
      file_dest="${file_src}.tmp.template.backup"
      replace_file "${file_src}" "${var_name}" > $file_dest && cat $file_dest > $file_src
    done
    for file_src in $options_files
    do
      file_dest="${file_src}.tmp.template.backup"
      replace_file "${file_src}" "${var_name}" > $file_dest && cat $file_dest > $file_src
    done
  done
  rm -rf $config_file_tmp
  rm -rf /etc/nginx/conf.d/*.tmp.template.backup
  rm -rf /etc/nginx/server.d/*.tmp.template.backup
}

function init() {
  generate_security_files
  replace_files
}

init && exec "$@"