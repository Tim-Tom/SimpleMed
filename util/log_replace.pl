use v5.24;

use strict;
use warnings;

use YAML::XS;
use File::Temp qw(tempfile);

my ($messages, @dirs);

if (@ARGV < 1) {
  $messages = 'log-messages.yml';
} else {
  $messages = shift @ARGV;
}
if (@ARGV < 1) {
  @dirs = ('lib', 'bin');
} else {
  @dirs = @ARGV;
}

my %messages = do {
  if (-f $messages) {
    open(my $in, '<:encoding(utf-8)', $messages) or die "Unable to open $messages for read: $!";
    local $/ = undef;
    %{ YAML::XS::Load(scalar <$in>) };
  } else {
    ();
  }
};

my $messageId = (sort { $b cmp $a } keys %messages)[0] || '0000';

my $anyChanged = 0;

while(my $dirname = shift @dirs) {
  die "$dirname is not a directory" unless -d $dirname;
  opendir(my $dir, $dirname);
  while(my $path = readdir $dir) {
    next if $path =~ /^\.\.?$/;
    my $fullPath = "$dirname/$path";
    if (-d $fullPath) {
      push(@dirs, $fullPath);
    } else {
      open(my $in, '<:encoding(utf-8)', $fullPath) or die "Unable to open $fullPath for read: $!";
      my ($out, $outname) = tempfile;
      my $changed = 0;
      while(<$in>) {
        $changed += s/q\^([^\^0-9][^\^]*)\^/$messageId = sprintf '%04d', $messageId + 1; $messages{$messageId} = $1; "q^$messageId^"/ge;
        print $out $_;
      }
      close $out;
      close $in;
      if ($changed) {
        rename $outname, $fullPath;
        ++$anyChanged;
      } else {
        unlink $outname;
      }
    }
  }
}

if ($anyChanged) {
  open(my $out, '>:encoding(utf-8)', $messages) or die "Unable to open $messages for write: $!";
  print $out YAML::XS::Dump(\%messages);
}
