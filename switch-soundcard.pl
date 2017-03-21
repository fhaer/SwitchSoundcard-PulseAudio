#!/usr/bin/perl
# switches all pulse audio streams to the next sound card ("sink") when called without parameter
# alternatively, the first parameter denotes the sink id (as given by pactl list sinks) to switch to

use strict;

# sink names matching the blacklist are ignored
my @blacklist = (); 
#@blacklist = ("hdmi", "remap", "iec");

my $newSink = $ARGV[0];
my $curSink = getCurrentSink();

# if user did not specify sink, retrieve the sink listed after the current one
if (!defined $newSink) {
 $newSink = getNextSink($curSink);
}

# set new sink as default
print "setting new default sink $newSink\n";
sysc("pactl set-default-sink \"$newSink\"");

# move all streams to the new sink
my $sinks = sysc("pactl list short sink-inputs");
for my $pactlSinkInput (@{$sinks}) {
 my $input = $pactlSinkInput;
 $input =~ s/^(\d+)\s+(\S+)\s+.*/$1/g;
 print "moving input stream $input\n";
 sysc("pactl move-sink-input \"$input\" \"$newSink\"");
}

# --- subroutines ---

# returns the current sink id
sub getCurrentSink {
 # return first sink id given by pulse audio
 my $sinks = sysc("pactl list short sink-inputs");
 for my $pactlSinkInput (@{$sinks}) {
  return $1 if ($pactlSinkInput =~ /^\S+\s+(\d+)\s+.*/);
 }
 print "current sink not found, possibly no audio playback\n";
 exit 1;
}

# returns the pactl sink after the current one
sub getNextSink {
 my $curSink = shift;
 my $nextSink = "";
 my $sinks = sysc("pactl list short sinks");
 # search for current sink; if found, return next non-blacklisted entry
 my $curSinkFound = 0;
 for my $pactlSink (@{$sinks}) {
  if (!$curSinkFound && isCurrentSink($pactlSink, $curSink)) {
   $curSinkFound = 1;
  } elsif ($curSinkFound) {
   if (!isBlacklisted($pactlSink)) {
    $nextSink = $pactlSink;
    last;
   }
  }
 }
 # if current sink found and end of the list reached => iterate again and return
 if (!$nextSink && $curSinkFound) {
  for my $pactlSink (@{$sinks}) {
   if (!isCurrentSink($pactlSink, $curSink) && !isBlacklisted($pactlSink)) {
     $nextSink = $pactlSink;
     last;
   }
  }
 }
 if ($nextSink) {
  print "$curSink -> " . getSinkId($nextSink) . ": " . getSinkName($nextSink) . "\n";
  return getSinkId($nextSink);
 }
 print "next sink not found\n";
 exit 1;
}

# reutnrs 1 if given pactl matches the given current sink id, 0 otherwise
sub isCurrentSink {
 my $pactlSink = shift;
 my $curSink = shift;
 return 1 if (getSinkId($pactlSink) == $curSink);
 return 0;
}

# returns 1 if given pactl sink is blacklisted, 0 otherwise
sub isBlacklisted {
 my $pactlSink = shift;
 my $sinkName = getSinkName($pactlSink);
 for my $b (@blacklist) {
  return 1 if ($sinkName =~ /$b/);
 }
 return 0;
}

# parses pactl sink and returns id
sub getSinkId {
 my $s = shift;
 $s =~ s/^(\d+)\s+(\S+)\s+.*/$1/g;
 return $s;
}

# parses pactl sink and returns name
sub getSinkName {
 my $s = shift;
 $s =~ s/^(\d+)\s+(\S+)\s+.*/$2/g;
 return $s;
}

# executes system calls
sub sysc {
 my $cmd = shift;
 my $out = `$cmd`;
 my @outArray = split('\n', $out);
 return \@outArray;
}
