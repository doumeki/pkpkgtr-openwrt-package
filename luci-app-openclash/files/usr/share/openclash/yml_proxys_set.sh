#!/bin/sh /etc/rc.common
status=$(ps|grep -c /usr/share/openclash/yml_proxys_set.sh)
[ "$status" -gt "3" ] && exit 0

START_LOG="/tmp/openclash_start.log"
SERVER_FILE="/tmp/yaml_servers.yaml"

#写入服务器节点到配置文件
yml_servers_set()
{

   local section="$1"
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "server" "$section" "server" ""
   config_get "port" "$section" "port" ""
   config_get "cipher" "$section" "cipher" ""
   config_get "password" "$section" "password" ""
   config_get "securitys" "$section" "securitys" ""
   config_get "udp" "$section" "udp" ""
   config_get "obfs" "$section" "obfs" ""
   config_get "obfs_vmess" "$section" "obfs_vmess" ""
   config_get "host" "$section" "host" ""
   config_get "custom" "$section" "custom" ""
   config_get "tls" "$section" "securitys" ""
   config_get "skip_cert_verify" "$section" "skip_cert_verify" ""
   config_get "path" "$section" "path" ""
   config_get "alterId" "$section" "alterId" ""
   config_get "uuid" "$section" "uuid" ""
   config_get "auth_name" "$section" "auth_name" ""
   config_get "auth_pass" "$section" "auth_pass" ""
   
	
   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$server" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      name="Server"
   fi
   
   if [ -z "$port" ]; then
      return
   fi
   
   if [ ! -z "$udp" ] && [ -z "$obfs" ]; then
      udp=", udp: $udp"
   fi
   
   if [ "$obfs" != "none" ]; then
      if [ "$obfs" = "websocket" ]; then
         obfss="plugin: v2ray-plugin"
      else
         obfss="plugin: obfs"
      fi
   else
      obfs=""
   fi
   
   if [ "$obfs_vmess" != "none" ]; then
      if [ "$type" = "vmess" ] && [ "$obfs" = "websocket" ]; then
         obfs_vmess=", network: ws"
      else
         obfs_vmess=""
      fi
   fi
   
   
   if [ ! -z "$host" ]; then
      host="host: $host"
   fi
   
   if [ ! -z "$custom" ] && [ "$type" = "vmess" ]; then
      custom=", ws-headers: { Host: $custom }"
   fi
   
   if [ ! -z "$tls" ] && [ "$type" != "ss" ]; then
      tls=", tls: $tls"
   elif [ ! -z "$tls" ]; then
      tls="tls: $tls"
   fi
   
   if [ ! -z "$path" ]; then
      if [ "$type" != "vmess" ]; then
         path="path: '$path'"
      else
         path="ws-path: /$path"
      fi
   fi
   
   if [ ! -z "$skip_cert_verify" ] && [ "$type" != "ss" ]; then
      skip_cert_verify=", skip-cert-verify: $skip_cert_verify"
   elif [ ! -z "$skip_cert_verify" ]; then
      skip_cert_verify="skip-cert-verify: $skip_cert_verify"
   fi

   if [ "$type" = "ss" ] && [ "$obfs" = "none" ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, cipher: $cipher, password: "$password"$udp }" >>$SERVER_FILE
   elif [ "$type" = "ss" ] && [ "$obfs" != "none" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  cipher: $cipher
  password: "$password"
EOF
  if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
  udp: $udp
EOF
  fi
  if [ ! -z "$obfss" ]; then
cat >> "$SERVER_FILE" <<-EOF
  $obfss
  plugin-opts:
    mode: $obfs
    $host
EOF
  fi
  if [ ! -z "$path" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $path
EOF
  fi
  if [ ! -z "$custom" ]; then
cat >> "$SERVER_FILE" <<-EOF
    headers:
      custom: $custom
EOF
  fi
   fi
   
   if [ "$type" = "vmess" ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, uuid: $uuid, alterId: $alterId, cipher: $securitys$skip_cert_verify$obfs_vmess$path$custom$tls }" >>$SERVER_FILE
   fi
   
   if [ "$type" = "socks5" ] || [ "$type" = "http" ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, username: $auth_name, password: $auth_pass$skip_cert_verify$tls }" >>$SERVER_FILE
   fi

}

yml_servers_change()
{
num=$(grep -c "^ \{0,\}" /tmp/Proxy_Server)
nums=$(grep -c "^ \{0,\}" /tmp/Proxy_Servers)
count=1
while [ "$count" -le "$num" ]
do
Server=$(sed -n "${count}p" /tmp/Proxy_Server |sed 's/\\/#d#/g' 2>/dev/null)
Servers=$(sed -n "${count}p" /tmp/Proxy_Servers |sed 's/\\/#d#/g' 2>/dev/null)
sed -i 's/\\/#d#/g' /etc/openclash/config.yaml 2>/dev/null 

if [ "$Server" != "$Servers" ] && [ ! -z "$Servers" ]; then
   sed -i "s/${Servers}/${Server}/g" /etc/openclash/config.yaml 2>/dev/null
elif [ -z "$Servers" ]; then
   space_num=$(grep "$last_server" /etc/openclash/config.yaml |sed -n '$p' |awk -F '-' '{print $1}' |sed 's/ /#spas#/g' 2>/dev/null |sed 's/\t/#tab#/g' 2>/dev/null)
   sed -i "/${last_server}/a${space_num}- \"${Server}\"" /etc/openclash/config.yaml 2>/dev/null
fi
last_server="$Server"
count=$(expr "$count" + 1)
done

if [ "$num" -lt "$nums" ]; then
while [ "$count" -le "$nums" ]
do
   Servers=$(sed -n "${count}p" /tmp/Proxy_Servers |sed 's/\\/#d#/g' 2>/dev/null)
   sed -i "/${Servers}/d" "/etc/openclash/config.yaml" 2>/dev/null
   count=$(expr "$count" + 1)
done
fi
sed -i 's/#d#/\\/g' /etc/openclash/config.yaml 2>/dev/null
sed -i 's/#spas#/ /g' /etc/openclash/config.yaml 2>/dev/null
sed -i 's/#tab#/	/g' /etc/openclash/config.yaml 2>/dev/null
}

#创建配置文件
echo "开始更新配置文件..." >$START_LOG
echo "Proxy:" >$SERVER_FILE
config_load "openclash"
config_foreach yml_servers_set "servers"
echo "Proxy Group:" >>$SERVER_FILE
rule_sources=$(uci get openclash.config.rule_sources 2>/dev/null)
egrep '^ {0,}-' $SERVER_FILE |grep name: |awk -F 'name: ' '{print $2}' |sed 's/,.*//' >/tmp/Proxy_Server 2>&1
sed -i "s/^ \{0,\}/  - /" /tmp/Proxy_Server 2>/dev/null #添加参数

if [ -z "$(grep "^ \{0,\}Proxy:" /etc/openclash/config.yaml)" ] || [ -z "$(grep "^ \{0,\}Proxy Group:" /etc/openclash/config.yaml)" ]; then
   echo "未找到配置文件，开始使用ConnersHua规则创建..." >$START_LOG
   uci set openclash.config.rule_sources="ConnersHua"
   uci set openclash.config.rule_source="ConnersHua"
   uci commit openclash
   rule_sources="ConnersHua"
fi

if [ "$rule_sources" = "ConnersHua" ]; then
echo "使用ConnersHua规则创建中..." >$START_LOG
cat >> "$SERVER_FILE" <<-EOF
- name: Auto - UrlTest
  type: url-test
  proxies:
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  url: http://www.gstatic.com/generate_204
  interval: "600"
- name: Proxy
  type: select
  proxies:
  - Auto - UrlTest
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Domestic
  type: select
  proxies:
  - DIRECT
  - Proxy
- name: Others
  type: select
  proxies:
  - Proxy
  - DIRECT
  - Domestic
- name: AdBlock
  type: select
  proxies:
  - REJECT
  - DIRECT
  - Proxy
- name: Apple
  type: select
  proxies:
  - DIRECT
  - Proxy
- name: AsianTV
  type: select
  proxies:
  - DIRECT
  - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: GlobalTV
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
uci set openclash.config.GlobalTV="GlobalTV"
uci set openclash.config.AsianTV="AsianTV"
uci set openclash.config.Proxy="Proxy"
uci set openclash.config.Apple="Apple"
uci set openclash.config.AdBlock="AdBlock"
uci set openclash.config.Domestic="Domestic"
uci set openclash.config.Others="Others"
elif [ "$rule_sources" = "lhie1" ]; then
echo "使用lhie1规则创建中..." >$START_LOG
cat >> "$SERVER_FILE" <<-EOF
- name: Auto - UrlTest
  type: url-test
  proxies:
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  url: http://www.gstatic.com/generate_204
  interval: "600"
- name: Proxy
  type: select
  proxies:
  - Auto - UrlTest
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Domestic
  type: select
  proxies:
  - DIRECT
  - Proxy
- name: Others
  type: select
  proxies:
  - Proxy
  - DIRECT
  - Domestic
- name: AsianTV
  type: select
  proxies:
  - DIRECT
  - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: GlobalTV
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
uci set openclash.config.GlobalTV="GlobalTV"
uci set openclash.config.AsianTV="AsianTV"
uci set openclash.config.Proxy="Proxy"
uci set openclash.config.Domestic="Domestic"
uci set openclash.config.Others="Others"
elif [ "$rule_sources" = "ConnersHua_return" ]; then
echo "使用ConnersHua回国规则创建中..." >$START_LOG
cat >> "$SERVER_FILE" <<-EOF
- name: Auto - UrlTest
  type: url-test
  proxies:
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  url: http://www.gstatic.com/generate_204
  interval: "600"
- name: Proxy
  type: select
  proxies:
  - Auto - UrlTest
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Others
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
uci set openclash.config.Proxy="Proxy"
uci set openclash.config.Others="Others"
fi
if [ "$rule_sources" != "0" ]; then
   echo "Rule:" >>$SERVER_FILE
   uci commit openclash
   cat $SERVER_FILE > "/etc/openclash/config.yaml" 2>/dev/null
else
   echo "正在更新配置文件服务器节点信息..." >$START_LOG
   awk '/Proxy:/,/Proxy Group:/{print}' /etc/openclash/config.yaml 2>/dev/null |egrep '^ {0,}-' |grep name: |awk -F 'name: ' '{print $2}' |sed 's/,.*//' |sed 's/\"//g' >/tmp/Proxy_Servers 2>&1
   sed -i 's/\"//g' /tmp/Proxy_Server |sed 's/^ \{0,\}- //g' 2>/dev/null
   
   sed -i '/^ \{0,\}Proxy:/i\#change server#' "/etc/openclash/config.yaml" 2>/dev/null
   sed -i '/^ \{0,\}Proxy:/,/^ \{0,\}Proxy Group:/d' "/etc/openclash/config.yaml" 2>/dev/null
   
   yml_servers_change
   
   sed -i '/#change server#/r/tmp/yaml_servers.yaml' "/etc/openclash/config.yaml" 2>/dev/null
   sed -i '/#change server#/d' "/etc/openclash/config.yaml" 2>/dev/null
fi
echo "配置文件更新完成！" >$START_LOG
rm -rf $SERVER_FILE 2>/dev/null
rm -rf /tmp/Proxy_Server 2>/dev/null
rm -rf /tmp/Proxy_Servers 2>/dev/null
/etc/init.d/openclash restart >/dev/null 2>&1 &