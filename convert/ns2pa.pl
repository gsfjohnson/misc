#!/usr/bin/perl

#
# Convert sections of NetScreen 5400 config to Palo Alto 5060
#
# 2014-Nov-22 gsfjohnson initial
#

use strict;

sub DEBUG { 1 }

my $caller = ''; # caller name (hwaddr is expected type)
my $entry = ''; # entry point (e.g. preacct, authenticate, authorize, etc)

sub PREFIX { FILENAME() .': '. ( $caller ? $caller .' ' : '' ) . SUBNAME($_[0]) };
sub DEBUG_ { printf STDOUT $_[0] ."\n" if DEBUG; };

my $hrSvc = {
  # default services
	'ANY'		=>	{ protocol => 'hidden' }
#	,'AOL'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'BGP'		=> 	{ protocol => 'tcp', dstport => 001 } 
	,'FINGER'	=>	{ protocol => 'tcp', dstport => '79' }
	,'FTP'		=> 	{ protocol => 'tcp', dstport => '21' } 
#	,'FTP-Get'	=>	{ protocol => 'tcp', dstport => 001 } 
#	,'FTP-Put'	=>	{ protocol => 'tcp', dstport => 001 } 
#	,'GOPHER'	=>	{ protocol => 'tcp', dstport => 001 } 
#	,'H.323'		=> 	{ protocol => 'tcp', dstport => 001 }
	,'HTTP'		=> 	{ protocol => 'rename', newname => 'service-http' } 
#	,'HTTP-EXT'	=> 	{ protocol => 'tcp', dstport => 001 }
	,'HTTPS'		=> 	{ protocol => 'rename', newname => 'service-https' } 
#	,'IDENT'		=> 	{ protocol => 'tcp', dstport => 001 } 
	,'IMAP'		=> 	{ protocol => 'tcp', dstport => '143' } 
#	,'Internet Locator Service'	=> 	{ protocol => 'tcp', dstport => 001 }
#	,'IRC'		=> 	{ protocol => 'tcp', dstport => 001 } 
	,'LDAP'		=> 	{ protocol => 'tcp', dstport => '389' } 
#	,'LPR'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'MAIL'		=> 	{ protocol => 'tcp', dstport => '25' } 
#	,'MSN'		=> 	{ protocol => 'tcp', dstport => 001 } 
	,'MS-SQL'	=>	{ protocol => 'tcp', dstport => '1433' } 
	,'SQL Monitor'	=>	{ protocol => 'udp', dstport => '1434' } 
#	,'NetMeeting'	=> 	{ protocol => 'tcp', dstport => 001 }
#	,'NNTP'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'NS Global'	=> 	{ protocol => 'tcp', dstport => 001 }
#	,'NS Global PRO'	=> 	{ protocol => 'tcp', dstport => 001 }
#	,'PPTP'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'Real Media'	=> 	{ protocol => 'tcp', dstport => 001 }
#	,'REXEC'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'RLOGIN'	=>	{ protocol => 'tcp', dstport => 001 } 
#	,'RSH'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'RTSP'		=> 	{ protocol => 'tcp', dstport => 001 } 
	,'SMB'		=> 	{ protocol => 'tcp', dstport => '139,445' }
	,'SMTP'		=> 	{ protocol => 'tcp', dstport => '25' } 
#	,'SQL*Net V1'	=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'SQL*Net V2'	=> 	{ protocol => 'tcp', dstport => 001 } 
	,'SSH'		=> 	{ protocol => 'tcp', dstport => '22' } 
#	,'TCP-ANY'	=>	{ protocol => 'tcp', dstport => 001 }
	,'TELNET'	=>	{ protocol => 'tcp', dstport => '23' } 
#	,'UDP-ANY'	=>	{ protocol => 'tcp', dstport => 001 }
#	,'VDO Live'	=> 	{ protocol => 'tcp', dstport => 001 } 
	,'VNC'		=> 	{ protocol => 'tcp', dstport => '5800,5900' }
#	,'WAIS'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'WHOIS'		=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'WINFRAME'	=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'X-WINDOWS'	=> 	{ protocol => 'tcp', dstport => 001 } 
#	,'YMSG'		=> 	{ protocol => 'tcp', dstport => 001 }
  ,'SNMP_UDP'   =>  { protocol => 'udp', dstport => '161' }
  ,'SNMPTRAP_TCP'   =>  { protocol => 'tcp', dstport => '162' }
  ,'SNMPTRAP_UDP'   =>  { protocol => 'udp', dstport => '162' }
  ,'DNS_TCP'   =>  { protocol => 'tcp', dstport => '53' }
  ,'DNS_UDP'   =>  { protocol => 'udp', dstport => '53' }
	,'TFTP'   =>  { protocol => 'udp', dstport => '69' }
	,'NTP_UDP'   =>  { protocol => 'udp', dstport => '123' }
	,'NTP_TCP'   =>  { protocol => 'tcp', dstport => '123' }
	,'RTSP_UDP'   =>  { protocol => 'udp', dstport => '554' }
	,'RTSP_TCP'   =>  { protocol => 'tcp', dstport => '554' }
	,'DHCP-Relay'   =>  { protocol => 'udp', dstport => '67-68' }
	,'POP3'		=>	{ protocol => 'tcp', dstport => '110' }
	,'NBNAME'		=>	{ protocol => 'udp', dstport => '137' }
	,'SYSLOG'		=>	{ protocol => 'udp', dstport => '514' }
	,'NFS_UDP'   =>  { protocol => 'udp', dstport => '111,2049' }
	,'NFS_TCP'   =>  { protocol => 'tcp', dstport => '111,2049' }
	,'H.323_TCP'   =>  { protocol => 'tcp', dstport => '1720,1503,389,522,1731' }
	,'H.323_UDP'   =>  { protocol => 'udp', dstport => '1719' }
	,'MS-RPC-EPM_UDP'   =>  { protocol => 'udp', dstport => '135' }
	,'MS-RPC-EPM_TCP'   =>  { protocol => 'tcp', dstport => '135' }
	,'service-http'		=>	{ protocol => 'hidden' }
	,'service-https'	=>	{ protocol => 'hidden' }
}; 
my $hrSvcGroup = {
	 'SNMP' => { members => 'SNMP_UDP|SNMPTRAP_UDP|SNMPTRAP_TCP' }
	,'DNS' => { members => 'DNS_UDP|DNS_TCP' }
	,'NTP' => { members => 'NTP_UDP|NTP_TCP' }
	,'NFS' => { members => 'NFS_UDP|NFS_TCP' }
	,'MS-RPC-EPM' => { members => 'MS-RPC-EPM_UDP|MS-RPC-EPM_TCP' }
	,'H.323' => { members => 'H.323_UDP|H.323_TCP' }
	,'RTSP' => { members => 'RTSP_UDP|RTSP_TCP' }
};
my $hrAddr = {};
my $hrAddrGroup = {};
my $hrPolicy = {};
my @arrPolicy;
my $state = undef;
my $id = undef;

my $line = <STDIN>; chomp($line);
do {

	if ( $state eq 'service' || ( ! $state && $line =~ /^set service / ) )
	{
		my ($name,$extra,$srcport,$dstport,$prot,$hr);
		if ( $line =~ /^set service "([^"]+)" (.+)/ )
		{
			$name = $1;
			$extra = $2;

			$hrSvc->{$name} = {}
				unless ( $hrSvc->{$name} && ref($hrSvc->{$name}) eq 'HASH' );
			$hr = $hrSvc->{$name};

			if ( $extra =~ /(?:\+|protocol) (udp|tcp) src-port ([-0-9]+) dst-port ([-0-9]+)/ )
			{
				$prot = $1;
				$srcport = $2;
				$dstport = $3;

				if ( $hr->{'protocol'} && $prot ne $hr->{'protocol'} )
				{
					my $err = "ERR: new protocol [". $prot ."] overwriting [". $hr->{'protocol'} ."]";
					DEBUG_ "S[". $name ."]: ". $err;
					$hr->{error} = pushError( $hr->{error}, $err );
					$hr->{'protocol'} = $prot;
				}
				else
				{
					$hr->{'protocol'} = $prot;
				}

				# source port
				my $n = 'srcport';
				if ( $srcport ne '0-65535' && $srcport ne '1-65535' )
				{
					if ( $hr->{$n} )
					{
						$hr->{$n} .= ','.$srcport
							if index($hr->{$n},$2) == -1
					}
					else
					{
						$hr->{$n} = $srcport;
					}
				}

				# dest port
				$n = 'dstport';
				if ( $dstport =~ /(\d+)-(\d+)/ )
				{
					$dstport = $1 if ( $1 eq $2 ); 
				}

				if ( $hr->{$n} )
				{
					$hr->{$n} .= ','.$dstport
							if index($hr->{$n},$2) == -1
				}
				else
				{
					$hr->{$n} = $dstport;
				}

				DEBUG_ "S[". $name ."]: protocol[". $hr->{protocol} ."] srcport[". $hr->{srcport} ."] dstport[". $hr->{dstport} ."]";
			}
			elsif ( $extra =~ /timeout (\d+)/ )
			{
				if ( $1 == 350 )
				{
					# nothing
				}
				else
				{
					DEBUG_ "S[$name] non-default timeout: ". $1;
					$hr->{'timeout'} = $1
				}

			}
			else
			{
				DEBUG_ "S< FAILED TO PARSE extra: ". $extra;
			}
		}
		else
		{
			DEBUG_ "S< FAILED TO PARSE: ". $line;
		}
	}
	elsif ( $state eq 'svcgrp' || ( ! $state && $line =~ /^set group service / ) )
	{
		my ($zone,$name,$key,$val,$desc);
		if ( $line =~ /^set group service "([^"]+)"$/ )
		{
			# skip this
		}
		elsif ( $line =~ /^set group service "([^"]+)" (add|comment) "([^"]+)"$/ )
		{
			($name,$key,$val) = ($1,$2,$3);

			unless ( $hrSvcGroup->{$name} && ref($hrSvcGroup->{$name}) eq 'HASH' )
			{
				$hrSvcGroup->{$name} = {};
			}
			my $hr = $hrSvcGroup->{$name};

			if ( $key eq 'add' )
			{
				# check for exist
				my $f = findSvcOrGroup($val);
				DEBUG_ 'SG['. $name .']+ "'. $val .'"'. ( $f ? '' : ' -ERR:DNE-' );
				$hr->{error} = 'service['. $val .'] does not exist' if ! $f;

				# check for rename
				my $newname = renameSvc($val);
				if ( $val ne $newname )
				{
					DEBUG_ 'SG['. $name .']+ "'. $val .'" renamed to "'. $newname .'"';
					$val = $newname;
				}

				# add to members
				if ( $hr->{'members'} && index($hr->{'members'},$val) == -1 )
				{
					$hr->{'members'} .= '|'. $val;
				}
				else
				{
					$hr->{'members'} = $val;
				}
			}
			if ( $key eq 'comment' )
			{
				DEBUG_ 'SG['. $name .']: "'. $val .'"';
				$hr->{'description'} = $val;
			}
		}
		else
		{
			DEBUG_ "SG< FAILED TO PARSE: ". $line;
		}

	}
	elsif ( $line =~ /^(unset|set) (zone|auth|admin|flow|pki|nsrp|dns|interface) .+/ )
	{
		#DEBUG_ "< ". $line;
	}
	elsif ( $state eq 'address' || ( ! $state && $line =~ /^set address / ) )
	{
		my ($zone,$name,$addr,$p,$desc);
		if ( $line =~ /^set address "([^"]+)" "([^"]+)" ([^ ]+)(\s[0-9\.]+|\s+)("([^"]+)"|())/ )
		{
			($zone,$name,$addr,$p,$desc) = ($1,$2,$3,undef,$6);
			$p = 32 if $4 eq " 255.255.255.255";
			$p = 31 if $4 eq " 255.255.255.254";
			$p = 30 if $4 eq " 255.255.255.252";
			$p = 29 if $4 eq " 255.255.255.248";
			$p = 28 if $4 eq " 255.255.255.240";
			$p = 27 if $4 eq " 255.255.255.224";
			$p = 26 if $4 eq " 255.255.255.192";
			$p = 25 if $4 eq " 255.255.255.128";
			$p = 24 if $4 eq " 255.255.255.0";
			$p = 23 if $4 eq " 255.255.254.0";
			$p = 22 if $4 eq " 255.255.252.0";
			$p = 21 if $4 eq " 255.255.248.0";
			$p = 20 if $4 eq " 255.255.240.0";
			$p = 19 if $4 eq " 255.255.224.0";
			$p = 18 if $4 eq " 255.255.192.0";
			$p = 17 if $4 eq " 255.255.128.0";
			$p = 16 if $4 eq " 255.255.0.0";
			$p = 15 if $4 eq " 255.254.0.0";
			$p = 14 if $4 eq " 255.252.0.0";
			$p = 13 if $4 eq " 255.248.0.0";
			$p = 12 if $4 eq " 255.240.0.0";
			$p = 11 if $4 eq " 255.224.0.0";
			$p = 10 if $4 eq " 255.192.0.0";
			$p = 9  if $4 eq " 255.128.0.0";
			$p = 8  if $4 eq " 255.0.0.0";
			$p = 7  if $4 eq " 254.0.0.0";
			$p = 6  if $4 eq " 252.0.0.0";
			$p = 5  if $4 eq " 248.0.0.0";
			$p = 4  if $4 eq " 240.0.0.0";
			$p = 3  if $4 eq " 224.0.0.0";
			$p = 2  if $4 eq " 192.0.0.0";
			$p = 1  if $4 eq " 128.0.0.0";
			$p = 0  if $4 eq " 0.0.0.0";
			$hrAddr->{$name} = { 'tag' => $zone }
				unless $hrAddr->{$name} && ref($hrAddr->{$name}) eq 'HASH';
			my $hr = $hrAddr->{$name};

			# description
			if ( length($desc) && $hr->{'description'} && $desc ne $hr->{'description'} )
			{
				my $err = "New description [". $desc ."] overwriting [". $hr->{'description'} ."]";
				DEBUG_ "A[". $name ."]: ". $err;
				$hr->{error} = pushError( $hr->{error}, $err );
			}
			$hr->{'description'} = $desc if length($desc);

			# zone
			if ( index($hr->{'tag'}, $zone) == -1 )
			{
				my $err = "already exists, adding zone [". $zone ."] to list [". $hr->{tag} ."]";
				DEBUG_ "A[". $name ."]: ". $err;

				$hr->{tag} .= "|".$zone;
			}

			# address
			my $newaddr = $addr .( $p ? '/'.$p : '' );
			if ( $hr->{'addr'} && $newaddr ne $hr->{'addr'} )
			{
				my $err = "New addr [". $newaddr ."] overwriting old addr [". $hr->{'addr'} ."]";
				DEBUG_ "A[". $name ."]: ". $err;
				$hr->{error} = pushError( $hr->{error}, $err );
			}
			$hr->{'addr'} = $newaddr;

			# debug
			DEBUG_ "A[". $name ."]+ ". $newaddr;
		}
		else
		{
			DEBUG_ "A< FAILED TO PARSE: ". $line;
		}
	}
	elsif ( $state eq 'addrgrp' || ( ! $state && $line =~ /^set group address / ) )
	{
		my ($zone,$name,$key,$val,$desc);
		if ( $line =~ /^set group address "([^"]+)" "([^"]+)"$/ )
		{
			# skip this
		}
		elsif ( $line =~ /^set group address "([^"]+)" "([^"]+)" (add|comment) "([^"]+)"/ )
		{
			($zone,$name,$key,$val) = ($1,$2,$3,$4);

			if ( $hrAddrGroup->{$name} && ref($hrAddrGroup->{$name}) eq 'HASH' )
			{
				if ( index($hrAddrGroup->{$name}->{'tag'},$zone) == -1 )
				{
					DEBUG_ "AG[". $name ."]: NOTE: new address-group [". $name ."] already exists in zones [". $hrAddrGroup->{$name}->{'tag'} ."]";
					$hrAddrGroup->{$name}->{'tag'} .= '|'.$zone;
				}
			}
			else 
			{
				$hrAddrGroup->{$name} = { 'tag' => $zone };
			}
			my $hr = $hrAddrGroup->{$name};

			if ( $key eq 'add' )
			{
				DEBUG_ 'AG['. $name .']+ "'. $val .'"';
				if ( $hr->{'members'} && index($hr->{'members'},$val) == -1 )
				{
					$hr->{'members'} .= '|'. $val;
				}
				else
				{
					$hr->{'members'} = $val;
				}
			}
			if ( $key eq 'comment' )
			{
				DEBUG_ 'AG['. $name .']: "'. $val .'"';
				$hr->{'description'} = $val;
			}
		}
		else
		{
			DEBUG_ "AG< FAILED TO PARSE: ". $line;
		}

	}
	elsif ( $state eq 'policy' || ( ! $state && $line =~ /^set policy / ) )
	{
		my $hr = undef;
		$hr = $hrPolicy->{$id} if $state eq 'policy' && $id;

		if ( $line =~ /^set policy (global id|id) (\d+) from "([^"]+)" to "([^"]+)"  "([^"]+)" "([^"]+)" "([^"]+)" (permit|reject)( log|)/ )
		{
			$state = 'policy'; # force return
			$id = $2;
			$hr = {
				 'id' => $2
				,'srczone' => $3
				,'dstzone' => $4
				,'srcaddr' => $5
				,'dstaddr' => $6
				,'svc' => $7
				,'action' => ( $8 eq 'permit' ? 'allow' : 'deny' )
			};
			$hrPolicy->{$id} = $hr;
			push @arrPolicy, $id; # ensure order

			DEBUG_ 'P['. $id .']: '. $hr->{action} .' '. $hr->{srcaddr} .'['. $hr->{srczone} .'] -> '. $hr->{dstaddr} .'['. $hr->{dstzone} .'] : '. $hr->{svc} .( findSvcOrGroup($hr->{svc}) ? '' : ' -ERR:DNE-' );

			# check for rename
			my $newname = renameSvc($hr->{svc});
			if ( $hr->{svc} ne $newname )
			{
				DEBUG_ 'P['. $id .']: service '. $hr->{svc} .' renamed to '. $newname;
				$hr->{svc} = $newname;
			}
		}
		elsif ( $line =~ /^set policy id (\d+)( disable|)$/ )
		{
			DEBUG_ 'P['. $id .']: different id '. $1 .'(ignoring)'
				if $id != $1;
			if ($2 eq ' disable')
			{
				DEBUG_ 'P['. $id ."]: disabled";
				$hr->{'disabled'} = 'yes';
			}
		}
		elsif ( $line =~ /^set service "([^"]+)"$/ )
		{
			my $f = findSvcOrGroup($1);
			DEBUG_ 'P['. $id .']: addl svc '. $1 .( $f ? '' : ' -ERR:DNE-' ) . ( $f && renameSvc($1) ne $1 ? ' renamed to '. renameSvc($1) : '' );
			if ( $f )
			{
				$hr->{svc} .= '|'. renameSvc($1)
					if index($hr->{svc},$1) == -1;
			}
			else
			{
				$hr->{error} = pushError( $hr->{error}, 'ERR: svc['. $1 .'] not found' );
			}
		}
		elsif ( $line =~ /^set (src|dst)-address "([^"]+)"$/ )
		{
			my $f = findAddrOrGroup($2); my $n = $1.'addr';
			DEBUG_ 'P['. $id ."]: addl ". $1 ."-address: ". $2 .( $f ? '' : ' -ERR:DNE-' );
			if ( $f )
			{
				$hr->{$n} .= '|'. $2
					if index($hr->{$n},$2) == -1;
			}
			else
			{
				$hr->{error} = pushError( $hr->{error}, 'ERR: address or address-group ['. $1 .'] not found' );
			}
		}
		elsif ( $line =~ /^set log (session-init)$/ )
		{
			DEBUG_ 'P['. $id ."]: log ". $1;
			$hrPolicy->{$id}->{'log-start'} = 'yes'
				if $1 eq 'session-init';
		}
		elsif ( $line =~ /^exit$/ )
		{
			$state = undef;
			$hr = $hrPolicy->{$id};

			# build address-/service-group if needed
			my $updated = 0;
			if ( index($hr->{srcaddr},'|') > 0 )
			{
				my $name = undef;
				foreach my $key ( keys %$hrAddrGroup )
				{
					$name = $key if $hrAddrGroup->{$key}->{members} eq $hr->{srcaddr};
				}
				if ( $name )
				{
					$hr->{srcaddr} = $name;
				}
				else
				{
					$name = 'ag_r'. $id .'_1';
					my $hrAG = {};
					$hrAG->{members} = $hr->{srcaddr};
					$hrAddrGroup->{$name} = $hrAG;
					$hr->{srcaddr} = $name;
				}
				DEBUG_ 'P['. $id .']: address-group created: '. $name;
				$updated++;
			}
			if ( index($hr->{dstaddr},'|') > 0 )
			{
				my $name = undef;
				foreach my $key ( keys %$hrAddrGroup )
				{
					$name = $key if $hrAddrGroup->{$key}->{members} eq $hr->{dstaddr};
				}
				if ( $name )
				{
					$hr->{dstaddr} = $name;
				}
				else
				{
					$name = 'ag_r'. $id .'_2';
					my $hrAG = {};
					$hrAG->{members} = $hr->{dstaddr};
					$hrAddrGroup->{$name} = $hrAG;
					$hr->{dstaddr} = $name;
				}
				DEBUG_ 'P['. $id .']: address-group created: '. $name;
				$updated++;
			}
			if ( index($hr->{svc},'|') > 0 )
			{
				my $name = undef;
				foreach my $key ( keys %$hrSvcGroup )
				{
					$name = $key if $hrSvcGroup->{$key}->{members} eq $hr->{svc};
				}
				if ( $name )
				{
					$hr->{svc} = $name;
				}
				else
				{
					$name = 'sg_r'. $id;
					my $hrSG = {};
					$hrSG->{members} = $hr->{svc};
					$hrSvcGroup->{$name} = $hrSG;
					$hr->{svc} = $name;
				}
				DEBUG_ 'P['. $id .']: service-group created: '. $name;
				$updated++;
			}

			# check srcaddr
			my $n; my $f;
			$n = 'srcaddr'; $f = findAddrOrGroup($hr->{$n});
			unless ( $f )
			{
				my $err = 'ERR: '.$n.'['. $hr->{$n} .'] not found';
				DEBUG_ 'P['. $id .']: '. $err;
				$hr->{error} = pushError( $hr->{error}, $err );
			}
			$n = 'dstaddr'; $f = findAddrOrGroup($hr->{$n});
			unless ( $f )
			{
				my $err = 'ERR: '.$n.'['. $hr->{$n} .'] not found';
				DEBUG_ 'P['. $id .']: '. $err;
				$hr->{error} = pushError( $hr->{error}, $err );
			}
			$n = 'svc'; $f = findSvcOrGroup($hr->{$n});
			unless ( $f )
			{
				my $err = 'ERR: '.$n.'['. $hr->{$n} .'] not found';
				DEBUG_ 'P['. $id .']: '. $err;
				$hr->{error} = pushError( $hr->{error}, $err );
			}

			DEBUG_ 'P['. $id .']: '. $hr->{action} .' '. $hr->{srcaddr} .'['. $hr->{srczone} .'] -> '. $hr->{dstaddr} .'['. $hr->{dstzone} .'] : '. $hr->{svc};
			DEBUG_ 'P['. $id .']';

			# clear id
			$id = undef;
		}
		else
		{
			DEBUG_ "P< FAILED TO PARSE: ". $line;
		}

	}
	else
	{
		# DEBUG_ $line;
	}

} while ( chomp($line = <STDIN>) );

foreach my $key ( keys %$hrSvc )
{
	my $hr = $hrSvc->{$key}; my $out;
	next unless $hr->{'dstport'} && $hr->{'protocol'};
	$out = formatErrors($hr->{error});
	$out .= 'set service "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' protocol '. $hr->{'protocol'};
	$out .= ' port '. $hr->{'dstport'};
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

foreach my $key ( keys %$hrSvcGroup )
{
	# DEBUG_ "SG[". $key ."]";
	my $hr = $hrSvcGroup->{$key}; my $out;
	$out = formatErrors($hr->{error});
	$out .= 'set service-group "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' [ "'. join('" "',split(/\|/,$hr->{'members'})) .'" ]';
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

foreach my $key ( keys %$hrAddr )
{
	# DEBUG_ "A[". $key ."]";
	my $hr = $hrAddr->{$key}; my $out;
	$out = formatErrors($hr->{error});
	$out .= 'set address "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' description "'. $hr->{'description'} .'"' if $hr->{'description'};
	$out .= ' '. ( $hr->{'addr'} =~ /\/\d/ ? 'ip-netmask ' : 'fqdn ' ). $hr->{'addr'};
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

foreach my $key ( keys %$hrAddrGroup )
{
	# DEBUG_ "AG[". $key ."]";
	my $hr = $hrAddrGroup->{$key}; my $out;
	$out = formatErrors($hr->{error});
	$out .= 'set address-group "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' description "'. $hr->{'description'} .'"' if $hr->{'description'};
	$out .= ' static [ "'. join('" "',split(/\|/,$hr->{'members'})) .'" ]';
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

foreach my $key ( @arrPolicy )
{
	# DEBUG_ "P[". $key ."]";
	my $hr = $hrPolicy->{$key}; my $out;
	$out = formatErrors($hr->{error});
	$out .= 'set rules "r'. $key .'"';
	$out .= ' action '. $hr->{action};
	$out .= ' disabled '. $hr->{'disabled'} if $hr->{'disabled'};
	$out .= ' log-start '. $hr->{'log-start'} if $hr->{'log-start'};
	$out .= ' from "'. $hr->{srczone} .'"' unless $hr->{srczone} eq 'Global';
	$out .= ' to "'. $hr->{dstzone} .'"' unless $hr->{dstzone} eq 'Global';
	$out .= ' source "'. $hr->{srcaddr} .'"';
	$out .= ' destination "'. $hr->{dstaddr} .'"';
	$out .= ' service "'. $hr->{svc} .'"' unless $hr->{svc} eq 'ANY';
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

sub findSvc
{
	my $n = shift;

	return $hrSvc->{$n}
		if $hrSvc->{$n} && $hrSvc->{$n}->{protocol};

	0;
}

sub findSvcGroup
{
	my $n = shift;

	return $hrSvcGroup->{$n}
		if $hrSvcGroup->{$n};

	0;
}

sub findSvcOrGroup
{
	my $n = shift;

	return 'ANY'
		if ( uc($n) eq 'ANY' );

	return findSvc($n)
		if findSvc($n);
	return findSvcGroup($n)
		if findSvcGroup($n);

	0;
}

sub renameSvc
{
	my $n = shift;

	return $hrSvc->{$n}->{newname}
		if ( $hrSvc->{$n} && $hrSvc->{$n}->{newname} );
	
	return $n;
}

sub findAddr
{
	my $n = shift;

	return $hrAddr->{$n}
		if $hrAddr->{$n} && $hrAddr->{$n}->{addr};
	
	0;
}

sub findAddrGroup
{
	my $n = shift;

	return $hrAddrGroup->{$n}
		if $hrAddrGroup->{$n} && $hrAddrGroup->{$n}->{members};
	
	0;
}

sub findAddrOrGroup
{
	my $n = shift;

	return 'ANY'
		if uc($n) eq 'ANY';

	return findAddr($n)
		if findAddr($n);
	return findAddrGroup($n)
		if findAddrGroup($n);
	
	0;
}

sub formatErrors
{
	my $err = shift;
	
	return "\n# ". join("\n# ",split(/\|/,$err)) ."\n# " if $err;
	return '';
}

sub pushError
{
	my $str = shift;
	my $err = shift;

	return ( length($str) ? '|' : '' ). $err;
}
