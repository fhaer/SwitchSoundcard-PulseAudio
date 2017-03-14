#!/usr/bin/perl
# switches all pulse audio streams to the next sound card ("sink") when called without parameter
# alternatively, the first parameter denotes the sink id (as given by pactl list sinks) to switch to

use strict;

# sink names matching the blacklist are ignored
my @blacklist = ("hdmi", "remap");

my $newSink = $ARGV[0];
my $curSink = getCurrentSink();

if (!defined $newSink) {
 $newSink = getNextSink($curSink);
}

# set new sink as default
print "setting new default sink $newSink\n";
sysc("pactl set-default-sink \"$newSink\"");

# move all streams to the new sink
my $sinks = sysc("pactl list short sink-inputs");
for my $line (@{$sinks}) {
 my $sinkInput = $line;
 $sinkInput =~ s/^(\d+)\s+(\S+)\s+.*/$1/g;
 print "moving stream $sinkInput\n";
 sysc("pactl move-sink-input \"$sinkInput\" \"$newSink\"");
}

# --- subroutines ---

# returns the current sink id
sub getCurrentSink {
 # return first sink id given by pulse audio
 my $sinks = sysc("pactl list short sink-inputs");
 for my $line (@{$sinks}) {
  return $1 if ($line =~ /^\S+\s+(\d+)\s+.*/);
 }
 print "current sink not found\n";
 exit 1;
}

# returns the sink id after the current one
sub getNextSink {
 my $curSink = shift;
 my $sinks = sysc("pactl list short sinks");
 # search for current sink
 my $curSinkFound = 0;
 for my $line (@{$sinks}) {
  my $sink = $line;
  my $sinkName = $line;
  $sink     =~ s/^(\d+)\s+(\S+)\s+.*/$1/g;
  $sinkName =~ s/^(\d+)\s+(\S+)\s+.*/$2/g;
  if (!$curSinkFound && $sink == $curSink) {
   $curSinkFound = 1;
  } elsif ($curSinkFound) {
   # return sink if not blacklisted
   my $isBlacklisted = 0;
   for my $b (@blacklist) {
     $isBlacklisted = 1 if ($sinkName =~ /$b/);
   }
   if (!$isBlacklisted) {
    print "$curSink -> $newSink: $sinkName\n";
    return $newSink;
   }
  }
 }
 print "next sink not found\n";
 exit 1;
}

# executes system calls
sub sysc {
 my $cmd = shift;
 my $out = `$cmd`;
 my @outArray = split('\n', $out);
 return \@outArray;
}
