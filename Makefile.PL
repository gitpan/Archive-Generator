require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Archive::Generator',
	'VERSION_FROM' => 'lib/Archive/Generator.pm',
	'PREREQ_PM'    => {
		Test::More    => 0,
		Class::Handle => 0.2,
		File::Spec    => 0.82,
		File::Flat    => 0.6,
	},	
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (adam@ali.as)',
		'ABSTRACT' => 'Framework for generating files, and making them into Archives',
	) : (),
);
