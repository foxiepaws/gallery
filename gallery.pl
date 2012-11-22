#!/usr/bin/env perl

#########################################################################
# PerlGallery                                                           #
# A simple Static image gallery generator. Thats right, Static.         #
# Static pages are faster to serve. this same code CAN be used for a    #
# CGI by enabling the CGI mode but by default will generate many static #
# files                                                                 #
#########################################################################
# Author: Joshua Theze <foxwolfblood>         ###########################
# License:                                    ###########################
# This program released under the WTFPL.      ###########################
#                                             ###########################
#                                             ###########################
#   0. You just DO WHAT THE FUCK YOU WANT TO. ###########################
#########################################################################

## lets use the modules we are going to use
# good practice
use strict;
use warnings; 
# qualify our globals
use vars qw(%config @pics);
# HTML::Template, for generating the index and single page.
use HTML::Template;
##

my %config = (
CGIMODE => 0,
imagedir => "full/",
thumbdir => "thumbs/",
pubdir => "",
tmpldir => "./tmpls/"
);

# this array will hold all the image files from the image store.
my @pics; 

# put the single template in memory for speed reasons
our $singletmpl  = HTML::Template->new(filename => $config{tmpldir}.'single.tmpl');

# function to get the images for all the functions to use.
sub get_images {
    # change to the image store directory.
    chdir $config{pubdir}.$config{imagedir};
    # grab all the pic types into an array, this line should probably be changed to include more types but im lazy.
    @pics = (<*.jpg>,<*.gif>,<*.png>);
}

## Thumbnail generation script, uses ImageMagick's `convert` though system().
sub generate_thumbs { 
    # create thumbnails using ImageMagick for each picture in @pics. and save into the thumbnail dir. 
    foreach (@pics) {
	# we only want to generate the thumbs if they dont already exist so ensure thats the case.
        if (!(-f $config{pubdir}.$config{thumbdir}.$_)) {
            system("convert ".$config{pubdir}.$config{imagedir}.$_." -thumbnail 260x180 ".$config{pubdir}.$config{thumbdir}.$_);
        }
    } 
}
# this function calls the generate functions and then saves the content to files.
sub generate_gallery {
    # get all the images in @pics 
    get_images();
    # generate new thumbnails if needed.
    generate_thumbs();
    # generate the index file to the pubdir.
    open (FILE,">".$config{pubdir}."index.html");
    print FILE generate_index();
    close FILE;
    # generate each single page.
    my $picl = scalar @pics;
    for (my $count = 0; $count < $picl; $count++) {
        my ($previmage, $nextimage);
	if ($count == 0) {
	    $previmage = $pics[$picl-1];
	    $nextimage = $pics[$count+1];
	} elsif ($count == $picl-1) {
            $previmage = $pics[$count-1];
	    $nextimage = $pics[0];
	} else {
            $previmage = $pics[$count-1];
	    $nextimage = $pics[$count+1];
	}
	my $currentimage = $pics[$count];
	open(FILE, ">".$config{pubdir}.$pics[$count].".html");
	print FILE generate_single($currentimage,$previmage,$nextimage);
	close FILE;
    }
}
## generates the index page for the gallery
sub generate_index {
    # load the index template
    my $tmpl = HTML::Template->new(filename => $config{tmpldir}.'index.tmpl');
    # an array for the pics, don't worry, despite the name we dont actually need to use a table in the template.
    my @table;
    # for every picture in @pics we want to bind the variables to the single view page and the thumbnail 
    foreach (@pics) {
        my %row;
        $row{LINK} = "$_.html";
        $row{THUMB} = $config{thumbdir}.$_;
	# push the hash to the list for the gallery
        push @table, \%row;
    }
    # bind the table to the template.
    $tmpl->param(GALLERY => \@table);
    # return the finished product
    return $tmpl->output;
}
## generates a view image page
sub generate_single {
   # shift the image we need to work with into $image from @_
   my ($image,$prev,$next) = @_;
   # bind the path for the fullsize image.
   $singletmpl->param(PATH => $config{imagedir}.$image,PREV=>$prev.".html",NEXT=>$next.".html");
   # return the finished product
   return $singletmpl->output;
}

# do work! in a later revision this will be replaced w/ code to allow CGIMODE to be turned on :D
generate_gallery();
