#-----------------------------------------------------------------------------
# 01write.t	OpenOffice::OODoc Installation test		2008-11-07
#-----------------------------------------------------------------------------

use Test;
BEGIN	{ plan tests => 19 }

use OpenOffice::OODoc	2.107;
ok($OpenOffice::OODoc::VERSION >= 2.107);

#-----------------------------------------------------------------------------

my $generator	=	"OpenOffice::OODoc " . $OpenOffice::OODoc::VERSION .
				" installation test";
my $testfile	=	$OpenOffice::OODoc::File::DEFAULT_OFFICE_FORMAT == 2 ?
				"odftest.odt" : "ootest.sxw";
my $class	=	"text";
my $image_file	=	"OODoc/data/image.png";
my $image_size	=	"91mm, 53mm";
my $test_date	=	odfLocaltime();

# Creating an empty new ODF file with the default template
unlink $testfile;
my $archive = odfContainer($testfile, create => $class);
unless ($archive)
	{
	ok(0); # Unable to create the test file
	die "# Unable to create the test file\n";
	}
else
	{
	ok(1); # Test file created
	}
	
#-----------------------------------------------------------------------------

my $notice	= 
"This document has been generated by the OpenOffice::OODoc " .
"installation test. If you can read this paragraph in blue letters with " .
"a yellow background, if you can see a centered image at the top of the " .
"page, and if the informations below make sense, " .
"your installation is probably OK.";

my $title	= "OpenOffice::OODoc test document";
my $description	= "Generated by $generator";

# Opening the content using OpenOffice::OODoc::Document
my $doc	= odfConnector
		(
		container	=> $archive,
		part		=> 'content',
		readable_XML	=> 'true'
		)
	or die "# Unable to find a regular document content\n";
ok($doc); # Document open and parsed

my $styles = odfConnector
		(
		container	=> $archive,
		part		=> 'styles',
		readable_XML	=> 'true'
		)
	or die "# Unable to get the styles\n";
ok($styles); # Styles open and parsed

# Creating a graphic style
ok	(
	$styles->createImageStyle
		(
		'Centered Image',
		properties	=>
			{
			'style:horizontal-pos'	=> 'center',
			'style:vertical-pos'	=> 'from-top',
			'fo:margin-bottom'	=> '2cm'
			}
		)
	);
# Inserting an image in the document
ok	(
	$doc->createImageElement
		(
		'Logo',
		style		=> 'Centered Image',
		page		=> 1,
		size		=> $image_size,
		import		=> $image_file
		)
	);

# Appending a page footer
$styles->createStyle
	(
	'Centered Paragraph',
	family		=> 'paragraph',
	parent		=> 'Standard',
	properties	=>
		{
		'fo:text-align'		=> 'center'
		}
	);
$styles->styleProperties
	(
	'Centered Paragraph',
	area		=> 'text',
	'fo:font-size'	=> '60%'
	);
ok	(
	$styles->masterPageFooter
		(
		'Standard',
		$styles->createParagraph
			(
			"Created by OpenOffice::OODoc\n" . localtime(),
			'Centered Paragraph'
			)
		)
	);
# Appending a level 1 heading
ok	(
	$doc->appendHeading
		(
		text	=> "Congratulations !",
		level	=> "1",
		style	=> "Heading_20_1"
		)
	);
# Creating a coloured paragraph style (blue foreground, yellow background)
ok	(
	$styles->createStyle
		(
		"Colour",
		family		=> 'paragraph',
		parent		=> 'Standard',
		properties	=>
			{
			-area			=> 'paragraph',
			'fo:color'		=> odfColor(0,0,128),
			'fo:background-color'	=> odfColor("yellow"),
			'fo:text-align'		=> 'justify'
			}
		)
	);
if ($doc->isOpenDocument)
	{
	$styles->styleProperties
		("Colour", -area => 'text', 'fo:color' => '#000080');
	}
# Appending another paragraph using the new style
ok	(
	$doc->appendParagraph(text => $notice, style => "Colour" )
	);
# Appending another level 1 heading
ok	(
	$doc->appendHeading
		(
		text	=> "Your environment",
		level	=> 1,
		style	=> "Heading_20_1"
		)
	);
# Appending a table showing some environment details
my $table = $doc->appendTable("Environment", 6, 2);
$doc->cellValue($table, "A1", "Platform");
$doc->cellValue($table, "B1", $^O);
$doc->cellValue($table, "A2", "Perl version");
$doc->cellValue($table, "B2", $]);
$doc->cellValue($table, "A3", "Archive::Zip version");
$doc->cellValue($table, "B3", $Archive::Zip::VERSION);
$doc->cellValue($table, "A4", "XML::Twig version");
$doc->cellValue($table, "B4", $XML::Twig::VERSION);
$doc->cellValue($table, "A5", "OpenOffice::OODoc version");
$doc->cellValue($table, "B5", $OpenOffice::OODoc::VERSION);
$doc->cellValue($table, "A6", "OpenOffice::OODoc build");
$doc->cellValueType($table, "B6", 'date');
$doc->cellValue($table, "B6", $OpenOffice::OODoc::BUILD_DATE);

# Appending another level 1 heading
ok	(
	$doc->appendHeading
		(
		text	=> "Your installation choices",
		level	=> 1,
		style	=> "Heading_20_1"
		)
	);

# Appending a table with the installation parameters
my $office_format = $OpenOffice::OODoc::File::DEFAULT_OFFICE_FORMAT == 2 ?
	"OASIS Open Document" : "OpenOffice.org 1.0";
my $color_map	= $OpenOffice::OODoc::Styles::COLORMAP || "<none>";
$table = $doc->appendTable("Choices", 4, 2);
$doc->cellValue($table, "A1", "Local character set");
$doc->cellValue($table, "B1", $OpenOffice::OODoc::XPath::LOCAL_CHARSET);
$doc->cellValue($table, "A2", "Working directory");
$doc->cellValue($table, "B2", $OpenOffice::OODoc::File::WORKING_DIRECTORY);
$doc->cellValue($table, "A3", "RGB color map");
$doc->cellValue($table, "B3", $color_map);
$doc->cellValue($table, "A4", "Default office document format");
$doc->cellValue($table, "B4", $office_format);

# Opening the metadata of the document
my $meta = odfMeta(container => $archive, readable_XML => 'on')
	or die "# Unable to find regular metadata\n";
ok($meta);
# Writing some metadata elements
ok($meta->title($title));
ok($meta->description($description));
ok($meta->generator($generator));
ok($meta->creation_date($test_date));
ok($meta->date($test_date));
$meta->creator($ENV{'USER'});
$meta->initial_creator($ENV{'USER'});

# Saving the $testfile file
ok($archive->save);

$doc->dispose;
$styles->dispose;
$meta->dispose;

exit 0;
