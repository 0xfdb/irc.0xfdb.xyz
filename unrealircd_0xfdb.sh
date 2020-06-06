#!/bin/bash
#written by f0ur0ne
script_version="0.5"
base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function prepareircdsource {
	echo "Downloading latest version of UnrealIRCd..."
	base_gzip=$(wget --trust-server-names https://www.unrealircd.org/downloads/unrealircd-latest.tar.gz 2>&1 | grep "Saving to" | cut -c 12- | tr -d "‘’")
	tar xzvf $base_gzip
	rm "$base_dir/$base_gzip"
	source_dir=$(ls $base_dir | grep unrealircd- | sed '/gz$/d')
	unrealsource_dir="$base_dir/$source_dir"
	unrealbinary_dir="$base_dir/unrealircd"
	BASEPATH=$unrealbinary_dir
}

function patch_fakelag {
	echo "Applying fakelag patch..."
	echo "--- ./include/config.h	2020-05-29 02:56:40.000000000 -0400
	+++ configtest.h	2020-06-04 21:40:53.028844841 -0400
	@@ -126,7 +126,7 @@
	  * Common usage for this are: a trusted bot ran by an IRCOp, that you only
	  * want to give 'flood access' and nothing else, and other such things.
	  */
	-//#undef FAKELAG_CONFIGURABLE
	+#define FAKELAG_CONFIGURABLE
	 
	 /* The default value for class::sendq */
	 #define DEFAULT_SENDQ	3000000
	-
	" > $unrealsource_dir/fakelag.patch
	patch $unrealsource_dir/include/config.h $unrealsource_dir/fakelag.patch
}

function check_deps {
	libssl_true=$(ldconfig -p | grep libssl3)
	c-ares_true=$(ldconfig -p | grep libcares)
	nsl_true=$(ldconfig -p | grep libnsl)
	pcre2_true=$(ldconfig -p | grep pcre2)
	distro=$(cat /etc/*-release | head -n1)
	if [ -z $libssl_true ] || [ -z $c-ares_true ] || [ -z $nsl_true ]; then
		echo "You are missing a build dependency..."
		echo "Checking distro..."
		if [ "$distro" = 'NAME="void"' ]; then
			echo "Void Linux - Checking with xbps"
			echo "Ensuring base-devel and LibreSSL dev packages are installed..."
			sudo xbps-install -S base-devel libressl-devel
		fi
		if [ "$distro" = 'NAME="Arch Linux"' ]; then
			echo "Arch Linux - Checking with pacman"
			echo "Ensuring base-devel meta and OpenSSL packages are installed..."
			sudo pacman -S base-devel openssl
		fi
		if [ "$distro" = 'NAME="Linux Mint"' ] || [ "$distro" = 'PRETTY_NAME="Debian GNU/Linux 10 (*)"' ]; then
			echo "Debian based Linux - Checking with apt"
			echo "Ensuring build-essential and OpenSSL packages are installed..."
			sudo apt install build-essential openssl
		fi
		if [ "$distro" = 'NAME="void"' ] || [ "$distro" = 'NAME="Arch Linux"' ] || [ "$distro" = 'NAME="Linux Mint"' ] || [ "$distro" = 'PRETTY_NAME="Debian GNU/Linux 10 (*)"' ]; then
			echo "You are running an unsupported distro for the automatic installation of build dependencies..."
			echo "Make sure you have the following packages installed:"
			echo " OpenSSL or LibreSSL development package"
			echo " c-ares"
			echo " nsl"
			echo " pcre2"
			echo ""
			echo "Manually verify all required dependencies are met then type build and hit enter..."
			read manually_checked
			if [ "$manually_checked" = "build" ]; then
				echo "Manually verified dependencies, Proceeding..."
			fi
		fi
	else
		echo "All build dependencies are satisfied..."
	fi
}

function build_unreal {
	echo "Starting UnrealIRCd config..."
	$unrealsource_dir/Config
	echo "Config done, lets compile and install..."
	make
	make install
}

function freshconf {
	echo "Overwriting conf..."
	mv $unrealbinary_dir/conf/unrealircd.conf $unrealbinary_dir/conf/unrealircd.conf.old
	cp $unrealbinary_dir/conf/examples/example.conf $unrealbinary_dir/conf/unrealircd.conf
}

function getconf_info {
	echo ""
	echo "We need some info to add to our config."
	echo "What is your servers FQDN? (example: ircX.0xfdb.xyz)"
	read XFDBSRVNAME
	echo ""
	echo "What should the server ID be? (Must be unique in network, example: 00x *numeric 3 digits*)"
	read XFDBSRVID
	echo ""
	echo "What is your full name (for server info)?"
	read XFDBOPFNAME
	echo ""
	echo "What is your nick name (for server info)?"
	read XFDBOPNAME
	echo ""
	echo "What is your email address (for server info)?"
	read XFDBOPEMAIL
	echo ""
	echo "What is the Nick that should be server OP?"
	read XFDBOPNICK
	echo ""
	echo "What is the password that $XFDBOPNICK should use to become server OP?"
	read XFDBOPPASSWD
	echo ""
	echo "When $XFDBOPNICK authenticates as server OP their vhost changes -"
	echo "What would you like the vhost for $XFDBOPNICK to be after they /OPER? (example: $XFDBSRVNAME or just 0xfdb.xyz)"
	read XFDBOPVHOST
	echo ""
	echo "OK!"
	echo ""
}
function printconf_info {
	echo "The following options have been selected:"
	echo " Server Name:	$XFDBSRVNAME"
	echo " Server ID:	$XFDBSRVID"
	echo " Owner Name:	$XFDBOPFNAME"
	echo " Owner Nick:	$XFDBOPNAME"
	echo " Owner Email:	$XFDBOPEMAIL"
	echo " Server Op:	$XFDBOPNICK"
	echo " S-Op passwd:	$XFDBOPPASSWD *this gets stored in clear text in your conf*"
	echo " S-Op vhost:	$XFDBOPVHOST"
	echo ""
	if [ "$script_interactive" == "y" ]; then
		echo "Is all that right? (Y/n)"
		read getconf_yn
		if [ "$getconf_yn " = "n" ] || [ "$getconf_yn " = "" ]; then
			getconf_info
		fi
	fi
}

function writeconf_patch {
	echo '6,8c6,8
	<  * Important: All lines, except { and } end with an ;
	<  * This is very important, if you miss a ; somewhere then the
	<  * configuration file parser will complain and the file will not
	---
	>  * Important: All lines, except the opening { line, end with an ;
	>  * including };. This is very important, if you miss a ; somewhere then
	>  * the configuration file parser will complain and your file will not
	61,64c61,64
	< 	name "irc.example.org";
	< 	info "ExampleNET Server";
	< 	sid "001";
	< }
	---
	> 	name "'$XFDBSRVNAME'";
	> 	info "0xfdb.xyz";
	> 	sid "'$XFDBSRVID'";
	> };
	70,73c70,73
	< 	"Bob Smith";
	< 	"bob";
	< 	"email@example.org";
	< }
	---
	> 	"'$XFDBOPFNAME'";
	> 	"'$XFDBOPNAME'";
	> 	"'$XFDBOPEMAIL'";
	> };
	88,90c88,93
	< 	sendq 200k;
	< 	recvq 8000;
	< }
	---
	> 	sendq 1M;
	> 	recvq 32k;
	> 	options {
	> 	nofakelag;
	> };
	> };
	98,99c101,105
	< 	recvq 8000;
	< }
	---
	> 	recvq 32k;
	> 	options {
	> 	nofakelag;
	> };
	> };
	108c114
	< }
	---
	> };
	122c128
	< }
	---
	> };
	133c139
	< }
	---
	> };
	150c156
	< oper bobsmith {
	---
	> oper '$XFDBOPNICK' {
	153c159
	< 	password "test";
	---
	> 	password "'$XFDBOPPASSWD'";
	161,162c167,182
	< 	vhost netadmin.example.org;
	< }
	---
	> 	vhost '$XFDBOPVHOST';
	> };
	> 
	> oper NickServ {
	> 	class opers;
	> 	mask *@*;
	> 	password "'GET_ME_FROM_f0ur0ne$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 28 | head -n 1)GET_ME_FROM_f0ur0ne'";
	> 	/* Oper permissions are defined in an "operclass" block.
	> 	 * See https://www.unrealircd.org/docs/Operclass_block
	> 	 * UnrealIRCd ships with a number of default blocks, see
	> 	 * the article for a full list. We choose "netadmin" here.
	> 	 */
	> 	operclass services-admin;
	> 	swhois "Nickname Service Bot";
	> 	vhost services.0xfdb.xyz;
	> };
	175,176c195,196
	<  *   }
	<  * }
	---
	>  *   };
	>  * };
	183c203
	< }
	---
	> };
	189,190c209,210
	< 	options { tls; }
	< }
	---
	> 	options { tls; };
	> };
	196,197c216,217
	< 	options { tls; serversonly; }
	< }
	---
	> 	options { tls; serversonly; };
	> };
	203c223
	<  *       listen { ip 1.2.3.4; port 6667; }
	---
	>  *       listen { ip 1.2.3.4; port 6667; };
	211c231
	< link hub.example.org
	---
	> link hub.mynet.org
	213,222c233,242
	< 	incoming {
	< 		mask *@something;
	< 	}
	< 
	< 	outgoing {
	< 		bind-ip *; /* or explicitly an IP */
	< 		hostname hub.example.org;
	< 		port 6900;
	< 		options { tls; }
	< 	}
	---
	> incoming {
	> 	mask *@something;
	> };
	> 
	> outgoing {
	> 	bind-ip *; /* or explicitly an IP */
	> 	hostname hub.mynet.org;
	> 	port 6900;
	> 	options { tls; };
	> };
	229,230c249,250
	< 	class servers;
	< }
	---
	> class servers;
	> };
	236c256
	< link services.example.org
	---
	> link services.mynet.org
	240c260
	< 	}
	---
	> 	};
	245c265
	< }
	---
	> };
	252,253c272,273
	< 	services.example.org;
	< }
	---
	> 	services.mynet.org;
	> };
	262c282
	< }
	---
	> };
	281,282c301,302
	< 	}
	< }
	---
	> 	};
	> };
	290c310,328
	< include "aliases/anope.conf";
	---
	> /* include "aliases/anope.conf"; */
	> 
	> alias ns {
	> 	format "^[^#]" {
	> 		target NickServ;
	> 		type normal;
	> 		parameters "%1-";
	> 	};
	> 	type command;
	> };
	> 
	> alias nickserv {
	> 	format "^[^#]" {
	> 		target NickServ;
	> 		type normal;
	> 		parameters "%1-";
	> 	};
	> 	type command;
	> };
	296c334
	< }
	---
	> };
	304c342
	< }
	---
	> };
	310c348
	< }
	---
	> };
	316c354
	< }
	---
	> };
	324c362
	< }
	---
	> };
	329c367
	< }
	---
	> };
	342c380
	< }
	---
	> };
	348c386
	< }
	---
	> };
	354c392
	< }
	---
	> };
	361c399
	< }
	---
	> };
	376c414
	< }
	---
	> };
	398,399c436,437
	<                 reply { 3; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; }
	<         }
	---
	>                 reply { 3; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; };
	>         };
	403c441
	< }
	---
	> };
	416,417c454,455
	<                 reply { 1; 4; 5; }
	<         }
	---
	>                 reply { 1; 4; 5; };
	>         };
	421c459
	< }
	---
	> };
	428,431c466,469
	< 	network-name 		"ExampleNET";
	< 	default-server 		"irc.example.org";
	< 	services-server 	"services.example.org";
	< 	stats-server 		"stats.example.org";
	---
	> 	network-name 		"0xfdb.xyz";
	> 	default-server 		"irc.0xfdv.xyz";
	> 	services-server 	"services.0xfdb.xyz";
	> 	stats-server 		"stats.0xfdb.xyz";
	445,448c483,486
	< 		"and another one";
	< 		"and another one";
	< 	}
	< }
	---
	> 		"'GET_ME_FROM_f0ur0ne$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 9 | head -n 1)'";
	> 		"'GET_ME_FROM_f0ur0ne$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 9 | head -n 1)'";
	> 	};
	> };
	453c491
	< 	kline-address "set.this.to.email.address"; /* e-mail or URL shown when a user is banned */
	---
	> 	kline-address "idk@0xfdb.xyz"; /* e-mail or URL shown when a user is banned */
	461c499
	< 	}
	---
	> 	};
	481c519
	< 	}
	---
	> 	};
	489c527
	< 	}
	---
	> 	};
	499c537
	< 		}
	---
	> 		};
	504c542
	< 		}
	---
	> 		};
	513c551
	< 		//}
	---
	> 		//};
	516,518c554,556
	< 		//}
	< 	}
	< }
	---
	> 		//};
	> 	};
	> };
	549c587
	< 		}
	---
	> 		};
	561c599
	< 		}
	---
	> 		};
	573,575c611,613
	< 		}
	< 	}
	< }
	---
	> 		};
	> 	};
	> };'>$unrealbinary_dir/0xfdb_config.patch
	echo ""
	echo "Patching conf for 0xfdb network..."
	patch $unrealbinary_dir/conf/unrealircd.conf $unrealbinary_dir/0xfdb_config.patch
}

function start_unreal {
	echo ""
	echo "Starting unrealircd with ./unrealircd start"
	$unrealbinary_dir/unrealircd start
	echo ""
}

function end_msg {
	sleep 2
	echo ""
	echo "There are a few things you need from f0ur0ne that must be manually added to ./config/unrealircd.conf"
	echo "All that stuff is marked with GET_ME_FROM_f0ur0ne in your conf file."
	echo "Also dont forget Your password exists in cleartext in the following files:"
	echo "	$unrealbinary_dir/0xfdb_config.patch"
	echo "	$unrealbinary_dir/config/unrealircd.conf"
	echo ""
}

function info {
		echo "UnrealIRCd_0xfdb.sh version $script_version"
		echo "Copyright (c) 2020 0xfdb Industries"
		echo "Written by f0ur0ne"
		echo ""
}
function usage {
		echo "Build script / CI-ish system for creating new irc.0xfdb.xyz leaf servers"
		echo "It also keeps our leaf servers IRCd, shared network settings, and shared build options up to date."
		echo ""
		echo " Usage: $ unrealircd_0xfdb.sh [option1] [option2] [...]"
		echo " Options:"
		echo "	-n --newconf	Creates a new config from template (Useful for new servers)"
		echo "	-f --file=path/to/file		Path to answer file (Disables most interaction, file must be in current dir)"
		echo "	-i --interactive			Forces interaction (This is how the script runs without options passed)"
		echo "	-h --help				Displays this help message"
		echo ""
		echo "Send bug reports, questions, discussions to f0ur0ne on irc.0xfdb.xyz or via email at <admin@0xfdb.xyz>"
		echo "and/or open issues at https://github.com/f0ur0ne/irc.0xfdb.xyz"
}

function main {
	info
	if [ "$script_interactive" == "y" ]; then
		echo "Running Interactively..."
		if [ "$new_configfile" == "" ]; then
			echo "Do you want to generate a fresh config file? (Y/n)"
			read new_configfile
		fi
	fi
	prepareircdsource
	cd $unrealsource_dir
		patch_fakelag
		check_deps
		build_unreal
	cd $unrealbinary_dir
		if [ "$new_configfile" == "y" ]; then
			echo "Option -n passed, creating fresh config file..."
			freshconf
				if [ "$script_interactive" == "y" ]; then
					getconf_info
				fi
				if [ "$file_given" == "y" ]; then
					source "$file_path"
				fi
			printconf_info
			writeconf_patch
		else
			echo "Keeping old conf..."
			if [ "$file_given" == "y" ]; then
				echo "Unneeded option --newconf was passed... ignored."
			fi
		fi
		start_unreal & end_msg
		exit
}

#Parsing options and setting variables
if [ "$1" == "" ]; then
	info
	echo "This script accepts options to automate most tasks, you can view them by running ./unrealircd_0xfdb.sh --help "
	echo "Would you like to continue as interactive? (Y/n)"
	read script_interactive
	echo ""
	if [ "$script_interactive" == "n" ]; then
		echo "exiting."
		exit
	else
		script_interactive="y"
		main
	fi
else
	for arg in "$@"; do
		if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
			info
			usage
			exit
		fi
		if [ "$arg" == "--interactive" ] || [ "$arg" == "-i" ]; then
			script_interactive="y"
		fi
		if [ "$arg" == "--newconf" ] || [ "$arg" == "-n" ]; then
			new_configfile="y"
		fi
		if [[ "$arg" == "--file="* ]] || [[ "$arg" == "-f="* ]]; then
			file_name=$(echo "$arg" | sed s/"-f="// | sed s/"--file="//)
				if [ "$file_name" == "" ]; then
					info
					echo "There is something wrong with the path you sent for [--file,-f] or your option syntax."
					echo "Refer to --help for info on usage."
					exit
				else
					file_given="y"
					file_path="$base_dir/$file_name"
				fi
		fi
	done
	main
fi

info
echo "Oops... wtf did u do?"
echo "Refer to --help for info on usage."
exit
