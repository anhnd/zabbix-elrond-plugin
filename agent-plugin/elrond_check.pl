#!/usr/bin/perl -w
use Getopt::Std;
use LWP::Simple;
use JSON;
use Scalar::Util qw(looks_like_number);

my $protocol = "http";
my $path = "/node/status";
my $statisticsLink = "https://wallet-api.elrond.com/validator/statistics";

sub startsWith{
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

sub validArg{
    if(defined($_[0]) && $_[0] ne "" && !startsWith($_[0],"-")){
        return 1;
    }
    return 0;
}

getopts("h:p:m:" => \%opts);
my $host = $opts{"h"};
my $port = $opts{"p"};
my $metric = $opts{"m"};

if(!validArg($port)){
    $port = "8080";
}
if(!validArg($metric)){
    print("0\n"); exit 1;
}
if(!validArg($host)){
    $host = "localhost";
}
$portAddr = $protocol . "://" . $host . ":" . $port . $path;
$content = get($portAddr);

if(!defined($content)){
    print("0\n"); exit 2;
}

if($metric eq "erd_node_running"){
    print("1\n"); exit 0;
}

my $jsonObj = from_json($content);
my $values = %$jsonObj{'details'};
if(!defined($values)){
    print("0\n"); exit 3;
}

my $retVal;
if($metric eq "erd_new_version_exists"){
    my $version = %$values{"erd_app_version"};
    my $latestVersion = %$values{"erd_latest_tag_software_version"};
    if(startsWith($version, $latestVersion)){
	$retVal = 0;
    }
    else{
        $retVal = 1;
    }
}
elsif($metric eq "erd_accepted_rate"){
    my $key = %$values{"erd_public_key_block_sign"};
    my $statisticsContent = get($statisticsLink);
    my $statisticsJsonObj = from_json($statisticsContent);
    my $validatorsJsonObj = %$statisticsJsonObj{'statistics'};
    my $validatorJsonObj = %$validatorsJsonObj{$key};
    my $totalNumLeaderSuccess = %$validatorJsonObj{'totalNumLeaderSuccess'};
    my $totalNumLeaderFailure = %$validatorJsonObj{'totalNumLeaderFailure'};
    if((looks_like_number($totalNumLeaderSuccess)) && (looks_like_number($totalNumLeaderFailure))){
        $totalNumLeader = $totalNumLeaderSuccess + $totalNumLeaderFailure;
        if($totalNumLeader==0){
	    $retVal = 100;
	}
	else{
	    $retVal = 100*($totalNumLeaderSuccess/$totalNumLeader);
	}
    }
}
else{
    $retVal = %$values{$metric};
}

if(!defined($retVal) || $retVal eq ""){
    print("0\n"); exit 4;
}
print "$retVal\n";
exit 0;
