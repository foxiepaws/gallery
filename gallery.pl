#!/usr/bin/env perl

#########################################################################
# PerlGallery                                                           #
# A simple Static image gallery generator. Thats right, Static.         #
#########################################################################
# Author: Joshua Theze <foxwolfblood>         ###########################
# License:                                    ###########################
# This program released under the WTFPL.      ###########################
#                                             ###########################
#                                             ###########################
# 0. You just DO WHAT THE FUCK YOU WANT TO.   ###########################
#########################################################################

## lets use the modules we are going to use
# good practice
use strict;
use warnings;
# we are using given, we need this
use feature "switch";
# qualify our globals
use vars qw(%config @pics);
# HTML::Template, for generating the index and single page.
use HTML::Template;
##

my %config = (
    imagedir => "full/",
    thumbdir => "thumbs/",
    pubdir => "/home/fox/pubtest/",
    tmpldir => "/home/fox/perl/gallery/tmpls/"
);
our $sortMode;
# this array will hold all the image files from the image store.
my @pics;

# Filesort
# Takes two Arguments, Requires one
#   * $temp     - [REQUIRED] Reference to an Array.
#   * $opts     - [Optional] Sets options
#     * dir      - Path to directory if not $PWD. 
#     * sortMode - Override the global sort mode.
# Returns an Array reference that is a sorted array.
# usage: sortFiles(\@temp,{dir => "$mydir",sortMode => "alpha"});
sub sortFiles { 
    my $temp = shift;
    my $opts = shift;
    my $dir;
    my $lsortMode;
    # if we have options passed as well, check it. 
    if ($opts) { 
        if ($opts->{dir}) {
            print "Set Dir\n";
            $dir = $opts->{dir};
        } else {
            print "PWD\n";
            $dir = ".";
        }
        if ($opts->{sortMode}) {
           $lsortMode = $opts->{sortMode};
        } elsif ($sortMode) { # we have a global sortmode.
           $lsortMode = $sortMode;
        } else { # we have nothing passed and the sortmode is undef!
           $lsortMode = "default";  
        }
           
    }
   
    given ($lsortMode) {
        when("alpha") {
            return sort @$temp 
        }
        when("bymod") {
            return sort { my ($a_dev,$a_ino,$a_mode,$a_nlink,$a_uid,$a_gid,$a_rdev,$a_size,$a_atime,$a_mtime,$a_ctime,$a_blksize,$a_blocks) = stat("$dir/$a"); my ($b_dev,$b_ino,$b_mode,$b_nlink,$b_uid,$b_gid,$b_rdev,$b_size,$b_atime,$b_mtime,$b_ctime,$b_blksize,$b_blocks) = stat("$dir/$b");return $a_mtime <=> $b_mtime; } @$temp;
        }
        when("bysize") {
            return sort { my ($a_dev,$a_ino,$a_mode,$a_nlink,$a_uid,$a_gid,$a_rdev,$a_size,$a_atime,$a_mtime,$a_ctime,$a_blksize,$a_blocks) = stat("$dir/$a"); my ($b_dev,$b_ino,$b_mode,$b_nlink,$b_uid,$b_gid,$b_rdev,$b_size,$b_atime,$b_mtime,$b_ctime,$b_blksize,$b_blocks) = stat("$dir/$b");return $a_size <=> $b_size; } @$temp;
        }
        when("ralpha") {
            return sort { $b cmp $a } @$temp 
        }
        when("rbymod") {
            return sort { my ($a_dev,$a_ino,$a_mode,$a_nlink,$a_uid,$a_gid,$a_rdev,$a_size,$a_atime,$a_mtime,$a_ctime,$a_blksize,$a_blocks) = stat("$dir/$a"); my ($b_dev,$b_ino,$b_mode,$b_nlink,$b_uid,$b_gid,$b_rdev,$b_size,$b_atime,$b_mtime,$b_ctime,$b_blksize,$b_blocks) = stat("$dir/$b");return $b_mtime cmp $a_mtime; } @$temp;
        }
        when("rbysize") {
            return sort { my ($a_dev,$a_ino,$a_mode,$a_nlink,$a_uid,$a_gid,$a_rdev,$a_size,$a_atime,$a_mtime,$a_ctime,$a_blksize,$a_blocks) = stat("$dir/$a"); my ($b_dev,$b_ino,$b_mode,$b_nlink,$b_uid,$b_gid,$b_rdev,$b_size,$b_atime,$b_mtime,$b_ctime,$b_blksize,$b_blocks) = stat("$dir/$b");return $b_size cmp $a_size; } @$temp;
        }
        default {
            return @$temp 
        }
    }
}

# put the single template in memory for speed reasons
our $singletmpl = HTML::Template->new(filename => $config{tmpldir}.'single.tmpl');

# function to get the images for all the functions to use.
sub get_images {
    # change to the image store directory.
    chdir $config{pubdir}.$config{imagedir};
    opendir (my $dh, ".") || die "can't opendir: $!";
    my @temp = grep { /.*\.(jpe?g|png|gif|tiff?)/i && -f "$_" } readdir $dh;
    @pics = sortFiles(\@temp,{sortMode=>'rbymod'});
    closedir $dh
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
        if ($config{CGIMODE} == 0){
            $row{LINK} = "$_.html";
        }else {
            $row{LINK} = "view?image=$_";
        }
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
   if ($config{CGIMODE} == 0){
       $singletmpl->param(PATH => $config{imagedir}.$image,PREV=>$prev.".html",NEXT=>$next.".html");
   } else {   
       $singletmpl->param(PATH => $config{imagedir}.$image,PREV=>"view?image=$prev",NEXT=>"view?image=$next");
   }
   # return the finished product
   return $singletmpl->output;
}

generate_gallery();
