#!/bin/bash

if [ "${SEC_RULE_ENGINE}" != "" ]; then
  sed -i".bak" "s/SecRuleEngine On/SecRuleEngine ${SEC_RULE_ENGINE}/" /etc/httpd/modsecurity.d/modsecurity.conf
  echo "SecRuleEngine set to '${SEC_RULE_ENGINE}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT}" != "" ]; then
  sed -i".bak" "s/SecPcreMatchLimit 1000/SecPcreMatchLimit ${SEC_PRCE_MATCH_LIMIT}/" /etc/httpd/modsecurity.d/modsecurity.conf
  echo "SecPcreMatchLimit set to '${SEC_PRCE_MATCH_LIMIT}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT_RECURSION}" != "" ]; then
  sed -i".bak" "s/SecPcreMatchLimitRecursion 1000/SecPcreMatchLimitRecursion ${SEC_PRCE_MATCH_LIMIT_RECURSION}/" /etc/httpd/modsecurity.d/modsecurity.conf
  echo "SecPcreMatchLimitRecursion set to '${SEC_PRCE_MATCH_LIMIT_RECURSION}'"
fi

if [ "${PROXY_UPSTREAM_HOST}" != "" ]; then
  sed -i".bak" "s/127.0.0.1:3000/${PROXY_UPSTREAM_HOST}/g" /etc/httpd/conf.d/proxy.conf
  echo "Upstream host set to '${PROXY_UPSTREAM_HOST}'"
fi

if [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "OFF" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "No" ]; then
  sed -i".bak" "s,^Header always append X-Frame-Options SAMEORIGIN$,Header always append X-Frame-Options ${PROXY_HEADER_X_FRAME_OPTIONS},g" /etc/httpd/conf.d/proxy.conf
  echo "X-Frame-Options set to '${PROXY_HEADER_X_FRAME_OPTIONS}'"
else
  sed -i".bak" "s/^Header always append X-Frame-Options SAMEORIGIN$//g" /etc/httpd/conf.d/proxy.conf
  echo "X-Frame-Options disabled"
fi

names=`env | grep SEC_RULE_BEFORE_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/httpd/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
  done <<< "$names"
fi
echo "REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf"
cat /etc/httpd/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

names=`env | grep SEC_RULE_AFTER_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/httpd/modsecurity.d/owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
  done <<< "$names"
fi
echo "RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf"
cat /etc/httpd/modsecurity.d/owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

echo "Adjust access and error logs, shall go to stdout and stderr respectively"
sed -i".bak" "s,CustomLog \"logs/access_log\" combined,CustomLog \"/dev/stdout\" combined," /etc/httpd/conf/httpd.conf
sed -i".bak" "s,ErrorLog \"logs/error_log\",ErrorLog \"/dev/stderr\"," /etc/httpd/conf/httpd.conf

echo "Starting httpd"
exec httpd -D FOREGROUND
