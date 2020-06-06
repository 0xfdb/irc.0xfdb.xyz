#1/bin/bash
#Answer file for unrealircd_0xfdb.sh

#Server Name:
XFDBSRVNAME=""
#Server ID:
XFDBSRVID=""
#Owner Name:
XFDBOPFNAME=""
#Owner Nick:
XFDBOPNAME=""
#Owner Email:
XFDBOPEMAIL=""
#Server Op:
XFDBOPNICK=""
#Server Op password:
XFDBOPPASSWD=""
#Server Op vhost:
XFDBOPVHOST=""

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
