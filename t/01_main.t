#!/usr/bin/perl

# Formal testing for Archive::Generator

use strict;
use lib '../../../modules'; # Development testing
use lib '../lib';           # Installation testing
use UNIVERSAL 'isa';
use Test::More qw{no_plan};
use Class::Autouse qw{:devel};
use Class::Handle;

# Set up any needed globals
BEGIN {
	$| = 1;
}




# Check their perl version
BEGIN {
	ok( $] >= 5.005, "Your perl is new enough" );
}
	




# Does the module load
BEGIN { use_ok( 'Archive::Generator' ) }
require_ok( 'Archive::Generator');


is( Archive::Generator->errstr, '', '->errstr correctly starts at ""' );



# Test the interface matches
my $methods = {
	'Archive::Generator' => [ qw{
		new errstr
		addSection newSection getSection Sections SectionList removeSection
		} ],
	'Archive::Generator::Section' => [ qw{
		name path errstr new
		addFile newFile getFile Files FileList removeFile
		} ],
	'Archive::Generator::File' => [ qw{
		new path errstr generator arguments
		} ],
	};
foreach my $class ( sort keys %$methods ) {
	my $Class = Class::Handle->new( $class )
		or die "Failed to get handle for class '$class'";
	foreach ( @{ $methods->{$class} } ) {	
		ok( $Class->can( $_ ), "$class has public API method '$_'" );
	}
}




####################################################################
# Section 1 - Test constructors

# Create a trivial generator
my $Trivial = Archive::Generator->new();
ok( $Trivial, 'Generator constructor returns true' );
my $expected = bless { SECTIONS => {} }, 'Archive::Generator';
is_deeply( $Trivial, $expected, 'Creation of trivial Generator returns expected value' );
my $Generator = $Trivial;

# Create a trivial section
ok( ! Archive::Generator::Section->new(), '->new() fails' );
foreach ( undef, '', ' asd ', 'a/b', 'a\b' ) {
	ok( ! Archive::Generator::Section->new( $_ ), '->new( name ) fails with bad name' );
}
my $Section = Archive::Generator::Section->new( 'name' );
ok( $Section, '->new( name ) with legal name returns true' );
my $expected2 = bless { name => 'name', path => 'name', zFILES => {} }, 'Archive::Generator::Section';
is_deeply( $Section, $expected2, 'Creation of simple Section returns expected value' );
ok( $Section->name eq 'name', '->name returns expected value' );
ok( $Section->path eq 'name', '->path returns expected value' );
ok( $Section->path eq 'name', '->path twice doesnt get a different value' );
foreach ( undef, '', 'bad/../path', 'bad\.\.path', '/path' ) {
	ok( ! $Section->path( $_ ), '->path change returns false for bad path' );
	is( $Section->path, 'name', '->path change does change for bad path' );
}
ok( $Section->path( 'path' ), '->path( path ) returns true' );
is( $Section->path , 'path', '->path( path ) changes the path' );
$expected2->{path} = 'path';

# Create a simple file
ok( ! Archive::Generator::File->new(), '->new() fails' );
ok( ! Archive::Generator::File->new( 'path' ), '->new( path ) fails with valid path' );
my $File = Archive::Generator::File->new( 'path', 'main::generator' );
ok( $File, '->new( path, generator ) for simple case returns true' );
my $expected3 = bless { path => 'path', generator => 'main::generator', arguments => 0 }, 'Archive::Generator::File';
is_deeply( $File, $expected3, 'Creation of simple File returns expected value' );

# Check reasons file creation might fail
foreach ( undef, '', 'bad/../path', 'bad\.\.path', '/path' ) {
	ok( ! Archive::Generator::File->new( $_, 'main::generator' ), '->new( path, generator ) fails correctly for bad paths' );
}
foreach ( undef, '', 'main::nonexistant', 'Foo::bar' ) {
	ok( ! Archive::Generator::File->new( 'path', $_ ), '->new( path, generator ) fails correctly for bad generators' );
}

ok( $File->path eq 'path', '->path returns expected value' );
ok( $File->generator eq 'main::generator', '->generator returns expected value' );
is( $File->arguments, 0, '->arguments returns expected value' );





###################################################################
# Test error handling

my @things = ( qw{Archive::Generator Archive::Generator::Section Archive::Generator::File},
	$Generator, $Section, $File );
my $i = 0;
foreach my $this ( @things ) {
	$i++;
	ok( ! defined $this->_error( 'this' . $i ), '->_error returns undef' );
	foreach my $that ( @things ) {
		is( 'this' . $i, $that->errstr, '->errstr picks up error' );
	}
	$this->_clear;
	foreach my $that ( @things ) {
		is( '', $that->errstr, '->errstr is cleared correctly' );
	}
}




#####################################################################
# Manipulating Files in Sections

is( $Section->Files, 0, '->Files returns expected value for empty Section' );
ok( ! $Section->addFile(), '->addFile() returns false' );
is_deeply( $Section, $expected2, '->addFile() doesnt alter section' );
foreach ( undef, '', 1, bless( {}, 'blah' )) {
	ok( ! $Section->addFile( $_ ), '->addFile( File ) fails for bad value' );
	is_deeply( $Section, $expected2, '->addFile( File ) for bad value doesnt alter Section' );
}
ok( $Section->addFile( $File ), '->addFile( File ) returns true' );
$expected2->{zFILES}->{path} = $expected3;
is_deeply( $Section, $expected2, '->addFile( File ) alters Section correctly' );

ok( ! $Section->newFile(), '->newFile() returns false' );
is_deeply( $Section, $expected2, '->newFile() doesnt alter Section' );
ok( ! $Section->newFile( 'path' ), '->newFile( path ) returns false' );
is_deeply( $Section, $expected2, '->newFile( path ) doesnt alter Section' );
foreach ( undef, '', 'bad/../path', 'bad\.\.path', '/path' ) {
	ok( ! $Section->newFile( $_, 'main::generator' ), '->newFile( path, generator ) returns false for bad path' );
	is_deeply( $Section, $expected2, '->newFile( path, generator ) doesnt alter the section' );
}
foreach ( undef, '', 'main::nonexistant', 'Foo::bar' ) {
	ok( ! $Section->newFile( 'path2', $_ ), '->newFile( path, generator ) returns false for bad geneartor' );
	is_deeply( $Section, $expected2, '->newFile( path, generator ) doesnt alter the section' );
}
ok( ! $Section->newFile( 'path', 'main::generator' ), '->newFile( path, generator ) returns false for existing path' );
is_deeply( $Section, $expected2, '->newFile( path, generator ) doesnt alter the section' );

my $rv = $Section->newFile( 'path2', 'main::generator' );
ok( $rv, '->newFile( path, generator ) returns true for good values' );
my $expected4 = bless { path => 'path2', generator => 'main::generator', arguments => 0 }, 'Archive::Generator::File';
$expected2->{zFILES}->{path2} = $expected4;
is_deeply( $rv, $expected4, '->newFile( path, generator ) returns the new file' );
is_deeply( $Section, $expected2, '->newFile( path, generator ) alters Section in expected way' );

is_deeply( $Section->Files, { 'path', $expected3, 'path2', $expected4 }, '->Files returns expected value' );
my @List = $Section->FileList;
my @Expe = ( $expected3, $expected4 );
is_deeply( \@List, \@Expe, '->FileList returns expected value' );

is_deeply( $expected3, $Section->getFile( 'path' ), '->getFile returns expected for existing file' );
ok( ! $Section->getFile( 'nonexistant' ), '->getFile returns false for nonexistant path' );
ok( ! $Section->getFile(), '->getFile returns false for no argument' );

ok( ! $Section->removeFile(), '->removeFile returns false for no argument' );
is_deeply( $Section, $expected2, '->removeFile for no argument doesnt modify Section' );
ok( ! $Section->removeFile( 'nonexistant' ), '->removeFile returns false for bad argument' );
is_deeply( $Section, $expected2, '->removeFile for bad argument doesnt modify Section' );
ok( $Section->removeFile( 'path' ), '->removeFile returns true for good argument' );
delete $expected2->{zFILES}->{path};
is_deeply( $Section, $expected2, '->removeFile removes File successfully' );






###############################################################################
# Manipulating Sections in Generators

is( $Generator->Sections, 0, '->Sections returns 0 for empty Generator' );
ok( ! $Generator->addSection(), '->addSection() returns false' );
foreach ( undef, '', 'blah', bless( {}, 'blah') ) {
	ok( ! $Generator->addSection( $_ ), '->addSection( Section ) returns false for bad argument' );
	is_deeply( $Generator, $expected, '->addSection( Section ) doesnt changeGenerator for bad argument' );
}

ok( $Generator->addSection( $Section ), '->addSection( Section ) returns true for valid section' );
$expected->{SECTIONS}->{name} = $expected2;
is_deeply( $Generator, $expected, '->addSection( Section ) modifies Generator as expected' );
ok( ! $Generator->addSection( $Section ), '->addSection( Section ) returns false for existing section' );
is_deeply( $Generator, $expected, '->addSection( SEction ) doesnt modify generator for existing section' );

ok( ! $Generator->newSection(), '->newSection() returns false' );
is_deeply( $Generator, $expected, '->newSection() doesnt modify object' );
foreach ( undef, '', ' asd ', 'a/b', 'a\b' ) {
	ok( ! $Generator->newSection( $_ ), '->newSection( name ) returns false for bad name' );
	is_deeply( $Generator, $expected, '->newSection( name ) doesnt change Generator for bad name' );
}
ok( ! $Generator->newSection( 'name' ), '->newSection( name ) fails for existing name' );
is_deeply( $Generator, $expected , '->newSection( name ) doesnt change Generator for existing name' );

$rv = $Generator->newSection( 'name2' );
my $expected5 = bless { name => 'name2', path => 'name2', zFILES => {}, }, 'Archive::Generator::Section';
$expected->{SECTIONS}->{name2} = $expected5;
is_deeply( $rv, $expected5, '->newSection(name) returns the expected new object' );
is_deeply( $Generator, $expected, '->newSection(name) modifys the generator as expected' );

is_deeply( $Generator->Sections, { 'name' => $expected2, 'name2' => $expected5 }, 
	'->Files returns the expected structure' );
@List = $Generator->SectionList;
@Expe = ( $expected2, $expected5 );
is_deeply( \@List, \@Expe, '->SectionList returns the expected structure' );

is_deeply( $Generator->getSection( 'name' ), $expected2, '->getSection returns the expected structure' );
ok( ! $Generator->getSection(), '->getSection() fails as expected' );
ok( ! $Generator->getSection( 'nonexistant' ), '->getSection( bad ) fails as expected' );

ok( ! $Generator->removeSection(), '->removeSection() returns false' );
ok( ! $Generator->removeSection( 'bad' ), '->removeSection( bad ) returns false' );
is_deeply( $Generator, $expected, '->bad removeSection() calls dont modify Generator' );
ok( $Generator->removeSection( 'name2' ), '->removeSection( good ) returns true' );
delete $expected->{SECTIONS}->{name2};
is_deeply( $Generator, $expected, '->removeSection( good ) modifys Generator as expected' );
 




# Changing the path of a sect

# Test generation of the contents of a file
use vars qw{$call_count};
$call_count = 0;
my $contents = $File->contents;
ok( $contents, '->contents returns true' );
is( $call_count, 1, '->contents called the generator' );
is( $contents, 'trivial', '->contents returned the correct contents' );
$contents = $File->contents;
is( $call_count, 1, '->contents didnt call the generator the second time' );
is( $contents, 'trivial', '->contents cached correctly' );






######################################################################
# Resources for tests


sub generator {
	$call_count++;
	my $File = shift;
	return 'trivial';
}

1;

