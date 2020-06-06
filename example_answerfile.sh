#!/bin/bash
#Answer file for unrealircd_0xfdb.sh

#Server Name:
XFDBSRVNAME=""  #This is the FQDN of this leaf, for example spider.0xfdb.xyz

#Server ID:
XFDBSRVID=""  #Every server in the same network must have a unique numerical identifier, like 420 for instance

#Owner Name:
XFDBOPFNAME=""  #For shit

#Owner Nick:
XFDBOPNAME=""  #For shit

#Owner Email:
XFDBOPEMAIL=""  #For shit

#Server Op:
XFDBOPNICK=""  #This is important, You need to put the server op's nick here

#Server Op password:
XFDBOPPASSWD="" #Server op password goes here

#Server Op virtual host:
XFDBOPVHOST=""  #server op's vhost, like nick@__ "underlined part" goes here. When they /OPER their vhost will change to this

#UnrealIRCd config options:
echo '#
BASEPATH="'$unrealbinary_dir'"
BINDIR="'$unrealbinary_dir'/bin"
DATADIR="'$unrealbinary_dir'/data"
CONFDIR="'$unrealbinary_dir'/conf"
MODULESDIR="'$unrealbinary_dir'/modules"
LOGDIR="'$unrealbinary_dir'/logs"
CACHEDIR="'$unrealbinary_dir'/cache"
DOCDIR="'$unrealbinary_dir'/doc"
TMPDIR="'$unrealbinary_dir'/tmp"
PRIVATELIBDIR="'$unrealbinary_dir'/lib"
PREFIXAQ="1"
MAXCONNECTIONS_REQUEST="auto"
NICKNAMEHISTORYLENGTH="2000"
DEFPERM="0600"
SSLDIR=""
REMOTEINC=""
CURLDIR=""
SHOWLISTMODES="1"
NOOPEROVERRIDE=""
OPEROVERRIDEVERIFY=""
GENCERTIFICATE="1"
EXTRAPARA=""
ADVANCED=""
' >$unrealsource_dir/config.settings

#UnrealIRCd SSL certificate creation options
orgname=$(echo $XFDBSRVNAME | sed s/".0xfdb.xyz"//) #grabs the "fully qualitied" Server Name from top of this file and removes our domain portion
echo '# create RSA certs - Server

[ req ]
# Note: RSA bits is ignored, as we use ECC now
default_bits = 2048
distinguished_name = req_dn
x509_extensions = cert_type

[ req_dn ]
countryName = Country Name
countryName_default             = US
countryName_min                 = 2
countryName_max                 = 2

stateOrProvinceName             = State/Province
stateOrProvinceName_default     = Michigan
stateOrProvinceName_value       = Michigan

localityName                    = Locality Name (eg, city)
localityName_value              = Detroit

0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = '$orgname'
0.organizationName_value        = '$orgname'

organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = 0xfdb.xyz
organizationalUnitName_value    = 0xfdb.xyz

0.commonName                    = Common Name (Full domain of your server)
0.commonName_value              = irc.0xfdb.xyz

[ cert_type ]
nsCertType = server'>$unrealsource_dir/extras/tls.cnf
