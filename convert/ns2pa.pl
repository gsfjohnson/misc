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
sub DEBUG_ { printf STDOUT $_[0] if DEBUG; };

my $hrSvc = {};
my $hrSvcGroup = {};
my $hrAddr = {};
my $hrAddrGroup = {};
my $hrPolicy = {};
my @arrPolicy;
my $state = undef;
my $id = undef;

my $line = <STDIN>; chomp($line);
MAIN: do {

START:

	if ( $state eq 'service' || ( ! $state && $line =~ /^set service / ) )
	{
		my ($name,$extra,$src,$dst,$prot,$hr);
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
				$src = $2;
				$dst = $3;

				if ( $hr->{'protocol'} && $prot ne $hr->{'protocol'} )
				{
					DEBUG_ "S[". $name ."]: New protocol [". $prot ."] overwriting [". $hr->{'protocol'} ."]\n";
					$hr->{'protocol'} = $prot;
				}
				else
				{
					$hr->{'protocol'} = $prot;
				}

				if ( $src ne '0-65535' && $src ne '1-65535' )
				{
					if ( $hr->{'src'} )
					{
						$hr->{'src'} .= ','.$src;
					}
					else
					{
						$hr->{'src'} = $src;
					}
				}

				if ( $dst =~ /(\d+)-(\d+)/ )
				{
					$dst = $1 if ( $1 eq $2 ); 
				}

				if ( $hr->{'dst'} )
				{
					$hr->{'dst'} .= ','.$dst;
				}
				else
				{
					$hr->{'dst'} = $dst;
				}

			}
			elsif ( $extra =~ /timeout (\d+)/ )
			{
				$hr->{'timeout'} = $1
					unless $1 == 350;
			}
			else
			{
				DEBUG_ "S< FAILED TO PARSE extra: $extra \n";
			}
		}
		else
		{
			DEBUG_ "S< FAILED TO PARSE: $line \n";
		}
	}
	elsif ( $line =~ /^(unset|set) (zone|auth|admin|flow|pki|nsrp|dns|interface) .+/ )
	{
		#DEBUG_ "< $line \n";
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

			if ( length($desc) && $hr->{'description'} && $desc ne $hr->{'description'} )
			{
				DEBUG_ "A[". $name ."]: New description [". $desc ."] overwriting [". $hr->{'description'} ."]\n";
			}
			$hr->{'description'} = $desc if length($desc);
			if ( index($hr->{'tag'}, $zone) == -1 )
			{
				$hr->{'tag'} .= "|".$zone;
			}
			my $newaddr = $addr .( $p ? '/'.$p : '' );
			if ( $hr->{'addr'} && $newaddr ne $hr->{'addr'} )
			{
				DEBUG_ "A[". $name ."]: New addr [". $newaddr ."] overwriting old addr [". $hr->{'addr'} ."]\n";
			}
			$hr->{'addr'} = $newaddr;

			DEBUG_ "A[". $name ."]+ $newaddr \n";
		}
		else
		{
			DEBUG_ "A< FAILED TO PARSE: $line \n";
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
					DEBUG_ "AG[". $name ."]: New address-group [". $name ."] already exists in zones [". $hrAddrGroup->{$name}->{'tag'} ."]\n";
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
				DEBUG_ 'AG['. $name .']+ "'. $val ."\"\n";
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
				DEBUG_ 'AG['. $name .']: "'. $val ."\"\n";
				$hr->{'description'} = $val;
			}
		}
		else
		{
			DEBUG_ "AG< FAILED TO PARSE: $line \n";
		}

	}
	elsif ( $state eq 'policy' || ( ! $state && $line =~ /^set policy / ) )
	{
		my $hr = undef;
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
			DEBUG_ 'P['. $id .']: '. $hr->{action} .' '. $hr->{srcaddr} .'['. $hr->{srczone} .'] -> '. $hr->{dstaddr} .'['. $hr->{dstzone} .'] : '. $hr->{svc} .( defined($hrSvc->{$7}) ? '(FOUND)' : '(NOT FOUND)' ) ."\n";
		}
		elsif ( $line =~ /^set policy id (\d+)( disable|)$/ )
		{
			DEBUG_ 'P['. $id .']: different id '. $1 ."\n"
				if $id != $1;
			$hrPolicy->{$id}->{'disabled'} = 1
				if $2 eq ' disable';
			DEBUG_ 'P['. $id ."]: disabled\n"
				if $2 eq ' disable';

		}
		elsif ( $line =~ /^set policy id (\d+) disable$/ )
		{
			DEBUG_ 'P['. $id .']: different id '. $1 ."\n"
				if ( $id != $1 );
			$hrPolicy->{$id}->{'disabled'} = 1;
			DEBUG_ 'P['. $id ."]: disabled xxx \n";
		}
		elsif ( $line =~ /^set service "([^"]+)"$/ )
		{
			DEBUG_ 'P['. $id .']: addl svc '. $1 ."\n";
			$hrPolicy->{$id}->{'svc'} .= '|'. $1
				if ( index($hrPolicy->{$id}->{'svc'},$1) == -1 );
		}
		elsif ( $line =~ /^set src-address "([^"]+)"$/ )
		{
			DEBUG_ 'P['. $id ."]: addl srcaddr: $1 \n";
			$hrPolicy->{$id}->{'srcaddr'} .= '|'. $1
				if ( index($hrPolicy->{$id}->{'srcaddr'},$1) == -1 );
		}
		elsif ( $line =~ /^set dst-address "([^"]+)"$/ )
		{
			DEBUG_ 'P['. $id ."]: addl dstaddr: $1 \n";
			$hrPolicy->{$id}->{'dstaddr'} .= '|'. $1
				if ( index($hrPolicy->{$id}->{'dstaddr'},$1) == -1 );
		}
		elsif ( $line =~ /^set log (session-init)$/ )
		{
			DEBUG_ 'P['. $id ."]: log $1 \n";
			$hrPolicy->{$id}->{'log-start'} = 'yes'
				if $1 eq 'session-init';
		}
		elsif ( $line =~ /^exit$/ )
		{
			DEBUG_ 'P['. $id ."]: done\n";
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
					$hr->{dstaddr} = $name;
				}
				else
				{
					$name = 'ag_rule'. $id .'_1';
					my $hrAG = {};
					$hrAG->{members} = $hr->{srcaddr};
					$hrAddrGroup->{$name} = $hrAG;
					$hr->{srcaddr} = $name;
				}
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
					$name = 'ag_rule'. $id .'_2';
					my $hrAG = {};
					$hrAG->{members} = $hr->{dstaddr};
					$hrAddrGroup->{$name} = $hrAG;
					$hr->{dstaddr} = $name;
				}
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
					$name = 'sg_rule'. $id;
					my $hrSG = {};
					$hrSG->{members} = $hr->{svc};
					$hrSvcGroup->{$name} = $hrSG;
					$hr->{svc} = $name;
				}
				$updated++;
			}

			DEBUG_ 'P['. $id .']: fin '. $hr->{action} .' '. $hr->{srcaddr} .'['. $hr->{srczone} .'] -> '. $hr->{dstaddr} .'['. $hr->{dstzone} .'] : '. $hr->{svc} .( defined($hrSvc->{$hr->{svc}}) || defined($hrSvcGroup->{$hr->{svc}}) ? '(FOUND)' : '(NOT FOUND)' ) ."\n"
				if $updated;

			# clear id
			$id = undef;
		}
		else
		{
			DEBUG_ "P< FAILED TO PARSE: $line \n";
		}

	}
	else
	{
		# DEBUG_ $line ."\n";
	}

} while ( chomp($line = <STDIN>) );

foreach my $key ( keys %$hrSvc )
{
	my $hr = $hrSvc->{$key}; my $out;
	next unless $hr->{'dst'} || $hr->{'protocol'};
	$out = 'set service "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' protocol '. $hr->{'protocol'};
	$out .= ' port '. $hr->{'dst'} ."\n";

	print $out;
}

foreach my $key ( keys %$hrSvcGroup )
{
	# DEBUG_ "SG[". $key ."]\n";
	my $hr = $hrSvcGroup->{$key}; my $out;
	$out = 'set service-group "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' [ "'. join('" "',split(/\|/,$hr->{'members'})) .'" ]' ."\n";

	print $out;
}

foreach my $key ( keys %$hrAddr )
{
	# DEBUG_ "A[". $key ."]\n";
	my $hr = $hrAddr->{$key}; my $out;
	$out = 'set address "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' description "'. $hr->{'description'} .'"' if $hr->{'description'};
	$out .= ' '. ( $hr->{'addr'} =~ /\/\d/ ? 'ip-netmask ' : 'fqdn ' ). $hr->{'addr'} ."\n";

	print $out;
}

foreach my $key ( keys %$hrAddrGroup )
{
	# DEBUG_ "AG[". $key ."]\n";
	my $hr = $hrAddrGroup->{$key}; my $out;
	$out = 'set address-group "'. $key .'"';
	# $out .= ' tag [ "'. join('" "',split(/\|/,$hr->{'tag'})) .'" ]';
	$out .= ' description "'. $hr->{'description'} .'"' if $hr->{'description'};
	$out .= ' static [ "'. join('" "',split(/\|/,$hr->{'members'})) .'" ]' ."\n";

	print $out;
}

foreach my $key ( @arrPolicy )
{
	# DEBUG_ "P[". $key ."]\n";
	my $hr = $hrPolicy->{$key}; my $out;
	$out = 'set rules "r'. $key .'"';
	$out .= ' action '. $hr->{action};
	$out .= ' disabled '. $hr->{'disabled'} if $hr->{'disabled'};
	$out .= ' log-start '. $hr->{'log-start'} if $hr->{'log-start'};
	$out .= ' from "'. $hr->{srczone} .'"' unless $hr->{srczone} eq 'Global';
	$out .= ' to "'. $hr->{dstzone} .'"' unless $hr->{dstzone} eq 'Global';
	$out .= ' source "'. $hr->{srcaddr} .'"';
	$out .= ' destination "'. $hr->{dstaddr} .'"';
	$out .= ' service "'. $hr->{svc} .'"' unless $hr->{svc} eq 'ANY';
	$out .= "\n";

	print $out;
}
