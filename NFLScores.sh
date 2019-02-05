#! /usr/bin/perl

use strict;
use warnings;
use utf8;
use Getopt::Long;
use LWP::Simple;
use Data::Dumper qw(Dumper);
use Net::Ping;
use Time::Piece;



# default values and variables
my $startOfSeason = Time::Piece->strptime("2018/09/06", "%Y/%m/%d");
my $now = localtime;
my $diff = $now - $startOfSeason;
my $numOfDays = int($diff->days);
my $currentWeek = int($numOfDays / 7) + 1;
my $nextWeek = $currentWeek + 1;
my $url = 'http://www.nfl.com/ajax/scorestrip?season=2018&seasonType=REG&week=' . $currentWeek;
my $data = get($url);
my $urlNextWeek = 'http://www.nfl.com/ajax/scorestrip?season=2018&seasonType=REG&week=' . $nextWeek;
my $week = 0;
my $dataNextWeek = get($urlNextWeek);
my $hold = 0;
my $counter = 0;
my $online = 0;
my $filename = 'NFLScores.txt';
my $scoresfile = 'NFLSavedScores.txt';
my @lines;
my $full_text;
my $short_text;
my $BLOCK_BUTTON = $ENV{'BLOCK_BUTTON'};

my $startStyle = "<span bgcolor='#3b3d3fce'>";
my $endStyle = "</span>";
print $startStyle;
# If data was not recived from url then use file
if(!defined $data) {
	# If file was not found then exit
	open(my $ssh, '<', $scoresfile) or die;
	# Add data from file to @lines
	while(my $row = <$ssh>) {
		push(@lines, $row);
	}
}
# Else process data from web
else {
	$online = 1;
	# Split the data into lines
	@lines = split '>', $data;
	my @linesNextWeek = split '>', $dataNextWeek;
	@lines = (@lines, @linesNextWeek);
	#print("\n" . $#lines . "\n");
	# Delete unwanted lines
	my $deletions = 0;
	for my $i ( 0 .. $#lines ) {
		#print("\n" . $lines[$i - $deletions] . "\n");
		if (index($lines[$i - $deletions], 'ss') != -1 
			|| index($lines[$i - $deletions], '<script />') != -1 
			|| index($lines[$i - $deletions], 'gms') != -1 
			|| index($lines[$i - $deletions], '<?xml') != -1) {
	        
			splice @lines, ($i-$deletions), 1;
		    $deletions++;
	    } 
	}
}

# Get counter for team list
# If file doesnt exist then create it and start at 0
if (open(my $fh, '<:encoding(UTF-8)', $filename)) {
	my @settingsA;
  while (my $row = <$fh>) {
    push(@settingsA, $row);
  }
  $counter = $settingsA[0];
  $hold = $settingsA[1];
  close $fh;
} else {
	open(my $wfh, '>', $filename); 
	print $wfh "0\n";
	print $wfh "0";
	close $wfh;
	  
}# Remove white space from lines
if(defined $BLOCK_BUTTON) {
	#print $BLOCK_BUTTON;
	if(index($BLOCK_BUTTON, '2') != -1) {
		if(index($hold, '0') != -1) {
			$hold = 1;
		} else {
			$hold = 0;
			$counter--;
		}
	}
	elsif(index($BLOCK_BUTTON, '3') != -1) {
		if(index($hold, '0') != -1) {
			$counter = $counter - 2;
		} else {
			$counter--;
		}
	}
	elsif(index($BLOCK_BUTTON, '1') != -1) {
		if(index($hold, '1') != -1) {
			$counter++;
		}
	}
}
# Increment counter
if(index($hold, '0') != -1) {
	$counter++;
	# Mod counter with number of games
	$counter = $counter % (@lines - 1);
	if($counter > ((@lines - 1) / 2)) {
		$week = $nextWeek;
	} else {
		$week = $currentWeek;
	}
} else {
	print " ";
}
$full_text .= "[W: ${week}] ";
$short_text .= "[W: ${week}] ";
#print $hold;
#print $counter;
@lines = grep /\S/, @lines;
for my $i (0 .. $#lines ) {
	$lines[$i] =~ s/^\s+//;
}
# Print lines into scores file to be used when offline
if($online) {
	open(my $sfh, '>', $scoresfile);
	print $sfh join ("\n", @lines), "\n";
	close $sfh;
}
# Get info for current line split by space
my @gameinfo = split / /, $lines[$counter];
#print(@gameinfo);

#If game is not in progress
if(index($gameinfo[5], 'F') != -1) {
	my $day;
	my $time;
	my $final;
	my $homescore;
	my $awayscore;
	my $home;
	my $away;
	# Get the day of the game
	my @dayA = split /=/, $gameinfo[3];
	$dayA[1] =~ s/"//g;
	$day = $dayA[1];
	# Get game time
	my @timeA = split /=/, $gameinfo[4];
	$timeA[1] =~ s/"//g;
	$time = $timeA[1];
	# Check if game ended
	if(index($gameinfo[5], 'F') != -1){
		my @finalA = split /=/, $gameinfo[5];
		$finalA[1] =~ s/"//g;
		if(index($finalA[1], 'FO') != -1) {
				$final = "Final - Overtime ";
		} else {
				$final = "Final ";
		}
		
	}
	# Get home team
	my @homeA = split /=/, $gameinfo[7];
	$homeA[1] =~ s/"//g;
	$home .= $homeA[1];
	# If game has not started then get home team score
	if(index($gameinfo[5], 'P') == -1) {
		my @homescoreA = split /=/, $gameinfo[9];
		$homescoreA[1] =~ s/"//g;
		$homescore = $homescoreA[1];
	}
	# Get away team
	my @awayA = split /=/, $gameinfo[10];
	$awayA[1] =~ s/"//g;
	$away .= $awayA[1];
	# If game has not started then get away team score
	if(index($gameinfo[5], 'P') == -1) {
		my @awayscoreA = split /=/, $gameinfo[12];
		$awayscoreA[1] =~ s/"//g;
		$awayscore = $awayscoreA[1];
	}
	# If home team and away team score were set then compare the scores
	if(defined $homescore && defined $awayscore) {
		# Bolds the winning team
		if($homescore > $awayscore) {
			$full_text .= "${day} - ${time} | <b>${home}[${homescore}]</b> @ ${away}[${awayscore}]";
			$short_text .= "<b>${home}[${homescore}]</b> @ ${away}[${awayscore}]";
		} elsif($awayscore > $homescore) {
			$full_text .= "${day} - ${time} | ${home}[${homescore}] @ <b>${away}[${awayscore}]</b>";
			$short_text .= "${home}[${homescore}] @ <b>${away}[${awayscore}]</b>";
		}
	}
	# Else game has not started yet
	else {
		$full_text .= "${day} - ${time} | ${home} @ ${away}";
		$short_text .= "${day} - ${time} | ${home} @ ${away}";
	}

}
#=pod
# Game is in progress
elsif (index($gameinfo[5], 'P') != -1) {
	my $time;
	my $quarter;
	my $home;
	my $homescore;
	my $away;
	my $awayscore;
	my $possesion;
	# Get game start
	my @timeA = split /=/, $gameinfo[4];
	$timeA[1] =~ s/"//g;
	$time = $timeA[1];
	#print $time;
	# Get game day
	my @dayA = split /=/, $gameinfo[3];
	$dayA[1] =~ s/"//g;
	my $day = $dayA[1];
	# Get home team
	my @homeA = split /=/, $gameinfo[7];
	$homeA[1] =~ s/"//g;
	$home = $homeA[1];
	# Get away team
	my @awayA = split /=/, $gameinfo[10];
	$awayA[1] =~ s/"//g;
	$away = $awayA[1];
	# Build full and short text
	$full_text .= "${day} - ${time} | ${home} @ ${away}";
	$short_text .= "${day} - ${time} | ${home} @ ${away}";

}
#=cut
else {
	my $time;
	my $quarter;
	my $home;
	my $homescore;
	my $away;
	my $awayscore;
	my $possesion;
	# Get time left in quarter
	my @timeA = split /=/, $gameinfo[3];
	$timeA[1] =~ s/"//g;
	$time = $timeA[1];
	# Get current quarter
	my @quartA = split /=/, $gameinfo[4];
	$quartA[1] =~ s/"//g;
	$quarter = $quartA[1];
	# Get home team
	my @homeA = split /=/, $gameinfo[7];
	$homeA[1] =~ s/"//g;
	$home = $homeA[1];
	# Get home team score
	my @homescoreA = split /=/, $gameinfo[9];
	$homescoreA[1] =~ s/"//g;
	$homescore .= $homescoreA[1];
	# Get away team
	my @awayA = split /=/, $gameinfo[10];
	$awayA[1] =~ s/"//g;
	$away = $awayA[1];
	# Get away team score
	my @awayscoreA = split /=/, $gameinfo[12];
	$awayscoreA[1] =~ s/"//g;
	$awayscore = $awayscoreA[1];
	my @possesionA = split /=/, $gameinfo[13];
	$possesionA[1] =~ s/"//g;
	$possesion = $possesionA[1];
	# Build full and short text
	if(index($possesion,$home) != -1) {
		$full_text .= "${time} - ${quarter} | <i>${home}[${homescore}]</i> @ ${away}[${awayscore}]";
		$short_text .= "<b>${home}[${homescore}]</b> @ ${away}[${awayscore}]";
	} else {
		$full_text .= "${time} - ${quarter} | ${home}[${homescore}] @<i> ${away}[${awayscore}]</i>";
		$short_text .= "${home}[${homescore}] @<b> ${away}[${awayscore}]</b>";
	}

}
#print $hold;
# Print out full and short text
$full_text .= $endStyle;
print "$full_text\n";
print "$short_text\n";
my @redzoneA = split /=/, $gameinfo[14];
my $redzone = 0;
$redzoneA[1] =~ s/"//g;
$redzone = $redzoneA[1];
if(defined $redzone && index($redzone, '1') != -1) {
	print "#FF0000";
}
# Print new counter to file
open(my $wfh, '>', $filename);
#$counter = 0;
#$hold = 0;
$counter =~ s/\n//g;
print $wfh "${counter} \n";
print $wfh "${hold}";
close $wfh;
