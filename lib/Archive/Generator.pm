package Archive::Generator;

# This packages provides a simplified object for a collection of generated
# files, and ways to then distribute the files.

use strict;
use UNIVERSAL 'isa';
use Class::Autouse qw{
	File::Spec
	File::Flat
	Class::Inspector
	Archive::Generator::Section
	Archive::Generator::File
	};

# Version
use vars qw{$VERSION};
BEGIN {
	$VERSION = 0.1;
}





#####################################################################
# Main Interface Methods

# Constructor
sub new { 
	my $class = shift;
	return bless { 
		SECTIONS => {} 
		}, $class;
}

# Generate and cache all files, rather than doing generation on demand
sub generate {
        my $self = shift;
        foreach my $Section ( @{ $self->{SECTIONS} } ) {
                foreach my $File ( $Section->FileList ) {
                        unless ( defined $File->contents ) {
                                my $section = $Section->name;
                                my $path = $File->path;
                                return $self->_error( "Generation failed for file '$path' in section '$section'" );
                        }
                }
        }

        return 1;
}

sub save {
	my $self = shift;
	my $base = shift || '.';

	# Check we can write to the location
	unless ( File::Flat->canWrite( $base ) ) {
		return $self->_error( "Insufficient permissions to write to '$base'" );
	}

	# Process each of the Sections
	foreach my $Section ( $self->SectionList ) {
		my $subdir = File::Spec->catdir( $base, $Section->path );
		unless ( $Section->save( $subdir ) ) {
			return $self->_error( "Failed to save Generator to '$base'" );
		}
	}

	return 1;
}





#########################################################################
# Working with Sections

# Add a new section and return it
sub newSection {
	my $self = shift;
	
	# Create the section with the arguments
	my $Section = Archive::Generator::Section->new( @_ )
		or return undef;
	
	# Add the new section
	return $self->addSection( $Section ) 
		? $Section : undef;
}

# Add an existing section
sub addSection {
	my $self = shift;
	my $Section = isa( $_[0], 'Archive::Generator::Section' )
		? shift : return undef;
			
	# Does a section with the name already exists?
	my $name = $Section->name;
	if ( exists $self->{SECTIONS}->{$name} ) {
		return $self->_error( 'A section with that name already exists' );
	}
	
	# Add the section
	$self->{SECTIONS}->{$name} = $Section;
	return 1;
}

# Get the hash of sections
sub Sections {
        my $self = shift;
        return 0 unless scalar keys %{ $self->{SECTIONS} };
        return { %{ $self->{SECTIONS} } };
}

# Get the sections as a list
sub SectionList {
	my $self = shift;
	my $Sections = $self->{SECTIONS};
	return map { $Sections->{$_} } sort keys %$Sections;
}

# Get a section by name
sub getSection { $_[0]->{SECTIONS}->{$_[1]} }

# Remove a section, by name
sub removeSection { delete $_[0]->{SECTIONS}->{$_[1]} }





#####################################################################
# Utility methods

sub _check {
	my $either = shift;
	my $type = shift;
	my $string = shift;
	
	if ( $type eq 'name' ) {
		return '' unless defined $string;
		return $string =~ /^\w{1,31}$/ ? 1 : '';
		
	} elsif ( $type eq 'relative path' ) {
		return '' unless defined $string;
		return '' unless length $string;
		
		# Get the canonical version of the path
		my $canon = File::Spec->canonpath( $string );
		
		# Does the path contain escaping forward slashes
		return '' if $string =~ /\\/;
		
		# Does the path contain relative directories
		return '' if $string =~ /\.\./;
		
		# Does the path start with a slash?
		return '' if $string =~ m!^/!;
		
		# Otherwise, looks good
		return 1;				
	
	} elsif ( $type eq 'generator' ) {
		return $either->_error( 'No generator defined' ) unless defined $string;
		
		# Look for illegal characters
		unless ( $string =~ /^\w+(::\w+)*$/ ) {
			return $either->_error( 'Invalid function name format' );
		}
	
		# All is good if the function is already loaded
		{ no strict 'refs';
			if ( defined *{"$string"}{CODE} ) {
				return 1;
			}
		}
	
		# Does the class exist?
		my ($module) = $string =~ m/^(.*)::.*$/;		
		unless ( Class::Inspector->installed( $module ) ) {
			return $either->_error( "Package '$module' does not appear to be present" );
		}
		
		# Looks good
		return 1;
		
	} else {
		return undef;
	}
}

# Error handling
use vars qw{$errstr};
BEGIN { $errstr = '' }
sub errstr { $errstr }
sub _error { $errstr = $_[1]; undef }
sub _clear { $errstr = '' }

1;

__END__

=pod

=head1 NAME Archive::Generator - File archive generation framework

=head1 DESCRIPTION

This module is highly experimental and dangerous.

It is likely to undergo API changes, and possibly an outright name change.

More documentation forthcoming after API freeze.

To assist with this module, contact the Author

=head1 AUTHOR

        Adam Kennedy ( maintainer )
        cpan@ali.as
	http://ali.as/
        
=head1 COPYRIGHT

Copyright (c) 2002 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

