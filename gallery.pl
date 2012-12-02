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
# 0. You just DO WHAT THE FUCK YOU WANT TO.   ###########################
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
our $singletmpl = HTML::Template->new(filename => $config{tmpldir}.'single.tmpl');

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

## prepare function used for handling CGI based.
sub prepare {
    get_images();
    generate_thumbs();

}

### CGI functions

## helper functions for sending headers and shit
# sending a single header, just takes the header content and adds the \r\n to it.
sub print_header {
    my $bla = shift;
    print $bla . "\r\n";
}
# ending the sent headers.
sub end_headers {
    # we want to send an X-Powered-By just because :3
    print_header "X-Powered-By: Gallery.pl/1.0.0";
    print "\r\n";
}
# extract each part out of a querystring and stuff it in a hash
sub query_string {
    my $qs = shift;
    my @sqs = split('&', $qs);
    my %hash;
    foreach (@sqs) {
        my ($key, $value) = split("=",$_,2);
        $hash{$key} = $value;
    }
    return %hash;
}


## Quick header sending stuff, makes it easier to send certain things
# HTML pages.
sub html_cgi_headers {
   print_header "Content-Type: text/html";
   # this is where you can send headers like Expires and such.
}
# error page.
sub error_404_headers {
   print_header "Status: 404 Not Found";
}
##################################################################################################
if ($config{CGIMODE} == 1) {
    # run the prepare function.
    prepare(); # builds image library and creates needed thumbs quick.
    # we have a few choices for handling the data, we can do it with QUERY_STRING or PATH_INFO
    # how we handle each one is a little different so bring on the logic!
    if ($ENV{PATH_INFO} eq undef) {              # just in case, this will probably handle QUERY_STRING based code later
        error_404_headers();                     # send the status line
        print_header "Content-Type: text/plain"; # we use plain text because im lazy
        end_headers();                           # end the headers
        print "not working";                     # print something...
    } else {
        # here is the querystring handling 
        my %qs = query_string($ENV{QUERY_STRING}); 
        if ($ENV{PATH_INFO} eq "/" or $ENV{PATH_INFO} eq "/index.html" or $ENV{PATH_INFO} eq "/index") { # handling the index
            html_cgi_headers();                                                                          # print content type and related stuff
            end_headers();                                                                               # print X-Powered-By and the blank \r\n to signify the beginning of content
            print generate_index();                                                                      # print  the content itself
        } elsif ($ENV{PATH_INFO} eq "/view" and !($qs{image} eq undef)) { # 
            my $image = $qs{image}; 
            my $found = -1;
            my $picl = scalar @pics;
            for (my $count = 0; $count < $picl; $count++) {
                my $currentimage = $pics[$count];
                if ($currentimage eq $image) {
                   $found = $count;
                }
            }

            if ($found == -1) {
                error_404_headers();
                print_header "Content-Type: text/plain";
                print_header "Refresh: 5; url=/"; # go back to index
                end_headers(); 
                print "the content you attempted to access does not exist.";
                die;
            } 
            # some logic to deal with the nextimage stuff
            my ($previmage, $nextimage);
            if ($found == 0) {
                $previmage = $pics[$picl-1];
                $nextimage = $pics[$found+1];
            } elsif ($found == $picl-1) {
                $previmage = $pics[$found-1];
                $nextimage = $pics[0];
            } else {
                $previmage = $pics[$found-1];
                $nextimage = $pics[$found+1];
            }
            my $currentimage = $pics[$found];
            html_cgi_headers(); # print content type and related stuff
            end_headers();      # print X-Powered-By and the blank \r\n to signify the beginning of content
            print generate_single($currentimage,$previmage,$nextimage);
        } else { # its a 404, show a page and then go back to the index.
            error_404_headers();
            print_header "Content-Type: text/plain";
            print_header "Refresh: 5; url=/"; # go back to index
            end_headers(); 
            print "the content you attempted to access does not exist.";
        }
    }
} else {
    generate_gallery();
}
