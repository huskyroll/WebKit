#!/usr/bin/perl -w

use strict;


my $MAC_SUPPORTED_ONLY = 1;

my %MIBNumberFromCharsetsFile;
my %aliasesFromCharsetsFile;
my %namesWritten;

my $invalid_encoding = "kCFStringEncodingInvalidId";

my $output = "";

my $error = 0;

sub error ($)
{
    print STDERR @_, "\n";
    $error = 1;
}

sub emit_line
{
    my ($name, $mibNum, $encodingNum) = @_;
 
    error "$name shows up twice in output" if $namesWritten{$name};
    $namesWritten{$name} = 1;
        
    $encodingNum = "kCFStringEncoding" . $encodingNum if $encodingNum !~ /^[0-9]/;
    $mibNum = -1 if !$mibNum;
    $output .= "    { \"$name\", $mibNum, $encodingNum },\n";
}

sub process_mac_encodings
{
    my ($filename) = @_;
    
    my %seenMacNames;
    my %seenIANANames;
    
    open MAC_ENCODINGS, $filename or die;
    
    while (<MAC_ENCODINGS>) {
        chomp;
	if (my ($MacName, $IANANames) = /(.*): (.*)/) {
            my %aliases;
            
            error "CFString encoding name $MacName is mentioned twice in mac-encodings.txt" if $seenMacNames{$MacName};
            $seenMacNames{$MacName} = 1;

            # Build the aliases list.
            # Also check that no two names are part of the same entry in the charsets file.
	    my @IANANames = sort split ", ", lc $IANANames;
            for my $name (@IANANames) {
                if ($name !~ /^[-a-z0-9_]+$/) {
                    error "$name, in mac-encodings.txt, has illegal characters in it";
                    next;
                }
                
                error "$name is mentioned twice in mac-encodings.txt" if $seenIANANames{$name};
                $seenIANANames{$name} = 1;
                
                $aliases{$name} = 1;
                next if !$aliasesFromCharsetsFile{$name};
                for my $alias (@{$aliasesFromCharsetsFile{$name}}) {
                    $aliases{$alias} = 1;
                }
                for my $otherName (@IANANames) {
                    next if $name eq $otherName;
                    if ($aliasesFromCharsetsFile{$otherName}
                        && $aliasesFromCharsetsFile{$name} eq $aliasesFromCharsetsFile{$otherName}
                        && $name le $otherName) {
                        error "mac-encodings.txt lists both $name and $otherName under $MacName, but that aliasing is already specified in character-sets.txt";
                    }
                }
            }
            
            # write out
            my $MIBNumber;
            my @aliases = sort keys %aliases;
            for my $alias (@aliases) {
                $MIBNumber = $MIBNumberFromCharsetsFile{$alias} if $MIBNumberFromCharsetsFile{$alias};
            }
            
            for my $alias (@aliases) {
                emit_line($alias, $MIBNumber, $MacName);
            }
	} elsif (/./) {
            my $MacName = $_;
            
            error "CFString encoding name $MacName is mentioned twice in mac-encodings.txt" if $seenMacNames{$MacName};
            $seenMacNames{$MacName} = 1;
        }
    }
    
    # Hack, treat -E and -I same as non-suffix case.
    # Not sure if this does the right thing or not.
    #$name_to_mac_encoding{"iso-8859-8-e"} = $name_to_mac_encoding{"iso-8859-8"};
    #$name_to_mac_encoding{"iso-8859-8-i"} = $name_to_mac_encoding{"iso-8859-8"};
    
    close MAC_ENCODINGS;
}

sub process_iana_charset 
{
    my ($canonical_name, $mib_enum, @aliases) = @_;
    
    return if !$canonical_name;
    
    my @names = sort $canonical_name, @aliases;
    
    for my $name (@names) {
        $MIBNumberFromCharsetsFile{$name} = $mib_enum if $mib_enum;
        $aliasesFromCharsetsFile{$name} = \@names;
    }
}

sub process_iana_charsets
{
    my ($filename) = @_;
    
    open CHARSETS, $filename or die;
    
    my %seen;
    
    my $canonical_name;
    my $mib_enum;
    my @aliases;
    
    while (<CHARSETS>) {
        chomp;
	if ((my $new_canonical_name) = /Name: ([^ \t]*).*/) {
            $new_canonical_name = lc $new_canonical_name;
            
            error "saw $new_canonical_name twice in character-sets.txt", if $seen{$new_canonical_name};
            $seen{$new_canonical_name} = 1;
            
	    process_iana_charset $canonical_name, $mib_enum, @aliases;
	    
	    $canonical_name = $new_canonical_name;
	    $mib_enum = "";
	    @aliases = ();
	} elsif ((my $new_mib_enum) = /MIBenum: ([^ \t]*).*/) {
	    $mib_enum = $new_mib_enum;
	} elsif ((my $new_alias) = /Alias: ([^ \t]*).*/) {
            next if $new_alias eq "None";
            
            $new_alias = lc $new_alias;
            
            error "saw $new_alias twice in character-sets.txt", if $seen{$new_alias};
            $seen{$new_alias} = 1;
            
            push @aliases, $new_alias;
	}
    }
    
    process_iana_charset $canonical_name, $mib_enum, @aliases;
    
    close CHARSETS;
}

# Program body

process_iana_charsets($ARGV[0]);
process_mac_encodings($ARGV[1]);

exit 1 if $error;

print "static const CharsetEntry table[] = {\n";
print $output;
print "    { NULL, -1, $invalid_encoding }\n};\n";
