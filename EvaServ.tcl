##############################################################
# ███████╗██╗   ██╗ █████╗ ███████╗███████╗██████╗ ██╗   ██╗ #
# ██╔════╝██║   ██║██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║ #
# █████╗  ██║   ██║███████║███████╗█████╗  ██████╔╝██║   ██║ #
# ██╔══╝  ╚██╗ ██╔╝██╔══██║╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝ #
# ███████╗ ╚████╔╝ ██║  ██║███████║███████╗██║  ██║ ╚████╔╝  #
# ╚══════╝  ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝   #
##############################################################
#
#	Auteur	:
#		-> ZarTek (ZarTek.Creole@GMail.Com)
#
#	Website :
#		-> github.com/ZarTek-Creole/TCL-EvaServ
#
#	Support	:
#		-> github.com/ZarTek-Creole/TCL-EvaServ/issues
#
#	Docs	:
#		-> github.com/ZarTek-Creole/TCL-EvaServ/wiki
#
#	LICENSE :
#		-> GNU General Public License v3.0
#		-> github.com/ZarTek-Creole/TCL-EvaServ/blob/main/LICENSE.txt
#
#	Code origine:
#		-> TiSmA (TiSmA@eXolia.fr)
#
##############################################################

if { [info commands ::EvaServ::uninstall] eq "::EvaServ::uninstall" } { ::EvaServ::uninstall }
namespace eval ::EvaServ {
	variable config
	variable SCRIPT
	array set config {
		"timerco"			"30"
		"timerdem"			"5"
		"timerinit"			"10"
		"counter"			"0"
		"dem"				"0"
		"init"				"0"
		"console"			"1"
		"login"				"1"
		"protection"		"1"
		"debug"				"0"
		"aclient"			"0"
	}
	array set SCRIPT {
		"name"				"EvaServ Service"
		"version"			"1.5.20220626"
		"auteur"			"ZarTek"
		
	}
	set SCRIPT(path_dir)	[file dirname [info script]]
	array set DBU_INFO		""
	array set UID_DB		""
	set scoredb(last)		""
	set VARS_LIST			[list 				\
						"UPLINK"				\
						"SERVICE_BOT"			\
						"SERVICE"];
	
	set VARS_UPLINK			[list 				\
						"hostname"			\
						"uplink_ssl"			\
						"uplink_port"			\
						"uplink_password"		\
						"serverinfo_name"		\
						"serverinfo_id"			\
						"uplink_useprivmsg"		\
						"uplink_debug"			\
						"service_nick"			\
						"service_user"			\
						"service_host"			\
						"service_gecos"			\
						"service_modes"			\
						"service_channel"		\
						"service_chanmodes"		\
						"service_usermodes"		\
						"prefix"				\
						"rnick"					\
						"duree"					\
						"rclient"				\
						"rhost"					\
						"rident"				\
						"rreal"					\
						"ruser"					\
						"raison"				\
						"console_com"			\
						"console_deco"			\
						"console_txt"];
	

	proc uninstall {args} {
		variable config
		variable CONNECT_ID
		variable SCRIPT

		putlog "Désallocation des ressources de \002${SCRIPT(name)}\002..." info
		${CONNECT_ID} destroy
		foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range [namespace current] 2 end]]*] " \{?(::)?${ns}"] {
			unbind [lindex ${binding} 0] [lindex ${binding} 1] [lindex ${binding} 2] [lindex ${binding} 4]
		}
		# Arrêt des timers en cours.
		foreach running_timer [timers] {
			if { [::tcl::string::match "*[namespace current]::*" [lindex ${running_timer} 1]] } { killtimer [lindex ${running_timer} 2] }
		}
		namespace delete ::EvaServ
	}
	
	foreach {color_name value} { red 1 yellow 3 cyan 5 magenta 6 blue 4 green 2 } {
		proc color_${color_name} {} "return \033\\\[01\\;3${value}m"
	}
	proc colors_end {} {
		return \033\[\;0m
	}
	proc putlog { text {level_name ""} {text_name ""} } {
		variable SCRIPT
		if { ${text_name} == "" } {
			if { ${level_name} != "" } {
				set text_name " - ${level_name}"
			} else {
				set text_name ""
			}
		} else {
			set text_name " - ${text_name}"
		}
		switch -nocase ${level_name} {
			"error"		{ puts "[color_red]\[${SCRIPT(name)}${text_name}\][colors_end] [color_blue]$text[colors_end]" }
			"warning"	{ puts "[color_yellow]\[${SCRIPT(name)}${text_name}\][colors_end] [color_blue]$text[colors_end]" }
			"notice"	{ puts "[color_cyan]\[${SCRIPT(name)}${text_name}\][colors_end] [color_blue]$text[colors_end]" }
			"debug"		{ puts "[color_magenta]\[${SCRIPT(name)}${text_name}\][colors_end] [color_blue]$text[colors_end]" }
			"info"		{ puts "[color_blue]\[${SCRIPT(name)}${text_name}\][colors_end] [color_blue]$text[colors_end]" }
			"success"	{ puts "[color_green]\[${SCRIPT(name)}${text_name}\][colors_end] [color_blue]$text[colors_end]" }
			default		{ puts "\[${SCRIPT(name)}${text_name}\] [color_blue]$text[colors_end]" }
		}
	}
}
proc ::EvaServ::INIT { } {
	variable SCRIPT
	variable UPLINK
	variable SERVICE
	variable SERVICE_BOT
	variable FloodControl
	variable commands
	variable config
	
	if { [ catch { source [Script:Get:Directory]/EvaServ.conf } err ] } { 
		if { [file exists [Script:Get:Directory]/EvaServ.Example.conf] } {
			putlog "Vous devez configurer EvaServ. Renommer EvaServ.Example.conf en EvaServ.conf et editez-le" error	
			exit
		}
		putlog "Probleme de chargement de '[Script:Get:Directory]/EvaServ.conf':\n$err" error
		exit
	} 
	bind time	- "00 00 * * *"	dbback
	#bind evnt	n init-server	initialisation
	bind evnt	n prerestart	evenement
	bind evnt	n sighup		evenement
	bind evnt	n sigterm		evenement
	bind evnt	n sigill		evenement
	bind evnt	n sigquit		evenement
	bind evnt	n prerehash		prerehash
	bind evnt	n rehash		rehash
	bind dcc	n eva			eva
	bind dcc	n evaconnect	connect
	bind dcc	n evadeconnect	deconnect
	bind dcc	n evauptime		uptime
	bind dcc	n evaversion	version
	bind dcc	n evainfos		infos
	bind dcc	n evadebug		debug
	
	Config:File:Check
	if { ![file isdirectory "[Script:Get:Directory]/db"] } { file mkdir "[Script:Get:Directory]/db" }

	# generer les db
	Database:initialisation [list \
						"gestion"	\
						"chan"		\
						"client"	\
						"close"		\
						"salon"		\
						"ident"		\
						"real"		\
						"host"		\
						"nick"		\
						"trust"		
					];
	if {
		[file exists [Script:Get:Directory]/TCL-PKG-IRCServices/ircservices.tcl] && \
			[catch { source [Script:Get:Directory]/TCL-PKG-IRCServices/ircservices.tcl } err]
	} {
		die "\[${SCRIPT(name)} - Erreur\] Chargement '[Script:Get:Directory]/TCL-PKG-IRCServices/ircservices.tcl' à échoué: ${err}";
	}
	if { [catch { package require IRCServices 0.0.1 }] } { putloglev o * "\00304\[${SCRIPT(name)} - erreur\]\003 ${SCRIPT(name)} nécessite le package IRCServices 0.0.1 (ou plus) pour fonctionner, Télécharger sur 'github.com/ZarTek-Creole/TCL-PKG-IRCServices'.\nLe chargement du script a été annulé." ; return }

	Database:Load:Data
	Service:Connexion
	putlog "v${SCRIPT(version)} par ${SCRIPT(auteur)} OK." success
}
proc ::EvaServ::Service:Connexion { } {
	variable config
	variable CONNECT_ID
	variable BOT_ID
	variable SERVICE
	variable SERVICE_BOT
	variable UPLINK
	
	if { ${UPLINK(mode_ssl)} == 1		} { set UPLINK(port) "+${UPLINK(port)}" }
	if { ${SERVICE(sid)} != ""	} { set config(uplink_ts6) 1 } else { set config(uplink_ts6) 0 }
	
	set CONNECT_ID [::IRCServices::connection]; # Creer une instance services
	putlog:info "Connexion du link service ${SERVICE(hostname)}"
	${CONNECT_ID} connect ${UPLINK(hostname)} ${UPLINK(port)} ${UPLINK(password)} ${config(uplink_ts6)} ${SERVICE(hostname)} ${SERVICE(sid)}; # Connexion de l'instance service
	if { ${SERVICE(mode_debug)} == 1} { ${CONNECT_ID} config logger 1; ${CONNECT_ID} config debug 1; }

	set BOT_ID [${CONNECT_ID} bot]; #Creer une instance bot dans linstance services
	
	putlog:info "Creation du bot service ${SERVICE_BOT(name)}"
	${BOT_ID} create ${SERVICE_BOT(name)} ${SERVICE_BOT(username)} ${SERVICE_BOT(hostname)} ${SERVICE_BOT(gecos)} ${SERVICE_BOT(mode_service)}]; # Creation d'un bot service
	${BOT_ID} join ${SERVICE_BOT(channel)}
	${BOT_ID} registerevent EOS {
		global ::EvaServ::config
		[sid] mode ${SERVICE_BOT(channel)} ${SERVICE_BOT(mode_channel)}
		if { ${SERVICE_BOT(mode_user)} != "" } { 
			[sid] mode ${SERVICE_BOT(channel)} ${SERVICE_BOT(mode_user)} ${SERVICE_BOT(name)}
		}
		
		
	}
	${BOT_ID} registerevent PRIVMSG {
		set cmd		[lindex [msg] 0]
		set data	[lrange [msg] 1 end]
		##########################
		#--> Commandes Privés <--#
		##########################
		# si [target] ne commence pas par # c'est un pseudo
		if { [string index [target] 0] != "#"} {
			IRC:CMD:MSG:PRIV [who2] [target] $cmd $data 
		}
		##########################
		#--> Commandes Salons <--#
		##########################
		# si [target] commence par # c'est un salon
		if { [string index [target] 0] == "#"} {
			IRC:CMD:MSG:PUB [who] [target] $cmd $data 
		}
	}; # Creer un event sur PRIVMSG
	
}
proc ::EvaServ::IRC:CMD:MSG:PRIV { NICK_SOURCE destination CMD_NAME CMD_VALUE } {
	variable config
	variable SCRIPT
	if { ![FloodControl:Check ${NICK_SOURCE}] } { return 0 }
	putlog "::EvaServ::IRC:CMD:MSG:PRIV ${NICK_SOURCE} $destination ${CMD_NAME} ${CMD_VALUE}"
	switch -nocase ${CMD_NAME} {
		"PING"	{
			SENT:NOTICE ${NICK_SOURCE} "\001PING ${CMD_VALUE}\001";
		}
		"TIME"	{
			SENT:NOTICE ${NICK_SOURCE} "\001TIME [clock format [clock seconds]]\001";
		}
		"VERSION"	{
			SENT:NOTICE ${NICK_SOURCE} "\001VERSION ${SCRIPT(name)} v${SCRIPT(version)} by $SCRIPT(auteur) © Visit: https://git.io/JOG1k\001";
		}
		"SOURCE"	{
			SENT:NOTICE ${NICK_SOURCE} "\001SOURCE https://git.io/JOG1k\001";
		}
		"FINGER"	{
			SENT:NOTICE ${NICK_SOURCE} "\001FINGER [string map {" " "_"} ${SCRIPT(name)}] ${SCRIPT(version)}\001";
		}
		"USERINFO"	{
			SENT:NOTICE ${NICK_SOURCE} "\001USERINFO [string map {" " "_"} ${SCRIPT(name)}] (v${SCRIPT(version)} - Visit: https://git.io/JOG1k)\001";
		}
		"CLIENTINFO"	{
			SENT:NOTICE ${NICK_SOURCE} "\001CLIENTINFO CLIENTINFO PING TIME VERSION FINGER USERINFO\001";
		}
		default		{
			if { [CMD:EXIST ${CMD_NAME}] } { 
				set SUB_CMD		[lindex ${CMD_VALUE} 0];
				if { ${CMD_NAME} == "help" && ${SUB_CMD} != "" } {
	 				if { [CMD:EXIST ${SUB_CMD}] } {
	 					Commands:Help ${NICK_SOURCE} ${CMD_VALUE}
	 				} else {
	 					SENT:MSG:TO:USER ${NICK_SOURCE} "Aide <b>${SUB_CMD}</b> Inconnue."
	 				}
	 			} else {
					putlog "::EvaServ::cmds ${CMD_NAME} ${NICK_SOURCE} ${CMD_VALUE}"
	 				cmds "${CMD_NAME} ${NICK_SOURCE} ${CMD_VALUE}"
	 			}
				Commands:Help ${NICK_SOURCE} ${CMD_VALUE}
			} else {
 				SENT:MSG:TO:USER ${NICK_SOURCE} "Commande <b>${CMD_NAME}</b> Inconnue."
			}
		}
	}
}
proc ::EvaServ::IRC:CMD:MSG:PUB { NICK_SOURCE destination cmd data } {
	variable config
	variable SCRIPT
	if { ![FloodControl:Check ${NICK_SOURCE}] } { return 0 }
	putlog "::EvaServ::IRC:CMD:MSG:PUB ${NICK_SOURCE} $destination $cmd $data"


	# "PRIVMSG" {
	# 	set vuser		[string tolower $user]
	# 	set robotUID	[string tolower [lindex $arg 2]]
	# 	set cmds		[string tolower [string trim [lindex $arg 3] :]]
	# 	set CMD_HELP	[string tolower [lindex $arg 4]]
	# 	set pcmds		[string trim $cmds $config(prefix)]
	# 	set data		[join [lrange $arg 4 end]]
	# 	if { [string toupper $robotUID] == [UID:CONVERT ${SERVICE_BOT(name)}] } {
			

			if { $cmds == "ping" } {
				SENT:MSG:TO:USER $user "\001PING [clock seconds]\001";
				return 0;
			} elseif { $cmds == "version" } {
				SENT:MSG:TO:USER $user "<c01>${SCRIPT(name)} ${SCRIPT(version)} by ${SCRIPT(auteur)}<c03>©";
				return 0;
				# verifie si c une command eva :

			} elseif { [CMD:EXIST $cmds] } {

				# si c help
				if { $cmds == "help" && ${CMD_HELP} != "" } {

					# verifie si c une command eva
					if { [CMD:EXIST ${CMD_HELP}] } {
						Commands:Help "${CMD_HELP} $user $data"
					} else {
						SENT:MSG:TO:USER $user "Aide <b>${CMD_HELP}</b> Inconnue."
					}
				} else {
					cmds "$cmds $user $data"
				}
			} else {
				SENT:MSG:TO:USER $user "Commande <b>$cmds</b> Inconnue."
			}
		}
		if { [string index $cmds 0] == $config(prefix) } {
			if { ![FloodControl:Check ${vuser}] } { return 0 }
			if { [CMD:EXIST $pcmds] } {
				if { $pcmds == "help" && ${CMD_HELP} != "" } {
					if { [CMD:EXIST ${CMD_HELP}] } {
						Commands:Help "${CMD_HELP} $user $data"
					}
				} else {
					cmds "$pcmds $user $data"
				}
			}
		}
	}
}
proc ::EvaServ::Config:File:Check { } {
	variable SCRIPT
	variable config
	variable FloodControl
	variable VARS_LIST
	foreach LIST_NAME ${VARS_LIST} {
		variable [subst VARS_${LIST_NAME}]
		if { ![info exists [subst VARS_${LIST_NAME}]] } {
				putlog "Listes de variables 'VARS_${LIST_NAME}' inexistante" error
				exit	
		}
		foreach VARS_NAME ${VARS_UPLINK} {
			set VAR_TMP ${LIST_NAME}(${VARS_NAME})
			putlog "... ${VAR_TMP}"
			if { ![info exists [return ${VAR_TMP}]] } {
				putlog "Configuration de ${SCRIPT(name)} Incorrecte... '${VAR_TMP}' Paramettre manquant" error
				exit
			}
			if { [set ${VAR_TMP}] == "" } {
				putlog "Configuration de ${SCRIPT(name)} Incorrecte... '${VAR_TMP}' Valeur vide" error
				exit
			}
		}
	}
	set FloodControl_LIST	[list 					\
								"Throttling"		\
								"IgnoreTime"];
	foreach CONF ${FloodControl_LIST} {
		putlog "[array get FloodControl]"
		if { ![info exists FloodControl($CONF)] } {
			putlog "Configuration de ${SCRIPT(name)} Incorrecte... 'FloodControl(${CONF})' Paramettre manquant" error
			exit
		}
		if { $FloodControl(${CONF}) == "" } {
			putlog "Configuration de ${SCRIPT(name)} Incorrecte... 'FloodControl(${CONF})' Valeur vide" error
			exit
		}
	}
}
proc ::EvaServ::Script:Get:Directory { } {
	variable SCRIPT;
	return ${SCRIPT(path_dir)}
}
proc ::EvaServ::Database:initialisation { LISTDB } {
	foreach DB_NAME $LISTDB {
		if { ![file exists "[Script:Get:Directory]/db/${DB_NAME}.db"] } {
			set FILE_PIPE	[open "[Script:Get:Directory]/db/${DB_NAME}.db" a+];
			close $FILE_PIPE
		}

	}
}
proc ::EvaServ::Database:Load:Data { } {
	variable config
	variable trust

	catch { open [Script:Get:Directory]/db/trust.db r } protection
	while { ![eof $protection] } {
		gets $protection hosts;
		if { $hosts != "" && ![info exists trust($hosts)] } { 
			set trust($hosts)	1
			putlog:info "L'host '$hosts' est chargement comme TRUST."
		}
	}
	catch { close $protection }
	catch { open [Script:Get:Directory]/db/gestion.db r } gestion
	while { ![eof $gestion] } {
		gets $gestion var2;
		if { $var2 != "" } { set [lindex $var2 0] [lindex $var2 1] }
	}
	catch { close $gestion }
}
proc ::EvaServ::putlog:info { MSG } {
	variable config
	if { [info exists config(putlog_info)] && $config(putlog_info) == 1 } { 
		putlog $MSG info
	}
}
proc ::EvaServ::SENT:NOTICE { DEST MSG } {
	variable BOT_ID
	${BOT_ID}	notice $DEST [FCT:apply_visuals $MSG]
}

proc ::EvaServ::SENT:PRIVMSG { DEST MSG } {
	variable BOT_ID
	${BOT_ID}	privmsg $DEST [FCT:apply_visuals $MSG]
}
proc ::EvaServ::SENT:MSG:TO:USER { DEST MSG } {
	variable config
	if { $SERVICE(use_privmsg) == 1 } {
		SENT:PRIVMSG $DEST $MSG;
	} else {
		SENT:NOTICE $DEST $MSG;
	}
}
proc ::EvaServ::FloodControl:Check { pseudo } {
	variable FloodControl
	if { ![info exists FloodControl(flood:${pseudo})] } {
		set FloodControl(flood:${pseudo})		1;
		utimer 3 [list ::EvaServ::FloodControl:NoticeUser ${pseudo}];
		# No-FLOOD
		return 1
	} elseif { $FloodControl(flood:${pseudo}) < ${FloodControl(Throttling)} } {
		incr FloodControl(flood:${pseudo})		1;
		# No-FLOOD
		return 1
	} else {
		if { ![info exists FloodControl(stopflood:$pseudo)] } { 
			set FloodControl(stopflood:$pseudo)		1 
		}
	}
	# FLOOD
	return 0
}
proc ::EvaServ::FloodControl:NoticeUser { pseudo }		{
	variable FloodControl
	if { [info exists FloodControl(stopflood:$pseudo)] } {
		SENT:MSG:TO:USER $pseudo "Vous êtes ignoré pendant $FloodControl(IgnoreTime) secondes.";
		utimer $FloodControl(IgnoreTime) [list ::EvaServ::FloodControl:Reset $pseudo];
	} else {
		unset FloodControl(flood:$pseudo)
	}
}
proc ::EvaServ::FloodControl:Reset { pseudo } {
	variable FloodControl
	if { [info exists FloodControl(stopflood:$pseudo)] }	{ unset FloodControl(stopflood:$pseudo) }
	if { [info exists FloodControl(flood:$pseudo)] }		{ unset FloodControl(flood:$pseudo) }
	SENT:MSG:TO:USER $pseudo "Vous n'êtes plus ignoré.";
	
}

proc ::EvaServ::authed { user cmd } {
	variable admins
	switch -exact [CMD:TO:LEVEL $cmd] {
		0 { return ok }
		1 {
			if { [info exists admins($user)] && [matchattr $admins($user) p] } {
				return ok
			} else {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0
			}
		}
		2 {
			if { [info exists admins($user)] && [matchattr $admins($user) o] } {
				return ok
			} else {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}
		}
		3 {
			if { [info exists admins($user)] && [matchattr $admins($user) m] } {
				return ok;
			} else {

				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}
		}
		4 {
			if { [info exists admins($user)] && [matchattr $admins($user) n] } {
				return ok;
			} else {

				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}
		}
		-1 {
			SENT:MSG:TO:USER $user "Command inconnue";
			return 0;
		}
		default {
			SENT:MSG:TO:USER $user "Niveau inconnue";
			return 0;
		}
	}
}
###################################################################################################################################################################################################

proc ::EvaServ::sent2socket { MSG } {
	variable config
	if { ${SERVICE(mode_debug)} } {
		putlog "Sent: $MSG"
	}
	putdcc ${config(idx)}  $MSG
}
proc ::EvaServ::sent2ppl { IDX MSG } {
	putdcc $IDX $MSG
}
proc ::EvaServ::SHOW:CMD:BY:LEVEL { DEST LEVEL } {
	variable commands
	set max				6;
	set l_espace		13;
	set CMD_LIST		""
	SENT:MSG:TO:USER $DEST "<c01>\[ Level [dict get $commands $LEVEL name] - Niveau $LEVEL \]"
	foreach CMD [lsort [dict get $commands $LEVEL cmd]] {
		lappend CMD_LIST	"<c02>[FCT:TXT:ESPACE:DISPLAY $CMD $l_espace]<c01>"
		if { [incr i] > $max-1 } {
			unset i
			SENT:MSG:TO:USER $DEST [join $CMD_LIST " | "];
			set CMD_LIST	""
		}
	}
	SENT:MSG:TO:USER $DEST [join $CMD_LIST " | "];
	SENT:MSG:TO:USER $DEST "<c>";
}
proc ::EvaServ::SHOW:CMD:DESCRIPTION:BY:LEVEL { DEST LEVEL } {
	variable commands
	set max				6;
	set l_espace		13;
	set CMD_LIST		""
	SENT:MSG:TO:USER $DEST "<c01>\[ Level [dict get $commands $LEVEL name] - Niveau $LEVEL \]"
	foreach CMD [lsort [dict get $commands $LEVEL cmd]] {
		set CMD_LOWER	[string tolower $CMD];
		set CMD_UPPER	[string toupper $CMD];
		if { [info commands [subst ::EvaServ::help:description:${CMD_LOWER}]] != "" } {
			SENT:MSG:TO:USER $DEST "<c02>[FCT:TXT:ESPACE:DISPLAY $CMD_UPPER $l_espace]<c01> \[<c04> [[subst ::EvaServ::help:description:${CMD_LOWER}]] <c01>\]";
		} else {
			SENT:MSG:TO:USER $DEST "<c02>[FCT:TXT:ESPACE:DISPLAY $CMD_UPPER $l_espace]<c01> \[<c07> Aucune description disponibles <c01>\]";
		}
	}
	SENT:MSG:TO:USER $DEST "<c>";
}
proc ::EvaServ::SHOW:INFO:TO:CHANLOG { TYPE DATA } {
	variable config
	SENT:MSG:TO:USER ${SERVICE_BOT(channel_logs)} "<c$config(console_com)>[FCT:TXT:ESPACE:DISPLAY $TYPE 16]<c$config(console_deco)>:<c$config(console_txt)> $DATA"
}
proc ::EvaServ::CMD:LIST { } {
	variable commands
	foreach level [dict keys $commands] {
		lappend CMD_LIST {*}[dict get $commands $level cmd]
	}
	return $CMD_LIST
}
proc ::EvaServ::CMD:TO:LEVEL { CMD } {
	variable commands
	foreach level [dict keys $commands] {
		if { [lsearch -nocase [dict get $commands $level cmd] $CMD] != "-1" } {
			return $level
		}
	}
	return -1
}
proc ::EvaServ::CMD:EXIST { CMD } {
	if { [lsearch -nocase [CMD:LIST] $CMD] == "-1" } { return 0 }
	return 1
}
proc ::EvaServ::UID:CONVERT { ID } {
	variable UID_DB
	if { [info exists UID_DB([string toupper $ID])] } {
		return "$UID_DB([string toupper $ID])"
	} else {
		return $ID
	}
}

proc ::EvaServ::DBU:GET { UID WHAT } {
	variable DBU_INFO
	set UID	[FCT:DATA:TO:UID [string toupper $UID]]
	if { [info exists DBU_INFO($UID,$WHAT)] } {
		return "$DBU_INFO($UID,$WHAT)";
	} else {
		return -1;
	}
}

proc ::EvaServ::FCT:SENT:MODE { DEST {MODE ""} {CIBLE ""} } {
	variable config
	sent2socket ":${config(server_id)} MODE $DEST $MODE $CIBLE"
}
proc ::EvaServ::FCT:SET:TOPIC { DEST TOPIC } {
	variable config
	sent2socket ":${config(server_id)} TOPIC $DEST :[FCT:apply_visuals $TOPIC]"
}
proc ::EvaServ::FCT:DATA:TO:NICK { DATA } {
	if { [string range $DATA 0 0] == 0 } {
		set user		[UID:CONVERT $DATA]
	} else {
		set user		$DATA
	}
	return $user;
}
proc ::EvaServ::FCT:DATA:TO:UID { DATA } {
	if { [string range $DATA 0 0] == 0 } {
		set UID		$DATA
	} else {
		set UID		[UID:CONVERT $DATA]
	}
	return $UID;
}
proc ::EvaServ::FCT:TXT:ESPACE:DISPLAY { text length } {
	set text			[string trim $text]
	set text_length		[string length $text];
	set espace_length	[expr ($length - $text_length)/2.0]
	set ESPACE_TMP		[split $espace_length .]
	set ESPACE_ENTIER	[lindex $ESPACE_TMP 0]
	set ESPACE_DECIMAL	[lindex $ESPACE_TMP 1]
	if { $ESPACE_DECIMAL == 0 } {
		set espace_one			[string repeat " " $ESPACE_ENTIER];
		set espace_two			[string repeat " " $ESPACE_ENTIER];
		return "$espace_one$text$espace_two"
	} else {
		set espace_one			[string repeat " " $ESPACE_ENTIER];
		set espace_two			[string repeat " " [expr ($ESPACE_ENTIER+1)]];
		return "$espace_one$text$espace_two"
	}

}

proc ::EvaServ::putdebug { string } {
	set deb		[open logs/EvaServ.debug a]
	puts $deb "[clock format [clock seconds] -format "\[%H:%M\]"] $string"
	close $deb
}

proc ::EvaServ::refresh { pseudo } {
	variable netadmin 
	variable admins 
	variable vhost 
	variable protect 
	variable users
	set vuser	[string tolower $pseudo]
	if { [info exists vhost($vuser)] } {
		if { [info exists protect($vhost($vuser))] && [info exists admins($vuser)] } {
			SHOW:INFO:TO:CHANLOG "Protecion du host" "$vhost($vuser) de $vuser (Désactivé)"
			unset protect($vhost($vuser))
		}
		unset vhost($vuser)
	}
	if { [info exists users($vuser)] } { unset users($vuser)		}
	if { [info exists netadmin($vuser)] } { unset netadmin($vuser)		}
	if { [info exists admins($vuser)] } { unset admins($vuser)		}
}

###############
# Eva Gestion #
###############

proc ::EvaServ::gestion { } {
	variable config
	set sv		[open [Script:Get:Directory]/db/gestion.db w+]
	puts $sv "SERVICE_BOT(channel_logs) ${SERVICE_BOT(channel_logs)}"
	puts $sv "config(debug) $config(debug)"
	puts $sv "config(console) $config(console)"
	puts $sv "config(protection) $config(protection)"
	puts $sv "config(login) $config(login)"
	puts $sv "config(aclient) $config(aclient)"
	close $sv
}

proc ::EvaServ::dbback { min h d m y } {
	variable config
	gestion
	set DB_LIST	[list "gestion" "chan" "client" "close" "nick" "ident" "real" "host" "salon" "trust"]
	foreach DB_NAME $DB_LIST {
		exec cp -f [Script:Get:Directory]/db/${DB_NAME}.db [Script:Get:Directory]/db/${DB_NAME}.bak
	}
	if { [console 1] == "ok" } {
		SHOW:INFO:TO:CHANLOG "Backup" "Sauvegarde des databases."
	}
}

proc ::EvaServ::duree { temps } {
	switch -exact [lindex [ctime ${temps}] 1] {
		"Jan" { set mois	"01" }
		"Feb" { set mois	"02" }
		"Mar" { set mois	"03" }
		"Apr" { set mois	"04" }
		"May" { set mois	"05" }
		"Jun" { set mois	"06" }
		"Jul" { set mois	"07" }
		"Aug" { set mois	"08" }
		"Sep" { set mois	"09" }
		"Oct" { set mois	"10" }
		"Nov" { set mois	"11" }
		"Dec" { set mois	"12" }
	}
	switch -exact [lindex [ctime ${temps}] 2] {
		1 { set jour		"01" }
		2 { set jour		"02" }
		3 { set jour		"03" }
		4 { set jour		"04" }
		5 { set jour		"05" }
		6 { set jour		"06" }
		7 { set jour		"07" }
		8 { set jour		"08" }
		9 { set jour		"09" }
	}
	if { ![info exists jour] } { set jour		[lindex [ctime ${temps}] 2] }
	set heure		[lindex [ctime ${temps}] 3]
	set annee		[lindex [ctime ${temps}] 4]
	set seen		"$jour/$mois/$annee à $heure"
	return $seen
}


proc ::EvaServ::console { level } {
	variable config
	switch -exact $level {
		1	{
			if { $config(console)>=1 } { return ok }
		}
		2	{
			if { $config(console)>=2 } { return ok }
		}
		3	{
			if { $config(console)>=3 } { return ok }
		}
	}
}

###########################################################
# Eva Verification de securité utilisateur a la connexion #
###########################################################
proc ::EvaServ::connexion:user:security:check { nickname hostname username gecos } {
	variable config
	variable trust
	# default
	set config(ahost)			1
	set config(aident)			1
	set config(areal)			1
	set config(anick)			1
	
	# Lors de l'init (connexion au irc du service) on verifie rien
	if { $config(init) == 1 } { return 0 }
	# on verifie si l'host est trusted
	foreach { mask num } [array get trust] {
		if { [string match -nocase *$mask* $hostname] } {
			SHOW:INFO:TO:CHANLOG "Hostname Trustée" "$mask"
			return 0
		}
	}
	# Si l'utilisateur est proteger, on skip les verification
	if { [info exists protect($hostname)] } {
		SHOW:INFO:TO:CHANLOG "Security Check" "Aucune verification de sécurité sur $hostname, le hostname protegé"
		return 0
	}
	
	set MSG_security_check	""
	# Version client ?
	if { $config(aclient) == 1 } { lappend MSG_security_check "Client version: On"; } else { lappend MSG_security_check "Client version: Off"; }
	# verif host?
	if { $config(ahost) == 1 } { lappend MSG_security_check "Host: On"; } else { lappend MSG_security_check "Host: Off"; }
	# verif ident?
	if { $config(aident) == 1 } { lappend MSG_security_check "Ident: On"; } else { lappend MSG_security_check "Ident: Off"; }
	# verif areal?
	if { $config(areal) == 1 } { lappend MSG_security_check "Realname: On"; } else { lappend MSG_security_check "Realname: Off"; }
	# verif nick?
	if { $config(anick) == 1 } { lappend MSG_security_check "Nick: On"; } else { lappend MSG_security_check "Nick: Off"; }

	if { [console 2] == "ok" } {
		SHOW:INFO:TO:CHANLOG "Security Check" [join $MSG_security_check " | "]
	}
	

	# Version client
	if { $config(aclient) == 1	} {
		SENT:MSG:TO:USER $nickname "\001VERSION\001"
	}

	if { $config(ahost) == 1 	} {
		catch { open [Script:Get:Directory]/db/host.db r } liste2
		while { ![eof $liste2] } {
			gets $liste2 verif2
			if { [string match -nocase *$verif2* $hostname] && $verif2 != "" } {
				if { [console 1] == "ok" && $config(init) == 0 } {
					SHOW:INFO:TO:CHANLOG "Kill" "$nickname a été killé : $config(rhost)"
				}
				sent2socket ":${config(server_id)} KILL $nickname $config(rhost)";
				break;
				refresh $nickname;
				return 0
			}
		}
		catch { close $liste2 }
	}
	if { $config(aident) == 1 	} {
		catch { open [Script:Get:Directory]/db/ident.db r } liste3
		while { ![eof $liste3] } {
			gets $liste3 verif3
			if { [string match -nocase *$verif3* $username] && $verif3 != "" } {
				if { [console 1] == "ok" && $config(init) == 0 } {
					SHOW:INFO:TO:CHANLOG "Kill" "$nickname ($verif3) a été killé : $config(rident)"
				}
				sent2socket ":${config(server_id)} KILL $nickname $config(rident)";
				break ;
				refresh $nickname;
				return 0;
			}
		}
		catch { close $liste3 }
	}
	if { $config(areal) == 1 	} {
		catch { open [Script:Get:Directory]/db/real.db r } liste4
		while { ![eof $liste4] } {
			gets $liste4 verif4
			if { [string match -nocase *$verif4* $gecos] && $verif4 != "" } {
				if { [console 1] == "ok" && $config(init) == 0 } {
					SHOW:INFO:TO:CHANLOG "Kill" "$nickname (Realname: $verif4) a été killé : $config(rreal)"
				}
				sent2socket ":${config(server_id)} KILL $nickname $config(rreal)";
				break;
				refresh $nickname;
				return 0;
			}
		}
		catch { close $liste4 }
	}
	if { $config(anick) == 1 	} {
		catch { open [Script:Get:Directory]/db/nick.db r } liste5
		while { ![eof $liste5] } {
			gets $liste5 verif5
			if { [string match -nocase $verif5 $nickname] && $verif5 != "" } {
				if { [console 1] == "ok" && $config(init) == 0 } {
					SHOW:INFO:TO:CHANLOG "Kill" "$nickname a été killé : $config(ruser)"
				}
				sent2socket ":${config(server_id)} KILL $nickname $config(ruser)";
				break;
				refresh $nickname;
				return 0;
			}
		}
		catch { close $liste5 }
	}
}

proc ::EvaServ::protection { user level } {
	variable config
	variable netadmin
	variable admins
	variable vhost
	switch -exact $level {
		0 {
			if { [info exists netadmin($user)] } { return ok }
		}
		1 {
			if { [info exists netadmin($user)] } {
				return ok
				} elseif { [
					info exists admins($user)] && \
						[matchattr $admins($user) n]
				} {
				return ok
			}
		}
		2 {
			if { [info exists netadmin($user)] } {
				return ok
			} elseif {
				[info exists admins($user)] && \
					[matchattr $admins($user) m]
			} {
				return ok
			}
		}
		3 {
			if { [info exists netadmin($user)] } {
				return ok
			} elseif {
				[info exists admins($user)] && \
					[matchattr $admins($user) o]
			} {
				return ok
			}
		}
		4 {
			if { [info exists netadmin($user)] } {
				return ok
			} elseif {
				[info exists admins($user)] && \
					[matchattr $admins($user) p]
			} {
				return ok
			}
		}
	}
}

proc ::EvaServ::rnick { user } {
	variable config
	if { $config(rnick) == 1 } { return "($user)" }
}


proc ::EvaServ::prerehash { arg } {
	variable config
	if { [info exists config(idx)] && [valididx ${config(idx)}] } {
		gestion
	}
}

proc ::EvaServ::rehash { arg } {
	variable config
	if { [info exists config(idx)] && [valididx ${config(idx)}] } {
		Database:Load:Data
	}
}

proc ::EvaServ::evenement { arg } {
	variable config
	if { [info exists config(idx)] && [valididx ${config(idx)}] } {
		gestion
		sent2socket ":${config(server_id)} QUIT :$config(raison)"
		sent2socket ":$config(link) SQUIT $config(link) :$config(raison)"
		foreach kill [utimers] {
			if { [lindex $kill 1] == "::EvaServ::verif" } { killutimer [lindex $kill 2] }
		}
		unset config(idx)
	}
}

proc ::EvaServ::eva { nick idx arg } {
	variable SCRIPT
	sent2ppl $idx "<c01,01>------------<b><c00> Commandes de ${SCRIPT(name)} <c01>------------"
	sent2ppl $idx " "
	sent2ppl $idx "<c01> .evaconnect <c03>: <c14>Connexion de ${SCRIPT(name)}"
	sent2ppl $idx "<c01> .evadeconnect <c03>: <c14>Déconnexion de ${SCRIPT(name)}"
	sent2ppl $idx "<c01> .evadebug on/off <c03>: <c14>Mode debug de ${SCRIPT(name)}"
	sent2ppl $idx "<c01> .evainfos <c03>: <c14>Voir les infos de ${SCRIPT(name)}"
	sent2ppl $idx "<c01> .evauptime <c03>: <c14>Uptime de ${SCRIPT(name)}"
	sent2ppl $idx "<c01> .evaversion <c03>: <c14>Version de ${SCRIPT(name)}"
	sent2ppl $idx ""
}
proc ::EvaServ::connect { nick idx arg } {
	variable SCRIPT
	variable config
	set config(counter)		0
	if { ![info exists config(idx)] } {
		sent2ppl $idx "<c01>\[ <c03>Connexion<c01> \] <c01> Lancement de ${SCRIPT(name)}...";
		connexion
		set config(dem)		1;
		utimer $config(timerdem) [list set config(dem)		0]
	} else {
		if { ![valididx ${config(idx)}] } {
			sent2ppl $idx "<c01>\[ <c03>Connexion<c01> \] <c01> Lancement de ${SCRIPT(name)}...";
			connexion
			set config(dem)		1;
			utimer $config(timerdem) [list set config(dem)		0]
		} else {
			sent2ppl $idx "<c01>\[ <c04>Impossible<c01> \] <c01> ${SCRIPT(name)} est déjà connecté..."
		}
	}

}

proc ::EvaServ::deconnect { nick idx arg } {
	variable config
	if { $config(dem) == 0 } {
		if { [info exists config(idx)] && [valididx ${config(idx)}] } {
			gestion
			sent2ppl $idx "<c01>\[ <c03>Déconnexion<c01> \] <c01> Arret de ${SCRIPT(name)}..."
			sent2socket ":${config(server_id)} QUIT :$config(raison)"
			sent2socket ":$config(link) SQUIT $config(link) :$config(raison)"
			foreach kill [utimers] {
				if { [lindex $kill 1] == "::EvaServ::verif" } { killutimer [lindex $kill 2] }
			}
			unset config(idx)
		} else {
			sent2ppl $idx "<c01>\[ <c04>Impossible<c01> \] <c01> ${SCRIPT(name)} n'est pas connecté..."
		}
	} else {
		sent2ppl $idx "<c01>\[ <c04>Erreur<c01> \] <c01> Connexion de ${SCRIPT(name)} en cours..."
	}
}

proc ::EvaServ::uptime { nick idx arg } {
	variable config
	if { [info exists config(idx)] && [valididx ${config(idx)}] } {
		set show		""
		set up			[expr ([clock seconds] - ${config(uptime))}]
		set jour		[expr ($up / 86400)]
		set up			[expr ($up % 86400)]
		set heure		[expr ($up / 3600)]
		set up			[expr ($up % 3600)]
		set minute		[expr ($up / 60)]
		set seconde		[expr ($up % 60)]
		if { $jour == 1 } { append show "$jour jour " } elseif { $jour > 1 } { append show "$jour jours " }
		if { $heure == 1 } { append show "$heure heure " } elseif { $heure > 1 } { append show "$heure heures " }
		if { $minute == 1 } { append show "$minute minute " } elseif { $minute > 1 } { append show "$minute minutes " }
		if { $seconde == 1 } { append show "$seconde seconde " } elseif { $seconde > 1 } { append show "$seconde secondes " }
		sent2ppl $idx "<c01>\[ <c03>Uptime<c01> \] <c01> $show"
	} else {
		sent2ppl $idx "<c01>\[ <c04>Uptime<c01> \] <c01> ${SCRIPT(name)} n'est pas connecté..."
	}
}

proc ::EvaServ::version { nick idx arg } {
	variable SCRIPT
	sent2ppl $idx "<c01>\[ <c03>Version<c01> \] <c01> ${SCRIPT(name)} ${SCRIPT(version)} by ${SCRIPT(auteur)}"
}

proc ::EvaServ::infos { nick idx arg } {
	variable SCRIPT
	variable config
	sent2ppl $idx "<c01,01>-----------<b><c00> Infos de ${SCRIPT(name)} <c01>-----------"
	sent2ppl $idx "<c>"
	if { [info exists config(idx)] }	 {
		sent2ppl $idx "<c01> Statut : <c03>Online"
	} else {
		sent2ppl $idx "<c01> Statut : <c04>Offline"
	}
	if { $config(debug) == 1 } {
		sent2ppl $idx "<c01> Debug : <c03>On"
	} else {
		sent2ppl $idx "<c01> Debug : <c04>Off"
	}
	sent2ppl $idx "<c01> Os : ${::tcl_platform(os)} ${::tcl_platform(osVersion)}"
	sent2ppl $idx "<c01> Tcl Version : $::tcl_patchLevel"
	sent2ppl $idx "<c01> Tcl Lib : $::tcl_library"
	sent2ppl $idx "<c01> Encodage : [encoding system]"
	sent2ppl $idx "<c01> Eggdrop Version : [lindex $::version 0]"
	sent2ppl $idx "<c01> Config : [Script:Get:Directory]/EvaServ.conf"
	sent2ppl $idx "<c01> Noyau : [Script:Get:Directory]/EvaServ.tcl"
	sent2ppl $idx "<c>"
}

proc ::EvaServ::debug { nick idx arg } {
	variable config
	set arg			[split $arg]
	set status		[string tolower [lindex $arg 0]]
	if { $status != "on" && $status != "off" } {
		sent2ppl $idx ".evadebug on/off";
		return 0;
	}

	if { $status == "on" } {
		if { $config(debug) == 0 } {
			set config(debug)		1;
			sent2ppl $idx "<c01>\[ <c03>Debug<c01> \] <c01> Activé"
		} else {
			sent2ppl $idx "Le mode debug est déjà activé."
		}
	} elseif { $status == "off" } {
		if { $config(debug) == 1 } {
			set config(debug)		0;
			sent2ppl $idx "<c01>\[ <c03>Debug<c01> \] <c01> Désactivé"
			if { [file exists "logs/EvaServ.debug"] } { exec rm -rf logs/EvaServ.debug }
		} else {
			sent2ppl $idx "Le mode debug est déjà désactivé."
		}
	}
}

############
# Eva Cmds #
############

proc ::EvaServ::cmds { arg } {
	variable SCRIPT
	variable config
	variable users
	variable admin
	variable admins
	variable vhost
	variable protect
	variable trust
	set arg		[split $arg]
	set cmd		[lindex $arg 0]
	set user	[lindex $arg 1]
	set vuser	[string tolower $user]
	set value1	[lindex $arg 2]
	set value2	[string tolower [lindex $arg 2]]
	set value3	[lindex $arg 3]
	set value4	[string tolower [lindex $arg 3]]
	set value5	[join [lrange $arg 4 end]]
	set value6	[join [lrange $arg 3 end]]
	set value7	[join [lrange $arg 2 end]]
	set value8	[lindex $arg 4]
	set value9	[string tolower [lindex $arg 4]]
	set stop	0
	if { [authed $vuser $cmd] != "ok" } { return 0 }
	switch -exact $cmd {
		"auth" {
			if { [lindex $arg 2] == "" || [lindex $arg 3] == "" } {
				sent2socket ":${config(server_id)} NOTICE [UID:CONVERT $user] :<b>Commande Auth :</b> /msg ${SERVICE_BOT(name)} auth pseudo password";
				return 0
			}
			if { [passwdok [lindex $arg 2] [lindex $arg 3]] } {
				if { [matchattr [lindex $arg 2] o] || [matchattr [lindex $arg 2] m] || [matchattr [lindex $arg 2] n] } {
					if { $config(login) == 1 } {
						foreach { pseudo login } [array get admins] {
							if { $login == [string tolower [lindex $arg 2]] && $pseudo!=$vuser } {
								sent2socket ":${config(server_id)} NOTICE [UID:CONVERT $vuser] :Maximum de Login atteint.";
								return 0;
							}
						}
					}
					if { ![info exists admins($vuser)] } {
						set admins($vuser)		[string tolower [lindex $arg 2]]
						if { [info exists vhost($vuser)] && ![info exists protect($vhost($vuser))] } {
							SHOW:INFO:TO:CHANLOG "Protecion du host" "$vhost($vuser) de $vuser (Activé)"
							set protect($vhost($vuser))		1
						}
						setuser [string tolower [lindex $arg 2]] LASTON [unixtime]
						SENT:MSG:TO:USER $vuser "Authentification Réussie."
						sent2socket ":${config(server_id)} INVITE $vuser ${SERVICE_BOT(channel_logs)}"
						if { [console 1] == "ok" } {
							SHOW:INFO:TO:CHANLOG "Auth" "$user"
						}
						return 0
					} else {
						SENT:MSG:TO:USER $vuser "Vous êtes déjà authentifié.";
						return 0;
					}
				} elseif { [matchattr [lindex $arg 2] p] } {
					SENT:MSG:TO:USER $vuser "Authentification Helpeur Refusée.";
					return 0;
				}

			} else {
				SENT:MSG:TO:USER $vuser "Accès Refusé.";
				return 0;
			}
		}
		"deauth" {
			if { [info exists admins($vuser)] } {
				if { [matchattr $admins($vuser) o] || [matchattr $admins($vuser) m] || [matchattr $admins($vuser) n] } {
					if { [info exists vhost($vuser)] && [info exists protect($vhost($vuser))] } {
						SHOW:INFO:TO:CHANLOG "Protecion du host" "$vhost($vuser) de $vuser (Désactivé)"
						unset protect($vhost($vuser))
					}
					unset admins($vuser);
					SENT:MSG:TO:USER $vuser "Déauthentification Réussie."
					if { [console 1] == "ok" } {
						SHOW:INFO:TO:CHANLOG "Deauth" "$user"
					}
				} elseif { [matchattr $admins($vuser) p] } {
					SENT:MSG:TO:USER $vuser "Déauthentification Helpeur Refusée.";
					return 0;
				}

			} else {
				SENT:MSG:TO:USER $vuser "Vous n'êtes pas authentifié."
			}
		}
		"copyright" {
			SENT:MSG:TO:USER $user "<c01>${SCRIPT(name)} ${SCRIPT(version)} by ${SCRIPT(auteur)}"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Copyright" "$user"
			}
		}
		"console" {
			if { $value2 == "" || [regexp \[^0-3\] $value2] } {
				SENT:MSG:TO:USER $vuser "<b>Commande Console :</b> /msg ${SERVICE_BOT(name)} console 0/1/2/3"
				SENT:MSG:TO:USER $vuser "<c02>Level 0 <c04>:<c01> Aucune console"
				SENT:MSG:TO:USER $vuser "<c02>Level 1 <c04>:<c01> Console commande"
				SENT:MSG:TO:USER $vuser "<c02>Level 2 <c04>:<c01> Console commande & connexion & déconnexion"
				SENT:MSG:TO:USER $vuser "<c02>Level 3 <c04>:<c01> Toutes les consoles"
				return 0
			}
			switch -exact $value2 {
				0 {
					set config(console)		0;
					SENT:MSG:TO:USER $vuser "Level 0 : Aucune console"
					SHOW:INFO:TO:CHANLOG "Console" "$user"
				}
				1 {
					set config(console)		1;
					SENT:MSG:TO:USER $vuser "Level 1 : Console commande"
					SHOW:INFO:TO:CHANLOG "Console" "$user"
				}
				2 {
					set config(console)		2;
					SENT:MSG:TO:USER $vuser "Level 2 : Console commande & connexion & déconnexion"
					SHOW:INFO:TO:CHANLOG "Console" "$user"
				}
				3 {
					set config(console)		3;
					SENT:MSG:TO:USER $vuser "Level 3 : Toutes les consoles"
					SHOW:INFO:TO:CHANLOG "Console" "$user"
				}
			}
		}
		"chanlog" {
			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà le salon de log.";
				return 0
			}
			if { [string index $value2 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Chanlog :</b> /msg ${SERVICE_BOT(name)} chanlog #salon";
				return 0
			}
			catch { open "[Script:Get:Directory]/db/salon.db" r } liste1
			while { ![eof $liste1] } {
				gets $liste1 verif1;
				if { ![string compare -nocase $value2 $verif1] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Interdit";
					set stop 1;
					break
				}
			}
			catch { close $liste1 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/close.db" r } liste2
			while { ![eof $liste2] } {
				gets $liste2 verif2;
				if { ![string compare -nocase $value2 $verif2] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Fermé";
					set stop		1;
					break
				}
			}
			catch { close $liste2 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/chan.db" r } liste3
			while { ![eof $liste3] } {
				gets $liste3 verif3;
				if { ![string compare -nocase $value2 $verif3] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Autojoin";
					set stop		1;
					break
				}
			}
			catch { close $liste3 }
			if { $stop == 1 } { return 0 }
			sent2socket ":${config(server_id)} PART ${SERVICE_BOT(channel_logs)}"
			FCT:SENT:MODE ${SERVICE_BOT(channel_logs)} "-O"
			set SERVICE_BOT(channel_logs)		$value1
			sent2socket ":${config(server_id)} JOIN ${SERVICE_BOT(channel_logs)}"
			FCT:SENT:MODE ${SERVICE_BOT(channel_logs)} "+$config(smode)"
			if { ${config(chanmode)} == "q" || ${config(chanmode)} == "a" || ${config(chanmode)} == "o" || ${config(chanmode)} == "h" || ${config(chanmode)} == "v" } {
				FCT:SENT:MODE ${SERVICE_BOT(channel_logs)} "+${config(chanmode)}" ${SERVICE_BOT(name)}
			}
			SENT:MSG:TO:USER $vuser "Changement du salon de log reussi ($value1)"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Chanlog" "Changement du salon de log par $user ($value1)"
			}
		}
		"join" {
			if { [string index $value2 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Join :</b> /msg ${SERVICE_BOT(name)} join #salon";
				return 0
			}
			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $vuser "Accès Refusé : Salon de logs";
				return 0
			}
			catch { open "[Script:Get:Directory]/db/salon.db" r } liste1
			while { ![eof $liste1] } {
				gets $liste1 verif1;
				if { ![string compare -nocase $value2 $verif1] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Interdit";
					set stop		1;
					break
				}
			}
			catch { close $liste1 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/close.db" r } liste2
			while { ![eof $liste2] } {
				gets $liste2 verif2;
				if { ![string compare -nocase $value2 $verif2] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Fermé";
					set stop		1;
					break
				}
			}
			catch { close $liste2 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/chan.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "${SERVICE_BOT(name)} est déjà sur <b>$value1</b>.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set join		[open "[Script:Get:Directory]/db/chan.db" a];
			puts $join $value2;
			close $join;
			sent2socket ":${config(server_id)} JOIN $value1"
			if { ${config(chanmode)} == "q" || ${config(chanmode)} == "a" || ${config(chanmode)} == "o" || ${config(chanmode)} == "h" || ${config(chanmode)} == "v" } {
				FCT:SENT:MODE $value1 "+${config(chanmode)}" ${SERVICE_BOT(name)}
			}
			SENT:MSG:TO:USER $vuser "${SERVICE_BOT(name)} entre sur <b>$value1</b>"

			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Join" "$value1 par $user"
			}
		}
		"part" {
			if { [string index $value2 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Part :</b> /msg ${SERVICE_BOT(name)} part #salon";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $vuser "Accès Refusé";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/chan.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop		1 }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend salle "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "${SERVICE_BOT(name)} n'est pas sur <b>$value1</b>.";
				return 0;
			} else {
				if { [info exists salle] } {
					set del		[open "[Script:Get:Directory]/db/chan.db" w+];
					foreach chandel $salle { puts $del "$chandel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/chan.db" w+];
					close $del
				}
				FCT:SENT:MODE $value1 "-sntio";
				sent2socket ":${config(server_id)} PART $value1"
				SENT:MSG:TO:USER $vuser "${SERVICE_BOT(name)} part de <b>$value1</b>"
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "Part" "$value1 par $user"
				}
			}
		}
		"list" {
			catch { open "[Script:Get:Directory]/db/chan.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>--------- <c0>Autojoin salons <c1>---------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste salon;
				if { $salon != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $salon"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Salon"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "List" "$user"
			}
		}
		"showcommands" {
			SENT:MSG:TO:USER $vuser "<b><c01,01>--------------------------------------- <c00>Commandes de ${SCRIPT(name)} <c01>---------------------------------------"
			SHOW:CMD:DESCRIPTION:BY:LEVEL $vuser 0
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) p] } {
				SHOW:CMD:DESCRIPTION:BY:LEVEL $vuser 1
			}
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) o] } {
				SHOW:CMD:DESCRIPTION:BY:LEVEL $vuser 2
			}
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) m] } {
				SHOW:CMD:DESCRIPTION:BY:LEVEL $vuser 3
			}
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) n] } {
				SHOW:CMD:DESCRIPTION:BY:LEVEL $vuser 4
			}
			SENT:MSG:TO:USER $vuser "<c02>Aide sur une commande<c01> \[<c04> /msg ${SERVICE_BOT(name)} help <la_commande> <c01>\]"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Showcommands" "$user"
			}
		}
		"help" {
			SENT:MSG:TO:USER $vuser "<b><c01,01>--------------------------------------- <c00>Commandes de ${SCRIPT(name)} <c01>---------------------------------------"
			SENT:MSG:TO:USER $vuser "<c>"
			SHOW:CMD:BY:LEVEL $vuser 0
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) p] } {
				SHOW:CMD:BY:LEVEL $vuser 1
			}
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) o] } {
				SHOW:CMD:BY:LEVEL $vuser 2
			}
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) m] } {
				SHOW:CMD:BY:LEVEL $vuser 3
			}
			if { [info exists admins($vuser)] && [matchattr $admins($vuser) n] } {
				SHOW:CMD:BY:LEVEL $vuser 4
			}
			SENT:MSG:TO:USER $vuser "<c02>Listes des commandes<c01> \[<c04> /msg ${SERVICE_BOT(name)} showcommands <c01>\]"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Help" "$user"
			}
		}
		"maxlogin" {
			if { $value2 != "on" && $value2 != "off" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Maxlogin :</b> /msg ${SERVICE_BOT(name)} maxlogin on/off";
				return 0;
			}

			if { $value2 == "on" } {
				if { $config(login) == 0 } {
					set config(login)		1;
					SENT:MSG:TO:USER $vuser "Protection maxlogin activée"
					if { [console 1] == "ok" } {
						SHOW:INFO:TO:CHANLOG "Maxlogin" "$user"
					}
				} else {
					SENT:MSG:TO:USER $vuser "La protection maxlogin est déjà activée."
				}
			} elseif { $value2 == "off" } {
				if { $config(login) == 1 } {
					set config(login)		0;
					SENT:MSG:TO:USER $vuser "Protection maxlogin désactivée"
					if { [console 1] == "ok" } {
						SHOW:INFO:TO:CHANLOG "Maxlogin" "$user"
					}
				} else {
					SENT:MSG:TO:USER $vuser "La protection maxlogin est déjà désactivée."
				}
			}
		}
		"backup" {
			gestion
			exec cp -f [Script:Get:Directory]/db/gestion.db [Script:Get:Directory]/db/gestion.bak
			exec cp -f [Script:Get:Directory]/db/chan.db [Script:Get:Directory]/db/chan.bak
			exec cp -f [Script:Get:Directory]/db/client.db [Script:Get:Directory]/db/client.bak
			exec cp -f [Script:Get:Directory]/db/close.db [Script:Get:Directory]/db/close.bak
			exec cp -f [Script:Get:Directory]/db/real.db [Script:Get:Directory]/db/real.bak
			exec cp -f [Script:Get:Directory]/db/ident.db [Script:Get:Directory]/db/ident.bak
			exec cp -f [Script:Get:Directory]/db/host.db [Script:Get:Directory]/db/host.bak
			exec cp -f [Script:Get:Directory]/db/nick.db [Script:Get:Directory]/db/nick.bak
			exec cp -f [Script:Get:Directory]/db/salon.db [Script:Get:Directory]/db/salon.bak
			exec cp -f [Script:Get:Directory]/db/trust.db [Script:Get:Directory]/db/trust.bak
			SENT:MSG:TO:USER $vuser "Sauvegarde des databases réalisée."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Backup" "$user"
			}
		}
		"restart" {
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Restart" "$user"
			}
			SENT:MSG:TO:USER $vuser "Redémarrage de ${SCRIPT(name)}."
			gestion;
			sent2socket ":${config(server_id)} QUIT $config(raison)";
			sent2socket ":$config(link) SQUIT $config(link) :$config(raison)"
			foreach kill [utimers] {
				if { [lindex $kill 1] == "::EvaServ::verif" } { killutimer [lindex $kill 2] }
			}
			if { [info exists config(idx)] } { unset config(idx)		}
			set config(counter)		0;
			config
			utimer 1 ::EvaServ::connexion
		}
		"die" {
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Die" "$user"
			}
			SENT:MSG:TO:USER $vuser "Arrêt de ${SCRIPT(name)}."
			gestion;
			sent2socket ":${config(server_id)} QUIT $config(raison)";
			sent2socket ":$config(link) SQUIT $config(link) :$config(raison)"
			foreach kill [utimers] {
				if { [lindex $kill 1] == "::EvaServ::verif" } { killutimer [lindex $kill 2] }
			}
			if { [info exists config(idx)] } { unset config(idx)		}
		}
		"status" {
			set numuser		0;
			set numident	0;
			set numhost		0;
			set numreal		0;
			set numtrust	0
			set numclose	0;
			set numsalons	0;
			set numsalon	0;
			set numchan		0;
			set numclient	0;
			set show		""
			set up			[expr ([clock seconds] - ${config(uptime))}]
			set jour		[expr ($up / 86400)]
			set up			[expr ($up % 86400)]
			set heure		[expr ($up / 3600)]
			set up			[expr ($up % 3600)]
			set minute		[expr ($up / 60)]
			set seconde		[expr ($up % 60)]
			if { $jour == 1 }		{ append show "$jour jour " } elseif { $jour > 1 } { append show "$jour jours " }
			if { $heure == 1 }		{ append show "$heure heure " } elseif { $heure > 1 } { append show "$heure heures " }
			if { $minute == 1 }		{ append show "$minute minute " } elseif { $minute > 1 } { append show "$minute minutes " }
			if { $seconde == 1 }	{ append show "$seconde seconde " } elseif { $seconde > 1 } { append show "$seconde secondes " }
			catch { open [Script:Get:Directory]/db/client.db r } liste
			while { ![eof $liste] } {
				gets $liste sclients;
				if { $sclients != "" } { incr numclient 1 }
			}
			catch { close $liste }
			catch { open [Script:Get:Directory]/db/chan.db r } liste2
			while { ![eof $liste2] } {
				gets $liste2 schans;
				if { $schans != "" } { incr numchan 1 }
			}
			catch { close $liste2 }
			catch { open [Script:Get:Directory]/db/salon.db r } liste4
			while { ![eof $liste4] } {
				gets $liste4 ssalon;
				if { $ssalon != "" } { incr numsalons 1 }
			}
			catch { close $liste4 }
			catch { open [Script:Get:Directory]/db/close.db r } liste5
			while { ![eof $liste5] } {
				gets $liste5 sclose;
				if { $sclose != "" } { incr numclose 1 }
			}
			catch { close $liste5 }
			catch { open [Script:Get:Directory]/db/nick.db r } liste6
			while { ![eof $liste6] } {
				gets $liste6 suser;
				if { $suser != "" } { incr numuser 1 }
			}
			catch { close $liste6 }
			catch { open [Script:Get:Directory]/db/ident.db r } liste7
			while { ![eof $liste7] } {
				gets $liste7 sident;
				if { $sident != "" } { incr numident 1 }
			}
			catch { close $liste7 }
			catch { open [Script:Get:Directory]/db/host.db r } liste8
			while { ![eof $liste8] } {
				gets $liste8 shost;
				if { $shost != "" } { incr numhost 1 }
			}
			catch { close $liste8 }
			catch { open [Script:Get:Directory]/db/real.db r } liste9
			while { ![eof $liste9] } {
				gets $liste9 sreal;
				if { $sreal != "" } { incr numreal 1 }
			}
			catch { close $liste9 }
			catch { open [Script:Get:Directory]/db/trust.db r } liste10
			while { ![eof $liste10] } {
				gets $liste10 strust;
				if { $strust != "" } { incr numtrust 1 }
			}
			catch { close $liste10 }
			SENT:MSG:TO:USER $vuser "<b><c1,1>------------------ <c0>Status de ${SCRIPT(name)} <c1>------------------"
			SENT:MSG:TO:USER $vuser "<b>"
			SENT:MSG:TO:USER $vuser "<c02> Owner : <c01>$admin"
			SENT:MSG:TO:USER $vuser "<c02> Salon de logs : <c01>${SERVICE_BOT(channel_logs)}"
			SENT:MSG:TO:USER $vuser "<c02> Salon Autojoin : <c01>$numchan"
			SENT:MSG:TO:USER $vuser "<c02> Uptime : <c01>$show"
			switch -exact $config(console) {
				0 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Console : <c01>0" }
				1 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Console : <c01>1" }
				2 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Console : <c01>2" }
				3 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Console : <c01>3" }
			}
			switch -exact $config(protection) {
				0 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Protection : <c01>0" }
				1 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Protection : <c01>1" }
				2 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Protection : <c01>2" }
				3 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Protection : <c01>3" }
				4 { ::EvaServ::SENT:MSG:TO:USER $vuser "<c02> Level Protection : <c01>4" }
			}
			if { $config(login) == 1 } {
				SENT:MSG:TO:USER $vuser "<c02> Protection Maxlogin : <c03>On"
			} else {
				SENT:MSG:TO:USER $vuser "<c02> Protection Maxlogin : <c04>Off"
			}
			if { $config(aclient) == 1 } {
				SENT:MSG:TO:USER $vuser "<c02> Protection Clients IRC : <c03>On"
			} else {
				SENT:MSG:TO:USER $vuser "<c02> Protection Clients IRC : <c04>Off"
			}
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Salons Fermés : <c01>$numclose"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Salons Interdits : <c01>$numsalons"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Pseudos Interdits : <c01>$numuser"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Idents Interdits : <c01>$numident"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Hostnames Interdites : <c01>$numhost"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Realnames Interdits : <c01>$numreal"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Clients IRC : <c01>$numclient"
			SENT:MSG:TO:USER $vuser "<c02> Nbre de Trusts : <c01>$numtrust"
			SENT:MSG:TO:USER $vuser "<b>"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Status" "$user"
			}
		}
		"protection" {
			if { $value2 == "" || [regexp \[^0-4\] $value2] } {
				SENT:MSG:TO:USER $vuser "<b>Commande Protection :</b> /msg ${SERVICE_BOT(name)} protection 0/1/2/3/4"
				SENT:MSG:TO:USER $vuser "<c02>Level 0 <c04>:<c01> Aucune Protection"
				SENT:MSG:TO:USER $vuser "<c02>Level 1 <c04>:<c01> Protection Admins"
				SENT:MSG:TO:USER $vuser "<c02>Level 2 <c04>:<c01> Protection Admins + Ircops"
				SENT:MSG:TO:USER $vuser "<c02>Level 3 <c04>:<c01> Protection Admins + Ircops + Géofronts"
				SENT:MSG:TO:USER $vuser "<c02>Level 4 <c04>:<c01> Protection de tous les accès"
				return 0
			}
			switch -exact $value2 {
				0 {
					set config(protection)		0;
					SENT:MSG:TO:USER $vuser "Level 0 : Aucune Protection"
					SHOW:INFO:TO:CHANLOG "Protection" "$user"
				}
				1 {
					set config(protection)		1;
					SENT:MSG:TO:USER $vuser "Level 1 : Protection Admins"
					SHOW:INFO:TO:CHANLOG "Protection" "$user"
				}
				2 {
					set config(protection)		2;
					SENT:MSG:TO:USER $vuser "Level 2 : Protection Admins + Ircops"
					SHOW:INFO:TO:CHANLOG "Protection" "$user"
				}
				3 {
					set config(protection)		3;
					SENT:MSG:TO:USER $vuser "Level 3 : Protection Admins + Ircops + Géofronts"
					SHOW:INFO:TO:CHANLOG "Protection" "$user"
				}
				4 {
					set config(protection)		4;
					SENT:MSG:TO:USER $vuser "Level 4 : Protection de tous les accès"
					SHOW:INFO:TO:CHANLOG "Protection" "$user"
				}
			}
		}
		"newpass" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Newpass :</b> /msg ${SERVICE_BOT(name)} newpass mot-de-passe";
				return 0;
			}

			if { [string length $value1] <= 5 } {
				SENT:MSG:TO:USER $vuser "Le mot de passe doit contenir minimum 6 caractères.";
				return 0;
			}

			setuser $admins($vuser) PASS $value1
			SENT:MSG:TO:USER $user "Changement du mot de passe reussi."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Newpass" "$user"
			}
		}
		"map" {
			set config(rep)		$vuser
			sent2socket ":${config(server_id)} LINKS"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Map" "$user"
			}
		}
		"seen" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $user "<b>Commande Seen :</b> /msg ${SERVICE_BOT(name)} seen pseudo";
				return 0;
			}

			if { [validuser $value1] } {
				set annee		[lindex [ctime [getuser $value1 LASTON]] 4]
				if { $annee != "1970" } { set seen		[duree [getuser $value1 LASTON]] } else {
					set seen		"Jamais"
				}
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "Seen" "$user"
				}
				if { [matchattr $value1 n] } {
					SENT:MSG:TO:USER $vuser "<c1>Pseudo \[<c4>$value1<c1>\] <c> Level \[<c03>Admin<c1>\] <c> Seen \[<c02>$seen<c1>\]"
				} elseif { [matchattr $value1 m] } {
					SENT:MSG:TO:USER $vuser "<c1>Pseudo \[<c4>$value1<c1>\] <c> Level \[<c03>Ircop<c1>\] <c> Seen \[<c02>$seen<c1>\]"
				} elseif { [matchattr $value1 o] } {
					SENT:MSG:TO:USER $vuser "<c1>Pseudo \[<c4>$value1<c1>\] <c> Level \[<c03>Géofront<c1>\] <c> Seen \[<c02>$seen<c1>\]"
				} elseif { [matchattr $value1 p] } {
					SENT:MSG:TO:USER $vuser "<c1>Pseudo \[<c4>$value1<c1>\] <c> Level \[<c03>Helpeur<c1>\] <c> Seen \[<c02>$seen<c1>\]"
				}
			} else {
				SENT:MSG:TO:USER $vuser "Pseudo inconnu.";
				return 0;
			}
		}
		"access" {
			if { $value1 == "*" || $value1 == "" } {
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "Access" "$user"
				}
				SENT:MSG:TO:USER $vuser "<b><c1,1>------------------------------- <c0>Liste des Accès <c1>-------------------------------"
				SENT:MSG:TO:USER $vuser "<b>"
				foreach acces [userlist] {
					set annee		[lindex [ctime [getuser $acces LASTON]] 4]
					if { $annee != "1970" } { set seen		[duree [getuser $acces LASTON]] } else {
						set seen		"Jamais"
					}
					foreach { act reg } [array get admins] {
						if { $reg == [string tolower $acces] } { set status		"<c03>Online" }
					}
					if { ![info exists status] } { set status		"<c04>Offline" }
					switch -exact $config(protection) {
						1 {
							if { [matchattr $acces n] } { set aprotect		"<c03>On" }
						}
						2 {
							if { [matchattr $acces m] } { set aprotect		"<c03>On" }
						}
						3 {
							if { [matchattr $acces o] } { set aprotect		"<c03>On" }
						}
						4 {
							if { [matchattr $acces p] } { set aprotect		"<c03>On" }
						}
					}
					if { ![info exists aprotect] } { set aprotect		"<c04>Off" }
					if { [matchattr $acces n] } {
						SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$acces<c01>\] <c01> Level \[<c03>Admin<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $acces HOSTS]<c01>\]"
						SENT:MSG:TO:USER $vuser "<c>"
					} elseif { [matchattr $acces m] } {
						SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$acces<c01>\] <c01> Level \[<c03>Ircop<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $acces HOSTS]<c01>\]"
						SENT:MSG:TO:USER $vuser "<c>"
					} elseif { [matchattr $acces o] } {
						SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$acces<c01>\] <c01> Level \[<c03>Géofront<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $acces HOSTS]<c01>\]"
						SENT:MSG:TO:USER $vuser "<c>"
					} elseif { [matchattr $acces p] } {
						SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$acces<c01>\] <c01> Level \[<c03>Helpeur<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
						SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $acces HOSTS]<c01>\]"
						SENT:MSG:TO:USER $vuser "<c>"
					}
					unset status;
					unset seen;
					unset aprotect
				}
			} elseif { [validuser $value1] } {
				set annee		[lindex [ctime [getuser $value1 LASTON]] 4]
				if { $annee != "1970" } { set seen		[duree [getuser $value1 LASTON]] } else {
					set seen		"Jamais"
				}
				foreach { act reg } [array get admins] {
					if { $reg == [string tolower $value1] } { set status		"<c03>Online" }
				}
				if { ![info exists status] } { set status		"<c04>Offline" }
				switch -exact $config(protection) {
					1 {
						if { [matchattr $value1 n] } { set aprotect		"<c03>On" }
					}
					2 {
						if { [matchattr $value1 m] } { set aprotect		"<c03>On" }
					}
					3 {
						if { [matchattr $value1 o] } { set aprotect		"<c03>On" }
					}
					4 {
						if { [matchattr $value1 p] } { set aprotect		"<c03>On" }
					}
				}
				if { ![info exists aprotect] } { set aprotect		"<c04>Off" }
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "Access" "$user"
				}
				SENT:MSG:TO:USER $vuser "<b><c1,1>--------------------------- <c0>Accès de $value1 <c1>---------------------------"
				SENT:MSG:TO:USER $vuser "<b>"
				if { [matchattr $value1 n] } {
					SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$value1<c01>\] <c01> Level \[<c03>Admin<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $value1 HOSTS]<c01>\]"
				} elseif { [matchattr $value1 m] } {
					SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$value1<c01>\] <c01> Level \[<c03>Ircop<c01>\] <c> Seen \[<c12>$seen<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $value1 HOSTS]<c01>\]"
				} elseif { [matchattr $value1 o] } {
					SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$value1<c01>\] <c01> Level \[<c03>Géofront<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Statut \[<c03>$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $value1 HOSTS]<c01>\]"
				} elseif { [matchattr $value1 p] } {
					SENT:MSG:TO:USER $vuser "<c01> Pseudo \[<c04>$value1<c01>\] <c01> Level \[<c03>Helpeur<c01>\] <c01> Seen \[<c12>$seen<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Statut \[$status<c01>\] <c01> Protection \[$aprotect<c01>\]"
					SENT:MSG:TO:USER $vuser "<c01> Mask \[<c02>[getuser $value1 HOSTS]<c01>\]"
				}
				SENT:MSG:TO:USER $vuser "<c>"
			} else {
				SENT:MSG:TO:USER $vuser "Aucun Accès."
			}
		}
		"owner" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Owner :</b> /msg ${SERVICE_BOT(name)} owner #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}
			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0
				}
				FCT:SENT:MODE $value1 "+q" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Owner" "$value3 sur $value1 par $user"
				}
			} else {
				FCT:SENT:MODE $value1 "+q" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Owner" "$user sur $value1"
				}
			}
		}
		"deowner" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Deowner :</b> /msg ${SERVICE_BOT(name)} deowner #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "-q" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Deowner" "$value3 sur $value1 par $user"
				}
			} else {
				FCT:SENT:MODE $value1 "-q" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Deowner" "$user sur $value1"
				}
			}
		}
		"protect" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Protect :</b> /msg ${SERVICE_BOT(name)} protect #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "+a" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Protect" "$value3 sur $value1 par $user"
				}
			} else {
				FCT:SENT:MODE $value1 "+a" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Protect" "$user sur $value1"
				}
			}
		}
		"deprotect" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Deprotect :</b> /msg ${SERVICE_BOT(name)} deprotect #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "-a" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Deprotect" "$value3 sur $value1 par $user"
				}
			} else {
				FCT:SENT:MODE $value1 "-a" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Deprotect" "$user sur $value1"
				}
			}
		}
		"ownerall" {
			set config(cmd)		"ownerall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Ownerall :</b> /msg ${SERVICE_BOT(name)} ownerall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Ownerall" "$value1 par $user"
			}
		}
		"deownerall" {
			set config(cmd)		"deownerall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Deownerall :</b> /msg ${SERVICE_BOT(name)} deownerall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Deownerall" "$value1 par $user"
			}
		}
		"protectall" {
			set config(cmd)		"protectall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Protectall :</b> /msg ${SERVICE_BOT(name)} protectall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Protectall" "$value1 par $user"
			}
		}
		"deprotectall" {
			set config(cmd)		"deprotectall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Deprotectall :</b> /msg ${SERVICE_BOT(name)} deprotectall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Deprotectall" "$value1 par $user"
			}
		}
		"op" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Op :</b> /msg ${SERVICE_BOT(name)} op #salon pseudo";
				return 0
			}
			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0
			}
			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}
				FCT:SENT:MODE $value1 "+o" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Op" "$value3 a été opé par $user sur $value1"
				}
			} else {
				FCT:SENT:MODE $value1 "+o" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Op" "$user a été opé sur $value1"
				}
			}
		}
		"deop" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Deop :</b> /msg ${SERVICE_BOT(name)} deop #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "-o" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Deop" "$value3 a été déopé par $user sur $value1"
				}
			} else {
				FCT:SENT:MODE $value1 "-o" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Deop" "$user a été déopé sur $value1"
				}
			}
		}
		"halfop" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Halfop :</b> /msg ${SERVICE_BOT(name)} halfop #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "+h" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Halfop" "$value3 a été halfopé par $user sur $value1"
				}
			} else {
				FCT:SENT:MODE $value1 "+h" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Halfop" "$user a été halfopé sur $value1"
				}
			}
		}
		"dehalfop" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Dehalfop :</b> /msg ${SERVICE_BOT(name)} dehalfop #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "-h" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Dehalfop" "$value3 a été déhalfopé par $user sur $value1"
				}
			} else {
				FCT:SENT:MODE $value1 "-h" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Dehalfop" "$user a été déhalfopé sur $value1"
				}
			}
		}
		"voice" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Voice :</b> /msg ${SERVICE_BOT(name)} voice #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "+v" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Voice" "$value3 a été voicé par $user sur $value1"
				}
			} else {
				FCT:SENT:MODE $value1 "+v" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Voice" "$user a été voicé sur $value1"
				}
			}
		}
		"devoice" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Devoice :</b> /msg ${SERVICE_BOT(name)} devoice #salon pseudo";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value4 != "" } {
				if { ![info exists vhost($value4)] } {
					SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
					return 0;
				}

				FCT:SENT:MODE $value1 "-v" $value3
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Devoice" "$value3 a été dévoicé par $user sur $value1"
				}
			} else {
				FCT:SENT:MODE $value1 "-v" $user
				if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
					SHOW:INFO:TO:CHANLOG "Devoice" "$user a été dévoicé sur $value1"
				}
			}
		}
		"opall" {
			set config(cmd)		"opall"

			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Opall :</b> /msg ${SERVICE_BOT(name)} opall #salon";
				return 0;
			}
			sent2socket ":$config(link) NAMES $value1"

			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Opall" "$value1 par $user"
			}
		}
		"deopall" {
			set config(cmd)		"deopall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Deopall :</b> /msg ${SERVICE_BOT(name)} deopall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Deopall" "$value1 par $user"
			}
		}
		"halfopall" {
			set config(cmd)		"halfopall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Halfopall :</b> /msg ${SERVICE_BOT(name)} halfopall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Halfopall" "$value1 par $user"
			}
		}
		"dehalfopall" {
			set config(cmd)		"dehalfopall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Dehalfopall :</b> /msg ${SERVICE_BOT(name)} dehalfopall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Dehalfopall" "$value1 par $user"
			}
		}
		"voiceall" {
			set config(cmd)		"voiceall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Voiceall :</b> /msg ${SERVICE_BOT(name)} voiceall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Voiceall" "$value1 par $user"
			}
		}
		"devoiceall" {
			set config(cmd)		"devoiceall"
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Devoiceall :</b> /msg ${SERVICE_BOT(name)} devoiceall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Devoiceall" "$value1 par $user"
			}
		}
		"kick" {
			if { [string index $value1 0] != "#" || $value4 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Kick :</b> /msg ${SERVICE_BOT(name)} kick #salon pseudo raison";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value5 == "" } { set value5		"Kicked" }
			sent2socket ":${config(server_id)} KICK $value2 $value4 $value5 [rnick $user]"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Kick" "$value3 a été kické par $user sur $value1 - Raison : $value5"
			}
		}
		"kickall" {
			set config(cmd)		"kickall";
			set config(rep)		$user
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Kickall :</b> /msg ${SERVICE_BOT(name)} kickall #salon";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Kickall" "$value1 par $user"
			}
		}
		"ban" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Ban :</b> /msg ${SERVICE_BOT(name)} ban #salon mask";
				return 0;
			}

			FCT:SENT:MODE $value1 "+b" $value3
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Ban" "$value3 a été banni par $user sur $value1"
			}
		}
		"nickban" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Nickban :</b> /msg ${SERVICE_BOT(name)} nickban #salon pseudo raison";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { ![info exists vhost($value4)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			if { $value5 == "" } { set value5		"Nick Banned" }
			FCT:SENT:MODE $value1 "+b" "$value4*!*@*"
			sent2socket ":${config(server_id)} KICK $value1 $value3 $value5 [rnick $user]"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Nickban" "$value3 a été banni par $user sur $value1 - Raison : $value5"
			}
		}
		"kickban" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Kickban :</b> /msg ${SERVICE_BOT(name)} kickban #salon pseudo raison";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { ![info exists vhost($value4)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			if { $value5 == "" } { set value5		"Kick Banned" }
			FCT:SENT:MODE $value1 "+b" "*!*@$vhost($value4)"
			sent2socket ":${config(server_id)} KICK $value1 $value3 $value5 [rnick $user]"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Kickban" "$value3 a été banni par $user sur $value1 - Raison : $value5"
			}
		}
		"unban" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Unban :</b> /msg ${SERVICE_BOT(name)} unban #salon mask";
				return 0;
			}

			FCT:SENT:MODE $value1 "-b" $value3
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Unban" "$value3 a été débanni par $user sur $value1"
			}
		}
		"clearbans" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Clearbans :</b> /msg ${SERVICE_BOT(name)} clearbans #salon";
				return 0;
			}

			sent2socket ":${config(server_id)} SVSMODE $value1 -b"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Clearbans" "$value1 par $user"
			}
		}
		"topic" {
			if { [string index $value1 0] != "#" || $value6 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Topic :</b> /msg ${SERVICE_BOT(name)} topic #salon topic";
				return 0;
			}

			FCT:SET:TOPIC $value1 $value6
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Topic" "$user change le topic sur $value1 : $value6"
			}
		}
		"mode" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Mode :</b> /msg ${SERVICE_BOT(name)} mode #salon +/-mode";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}

			if { ![regexp ^\[\+\-\]+\[a-zA-Z\]+$ $value3] } {
				SENT:MSG:TO:USER $user "Chanmode Incorrect";
				return 0;
			}

			if { [string match *q* $value3] || [string match *a* $value3] ||[string match *o* $value3] ||[string match *h* $value3] ||[string match *v* $value3] } {
				SENT:MSG:TO:USER $user "Chanmode Refusé";
				return 0;
			}

			FCT:SENT:MODE $value1 $value6
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Mode" "$user applique le mode $value6 sur $value1"
			}
		}
		"clearmodes" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Clearmodes :</b> /msg ${SERVICE_BOT(name)} clearmodes #salon";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}

			FCT:SENT:MODE $value1
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Clearmodes" "$user sur $value1"
			}
		}
		"clearallmodes" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Clearallmodes :</b> /msg ${SERVICE_BOT(name)} clearallmodes #salon";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}

			sent2socket ":${config(server_id)} SVSMODE $value1 -beIqaohv"
			FCT:SENT:MODE $value1
			sent2socket ":${config(server_id)} SVSMODE $value1 -b"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Clearallmodes" "$user sur $value1"
			}
		}
		"kill" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Kill :</b> /msg ${SERVICE_BOT(name)} kill pseudo raison";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value2)] || [protection $value2 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { ![info exists vhost($value2)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			if { $value6 == "" } { set value6		"Killed" }
			sent2socket ":${config(server_id)} KILL $value1 $value6 [rnick $user]";
			refresh $value2
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Kill" "$value1 a été killé par $user : $value6"
			}
		}
		"chankill" {
			set config(cmd)		"chankill";
			set config(rep)		$user
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Chankill :</b> /msg ${SERVICE_BOT(name)} chankill #salon";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Chankill" "$value1 par $user"
			}
		}
		"svsjoin" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Svsjoin :</b> /msg ${SERVICE_BOT(name)} svsjoin #salon pseudo";
				return 0;
			}

			if { ![info exists vhost($value4)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			sent2socket ":${config(server_id)} SVSJOIN [UID:CONVERT $value3] $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Svsjoin" "$value3 entre sur $value1 par $user"
			}
		}
		"svspart" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Svspart :</b> /msg ${SERVICE_BOT(name)} svspart #salon pseudo";
				return 0;
			}

			if { ![info exists vhost($value4)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			if { $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value4)] || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			sent2socket ":${config(server_id)} SVSPART $value3 $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Svspart" "$value3 part de $value1 par $user"
			}
		}
		"svsnick" {
			if { $value1 == "" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Svsnick :</b> /msg ${SERVICE_BOT(name)} svsnick ancien-pseudo nouveau-pseudo";
				return 0;
			}

			if { $value2==$value4 } {
				SENT:MSG:TO:USER $vuser "Pseudo Identique.";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(name)}] || $value4 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value2)] || [info exists users($value4)] || [protection $value2 $config(protection)] == "ok" || [protection $value4 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { ![info exists vhost($value2)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable ($value1).";
				return 0;
			}

			if { [info exists vhost($value4)] } {
				SENT:MSG:TO:USER $vuser "Pseudo existant ($value3).";
				return 0;
			}

			sent2socket ":${config(SID)} SVSNICK [UID:CONVERT $value1] $value3 [unixtime]"
			if { [info exists vhost($value1)] && $value1!=$value3 } {
				set vhost($value3)		$vhost($value1);
				unset vhost($value1)
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Svsnick" "$user change le pseudo de $value1 en $value3"
			}
		}
		"say" {
			if { [string index $value1 0] != "#" || $value6 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Say :</b> /msg ${SERVICE_BOT(name)} say #salon message";
				return 0;
			}

			SENT:MSG:TO:USER $value1 "$value6"
			if { [console 1] == "ok" && $value2!=[string tolower ${SERVICE_BOT(channel_logs)}] } {
				SHOW:INFO:TO:CHANLOG "Say" "$user sur $value1 : $value6"
			}
		}
		"invite" {
			if { [string index $value1 0] != "#" || $value3 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Invite :</b> /msg ${SERVICE_BOT(name)} invite #salon pseudo";
				return 0;
			}

			if { ![info exists vhost($value4)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			sent2socket ":${config(server_id)} INVITE $value3 $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Invite" "$user invite $value3 sur $value1"
			}
		}
		"inviteme" {
			sent2socket ":${config(server_id)} INVITE $user ${SERVICE_BOT(channel_logs)}"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Inviteme" "$user"
			}
		}
		"wallops" {
			if { $value7 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Wallops :</b> /msg ${SERVICE_BOT(name)} wallops message";
				return 0;
			}

			sent2socket ":${config(server_id)} WALLOPS $value7 ($user)"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Wallops" "$user : $value7"
			}
		}
		"globops" {
			if { $value7 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Globops :</b> /msg ${SERVICE_BOT(name)} globops message";
				return 0;
			}

			sent2socket ":${config(server_id)} GLOBOPS $value7 ($user)"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Globops" "$user : $value7"
			}
		}
		"notice" {
			if { $value7 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Notice :</b> /msg ${SERVICE_BOT(name)} notice message";
				return 0;
			}

			SENT:MSG:TO:USER "$*.*" "\[<b>Notice Globale</b>\] $value7"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Notice" "$user"
			}
		}
		"whois" {
			set config(rep)		$vuser
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Whois :</b> /msg ${SERVICE_BOT(name)} whois pseudo";
				return 0;
			}

			if { ![info exists vhost($value2)] } {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}

			sent2socket ":${config(server_id)} WHOIS $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Whois" "$user"
			}
		}
		"changline" {
			set config(cmd)		"changline";
			set config(rep)		$user
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Changline :</b> /msg ${SERVICE_BOT(name)} changline #salon";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $user "Accès Refusé";
				return 0;
			}

			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Changline" "$value1 par $user"
			}
		}
		"gline" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Gline :</b> /msg ${SERVICE_BOT(name)} gline <pseudo ou ip> raison";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value2)] || [protection $value2 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value6 == "" } { set value6		"Glined" }
			if { [info exists vhost($value2)] } {
				sent2socket ":$config(link) TKL + G * $vhost($value2) ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] : $value6 [rnick $user] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} elseif { [string match *.* $value1] } {
				sent2socket ":$config(link) TKL + G * $value1 ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] : $value6 [rnick $user] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} else {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Gline" "$value1 par $user - Raison : $value6"
			}
		}
		"ungline" {
			if { $value1 == "" ||![string match *@* $value1] } {
				SENT:MSG:TO:USER $vuser "<b>Commande Ungline :</b> /msg ${SERVICE_BOT(name)} ungline ident@host";
				return 0;
			}

			sent2socket ":$config(link) TKL - G [lindex [split $value1 @] 0] [lindex [split $value1 @] 1] ${SERVICE_BOT(name)}"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Ungline" "$value1 par $user"
			}
		}
		"shun" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Shun :</b> /msg ${SERVICE_BOT(name)} shun <pseudo ou ip> raison";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value2)] || [protection $value2 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value6 == "" } { set value6		"Shun" }
			if { [info exists vhost($value2)] } {
				sent2socket ":$config(link) TKL + s * $vhost($value2) ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] : $value6 [rnick $user] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} elseif { [string match *.* $value1] } {
				sent2socket ":$config(link) TKL + s * $value1 ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] : $value6 [rnick $user] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} else {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Shun" "$value1 par $user - Raison : $value6"
			}
		}
		"unshun" {
			if { $value1 == "" ||![string match *@* $value1] } {
				SENT:MSG:TO:USER $vuser "<b>Commande Unshun :</b> /msg ${SERVICE_BOT(name)} unshun ident@host";
				return 0;
			}

			sent2socket ":$config(link) TKL - s [lindex [split $value1 @] 0] [lindex [split $value1 @] 1] ${SERVICE_BOT(name)}"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Unshun" "$value1 par $user"
			}
		}
		"kline" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Kline :</b> /msg ${SERVICE_BOT(name)} kline <pseudo ou ip> raison";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(name)}] || [info exists users($value2)] || [protection $value2 $config(protection)] == "ok" } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			if { $value6 == "" } { set value6		"Klined" }
			if { [info exists vhost($value2)] } {
				sent2socket ":$config(link) TKL + k * $vhost($value2) ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] : $value6 [rnick $user] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} elseif { [string match *.* $value1] } {
				sent2socket ":$config(link) TKL + k * $value1 ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] : $value6 [rnick $user] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} else {
				SENT:MSG:TO:USER $vuser "Pseudo introuvable.";
				return 0;
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Kline" "$value1 par $user - Raison : $value6"
			}
		}
		"unkline" {
			if { $value1 == "" || ![string match *@* $value1] } {
				SENT:MSG:TO:USER $vuser "<b>Commande Unkline :</b> /msg ${SERVICE_BOT(name)} unkline ident@host";
				return 0;
			}

			sent2socket ":$config(link) TKL - k [lindex [split $value1 @] 0] [lindex [split $value1 @] 1] ${SERVICE_BOT(name)}"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Unkline" "$value1 par $user"
			}
		}
		"glinelist" {
			set config(cmd)		"gline";
			set config(rep)		$vuser
			sent2socket ":${config(server_id)} STATS G"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Glinelist" "$user"
			}
		}
		"shunlist" {
			set config(cmd)		"shun";
			set config(rep)		$vuser
			sent2socket ":${config(server_id)} STATS s"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Shunlist" "$user"
			}
		}
		"klinelist" {
			set config(cmd)		"kline";
			set config(rep)		$vuser
			sent2socket ":${config(server_id)} STATS K"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Klinelist" "$user"
			}
		}
		"cleargline" {
			set config(cmd)		"cleargline"
			sent2socket ":${config(server_id)} STATS G"
			SENT:MSG:TO:USER $vuser "Liste des glines vidée."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Cleargline" "$user"
			}
		}
		"clearkline" {
			set config(cmd)		"clearkline"
			sent2socket ":${config(server_id)} STATS K"
			SENT:MSG:TO:USER $vuser "Liste des klines vidée."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Clearkline" "$user"
			}
		}
		"clientlist" {
			catch { open "[Script:Get:Directory]/db/client.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>------ <c0>Liste des clients IRC interdits <c1>------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste version;
				if { $version != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $version"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun client IRC"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Clientlist" "$user"
			}
		}
		"clientadd" {
			if { $value7 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande clientadd :</b> /msg ${SERVICE_BOT(name)} clientadd version";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/client.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value7 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value7</b> est déjà dans la liste des clients IRC interdits.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set bclient		[open "[Script:Get:Directory]/db/client.db" a];
			puts $bclient [string tolower $value7];
			close $bclient
			SENT:MSG:TO:USER $vuser "<b>$value7</b> a bien été ajouté à la liste des clients IRC interdits."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "clientadd" "$user"
			}
		}
		"clientdel" {
			if { $value7 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande clientdel :</b> /msg ${SERVICE_BOT(name)} clientdel version";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/client.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value7 $verif] } { set stop		1 }
				if { [string compare -nocase $value7 $verif] && $verif != "" } { lappend vers "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value7</b> n'est pas dans la liste des clients IRC interdits.";
				return 0;
			} else {
				if [info exists vers] {
					set del		[open "[Script:Get:Directory]/db/client.db" w+];
					foreach clientdel $vers { puts $del "$clientdel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/client.db" w+];
					close $del
				}
				SENT:MSG:TO:USER $vuser "<b>$value7</b> a bien été supprimé de la liste des clients IRC interdits."
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "clientdel" "$user"
				}
			}
		}
		"client" {
			if { $value2 != "on" && $value2 != "off" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Client :</b> /msg ${SERVICE_BOT(name)} client on/off";
				return 0;
			}

			if { $value2 == "on" } {
				if { $config(aclient) == 0 } {
					set config(aclient)		1;
					SENT:MSG:TO:USER $vuser "Protection clients IRC activée"
					if { [console 1] == "ok" } {
						SHOW:INFO:TO:CHANLOG "Client" "$user"
					}
				} else {
					SENT:MSG:TO:USER $vuser "La protection clients IRC est déjà activée."
				}
			} elseif { $value2 == "off" } {
				if { $config(aclient) == 1 } {
					set config(aclient)		0;
					SENT:MSG:TO:USER $vuser "Protection clients IRC désactivée"
					if { [console 1] == "ok" } {
						SHOW:INFO:TO:CHANLOG "Client" "$user"
					}
				} else {
					SENT:MSG:TO:USER $vuser "La protection clients IRC est déjà désactivée."
				}
			}
		}
		"closeadd" {
			set config(cmd)		"closeadd";
			set config(rep)		$user
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande Close add :</b> /msg ${SERVICE_BOT(name)} closeadd #salon";
				return 0;
			}

			if { $value2 == [string tolower ${SERVICE_BOT(channel_logs)}] } {
				SENT:MSG:TO:USER $user "Accès Refusé : Salon de logs";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/salon.db" r } liste1
			while { ![eof $liste1] } {
				gets $liste1 verif1;
				if { ![string compare -nocase $value2 $verif1] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Interdit";
					set stop		1;
					break
				}
			}
			catch { close $liste1 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/chan.db" r } liste3
			while { ![eof $liste3] } {
				gets $liste3 verif3;
				if { ![string compare -nocase $value2 $verif3] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Autojoin";
					set stop		1;
					break
				}
			}
			catch { close $liste3 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/close.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la liste des salons fermés.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set bclose		[open "[Script:Get:Directory]/db/close.db" a];
			puts $bclose $value2;
			close $bclose
			SENT:MSG:TO:USER $vuser "<b>$value1</b> vient d'être ajouté dans la liste des salons fermés."
			sent2socket ":${config(server_id)} JOIN $value1";
			FCT:SENT:MODE $value1 +sntio "${SERVICE_BOT(name)}";
			FCT:SET:TOPIC $value1 "<c1>Salon Fermé le [duree [unixtime]]"
			sent2socket ":$config(link) NAMES $value1"
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "closeadd" "$value1 par $user"
			}
		}
		"closedel" {
			if { [string index $value1 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande closedel :</b> /msg ${SERVICE_BOT(name)} closedel #salon";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/close.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop		1 }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend salon "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des salons fermés.";
				return 0;
			} else {
				if [info exists salon] {
					set del		[open "[Script:Get:Directory]/db/close.db" w+];
					foreach chandel $salon { puts $del "$chandel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/close.db" w+];
					close $del
				}
				SENT:MSG:TO:USER $user "<b>$value1</b> a bien été supprimé de la liste des salons fermés."
				FCT:SENT:MODE $value1
				FCT:SET:TOPIC $value1 "Bienvenue sur $value1"
				sent2socket ":${config(server_id)} PART $value1"
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "closedel" "$value1 par $user"
				}
			}
		}
		"closelist" {
			catch { open "[Script:Get:Directory]/db/close.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>------ <c0>Liste des salons fermés <c1>------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste salon;
				if { $salon != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c1> \[<c03> $stop <c01>\] <c01> $salon"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Salon."
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Closelist" "$user"
			}
		}
		"closeclear" {
			catch { open "[Script:Get:Directory]/db/close.db" r } liste
			while { ![eof $liste] } {
				gets $liste salon
				if { $salon != "" } {
					FCT:SENT:MODE $salon
					FCT:SET:TOPIC $salon "Bienvenue sur $salon"
					sent2socket ":${config(server_id)} PART $salon"
				}
			}
			catch { close $liste }
			set del		[open "[Script:Get:Directory]/db/close.db" w+];
			close $del
			SENT:MSG:TO:USER $user "La liste des salons fermés à bien été vidée."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "closeclear" "$user"
			}
		}
		"nickadd" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande nickadd :</b> /msg ${SERVICE_BOT(name)} nickadd pseudo";
				return 0;
			}

			if { [string match *$value2* [string tolower ${SERVICE_BOT(name)}]] } {
				SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
				return 0;
			}

			foreach { p n } [array get users] {
				if { [string match *$value2* $p] } {
					SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
					return 0;
				}

			}
			foreach { a r } [array get admins] {
				if { [string match *$value2* $r] } {
					SENT:MSG:TO:USER $user "Accès Refusé : Pseudo Protégé";
					return 0;
				}

			}
			catch { open "[Script:Get:Directory]/db/nick.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la liste des pseudos interdits.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set nick		[open "[Script:Get:Directory]/db/nick.db" a];
			puts $nick $value2;
			close $nick
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajouté dans la liste des pseudos interdits."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "nickadd" "$user"
			}
		}
		"nickdel" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande nickdel :</b> /msg ${SERVICE_BOT(name)} nickdel pseudo";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/nick.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop		1 }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend pseudo "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des pseudos interdits.";
				return 0;
			} else {
				if { [info exists pseudo] } {
					set del		[open "[Script:Get:Directory]/db/nick.db" w+];
					foreach nickdel $pseudo { puts $del "$nickdel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/nick.db" w+];
					close $del
				}
				SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimé de la liste des pseudos interdits."
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "nickdel" "$user"
				}
			}
		}
		"nicklist" {
			catch { open "[Script:Get:Directory]/db/nick.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>--------- <c0>Pseudos Interdits <c1>---------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste pseudo;
				if { $pseudo != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $pseudo"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Pseudo"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Nicklist" "$user"
			}
		}
		"identadd" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande identadd :</b> /msg ${SERVICE_BOT(name)} identadd ident";
				return 0;
			}

			if { [string match *$value2* [string tolower ${SERVICE_BOT(username)}]] } {
				SENT:MSG:TO:USER $user "Accès Refusé : Ident Protégé";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/ident.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la liste des idents interdits.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set ident		[open "[Script:Get:Directory]/db/ident.db" a];
			puts $ident $value2;
			close $ident
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajouté dans la liste des idents interdits."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "identadd" "$user"
			}
		}
		"identdel" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande identdel :</b> /msg ${SERVICE_BOT(name)} identdel ident";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/ident.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop		1 }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend ident "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des idents interdits.";
				return 0;
			} else {
				if { [info exists ident] } {
					set del		[open "[Script:Get:Directory]/db/ident.db" w+];
					foreach identdel $ident { puts $del "$identdel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/ident.db" w+];
					close $del
				}
				SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimé de la liste des idents interdits."
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "identdel" "$user"
				}
			}
		}
		"identlist" {
			catch { open "[Script:Get:Directory]/db/ident.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>---------- <c0>Idents Interdits <c1>----------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste ident;
				if { $ident != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $ident"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Ident"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Identlist" "$user"
			}
		}
		"realadd" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande realadd :</b> /msg ${SERVICE_BOT(name)} realadd realname";
				return 0;
			}

			if { [string match *$value2* [string tolower ${SERVICE_BOT(gecos)}]] } {
				SENT:MSG:TO:USER $user "Accès Refusé : Realname Protégé";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/real.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la liste des realnames interdits.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set real		[open "[Script:Get:Directory]/db/real.db" a];
			puts $real $value2;
			close $real
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajouté dans la liste des realnames interdits."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "realadd" "$user"
			}
		}
		"realdel" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande realdel :</b> /msg ${SERVICE_BOT(name)} realdel realname";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/real.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop		1 }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend real "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des realnames interdits.";
				return 0;
			} else {
				if { [info exists real] } {
					set del		[open "[Script:Get:Directory]/db/real.db" w+];
					foreach realdel $real { puts $del "$realdel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/real.db" w+];
					close $del
				}
				SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimé de la liste des realnames interdits."
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "realdel" "$user"
				}
			}
		}
		"reallist" {
			catch { open "[Script:Get:Directory]/db/real.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>--------- <c0>Realnames Interdits <c1>---------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste real;
				if { $real != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $real"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Realname"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Reallist" "$user"
			}
		}
		"hostadd" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande hostadd :</b> /msg ${SERVICE_BOT(name)} hostadd hostname";
				return 0;
			}

			if { [string match *$value2* [string tolower ${SERVICE_BOT(hostname)}]] || [info exists protect($value2)] } {
				SENT:MSG:TO:USER $user "Accès Refusé : Hostname Protégée";
				return 0;
			}

			foreach { mask num } [array get trust] {
				if { [string match *$value2* $mask] } {
					SENT:MSG:TO:USER $user "Accès Refusé : Hostname Trustée";
					return 0;
				}

			}
			catch { open "[Script:Get:Directory]/db/host.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la liste des hostnames interdites.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set host		[open "[Script:Get:Directory]/db/host.db" a];
			puts $host $value2;
			close $host
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajouté dans la liste des hostnames interdites."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "hostadd" "$user"
			}
		}
		"hostdel" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande hostdel :</b> /msg ${SERVICE_BOT(name)} hostdel hostname";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/host.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop		1 }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend host "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des hostnames interdites.";
				return 0;
			} else {
				if { [info exists host] } {
					set del		[open "[Script:Get:Directory]/db/host.db" w+];
					foreach hostdel $host { puts $del "$hostdel" }
					close $del
				} else {
					set del		[open "[Script:Get:Directory]/db/host.db" w+];
					close $del
				}
				SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimé de la liste des hostnames interdites."
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "hostdel" "$user"
				}
			}
		}
		"hostlist" {
			catch { open "[Script:Get:Directory]/db/host.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>----------- <c0>Hostnames Interdites <c1>-----------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste host;
				if { $host != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $host"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucune Hostname"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Hostlist" "$user"
			}
		}
		"chanadd" {
			if { [string index $value2 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande chanadd :</b> /msg ${SERVICE_BOT(name)} chanadd #salon";
				return 0;
			}

			if { [string match *[string trimleft $value2 #]* [string trimleft [string tolower ${SERVICE_BOT(channel_logs)}] #]] } {
				SENT:MSG:TO:USER $user "Accès Refusé : Salon de logs";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/chan.db" r } liste1
			while { ![eof $liste1] } {
				gets $liste1 verif1;
				if { [string match *[string trimleft $value2 #]* [string trimleft $verif1 #]] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Autojoin";
					set stop		1;
					break
				}
			}
			catch { close $liste1 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/close.db" r } liste2
			while { ![eof $liste2] } {
				gets $liste2 verif2;
				if { [string match *[string trimleft $value2 #]* [string trimleft $verif2 #]] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Salon Fermé";
					set stop		1;
					break
				}
			}
			catch { close $liste2 }
			if { $stop == 1 } { return 0 }
			catch { open "[Script:Get:Directory]/db/salon.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la liste des salons interdits.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set chan		[open "[Script:Get:Directory]/db/salon.db" a];
			puts $chan $value2;
			close $chan
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajouté dans la liste des salons interdits."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "chanadd" "$user"
			}
		}
		"chandel" {
			if { [string index $value2 0] != "#" } {
				SENT:MSG:TO:USER $vuser "<b>Commande chandel :</b> /msg ${SERVICE_BOT(name)} chandel #salon";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/salon.db" r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { ![string compare -nocase $value2 $verif] } { set stop 1; }
				if { [string compare -nocase $value2 $verif] && $verif != "" } { lappend chan "$verif"; }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des salons interdits.";
				return 0;
			} else {
				if { [info exists chan] } {
					set FILE_PIPE		[open "[Script:Get:Directory]/db/salon.db" w+];
					foreach chandel $chan { puts $FILE_PIPE "$chandel" }
					close $FILE_PIPE
				} else {
					set FILE_PIPE		[open "[Script:Get:Directory]/db/salon.db" w+];
					close $FILE_PIPE
				}
				sent2socket ":${config(server_id)} PART $value1"
				SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimé de la liste des salons interdits."
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "chandel" "$user"
				}
			}
		}
		"chanlist" {
			catch { open "[Script:Get:Directory]/db/salon.db" r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>--------- <c0>Salons Interdits <c1>---------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste chan;
				if { $chan != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $chan"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Salon"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Chanlist" "$user"
			}
		}
		"trustadd" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande trustadd :</b> /msg ${SERVICE_BOT(name)} trustadd mask";
				return 0;
			}

			catch { open "[Script:Get:Directory]/db/host.db" r } liste1
			while { ![eof $liste1] } {
				gets $liste1 verif1;
				if { [string match *$value2* $verif1] } {
					SENT:MSG:TO:USER $vuser "Accès Refusé : Hostname Interdite";
					set stop		1;
					break
				}
			}
			catch { close $liste1 }
			if { $stop == 1 } { return 0 }
			catch { open [Script:Get:Directory]/db/trust.db r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { $verif==$value2 } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déjà dans la trustlist.";
					set stop		1;
					break
				}
			}
			catch { close $liste }
			if { $stop == 1 } { return 0 }
			set bprotect		[open [Script:Get:Directory]/db/trust.db a];
			puts $bprotect "$value2";
			close $bprotect
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajoutée dans la trustlist."
			if { ![info exists trust($value2)] } { set trust($value2)		1 }
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "trustadd" "$user"
			}
		}
		"trustdel" {
			if { $value2 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande trustdel :</b> /msg ${SERVICE_BOT(name)} trustdel mask";
				return 0;
			}

			catch { open [Script:Get:Directory]/db/trust.db r } liste
			while { ![eof $liste] } {
				gets $liste verif;
				if { $verif==$value2 } { set stop		1 }
				if { $verif!=$value2 && $verif != "" } { lappend hs "$verif" }
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la trustlist.";
				return 0;
			} else {
				if { [info exists hs] } {
					set del		[open [Script:Get:Directory]/db/trust.db w+];
					foreach delprotect $hs { puts $del "$delprotect" }
					close $del
				} else {
					set del		[open [Script:Get:Directory]/db/trust.db w+];
					close $del
				}
				SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimée de la trustlist."
				if { [info exists trust($value2)] } { unset trust($value2)		}
				if { [console 1] == "ok" } {
					SHOW:INFO:TO:CHANLOG "trustdel" "$user"
				}
			}
		}
		"trustlist" {
			catch { open [Script:Get:Directory]/db/trust.db r } liste
			SENT:MSG:TO:USER $vuser "<b><c1,1>----------------- <c0>Liste des Trusts <c1>-----------------"
			SENT:MSG:TO:USER $vuser "<b>"
			while { ![eof $liste] } {
				gets $liste mask;
				if { $mask != "" } {
					incr stop 1;
					SENT:MSG:TO:USER $vuser "<c01> \[<c03> $stop <c01>\] <c01> $mask"
				}
			}
			catch { close $liste }
			if { $stop == 0 } {
				SENT:MSG:TO:USER $vuser "Aucun Trust"
			}
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "Trustlist" "$user"
			}
		}
		"accessadd" {
			if {
				$value2 == "" || \
					$value4 == "" || \
					$value8 == "" || \
					[regexp \[^1-4\] $value8]
			} {
				SENT:MSG:TO:USER $vuser "<b>Commande accessadd :</b> /msg ${SERVICE_BOT(name)} accessadd pseudo password level"
				SENT:MSG:TO:USER $vuser "<c02>Level 1 <c04>:<c01> Helpeur"
				SENT:MSG:TO:USER $vuser "<c02>Level 2 <c04>:<c01> Géofront"
				SENT:MSG:TO:USER $vuser "<c02>Level 3 <c04>:<c01> IRCop"
				SENT:MSG:TO:USER $vuser "<c02>Level 4 <c04>:<c01> Admin"
				return 0
			}
			if { [string length $value2]>="10" } {
				SENT:MSG:TO:USER $vuser "Le pseudo doit contenir maximum 9 caractères.";
				return 0;
			}

			foreach verif [userlist] {
				if { [string tolower $value2] == [string tolower $verif] } {
					SENT:MSG:TO:USER $vuser "<b>$value1</b> est déja dans la liste des accès.";
					return 0;
				}

			}
			if { [string length $value4] <= 5 } {
				SENT:MSG:TO:USER $vuser "Le mot de passe doit contenir minimum 6 caractères.";
				return 0;
			}

			adduser $value1;
			setuser $value1 PASS $value3;
			setuser $value1 HOSTS $value1*!*@*;
			setuser $value1 HOSTS -telnet!*@*
			switch -exact $value8 {
				1 {
					chattr $value1 +p;
					set lvl		"helpeurs"
				}
				2 {
					chattr $value1 +op;
					set lvl		"géofronts"
				}
				3 {
					chattr $value1 +mop;
					set lvl		"IRCops"
				}
				4 {
					chattr $value1 +nmop;
					set lvl		"Admins"
				}
			}
			SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été ajouté dans la liste des $lvl."
			if { [console 1] == "ok" } {
				SHOW:INFO:TO:CHANLOG "accessadd" "$user"
			}
		}
		"accessdel" {
			if { $value1 == "" } {
				SENT:MSG:TO:USER $vuser "<b>Commande accessdel :</b> /msg ${SERVICE_BOT(name)} accessdel pseudo";
				return 0;
			}

			if { [string tolower $admin] == $value2 } {
				SENT:MSG:TO:USER $vuser "Accès Refusé.";
				return 0;
			}

			foreach verif [userlist] {
				if { $value2 == [string tolower $verif] } {
					foreach { pseudo auth } [array get admins] {
						if { [string tolower $auth] == $value2 } { unset admins([string tolower $pseudo]) }
					}
					deluser $value2
					SENT:MSG:TO:USER $vuser "<b>$value1</b> a bien été supprimé de la liste des accès."
					if { [console 1] == "ok" } {
						SHOW:INFO:TO:CHANLOG "accessdel" "$user"
					}
					return 0
				}
			}
			SENT:MSG:TO:USER $vuser "<b>$value1</b> n'est pas dans la liste des accès."
		}
		"accessmod" {
			if { $value2 != "level" && $value2 != "pass" } {
				SENT:MSG:TO:USER $vuser "<b>Commande accessmod Pass :</b> /msg ${SERVICE_BOT(name)} accessmod pass pseudo mot-de-passe"
				SENT:MSG:TO:USER $vuser "<b>Commande accessmod Level :</b> /msg ${SERVICE_BOT(name)} accessmod level pseudo level"
				return 0
			}
			switch -exact $value2 {
				"level"	{
					if {
						$value4 == "" || \
							$value8 == "" || \
							[regexp \[^1-4\] $value8]
					} {
						SENT:MSG:TO:USER $vuser "<b>Commande accessmod Level :</b> /msg ${SERVICE_BOT(name)} accessmod level pseudo level"
						SENT:MSG:TO:USER $vuser "<c02>Level 1 <c04>:<c01> Helpeur"
						SENT:MSG:TO:USER $vuser "<c02>Level 2 <c04>:<c01> Géofront"
						SENT:MSG:TO:USER $vuser "<c02>Level 3 <c04>:<c01> IRCop"
						SENT:MSG:TO:USER $vuser "<c02>Level 4 <c04>:<c01> Admin"
						return 0
					}
					if { [string tolower $admin] == $value4 } {
						SENT:MSG:TO:USER $vuser "Accès Refusé.";
						return 0;
					}

					foreach verif [userlist] {
						if { $value4 == [string tolower $verif] } {
							switch -exact $value8 {
								1 {
									chattr $value4 -nmopjltx;
									chattr $value4 +p
								}
								2 {
									chattr $value4 -nmopjltx;
									chattr $value4 +op
								}
								3 {
									chattr $value4 -nmopjltx;
									chattr $value4 +mop
								}
								4 {
									chattr $value4 -nmopjltx;
									chattr $value4 +nmop
								}
							}
							SENT:MSG:TO:USER $vuser "Changement du level de <b>$value4</b> reussi."
							if { [console 1] == "ok" } {
								SHOW:INFO:TO:CHANLOG "accessmod" "$user"
							}
							return 0
						}
					}
					SENT:MSG:TO:USER $vuser "<b>$value4</b> n'est pas dans la liste des accès.";
					return 0;
				}
				"pass" {
					if { $value4 == "" || $value8 == "" } {
						SENT:MSG:TO:USER $vuser "<b>Commande accessmod Pass :</b> /msg ${SERVICE_BOT(name)} accessmod pass pseudo mot-de-passe";
						return 0;
					}

					if { [string tolower $admin] == $value4 } {
						SENT:MSG:TO:USER $vuser "Accès Refusé.";
						return 0;
					}

					foreach verif [userlist] {
						if { $value4 == [string tolower $verif] } {
							if { [string length $value8] <= 5 } {
								SENT:MSG:TO:USER $vuser "Le mot de passe doit contenir minimum 6 caractères.";
								return 0;
							}
							setuser $value3 PASS $value8
							SENT:MSG:TO:USER $vuser "Changement du mot de passe de <b>$value4</b> reussi."
							if { [console 1] == "ok" } {
								SHOW:INFO:TO:CHANLOG "accessmod" "$user"
							}
							return 0
						}
					}
					SENT:MSG:TO:USER $vuser "<b>$value4</b> n'est pas dans la liste des accès.";
					return 0;
				}
			}
		}
		default {
			putlog "socket => command inconue $arg"
		}
	}
}
proc ::EvaServ::help:description:help {}			{ return "Permet de voir l'aide détaillée de la commande." }
proc ::EvaServ::help:description:auth {}			{
	variable config
	return "Permet de vous authentifier sur ${SERVICE_BOT(name)}."
}
proc ::EvaServ::help:description:copyright {}		{
	variable config
	return "Permet de voir l'auteur de ${SERVICE_BOT(name)}."
}
proc ::EvaServ::help:description:deauth {}			{
	variable config
	return "Permet de vous déauthentifier sur ${SERVICE_BOT(name)}."
}
proc ::EvaServ::help:description:seen {}			{ return "Permet de voir la dernière authentification du pseudo." }
proc ::EvaServ::help:description:showcommands {}	{
	variable SCRIPT
	 return "Permet de voir la liste des commandes de ${SCRIPT(name)}."
}
proc ::EvaServ::help:description:map {}				{ return "Permet de voir la liste des serveurs." }
proc ::EvaServ::help:description:whois {}			{ return "Permet de voir le whois d'un utilisateur." }
proc ::EvaServ::help:description:access {}			{ return "Permet de voir l'accès du pseudo." }
proc ::EvaServ::help:description:ban {}				{ return "Permet de bannir un mask d'un salon." }
proc ::EvaServ::help:description:clearallmodes {}	{ return "Permet de retirer tous les modes, tous les accès et tous les bans d'un salon." }
proc ::EvaServ::help:description:clearbans {}		{ return "Permet de débannir tous les masks d'un salon." }
proc ::EvaServ::help:description:clearmodes {}		{ return "Permet de retirer tous les modes d'un salon." }
proc ::EvaServ::help:description:dehalfop {}		{ return "Permet de déhalfoper un utilisateur d'un salon." }
proc ::EvaServ::help:description:dehalfopall {}		{ return "Permet de déhalfoper tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:deop {}			{ return "Permet de déoper un utilisateur d'un salon." }
proc ::EvaServ::help:description:deopall {}			{ return "Permet de déoper tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:deowner {}			{ return "Permet de retirer un utilisateur owner d'un salon." }
proc ::EvaServ::help:description:deownerall {}		{ return "Permet de retirer tous les utilisateurs owner d'un salon." }
proc ::EvaServ::help:description:deprotect {}		{ return "Permet de retirer un utilisateur protect d'un salon." }
proc ::EvaServ::help:description:deprotectall {}	{ return "Permet de retirer tous les utilisateurs protect d'un salon." }
proc ::EvaServ::help:description:devoice {}			{ return "Permet de dévoicer un utilisateur d'un salon." }
proc ::EvaServ::help:description:devoiceall {}		{ return "Permet de dévoicer tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:gline {}			{ return "Permet de gline un utilisateur du serveur." }
proc ::EvaServ::help:description:glinelist {}		{ return "Permet de voir la liste des glines." }
proc ::EvaServ::help:description:shunlist {}		{ return "Permet de voir la liste des shuns." }
proc ::EvaServ::help:description:globops {}			{ return "Permet d'envoyer un message en globops à tous les ircops et admins." }
proc ::EvaServ::help:description:halfop {}			{ return "Permet d'halfoper un utilisateur d'un salon." }
proc ::EvaServ::help:description:halfopall {}		{ return "Permet d'halfoper tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:invite {}			{ return "Permet d'inviter un utilisateur sur un salon." }
proc ::EvaServ::help:description:inviteme {}		{
	variable config
	return "Permet de s'inviter sur ${SERVICE_BOT(channel_logs)}."
}
proc ::EvaServ::help:description:kick {}			{ return "Permet de kicker un utilisateur d'un salon." }
proc ::EvaServ::help:description:kickall {}			{ return "Permet de kicker tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:kickban {}			{ return "Permet de bannir et kicker un utilisateur d'un salon." }
proc ::EvaServ::help:description:kill {}			{ return "Permet de killer un utilisateur du serveur." }
proc ::EvaServ::help:description:kline {}			{ return "Permet de kline un utilisateur du serveur." }
proc ::EvaServ::help:description:klinelist {}		{ return "Permet de voir la liste des klines."}
proc ::EvaServ::help:description:mode {}			{ return "Permet de changer les modes d'un salon." }
proc ::EvaServ::help:description:newpass {}			{ return "Permet de changer le mot de passe de votre accès." }
proc ::EvaServ::help:description:nickban {}			{ return "Permet de bannir et kicker un utilisateur d'un salon en fonction de son pseudo." }
proc ::EvaServ::help:description:op {}				{ return "Permet d'oper un utilisateur d'un salon." }
proc ::EvaServ::help:description:opall {}			{ return "Permet d'oper tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:owner {}			{ return "Permet de mêttre un utilisateur owner d'un salon." }
proc ::EvaServ::help:description:ownerall {}		{ return "Permet de mêttre tous les utilisateurs owner d'un salon." }
proc ::EvaServ::help:description:protect {}			{ return "Permet de mêttre un utilisateur protect d'un salon." }
proc ::EvaServ::help:description:protectall {}		{ return "Permet de mêttre tous les utilisateurs protect d'un salon." }
proc ::EvaServ::help:description:topic {}			{ return "Permet de changer le topic d'un salon." }
proc ::EvaServ::help:description:unban {}			{ return "Permet de débannir un mask d'un salon."}
proc ::EvaServ::help:description:ungline {}			{ return "Permet de supprimer un mask de la liste des glines." }
proc ::EvaServ::help:description:unshun {}			{ return "Permet de unshun un utilisateur du serveur." }
proc ::EvaServ::help:description:unkline {}			{ return "Permet de supprimer un mask de la liste des klines." }
proc ::EvaServ::help:description:voice {}			{ return "Permet de voicer un utilisateur d'un salon." }
proc ::EvaServ::help:description:voiceall {}		{ return "Permet de voicer tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:wallops {}			{ return "Permet d'envoyer un message en wallops à tous les utilisateurs." }
proc ::EvaServ::help:description:changline {}		{ return "Permet de gline tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:chankill {}		{ return "Permet de killer tous les utilisateurs d'un salon." }
proc ::EvaServ::help:description:chanlist {}		{ return "Permet de voir la liste des salons interdits." }
proc ::EvaServ::help:description:closeclear {}		{ return "Permet de vider la liste des salons fermés." }
proc ::EvaServ::help:description:cleargline {}		{ return "Permet de retirer tous les glines du serveur." }
proc ::EvaServ::help:description:clearkline {}		{ return "Permet de retirer tous les klines du serveur." }
proc ::EvaServ::help:description:clientlist {}		{ return "Permet de voir la liste des clients IRC interdits."}
proc ::EvaServ::help:description:closeadd {}		{ return "Permet de fermer un salon." }
proc ::EvaServ::help:description:closelist {}		{ return "Permet de voir la liste des salons fermés." }
proc ::EvaServ::help:description:hostlist {}		{ return "Permet de voir la liste des hostnames interdites." }
proc ::EvaServ::help:description:identlist {}		{ return "Permet de voir la liste des idents interdits." }
proc ::EvaServ::help:description:join {}			{
	variable config
	return "Permet de faire joindre ${SERVICE_BOT(name)} sur un salon."
}
proc ::EvaServ::help:description:list {}			{ return "Permet de voir les autojoin salons."}
proc ::EvaServ::help:description:nicklist {}		{ return "Permet de voir la liste des pseudos interdits." }
proc ::EvaServ::help:description:notice {}			{ return "Permet d'envoyer une notice à tous les utilisateurs."}
proc ::EvaServ::help:description:part {}			{
	variable config
	return "Permet de faire partir ${SERVICE_BOT(name)} d'un salon."
}
proc ::EvaServ::help:description:reallist {}		{ return "Permet de voir la liste des realnames interdits." }
proc ::EvaServ::help:description:say {}				{ return "Permet d'envoyer un message sur un salon." }
proc ::EvaServ::help:description:status {}			{ return "Permet de voir les informations de ${SCRIPT(name)}." }
proc ::EvaServ::help:description:svsjoin {}			{ return "Permet de forcer un utilisateur à joindre un salon." }
proc ::EvaServ::help:description:svsnick {}			{ return "Permet de changer le pseudo d'un utilisateur."}
proc ::EvaServ::help:description:svspart {}			{ return "Permet de forcer un utilisateur à partir d'un salon." }
proc ::EvaServ::help:description:trustlist {}		{ return "Permet de voir la liste des trusts." }
proc ::EvaServ::help:description:closedel {}		{ return "Permet d'ouvrir un salon fermé." }
proc ::EvaServ::help:description:accessadd {}		{ return "Permet d'ajouter un accès sur ${SCRIPT(name)}." }
proc ::EvaServ::help:description:chanadd {}			{ return "Permet d'ajouter un salon interdit." }
proc ::EvaServ::help:description:clientadd {}		{ return "Permet d'ajouter un client IRC interdit." }
proc ::EvaServ::help:description:hostadd {}			{ return "Permet d'ajouter une hostname interdite." }
proc ::EvaServ::help:description:identadd {}		{ return "Permet d'ajouter un ident interdit." }
proc ::EvaServ::help:description:nickadd {}			{ return "Permet d'ajouter un pseudo interdit." }
proc ::EvaServ::help:description:realadd {}			{ return "Permet d'ajouter un realname interdit." }
proc ::EvaServ::help:description:trustadd {}		{ return "Permet d'ajouter un trust sur un mask." }
proc ::EvaServ::help:description:backup {}			{ return "Permet de créer une sauvegarde des databases." }
proc ::EvaServ::help:description:chanlog {}			{
	variable config
	return "Permet de changer le salon de log de ${SERVICE_BOT(name)}."
}
proc ::EvaServ::help:description:client {}			{ return "Permet d'activer ou désactiver les clients IRC interdits." }
proc ::EvaServ::help:description:console {}			{ return "Permet d'activer la console des logs en fonction du level." }
proc ::EvaServ::help:description:accessdel {}		{ return "Permet de supprimer un accès de ${SCRIPT(name)}." }
proc ::EvaServ::help:description:chandel {}			{ return "Permet de supprimer un salon interdit." }
proc ::EvaServ::help:description:clientdel {}		{ return "Permet de supprimer un client IRC interdit." }
proc ::EvaServ::help:description:hostdel {}			{ return "Permet de supprimer une hostname interdite." }
proc ::EvaServ::help:description:identdel {}		{ return "Permet de supprimer un ident interdit." }
proc ::EvaServ::help:description:nickdel {}			{ return "Permet de supprimer un pseudo interdit." }
proc ::EvaServ::help:description:realdel {}			{ return "Permet de supprimer un realname interdit." }
proc ::EvaServ::help:description:trustdel {}		{ return "Permet de supprimer le trust d'un mask." }
proc ::EvaServ::help:description:die {}				{ return "Permet d'arrêter ${SCRIPT(name)}." }
proc ::EvaServ::help:description:maxlogin {}		{ return "Permet d'activer où désactiver la protection max login." }
proc ::EvaServ::help:description:accessmod {}		{ return "Permet de modifier un accès de ${SCRIPT(name)}." }
proc ::EvaServ::help:description:protection {}		{ return "Permet d'activer la protection en fonction du level." }
proc ::EvaServ::help:description:restart {}			{ return "Permet de redémarrer ${SCRIPT(name)}." }
proc ::EvaServ::help:description:shun {}			{ return "Permet de shun un utilisateur du serveur." }


proc ::EvaServ::Commands:Help { NICK_SOURCE hcmd } {
	variable config
	if { [authed ${NICK_SOURCE} $hcmd] != "ok" } { return 0 }
	switch -exact $hcmd {
		"help" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} help nom-de-la-commande"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:help]
		}
		"auth" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} auth pseudo mot-de-passe"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:auth]
		}
		"copyright" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} copyright"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:copyright]
		}
		"deauth" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deauth"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deauth]
		}
		"seen" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} seen pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:seen]
		}
		"showcommands" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} showcommands"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:showcommands]
		}
		"map" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} map"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:map]
		}
		"whois" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} whois pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:whois]
		}
		"shun" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} shun <pseudo ou ip> raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:shun]
		}
		"access" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} access pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:access]
		}
		"ban" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} ban #salon mask"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:ban]
		}
		"clearallmodes" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clearallmodes #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clearallmodes]
		}
		"clearbans" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clearbans #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clearbans]
		}
		"clearmodes" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clearmodes #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clearmodes]
		}
		"dehalfop" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} dehalfop #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:dehalfop]
		}
		"dehalfopall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} dehalfopall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:dehalfopall]
		}
		"deop" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deop #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deop]
		}
		"deopall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deopall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deopall]
		}
		"deowner" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deowner #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deowner]
		}
		"deownerall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deownerall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deownerall]
		}
		"deprotect" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deprotect #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deprotect]
		}
		"deprotectall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} deprotectall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:deprotectall]
		}
		"devoice" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} devoice #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:devoice]
		}
		"devoiceall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} devoiceall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:devoiceall]
		}
		"gline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} gline <pseudo ou ip> raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:gline]
		}
		"glinelist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} glinelist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:glinelist]
		}
		"shunlist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} shunlist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:shunlist]
		}
		"globops" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} globops message"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:globops]
		}
		"halfop" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} halfop #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:halfop]
		}
		"halfopall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} halfopall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:halfopall]
		}
		"invite" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} invite #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:invite]
		}
		"inviteme" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} inviteme"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:inviteme]
		}
		"kick" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} kick #salon pseudo raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:kick]
		}
		"kickall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} kickall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:kickall]
		}
		"kickban" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} kickban #salon pseudo raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:kickban]
		}
		"kill" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} kill pseudo raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:kill]
		}
		"kline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} kline <pseudo ou ip> raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:kline]
		}
		"klinelist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} klinelist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:klinelist]
		}
		"mode" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} mode #salon +/-mode"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:mode]
		}
		"newpass" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} newpass mot-de-passe"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:newpass]
		}
		"nickban" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} nickban #salon pseudo raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:nickban]
		}
		"op" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} op #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:op]
		}
		"opall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} opall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:opall]
		}
		"owner" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} owner #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:owner]
		}
		"ownerall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} ownerall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:ownerall]
		}
		"protect" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} protect #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:protect]
		}
		"protectall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} protectall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:protectall]
		}
		"topic" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} topic #salon topic"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:topic]
		}
		"unban" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} unban #salon mask"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:unban]
		}
		"ungline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} ungline ident@host"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:ungline]
		}
		"unshun" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} unshun pseudo raison"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:unshun]
		}
		"unkline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} unkline ident@host"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:unkline]
		}

		"voice" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} voice #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:voice]
		}
		"voiceall" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} voiceall #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:voiceall]
		}
		"wallops" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} wallops message"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:wallops]
		}
		"changline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} changline #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:changline]
		}
		"chankill" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} chankill #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:chankill]
		}
		"chanlist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} chanlist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:chanlist]
		}
		"closeclear" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} closeclear"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:closeclear]
		}
		"cleargline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} cleargline"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:cleargline]
		}
		"clearkline" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clearkline"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clearkline]
		}
		"clientlist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clientlist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clientlist]
		}
		"closeadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} closeadd #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:closeadd]
		}
		"closelist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} closelist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:closelist]
		}
		"hostlist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} hostlist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:hostlist]
		}
		"identlist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} identlist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:identlist]
		}
		"join" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} join #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:join]
		}
		"list" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} list"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:list]
		}
		"nicklist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} nicklist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:nicklist]
		}
		"notice" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} notice message"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:notice]
		}
		"part" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} part #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:part]
		}
		"reallist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} reallist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:reallist]
		}
		"say" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} say #salon message"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:say]
		}
		"status" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} status"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:status]
		}
		"svsjoin" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} svsjoin #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:svsjoin]
		}
		"svsnick" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} svsnick ancien-pseudo nouveau-pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:svsnick]
		}
		"svspart" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} svspart #salon pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:svspart]
		}
		"trustlist" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} trustlist"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:trustlist]
		}
		"closedel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} closedel #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:closedel]
		}
		"accessadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} accessadd pseudo password level"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:accessadd]
		}
		"chanadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} chanadd #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:chanadd]
		}
		"clientadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clientadd version"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clientadd]
		}
		"hostadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} hostadd hostname"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:hostadd]
		}
		"identadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} identadd ident"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:identadd]
		}
		"nickadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} nickadd pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:nickadd]
		}
		"realadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} realadd realname"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:realadd]
		}
		"trustadd" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} trustadd mask"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:trustadd]
		}
		"backup" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} backup"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:backup]
		}
		"chanlog" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} chanlog #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:chanlog]
		}
		"client" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} client on/off"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:client]
		}
		"console" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} console 0/1/2/3"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 0 <c04>:<c01> Aucune console"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 1 <c04>:<c01> Console commande"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 2 <c04>:<c01> Console commande & connexion & déconnexion"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 3 <c04>:<c01> Toutes les consoles"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:console]
		}
		"accessdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} accessdel pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:accessdel]
		}
		"chandel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} chandel #salon"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:chandel]
		}
		"clientdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} clientdel version"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:clientdel]
		}
		"hostdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} hostdel hostname"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:hostdel]
		}
		"identdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} identdel ident"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:identdel]
		}
		"nickdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} nickdel pseudo"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:nickdel]
		}
		"realdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} realdel realname"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:realdel]
		}
		"trustdel" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} trustdel mask"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:trustdel]
		}
		"die" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} die"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:die]
		}
		"maxlogin" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} maxlogin on/off"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:maxlogin]
		}
		"accessmod" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} accessmod pass pseudo mot-de-passe"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} accessmod level pseudo level"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:accessmod]
		}
		"protection" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} protection 0/1/2/3/4"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 0 <c04>:<c01> Aucune Protection"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 1 <c04>:<c01> Protection Admins"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 2 <c04>:<c01> Protection Admins + Ircops"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 3 <c04>:<c01> Protection Admins + Ircops + Géofronts"
			SENT:MSG:TO:USER ${NICK_SOURCE} "<c02>Level 4 <c04>:<c01> Protection de tous les accès"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:protection]
		}
		"restart" {
			SENT:MSG:TO:USER ${NICK_SOURCE} "<b>Commande Help :</b> /msg ${SERVICE_BOT(name)} restart"
			SENT:MSG:TO:USER ${NICK_SOURCE} [help:description:restart]
		}
	}
}

#################
# Eva Connexion #
#################

proc ::EvaServ::connexion:server { } {
	variable config
	sent2socket "EOS"
	sent2socket ":${config(SID)} SQLINE ${SERVICE_BOT(name)} :Reserved for services"
	sent2socket ":${config(SID)} UID ${SERVICE_BOT(name)} 1 [unixtime] ${SERVICE_BOT(username)} ${SERVICE_BOT(hostname)} ${config(server_id)} * +qioS * * * :${SERVICE_BOT(gecos)}"
	sent2socket ":${config(SID)} SJOIN [unixtime] ${SERVICE_BOT(channel_logs)} + :${config(server_id)}"
	sent2socket ":${config(SID)} MODE ${SERVICE_BOT(channel_logs)} +$config(smode)"
	for { set i		0 } { $i < [string length ${config(chanmode)}] } { incr i } {
		set tmode		[string index ${config(chanmode)} $i]
		if { $tmode == "q" || $tmode == "a" || $tmode == "o" || $tmode == "h" || $tmode == "v" } {
			FCT:SENT:MODE ${SERVICE_BOT(channel_logs)} "+$tmode" ${config(server_id)}
		}
	}
	catch { open "[Script:Get:Directory]/db/chan.db" r } autojoin
	while { ![eof ${autojoin}] } {
		gets ${autojoin} salon;
		if { $salon != "" } {
			sent2socket ":${config(server_id)} JOIN $salon";
			if { ${config(chanmode)} == "q" || ${config(chanmode)} == "a" || ${config(chanmode)} == "o" || ${config(chanmode)} == "h" || ${config(chanmode)} == "v" } {
				FCT:SENT:MODE $salon "+${config(chanmode)}" ${config(server_id)}
			}
		}
	}
	catch { close ${autojoin} }
	catch { open "[Script:Get:Directory]/db/close.db" r } ferme
	while { ![eof $ferme] } {
		gets $ferme salle;
		if { $salle != "" } {
			sent2socket ":${config(server_id)} JOIN $salle";
			FCT:SENT:MODE $salle "+sntio" ${SERVICE_BOT(name)};
			FCT:SET:TOPIC $salle "<c1>Salon Fermé le [duree [unixtime]]";
			sent2socket ":$config(link) NAMES $salle"
		}
	}
	catch { close $ferme }
	incr config(counter) 1
	utimer $config(timerco) ::EvaServ::verif
}

proc ::EvaServ::verif { } {
	variable config
	if { [valididx ${config(idx)}] } {
		utimer $config(timerco) ::EvaServ::verif
	} else {
		if { $config(counter)<="10" } {
			config
			connexion
		} else {
			foreach kill [utimers] {
				if { [lindex $kill 1] == "::EvaServ::verif" } { killutimer [lindex $kill 2] }
			}
			if { [info exists config(idx)] } { unset config(idx)		}
		}
	}
}

proc remove_modenicklist { data } {
	return [::tcl::string::map -nocase {
		"@" "" "&" "" "+" "" "~" "" "%" ""
	} $data]
}

proc ::EvaServ::link { idx arg } {
	variable config
	variable commands
	variable admins
	variable netadmin
	variable vhost
	variable protect
	variable users
	variable trust
	variable UID_DB
	variable scoredb
	variable DBU_INFO
	if { ${SERVICE(mode_debug)} } { putlog "Received: $arg" }
	set arg	[split $arg]
	if { $config(debug) == 1 } {
		putdebug "[join [lrange $arg 0 end]]"
	}
	set user		[FCT:DATA:TO:NICK [string trim [lindex $arg 0] :]]
	set vuser		[string tolower $user]
	switch -exact [lindex $arg 0] {
		"PING" {
			set config(counter)		0
			sent2socket "PONG [lindex $arg 1]"
		}
		"NETINFO" {
			set config(netinfo)		[lindex $arg 4]
			set config(network)		[lindex $arg 8]
			sent2socket "NETINFO 0 [unixtime] 0 $config(netinfo) 0 0 0 $config(network)"
		}
		"SQUIT" {
			set serv		[lindex $arg 1]
			if { [console 2] == "ok" && $config(init) == 0 } {
				SHOW:INFO:TO:CHANLOG "Unlink" "$serv"
			}
		}
		"SERVER" {
			# Received: SERVER irc.xxx.net 1 :U5002-Fhn6OoEmM-001 Serveur networkname
			set config(ircdservname)	[lindex $arg 1]
			set desc		[join [string trim [lrange $arg 3 end] :]]
			# set serv		[lindex $arg 2]
			# set desc		[join [string trim [lrange $arg 4 end] :]]
			if { $config(init) == 1 } {
				connexion:server
			}
		}

	}
	switch -exact [lindex $arg 1] {
		"MD"	{
			#:001 MD client 001E6A4GK certfp :023f2eae234f23fed481be360d744e99df957f.....
			if { [console 2] == "ok" && $config(init) == 0 } {
				set user	[FCT:DATA:TO:NICK [lindex $arg 3]]
				set certfp	[string trim [string tolower [join [lrange $arg 5 end]]] :]
				SHOW:INFO:TO:CHANLOG "Client CertFP" "$user ($certfp)"
			}

		}
		"REPUTATION"	{
			#:001 REPUTATION xxx.xxx.xxx.xxx 373
			if { [console 2] == "ok" && $config(init) == 0 } {
				set host	[lindex $arg 2]
				set score	[lindex $arg 3]
				set scoredb($host) $score
				set scoredb(last) "$host|$score"
				#::EvaServ::SHOW:INFO:TO:CHANLOG "Réputation" "score $score ($host)"
			}
		}

		"UID"		{
			set SID				[string range [lindex $arg 0] 1 end]
			set nickname		[lindex $arg 2]
			set nickname2		[string tolower [lindex $arg 2]]
			set hopcount		[lindex $arg 3]
			set timestamp		[lindex $arg 4]
			set username		[lindex $arg 5]
			set hostname		[lindex $arg 6]
			set uid				[string toupper [lindex $arg 7]]
			set servicestamp	[lindex $arg 8]
			set umodes			[lindex $arg 9]
			set virthost		[lindex $arg 10]
			set cloakedhost		[lindex $arg 11]
			set ip				[lindex $arg 12]
			set gecos			[string trim [string tolower [join [lrange $arg 13 end]]] :]

			set UID_DB([string		toupper $nickname])	$uid
			set UID_DB([string		toupper $uid])		$nickname

			if { ![info exists vhost($nickname2)] } { set vhost($nickname2)		$hostname }

			# Genere une base USER infos:
			if { ![info exists DBU_INFO($uid,VHOST)] }		{ set DBU_INFO($uid,VHOST)		$hostname }
			if { ![info exists DBU_INFO($uid,IDENT)] }		{ set DBU_INFO($uid,IDENT)		$username }
			if { ![info exists DBU_INFO($uid,NICK)] }		{ set DBU_INFO($uid,NICK)		$nickname }
			if { ![info exists DBU_INFO($uid,REALNAME)] }	{ set DBU_INFO($uid,REALNAME)	$gecos }
			

			if { ![info exists users($nickname)] && [string match *+*S* $umodes] } {
				set users($nickname)		on
			}
			if { ![info exists users($nickname)] } { 
				connexion:user:security:check $nickname $hostname $username $gecos
			}
			if { [string match *+*z* $umodes] } {
				set stype		"Connexion SSL"
			} else {
				set stype		"Connexion"
			}
			if { [console 2] == "ok" && $config(init) == 0 } {
				set MSG_CONNECT		"[DBU:GET $uid NICK]"
				append MSG_CONNECT	" ([DBU:GET $uid IDENT]@[DBU:GET $uid VHOST]) "
				append MSG_CONNECT	"- Serveur : $config(ircdservname) "
				if { $scoredb(last) != "" } {
					if { ![info exists DBU_INFO($uid,REPUTATION)] } {
						set TMP	[split $scoredb(last) "|"]
						set DBU_INFO($uid,IP)			[lindex $TMP 0]
						set DBU_INFO($uid,REPUTATION)	[lindex $TMP 1]
					}
					append MSG_CONNECT	"- Score: [DBU:GET $uid REPUTATION] "
				}
				append MSG_CONNECT	"- realname: [DBU:GET $uid REALNAME] "
				SHOW:INFO:TO:CHANLOG $stype $MSG_CONNECT
			}
		}
		"219" {
			if { ![info exists config(aff)] && $config(cmd) == "gline" } {
				SENT:MSG:TO:USER "$config(rep)" "Aucun Gline"
			}
			if { ![info exists config(aff)] && $config(cmd) == "shun" } {
				SENT:MSG:TO:USER "$config(rep)" "Aucun shun"
			}
			if { ![info exists config(aff)] && $config(cmd) == "kline" } {
				SENT:MSG:TO:USER "$config(rep)" "Aucun Kline"
			}
			if { [info exists config(cmd)] } { unset config(cmd)		}
			if { [info exists config(rep)] } { unset config(rep)		}
			if { [info exists config(aff)] } { unset config(aff)		}
		}
		"223" {
			set host		[lindex $arg 4]
			set auteur		[lindex $arg 7]
			set raison		[join [string trim [lrange $arg 8 end] :]]
			if { $config(cmd) == "gline" } {
				if { ![info exists config(aff)] } {
					set config(aff)		1
					SENT:MSG:TO:USER "$config(rep)" "<b><c1,1>---------------------- <c0>Liste des Glines <c1>----------------------"
					SENT:MSG:TO:USER "$config(rep)" "<b>"
				}
				SENT:MSG:TO:USER "$config(rep)" "Host \[<c03> $host <c01>\] | Auteur \[<c03> $auteur <c01>\] | Raison \[<c03> $raison <c01>\]"
			} elseif { $config(cmd) == "shun" } {
				if { ![info exists config(aff)] } {
					set config(aff)		1
					SENT:MSG:TO:USER "$config(rep)" "<b><c1,1>---------------------- <c0>Liste des Shuns <c1>----------------------"
					SENT:MSG:TO:USER "$config(rep)" "<b>"
				}
				SENT:MSG:TO:USER "$config(rep)" "Host \[<c03> $host <c01>\] | Auteur \[<c03> $auteur <c01>\] | Raison \[<c03> $raison <c01>\]"
			} elseif { $config(cmd) == "kline" } {
				if { ![info exists config(aff)] } {
					set config(aff)		1
					SENT:MSG:TO:USER "$config(rep)" "<b><c1,1>---------------------- <c0>Liste des Klines <c1>----------------------"
					SENT:MSG:TO:USER "$config(rep)" "<b>"
				}
				SENT:MSG:TO:USER "$config(rep)" "Host \[<c03> $host <c01>\] | Auteur \[<c03> $auteur <c01>\] | Raison \[<c03> $raison <c01>\]"
			} elseif { $config(cmd) == "cleargline" } {
				sent2socket ":$config(link) TKL - G [lindex [split $host @] 0] [lindex [split $host @] 1] ${SERVICE_BOT(name)}"
			} elseif { $config(cmd) == "clearkline" } {
				sent2socket ":$config(link) TKL - k [lindex [split $host @] 0] [lindex [split $host @] 1] ${SERVICE_BOT(name)}"
			}
		}
		"307" {
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> NickServ <c01>\] <c02> Oui"
		}
		"487" {
			SENT:MSG:TO:USER "${SERVICE_BOT(channel_logs)}" "<c01> \[<c03> ERREUR <c01>\] <c02> $arg"
		}
		"310" {
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Helpeur <c01>\] <c02> Oui"
		}
		"311" {
			set nick		[lindex $arg 3]
			set ident		[lindex $arg 4]
			set host		[lindex $arg 5]
			set real		[join [string trim [lrange $arg 7 end] :]]
			SENT:MSG:TO:USER "$config(rep)" "<b><c1,1>------------------------------ <c0>Whois <c1>------------------------------"
			SENT:MSG:TO:USER "$config(rep)" "<b>"
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Pseudo <c01>\] <c02> $nick"
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Nom Réel <c01>\] <c02> $real"
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Host <c01>\] <c02> $ident@$host"
		}
		"312" {
			set serveur		[lindex $arg 4]
			set desc		[join [string trim [lrange $arg 5 end] :]]
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Serveur <c01>\] <c02> $serveur ($desc)"
		}
		"313" {
			set grade		[join [lrange $arg 6 end]]
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Grade <c01>\] <c02> $grade"
		}
		"317" {
			set idle		[lindex $arg 4]
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Idle <c01>\] <c02> [duration $idle]"
		}
		"318" {
			if { [info exists config(rep)] } { unset config(rep)		}
		}
		"319" {
			set salon		[join [string trim [lrange $arg 4 end] :]]
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Salon <c01>\] <c02> $salon"
		}
		"320" {
			set swhois		[join [string trim [lrange $arg 4 end] :]]
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Swhois <c01>\] <c02> $swhois"
		}
		"324" {
			set chan		[lindex $arg 3]
			set mode		[join [string trimleft [lrange $arg 4 end] +]]
			FCT:SENT:MODE $chan "-$mode"
		}
		"335" {
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Robot <c01>\] <c02> Oui"
		}
		"353" {

			set userliste		[string trim [string tolower [lrange $arg 5 end]] :]
			set userliste2		[string trim [lrange $arg 5 end] :]
			set chan		[lindex $arg 4]
			set user		[remove_modenicklist [lrange $userliste 0 end-1]]

			set user2		[remove_modenicklist $userliste2]
			set nblistenick		[llength [split $user]]
			#set ident		[lindex $arg 4]
			#set host		[lindex $arg 5]

			foreach n [split $user] {
				if { $config(cmd) == "ownerall" && \
					![info exists users($n)] && \
						$n!=[string tolower ${SERVICE_BOT(name)}] && \
						![info exists admins($n)] && \
						[protection $n $config(protection)] != "ok"
				} {
				FCT:SENT:MODE $chan "+q" $n
			} elseif {
				$config(cmd) == "deownerall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "-q" $n
			} elseif {
				$config(cmd) == "protectall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "+a" $n
			} elseif {
				$config(cmd) == "deprotectall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "-a" $n
			} elseif {
				$config(cmd) == "opall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "+o" $n
			} elseif {
				$config(cmd) == "deopall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "-o" $n
			} elseif {
				$config(cmd) == "halfopall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "+h" $n
			} elseif {
				$config(cmd) == "dehalfopall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "-h" $n
			} elseif {
				$config(cmd) == "voiceall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "+v" $n
			} elseif {
				$config(cmd) == "devoiceall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				FCT:SENT:MODE $chan "-v" $n
			} elseif {
				$config(cmd) == "kickall" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {

				sent2socket ":${config(server_id)} KICK $chan $n Kicked [rnick $config(rep)]"
			} elseif {
				$config(cmd) == "chankill" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok" && [protection $n $config(protection)] != "ok"
			} {
				sent2socket ":${config(server_id)} KILL $n Chan Killed [rnick $config(rep)]";
				refresh $n
			} elseif {
				$config(cmd) == "changline" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok" && [protection $n $config(protection)] != "ok"
			} {
				sent2socket ":$config(link) TKL + G * $vhost($n) ${SERVICE_BOT(name)} [expr [unixtime] + ${config(gline_duration)}] [unixtime] :Chan Glined [rnick $config(rep)] (Expire le [duree [expr [unixtime] + ${config(gline_duration)}]])"
			} elseif {
				$config(cmd) == "badchan" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				sent2socket ":${config(server_id)} KICK $chan $n Salon Interdit"
			} elseif {
				$config(cmd) == "closeadd" && \
					![info exists users($n)] && \
					$n!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists admins($n)] && \
					[protection $n $config(protection)] != "ok"
			} {
				if { [info exists config(rep)] } {
					sent2socket ":${config(server_id)} KICK $chan $n Closed [rnick $config(rep)]"
				} else {
					sent2socket ":${config(server_id)} KICK $chan $n Closed"
				}

			}
		}
	}
	"364" {
		set serv		[lindex $arg 3]
		set desc		[join [lrange $arg 6 end]]
		if { ![info exists config(aff)] } {
			set config(aff)		1
			SENT:MSG:TO:USER "$config(rep)" "<b><c1,1>--------------------------------- <c0>Map du Réseau <c1>---------------------------------"
			SENT:MSG:TO:USER "$config(rep)" "<b>"
		}
		SENT:MSG:TO:USER "$config(rep)" "<c01>Serveur \[<c04> $serv <c01>\] <c> Description \[<c03> $desc <c01>\]"
	}
	"365" {
		if { [info exists config(aff)] } { unset config(aff)		}
		if { [info exists config(rep)] } { unset config(rep)		}
	}
	"378" {
		set host		[lindex $arg 7]
		set ip		[lindex $arg 8]
		SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Host Décodé <c01>\] <c02> $host"
		if { [info exists $ip] } {
			SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> Ip <c01>\] <c02> $ip"
		}
	}
	"671" {
		SENT:MSG:TO:USER "$config(rep)" "<c01> \[<c03> SSL <c01>\] <c02> Oui"
	}
	"SERVER" {
		set serv		[lindex $arg 2]
		set desc		[join [string trim [lrange $arg 4 end] :]]
		if { [console 2] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Link" "$serv : $desc"
		}
	}
	"NOTICE" {
		#Received: :001FKJTPQ NOTICE 00CAAAAAB :VERSION HexChat 2.14.2 / Linux 5.4.0-66-generic [x86_64/1,30GHz/SMP]
		set version		[string trim [lindex $arg 3] :]
		set vdata		[string trim [join [lrange $arg 4 end]] \001]
		if { ![FloodControl:Check ${vuser}] } { return 0 }
		if { $config(aclient) == 1 && $version == "\001VERSION" } {
			SHOW:INFO:TO:CHANLOG "Client Version" "$vuser : $vdata"
			catch { open [Script:Get:Directory]/db/client.db r } vcli
			while { ![eof $vcli] } {
				gets $vcli verscli
				if {$verscli != "" } { continue }
				if { [string match *$verscli* $vdata] } {
					if { [console 3] == "ok" && $config(init) == 0 } {
						SHOW:INFO:TO:CHANLOG "Kill" "$user a été killé : $config(rclient)"
					}
					sent2socket ":${config(server_id)} KILL $vuser $config(rclient)";
					refresh $vuser
					break
				}
			}
			catch { close $vcli }
		}
	}
	"MODE" {
		set chan		[lindex $arg 2]
		set vchan		[string tolower [lindex $arg 2]]
		set umode		[lindex $arg 3]
		set pmode		[join [lrange $arg 4 end]]
		set unix		[lindex $arg end]
		if {
			[console 3] == "ok" && \
				$vchan!=[string tolower ${SERVICE_BOT(channel_logs)}] && \
				$config(init) == 0 && \
				[string tolower $user]!=[string tolower ${SERVICE_BOT(name)}]
		} {
			if {[regexp "^\[0-9\]\{10\}" $unix]} {
				set smode		[string trim $pmode $unix]
				SHOW:INFO:TO:CHANLOG "Mode" "$user applique le mode $umode $smode sur $chan"
			} else {
				SHOW:INFO:TO:CHANLOG "Mode" "$user applique le mode $umode $pmode sur $chan"
			}
		}
	}
	"UMODE2" {
		set umode		[lindex $arg 2]
		if { ![info exists users($user)] && [string match *+*S* $umode] } { set users($user)		on }
		if { ![info exists netadmin($user)] && [string match *+*N* $umode] } { set netadmin($user)		on }
		if { [info exists netadmin($user)] && [string match *-*N* $umode] } { unset netadmin($user)		}
		if { [console 3] == "ok" && $config(init) == 0 } {
			if { [string match *+*S* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un Service Réseau"
			} elseif { [string match *-*S* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un Service Réseau"
			} elseif { [string match *+*N* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un Administrateur Réseau"
			} elseif { [string match *-*N* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un Administrateur Réseau"
			} elseif { [string match *+*A* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un Administrateur Serveur"
			} elseif { [string match *-*A* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un Administrateur Serveur"
			} elseif { [string match *+*a* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un Administrateur Services"
			} elseif { [string match *-*a* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un Administrateur Services"
			} elseif { [string match *+*C* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un Co-Administrateur"
			} elseif { [string match *-*C* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un Co-Administrateur"
			} elseif { [string match *+*o* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un IRC Opérateur Global"
			} elseif { [string match *-*o* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un IRC Opérateur Global"
			} elseif { [string match *+*O* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un IRC Opérateur Local"
			} elseif { [string match *-*O* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un IRC Opérateur Local"
			} elseif { [string match *+*h* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user est un Helpeur"
			} elseif { [string match *-*h* $umode] } {
				SHOW:INFO:TO:CHANLOG "Usermode" "$user n'est plus un Helpeur"
			}
		}
	}
	"NICK" {
		set new			[lindex $arg 2]
		set vnew		[string tolower [lindex $arg 2]]
		
		set NICK_NEW	[lindex $arg 2]
		set NICK_OLD	[FCT:DATA:TO:NICK [string trim [lindex $arg 0] :]]
		set UID			[UID:CONVERT $vuser]
		set UID_DB([string toupper $UID])		$NICK_NEW
		set UID_DB([string toupper $NICK_NEW])	$UID
		set	unset UID_DB([string toupper $NICK_OLD])

		# [21:54:07] Received: :001PSYE4B NICK Amand[CoucouHibou] 1616792047
		if { [info exists users($vuser)] && $vuser!=$vnew } {
			set users($vnew)		on;
			unset users($vuser)
		}
		if { [info exists vhost($vuser)] && $vuser!=$vnew } {
			set vhost($vnew)		$vhost($vuser);
			unset vhost($vuser)
		}
		if { [info exists admins($vuser)] && $vuser!=$vnew } {
			set admins($vnew)		$admins($vuser);
			unset admins($vuser)
		}
		if { [info exists netadmin($vuser)] && $vuser!=$vnew } {
			set netadmin($vnew)		on;
			unset netadmin($vuser)
		}
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Nick" "$user change son pseudo en $new"
		}
		if {
			![info exists users($vnew)] && \
				![info exists admins($vnew)] && \
				[protection $vnew $config(protection)] != "ok"
		} {
			catch { open [Script:Get:Directory]/db/nick.db r } liste
			while { ![eof $liste] } {
				gets $liste verif
				if { [string match $verif $vnew] && $verif != "" } {
					if { [console 3] == "ok" && $config(init) == 0 } {
						SHOW:INFO:TO:CHANLOG "Kill" "$new a été killé : $config(ruser)"
					}
					sent2socket ":${config(server_id)} KILL $vnew $config(ruser)";
					break;
					refresh $vnew
				}
			}
			catch { close $liste }
		}
	}
	"TOPIC" {
		set chan		[lindex $arg 2]
		set vchan		[string tolower $chan]
		set topic		[join [string trim [lrange $arg 5 end] :]]
		if {
			[console 3] == "ok" && \
				$vchan!=[string tolower ${SERVICE_BOT(channel_logs)}] && \
				$config(init) == 0
		} {
			SHOW:INFO:TO:CHANLOG "Topic" "$user change le topic sur $chan : $topic<c>"
		}
	}
	"KICK" {
		set pseudo		[UID:CONVERT [lindex $arg 3]]
		set chan		[lindex $arg 2]
		set vchan		[string tolower [lindex $arg 2]]
		set raison		[join [string trim [lrange $arg 4 end] :]]
		if {
			[console 3] == "ok" && \
				$vchan!=[string tolower ${SERVICE_BOT(channel_logs)}] && \
				$config(init) == 0
		} {
			SHOW:INFO:TO:CHANLOG "Kick" "$pseudo a été kické par $user sur $chan : $raison<c>"
		}
	}
	"KILL" {
		set pseudo		[lindex $arg 2]
		set vpseudo		[string tolower [lindex $arg 2]]
		set text		[join [string trim [lrange $arg 2 end] :]]
		refresh $vpseudo
		if { [console 1] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Kill" "$pseudo : $text<c>"
		}
		if { $vpseudo == [string tolower ${SERVICE_BOT(name)}] } {
			gestion;
			sent2socket ":$config(link) SQUIT $config(link) :$config(raison)"
			foreach kill [utimers] {
				if { [lindex $kill 1] == "::EvaServ::verif" } { killutimer [lindex $kill 2] }
			}
			if { [info exists config(idx)] } { unset config(idx)		}
			set config(counter)		0;
			config
			utimer 1 ::EvaServ::connexion
		}
	}
	"GLOBOPS" {
		set text		[join [string trim [lrange $arg 2 end] :]]
		if {
			[console 3] == "ok" && \
				$config(init) == 0 && \
				![info exists users($vuser)]
		} {
			SHOW:INFO:TO:CHANLOG "Globops" "$user : $text<c>"
		}
	}
	"CHGIDENT" {
		set pseudo		[lindex $arg 2]
		set ident		[lindex $arg 3]
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Chgident" "$user change l'ident de $pseudo en $ident"
		}
	}
	"CHGHOST" {
		set pseudo		[FCT:DATA:TO:NICK [lindex $arg 2]]
		set host		[lindex $arg 3]
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Chghost" "$user change l'host de $pseudo en $host"
		}
	}
	"CHGNAME" {
		set pseudo		[lindex $arg 2]
		set real		[join [string trim [lrange $arg 3 end] :]]
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Chgname" "$user change le realname de $pseudo en $real"
		}
	}
	"SETHOST" {
		set host		[lindex $arg 2]
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Sethost" "Changement de l'host de $user en $host"
		}
	}
	"SETIDENT" {
		set ident		[lindex $arg 2]
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Setident" "Changement de l'ident de $user en $ident"
		}
	}
	"SETNAME" {
		set real		[join [string trim [lrange $arg 2 end] :]]
		if { [console 3] == "ok" && $config(init) == 0 } {
			SHOW:INFO:TO:CHANLOG "Setname" "Changement du realname de $user en $real"
		}
	}
	"SJOIN" {
		#	[20:40:16] Received: :001 SJOIN 1616246465 #Amandine :001119S0G
		set user		[FCT:DATA:TO:NICK [string trim [lindex $arg 4] :]]
		set vuser		[string tolower $user]
		set chan		[lindex $arg 3]
		set vchan		[string tolower $chan]
		if {
			[console 3] == "ok" && \
				$vchan!=[string tolower ${SERVICE_BOT(channel_logs)}] && \
				$config(init) == 0
		} {
			SHOW:INFO:TO:CHANLOG "Join" "$user entre sur $chan"
		}
		catch { open "[Script:Get:Directory]/db/salon.db" r } liste
		while { ![eof $liste] } {
			gets $liste verif
			if {
				$verif != "" && \
					[string match *[string trimleft $verif #]* [string trimleft $vchan #]] && \
					$vuser!=[string tolower ${SERVICE_BOT(name)}] && \
					![info exists users($vuser)] && \
					![info exists admins($vuser)] && \
					[protection $vuser $config(protection)] != "ok"
			} {
				set config(cmd)		"badchan";
				sent2socket ":${config(server_id)} JOIN $vchan";
				FCT:SENT:MODE $vchan "+ntsio" ${SERVICE_BOT(name)}
				FCT:SET:TOPIC $vchan "<c1>Salon Interdit le [duree [unixtime]]";
				sent2socket ":$config(link) NAMES $vchan"
				if { [console 3] == "ok" && $config(init) == 0 } {
					SHOW:INFO:TO:CHANLOG "Part" "$user part de $chan : Salon Interdit"
				}
				break
			}
		}
		catch { close $liste }
	}
	"PART" {
		set chan		[string trim [lindex $arg 2] :]
		set vchan		[string tolower $chan]
		if {
			[console 3] == "ok" && \
				$vchan!=[string tolower ${SERVICE_BOT(channel_logs)}] && \
				$config(init) == 0
		} {
			SHOW:INFO:TO:CHANLOG "Part" "$user part de $chan"
		}
	}
	"QUIT" {
		set text		[join [string trim [lrange $arg 2 end] :]]
		refresh $vuser

		if { [console 2] == "ok" && $config(init) == 0 } {
			if { $text != "" } {
				SHOW:INFO:TO:CHANLOG "Déconnexion" "$user a quitté l'IRC : $text - ([DBU:GET $user IDENT]@[DBU:GET $user VHOST])"
			} else {
				SHOW:INFO:TO:CHANLOG "Déconnexion" "$user a quitté l'IRC - ([DBU:GET $user IDENT]@[DBU:GET $user VHOST])"
			}
		}
	}
}
}
###############################################################################
### Substitution des symboles couleur/gras/soulignement/...
###############################################################################
# Modification de la fonction de MenzAgitat
# <cXX> : Ajouter un Couleur avec le code XX : <c01>; <c02,01>
# </c>  : Enlever la Couleur (refermer la deniere declaration <cXX>) : </c>
# <b>   : Ajouter le style Bold/gras
# </b>  : Enlever le style Bold/gras
# <u>   : Ajouter le style Underline/souligner
# </u>  : Enlever le style Underline/souligner
# <i>   : Ajouter le style Italic/Italique
# <s>   : Enlever les styles precedent
proc ::EvaServ::FCT:apply_visuals { data } {
	regsub -all -nocase {<c([0-9]{0,2}(,[0-9]{0,2})?)?>|</c([0-9]{0,2}(,[0-9]{0,2})?)?>} $data "\003\\1" data
	regsub -all -nocase {<b>|</b>} $data "\002" data
	regsub -all -nocase {<u>|</u>} $data "\037" data
	regsub -all -nocase {<i>|</i>} $data "\026" data
	return [regsub -all -nocase {<s>} $data "\017"]
}
proc ::EvaServ::FCT:Remove_visuals { data } {
	regsub -all -nocase {<c([0-9]{0,2}(,[0-9]{0,2})?)?>|</c([0-9]{0,2}(,[0-9]{0,2})?)?>} $data "" data
	regsub -all -nocase {<b>|</b>} $data "" data
	regsub -all -nocase {<u>|</u>} $data "" data
	regsub -all -nocase {<i>|</i>} $data "" data
	return [regsub -all -nocase {<s>} $data ""]
}
::EvaServ::INIT