#!/usr/bin/perl

#
# Convert sections of NetScreen 5400 config to Palo Alto 5060
#
# 2014-Nov-22 gsfjohnson initial
#

use strict;

sub DEBUG { 0 }

my $caller = ''; # caller name (hwaddr is expected type)
my $entry = ''; # entry point (e.g. preacct, authenticate, authorize, etc)

sub PREFIX { FILENAME() .': '. ( $caller ? $caller .' ' : '' ) . SUBNAME($_[0]) };
sub DEBUG_ { printf STDOUT $_[0] ."\n" if DEBUG; };

my $hrSvc = {
  # default services
	'ANY'		=>	{ protocol => 'hidden' }
#	,'AOL'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'BGP'		=> 	{ 'tcp' => { dstport => 001 } } 
	,'FINGER'	=>	{ 'tcp' => { dstport => '79' } }
	,'FTP'		=> 	{ 'tcp' => { dstport => '21' } } 
#	,'FTP-Get'	=>	{ 'tcp' => { dstport => 001 } } 
#	,'FTP-Put'	=>	{ 'tcp' => { dstport => 001 } } 
#	,'GOPHER'	=>	{ 'tcp' => { dstport => 001 } } 
#	,'H.323'		=> 	{ 'tcp' => { dstport => 001 } }
	,'HTTP'			=> 	{ newname => 'service-http' } 
	,'HTTPS'		=> 	{ newname => 'service-https' } 
#	,'IDENT'		=> 	{ 'tcp' => { dstport => 001 } } 
	,'IMAP'		=> 	{ 'tcp' => { dstport => '143' } } 
#	,'Internet Locator Service'	=> 	{ 'tcp' => { dstport => 001 } }
#	,'IRC'		=> 	{ 'tcp' => { dstport => 001 } } 
	,'LDAP'		=> 	{ 'tcp' => { dstport => '389' } } 
#	,'LPR'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'MAIL'		=> 	{ 'tcp' => { dstport => '25' } } 
#	,'MSN'		=> 	{ 'tcp' => { dstport => 001 } } 
	,'MS-SQL'	=>	{ 'tcp' => { dstport => '1433' } } 
	,'SQL Monitor'	=>	{ 'udp' => { dstport => '1434' } } 
#	,'NetMeeting'	=> 	{ 'tcp' => { dstport => 001 } }
#	,'NNTP'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'NS Global'	=> 	{ 'tcp' => { dstport => 001 } }
#	,'NS Global PRO'	=> 	{ 'tcp' => { dstport => 001 } }
#	,'PPTP'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'Real Media'	=> 	{ 'tcp' => { dstport => 001 } }
#	,'REXEC'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'RLOGIN'	=>	{ 'tcp' => { dstport => 001 } } 
#	,'RSH'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'RTSP'		=> 	{ 'tcp' => { dstport => 001 } } 
	,'SMB'		=> 	{ 'tcp' => { dstport => '139,445' } }
	,'SMTP'		=> 	{ 'tcp' => { dstport => '25' } } 
#	,'SQL*Net V1'	=> 	{ 'tcp' => { dstport => 001 } } 
#	,'SQL*Net V2'	=> 	{ 'tcp' => { dstport => 001 } } 
	,'SSH'		=> 	{ 'tcp' => { dstport => '22' } } 
#	,'TCP-ANY'	=>	{ 'tcp' => { dstport => 001 } }
	,'TELNET'	=>	{ 'tcp' => { dstport => '23' } } 
#	,'UDP-ANY'	=>	{ 'tcp' => { dstport => 001 } }
#	,'VDO Live'	=> 	{ 'tcp' => { dstport => 001 } } 
	,'VNC'		=> 	{ 'tcp' => { dstport => '5800,5900' } }
#	,'WAIS'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'WHOIS'		=> 	{ 'tcp' => { dstport => 001 } } 
#	,'WINFRAME'	=> 	{ 'tcp' => { dstport => 001 } } 
#	,'X-WINDOWS'	=> 	{ 'tcp' => { dstport => 001 } } 
#	,'YMSG'		=> 	{ 'tcp' => { dstport => 001 } }
	,'RADIUS'		=>	{ 'udp' => { dstport => '1812-1813' } }
  ,'SNMP_UDP'   =>  { 'udp' => { dstport => '161' } }
  ,'SNMPTRAP_TCP'   =>  { 'tcp' => { dstport => '162' } }
  ,'SNMPTRAP_UDP'   =>  { 'udp' => { dstport => '162' } }
  ,'DNS_TCP'   =>  { 'tcp' => { dstport => '53' } }
  ,'DNS_UDP'   =>  { 'udp' => { dstport => '53' } }
	,'TFTP'   =>  { 'udp' => { dstport => '69' } }
	,'NTP_UDP'   =>  { 'udp' => { dstport => '123' } }
	,'NTP_TCP'   =>  { 'tcp' => { dstport => '123' } }
	,'NSM_UDP'   =>  { 'udp' => { dstport => '69' } }
	,'NSM_TCP'   =>  { 'tcp' => { dstport => '7204,7800,11122,15400' } }
	,'RTSP_UDP'   =>  { 'udp' => { dstport => '554' } }
	,'RTSP_TCP'   =>  { 'tcp' => { dstport => '554' } }
	,'DHCP-Relay'   =>  { 'udp' => { dstport => '67-68' } }
	,'POP3'		=>	{ 'tcp' => { dstport => '110' } }
	,'NBNAME'		=>	{ 'udp' => { dstport => '137' } }
	,'SYSLOG'		=>	{ 'udp' => { dstport => '514' } }
	,'NFS_UDP'   =>  { 'udp' => { dstport => '111,2049' } }
	,'NFS_TCP'   =>  { 'tcp' => { dstport => '111,2049' } }
	,'H.323_TCP'   =>  { 'tcp' => { dstport => '1720,1503,389,522,1731' } }
	,'H.323_UDP'   =>  { 'udp' => { dstport => '1719' } }
	,'MS-RPC-EPM_UDP'   =>  { 'udp' => { dstport => '135' } }
	,'MS-RPC-EPM_TCP'   =>  { 'tcp' => { dstport => '135' } }
	,'WAIS'   =>  { 'tcp' => { dstport => '210' } }
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
	,'NSM' => { members => 'NSM_UDP|NSM_TCP' }
};
my $hrAddr = {};
my $hrAddrGroup = {};
my $hrPolicy = {};
my @arrPolicy;
my $state = undef;
my $id = undef;

my $line = <STDIN>; chomp($line);
do {

	#
	# Service
	#
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

				# create prot if needed
				$hr->{$prot} = {}
					if ! $hr->{$prot};
				my $hrP = $hr->{$prot};

				# source port
				my $n = 'srcport';
				if ( $srcport ne '0-65535' && $srcport ne '1-65535' )
				{
					if ( $hrP->{$n} )
					{
						$hrP->{$n} .= ','.$srcport
							if index($hrP->{$n},$srcport) == -1;
					}
					else
					{
						$hrP->{$n} = $srcport;
					}
					# DEBUG_ "S[". $name ."]: src = ". $prot ."/". $srcport;
				}

				# dest port
				$n = 'dstport';
				if ( $dstport =~ /(\d+)-(\d+)/ )
				{
					$dstport = $1 if ( $1 eq $2 ); 
				}

				if ( $hrP->{$n} )
				{
					$hrP->{$n} .= ','.$dstport
							if index($hrP->{$n},$dstport) == -1;
				}
				else
				{
					$hrP->{$n} = $dstport;
				}
				# DEBUG_ "S[". $name ."]: dst = ". $prot ."/". $dstport;

				DEBUG_ "S[". $name ."]: service". ( $hr->{udp} ? ( $hr->{udp}->{srcport} ? " src = udp/". $hr->{udp}->{srcport} : '' ) ." dst = udp/". $hr->{udp}->{dstport} : '' ).( $hr->{tcp} ? ( $hr->{tcp}->{srcport} ? " src = tcp/". $hr->{tcp}->{srcport} : '' ) ." dst = tcp/". $hr->{tcp}->{dstport} : '' );
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

	#
	# Service Group
	#
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

			# set hr
			unless ( $hrSvcGroup->{$name} && ref($hrSvcGroup->{$name}) eq 'HASH' )
			{
				$hrSvcGroup->{$name} = {};
			}
			my $hr = $hrSvcGroup->{$name};

			if ( $key eq 'add' )
			{
				# check for rename
				my $f = findSvcOrGroup($val);
				my $newname = renameSvc($val);
				if ( $val ne $newname )
				{
					DEBUG_ 'SG['. $name .']+ "'. $val .'" renamed to "'. $newname .'"';
					$val = $newname;
				}

				# check for exist
				elsif ( ! $f )
				{
					DEBUG_ 'SG['. $name .']+ "'. $val .'" -ERR:DNE-';
					$hr->{error} = 'service['. $val .'] does not exist';
				}
				else
				{
					DEBUG_ 'SG['. $name .']+ "'. $val .'"';
				}

				# add to members
				$hr->{'members'} = pushArrayUniq($hr->{'members'},$val);
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
			my $note = '';
			if ( index($hr->{'tag'}, $zone) == -1 )
			{
				$note = " NOTE: zone +". $zone;
				$hr->{tag} = pushArrayUniq($hr->{tag},$zone);
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
			DEBUG_ "A[". $name ."]+ ". $newaddr .' ['. $hr->{tag} .']'. $note;
		}
		else
		{
			DEBUG_ "A< FAILED TO PARSE: ". $line;
		}
	}
	elsif ( $state eq 'addrgrp' || ( ! $state && $line =~ /^set group address / ) )
	{
		my ($zone,$name,$key,$val,$desc);
		if ( $line =~ /^set group address "([^"]+)" "([^"]+)"( comment "[^"]+"|)$/ )
		{
			($zone,$name) = ($1,$2);
			if ( $hrAddrGroup->{$name} && ref($hrAddrGroup->{$name}) eq 'HASH' )
			{
				DEBUG_ "AG[". $name ."]: NOTE: new address-group [". $name ."] already exists in zones [". $hrAddrGroup->{$name}->{'tag'} ."]"
					if ( index($hrAddrGroup->{$name}->{'tag'},$zone) > -1 );
				$hrAddrGroup->{$name}->{'tag'} = pushArrayUniq($hrAddrGroup->{$name}->{'tag'}, $zone);
			}
			else 
			{
				DEBUG_ "AG[". $name ."]+ new [". $zone ."]";
				$hrAddrGroup->{$name} = { 'tag' => $zone };
			}
		}

		# add
		elsif ( $line =~ /^set group address "([^"]+)" "([^"]+)" (add) "([^"]+)"/ )
		{
			($zone,$name,$key,$val) = ($1,$2,$3,$4);

			unless ( $hrAddrGroup->{$name} && ref($hrAddrGroup->{$name}) eq 'HASH' )
			{
				DEBUG_ "AG[". $name ."]: address-group [". $name ."] does not exist";
				die;
			}
			my $hr = $hrAddrGroup->{$name};

			if ( $key eq 'add' )
			{
				DEBUG_ 'AG['. $name .']+ "'. $val .'"';
				$hr->{'members'} = pushArrayUniq($hr->{'members'}, $val);
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

		# policy start
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

			DEBUG_ 'P['. $id .']: '. $hr->{action} .' '. $hr->{srcaddr} .'['. $hr->{srczone} .'] -> '. $hr->{dstaddr} .'['. $hr->{dstzone} .'] : '. $hr->{svc};

			# validate addr exists
			my $f = findAddrOrGroup($5); my $n = 'srcaddr';
			DEBUG_ 'P['. $id ."]: $n: ". $5 .( $f ? '' : ' -ERR:DNE-' );
			if ( ! $f )
			{
				$hr->{error} = pushError( $hr->{error}, 'ERR: address or address-group ['. $5 .'] not found' );
			}

			$f = findAddrOrGroup($6); $n = 'dstaddr';
			DEBUG_ 'P['. $id ."]: $n: ". $6 .( $f ? '' : ' -ERR:DNE-' );
			if ( ! $f )
			{
				$hr->{error} = pushError( $hr->{error}, 'ERR: address or address-group ['. $6 .'] not found' );
			}

			# validate svc exists
			my $newname = renameSvc($7);
			$f = findSvcOrGroup($7);
			if ( $f || $newname ne $7 )
			{
				if ( ! grep(/$newname/,split(/\|/,$hr->{svc})) )
				{
					DEBUG_ 'P['. $id .']: svc '. $7 . ( $newname ne $7 ? ' renamed to '. $newname : '' );
					$hr->{svc} = $newname;
				}
				else
				{
					DEBUG_ 'P['. $id .']: NOTE: svc '. $7 . ( $newname ne $7 ? ' renamed to '. $newname : '' ). " already exists found in svc list [". $hr->{svc} ."]";
				}
			}
			else
			{
				my $err = 'ERR: svc['. $7 .'] not found';
				$hr->{error} = pushError( $hr->{error}, $err );
				DEBUG_ 'P['. $id .']: '. $err;
			}
		}

		# validate policy id
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

		# addl service
		elsif ( $line =~ /^set service "([^"]+)"$/ )
		{
			my $newname = renameSvc($1);
			my $f = findSvcOrGroup($1);
			if ( $f || $newname ne $1 )
			{
				if ( ! grep(/$newname/,split(/\|/,$hr->{svc})) )
				{
					DEBUG_ 'P['. $id .']: addl svc '. $1 . ( $newname ne $7 ? ' renamed to '. $newname : '' );
					$hr->{svc} .= '|'. $newname;
				}
				else
				{
					DEBUG_ 'P['. $id .']: NOTE: svc '. $1 . ( $newname ne $7 ? ' renamed to '. $newname : '' ). " already exists found in svc list [". $hr->{svc} ."]";
				}
			}
			else
			{
				my $err = 'ERR: addl svc['. $1 .'] not found';
				DEBUG_ 'P['. $id .']: '. $err;
				$hr->{error} = pushError( $hr->{error}, $err );

				# commit anyway
				$hr->{svc} .= '|'. $newname;
			}
		}

		# addl src/dst address
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

		# logging
		elsif ( $line =~ /^set log (session-init)$/ )
		{
			DEBUG_ 'P['. $id ."]: log ". $1;
			$hrPolicy->{$id}->{'log-start'} = 'yes'
				if $1 eq 'session-init';
		}

		# policy end
		elsif ( $line =~ /^exit$/ )
		{
			$state = undef;
			$hr = $hrPolicy->{$id};
			$hr->{app} = 'any' unless $hr->{app};

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

# post process services with both udp and tcp ports
DEBUG_ "\nPost-processing Services...\n";
foreach my $key ( keys %$hrSvc )
{
	my $hr = $hrSvc->{$key};

	if ( $hr->{tcp} && $hr->{udp} )
	{
		my $p = 'tcp'; my $n = $key .'_'. $p;
		$hrSvc->{$n} = { protocol => $p, dstport => $hr->{$p}->{dstport} };
		$hrSvc->{$n}->{srcport} = $hr->{$p}->{srcport} if $hr->{$p}->{srcport};
		DEBUG_ "S[". $n ."]: ". $p ." service ". ( $hrSvc->{$n}->{srcport} ? " src = ". $p ."/". $hrSvc->{$n}->{srcport} : '' ) ." dst = ". $p ."/". $hrSvc->{$n}->{dstport};

		$p = 'udp'; $n = $key .'_'. $p;
		$hrSvc->{$n} = { protocol => $p, dstport => $hr->{$p}->{dstport} };
		$hrSvc->{$n}->{srcport} = $hr->{$p}->{srcport} if $hr->{$p}->{srcport};
		DEBUG_ "S[". $n ."]: ". $p ." service ". ( $hrSvc->{$n}->{srcport} ? " src = ". $p ."/". $hrSvc->{$n}->{srcport} : '' ) ." dst = ". $p ."/". $hrSvc->{$n}->{dstport};

		# bind them with a service-group
		$hrSvcGroup->{$key.'_TcpUdp'} = { members => $key.'_tcp|'.$key.'_udp' };

		# erase original service
		delete $hrSvc->{$key};
	}
	elsif ( $hr->{tcp} || $hr->{udp} )
	{
		my $p = ( $hr->{tcp} ? 'tcp' : 'udp' );
		$hr->{protocol} = $p;
		$hr->{dstport} = $hr->{$p}->{dstport};
		$hr->{srcport} = $hr->{$p}->{srcport} if $hr->{$p}->{srcport};
	}
	else
	{
		DEBUG_ "ERR: post-processing failure for '". $key ."' - removing";
		delete $hrSvc->{$key};
	}
}

DEBUG_ "\nOutput Services...\n";
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

DEBUG_ "\nOutput Service Groups...\n";
foreach my $key ( keys %$hrSvcGroup )
{
	# DEBUG_ "SG[". $key ."]";
	my $hr = $hrSvcGroup->{$key}; my $out;
	$out = formatErrors($hr->{error});
	$out .= 'set service-group "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' members [ "'. join('" "',split(/\|/,$hr->{'members'})) .'" ]';
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

DEBUG_ "\nOutput Addresses...\n";
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

DEBUG_ "\nOutput Address Groups...\n";
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

DEBUG_ "\nOutput Policies...\n";
foreach my $key ( @arrPolicy )
{
	# DEBUG_ "P[". $key ."]";
	my $hr = $hrPolicy->{$key}; my $out;
	$out = formatErrors($hr->{error});
	$out .= 'set rules "r'. $key .'"';
	$out .= ' action '. $hr->{action};
	$out .= ' disabled '. $hr->{'disabled'} if $hr->{'disabled'};
	$out .= ' log-start '. $hr->{'log-start'} if $hr->{'log-start'};
	$out .= ' from "'. $hr->{srczone} .'"' unless uc($hr->{srczone}) eq 'GLOBAL';
	$out .= ' to "'. $hr->{dstzone} .'"' unless uc($hr->{dstzone}) eq 'GLOBAL';
	$out .= ' source '. formatArray($hr->{srcaddr}) unless uc($hr->{srcaddr}) eq 'ANY';
	$out .= ' destination '. formatArray($hr->{dstaddr}) unless uc($hr->{dstaddr}) eq 'ANY';
	$out .= ' application '. formatArray($hr->{app}) if $hr->{app};
	$out .= ' service '. formatArray($hr->{svc}) unless $hr->{svc} eq 'ANY';
	$out .= "\n" if $hr->{error};

	print $out ."\n";
}

sub findSvc
{
	my $n = shift;

	return $hrSvc->{$n}
		if $hrSvc->{$n} && ( $hrSvc->{$n}->{tcp} || $hrSvc->{$n}->{udp} );

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
		if $hrSvc->{$n} && $hrSvc->{$n}->{newname};
	
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

sub formatArray
{
	my $str = shift;

	return ( index($str,'|') != -1 ? '[ "'. join('" "',split(/\|/,$str)) .'" ]' : '"'. $str .'"' );
}

sub pushArrayUniq
{
	my $arr = shift;
	my $val = shift;

	return $arr .'|'. $val
		if ( $arr && index($arr,$val) == -1 );

	return $val;
}