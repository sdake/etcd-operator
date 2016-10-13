#!/bin/bash -e
set -o nounset


osslbin="`which openssl`"

function openssl {
  trap "set +x" RETURN
  set -x
  $osslbin $@
}

CMD=${1:-}
if [[ $CMD == "new-private-key" ]];then
  openssl genrsa -out "$2" 2048
elif [[ $CMD == "new-csr" ]];then
  openssl req -new -sha256 -key "$2" -out "$3"
elif [[ $CMD == "new-ca-cert" ]];then
  openssl req -x509 -new -nodes -key "$2" -sha256 -days 1024 -out "$3"
elif [[ $CMD == "sign-csr-with-ca" ]];then
  printf "" > index.txt
  echo "01" > serial.txt
  openssl ca -config openssl-ca.cnf -policy signing_policy -extensions signing_req \
	  -keyfile "$2" -cert "$3" -out "$5"  -infiles "$4"
elif [[ $CMD == "csr-info" ]];then
  openssl req -text -noout -in "$2"
elif [[ $CMD == "cert-info" ]];then
  if [[ "${2:-}" == "" ]];then
    echo "usage: $0 $CMD <path-to-cert>"
    exit 1
  fi
  openssl x509 -text -noout -in "$2"
elif [[ $CMD == "verify-cert-against-ca" ]];then
  openssl verify -verbose -CAfile "$2" "$3"
else
  set +x
  cat <<EOF
available commands:

  new-private-key <path-to-priv-key>
  new-csr <path-to-priv-key> <path-to-csr>
  new-ca-cert <path-to-ca-key> <path-to-cert>
  sign-csr-with-ca <path-to-ca-key> <path-to-ca-cert> <path-to-csr> <path-to-signed-cert>

  # validation
  csr-info <path-to-csr>
  cert-info <path-to-cert>
  verify-cert-against-ca <path-to-ca-cert> <path-to-signed-cert>

EOF
fi


