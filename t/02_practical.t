#!/usr/bin/perl

# Contains more practical tests for Archive::Generator

use strict;
use lib '../../../modules'; # Development testing
use lib '../lib';           # Installation testing
use UNIVERSAL 'isa';
use Test::More qw{no_plan};
use File::Flat;
use Archive::Generator;

# Create our generator
use vars qw{$Generator $Section1 $Section2};
sub init {
	$Generator = Archive::Generator->new();
	$Section1 = $Generator->newSection( 'one' );
	$Section1->newFile( 'this', 'main::trivial' );
	$Section1->newFile( 'that', 'main::direct', 'filecontents' );
	$Section1->newFile( 'foo/bar', 'main::direct', "Contains\ntwo lines" );
	$Section1->newFile( 'x/is a/number.file', 'main::numbers' );
	$Section2 = $Generator->newSection( 'two' );
	$Section2->newFile( 'another/file', 'main::trivial' );
	$Section2->newFile( 'another/ortwo', 'main::direct', 'filecontents' );
}
init();







########################################################################
# Save tests

# Try to save a single file
my $rv = $Generator->getSection( 'one' )->getFile( 'this' )->save( './first/file.txt' );
ok( $rv, 'File ->save returns true' );
ok( File::Flat->exists( './first/file.txt' ), 'File ->save creates file' );
file_contains( './first/file.txt', 'trivial' );

# Save a section
$rv = $Generator->getSection( 'two' )->save( './second' );
ok( $rv, 'Section ->save returns true' );
ok( File::Flat->exists( './second/another/file' ), 'First file exists' );
ok( File::Flat->exists( './second/another/ortwo' ), 'Second file exists' );
file_contains( './second/another/file', 'trivial' );
file_contains( './second/another/ortwo', 'filecontents' );

# Save the entire generator
$rv = $Generator->save( './third' );
ok( $rv, 'Generator ->save returns true' );
my $files = {
	'./third/one/this' => 'trivial',
	'./third/one/that' => 'filecontents',
	'./third/one/foo/bar' => "Contains\ntwo lines",
	'./third/one/x/is a/number.file' => "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n",
	'./third/two/another/file' => 'trivial',
	'./third/two/another/ortwo'  => 'filecontents',
	};
foreach ( keys %$files ) {
	ok( File::Flat->exists( $_ ), "File '$_' exists" );
	file_contains( $_, $files->{$_} );
}
	



# Additional tests

sub file_contains {
	my $filename = shift;
	my $contains = shift;
	return ok( undef, "File $filename doesn't exist" ) unless -e $filename;
	return ok( undef, "$filename isn't a file" ) unless -f $filename;
	return ok( undef, "Can't read contents of $filename" ) unless -r $filename;
	my $contents = File::Flat->slurp( $filename )
		or return ok( undef, 'Error while slurping file' );
	return is( $$contents, $contains, "File $filename contents match expected value" );
}





# Generators
sub trivial {
	my $File = shift;
	return 'trivial';
}

sub direct {
	my $File = shift;
	my $contents = shift;
	return $contents;
}

sub numbers {
	my $File = shift;
	return join '', map { "$_\n" } 1 .. 10;
}




END {
	File::Flat->remove( 'first' );
	File::Flat->remove( 'second' );
	File::Flat->remove( 'third' );
}
