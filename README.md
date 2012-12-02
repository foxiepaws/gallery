gallery.pl
==========

This is a simple gallery generator using HTML::Template and Imagemagick's convert
though a system call. 

Install HTML::Template (debian and deratives: libhtml-template-perl) or use CPAN

Install Imagemagick (debian and deratives: imagemagick)

set pubdir and tmpldir to ABSOLUTE PATHS TO WHERE THEY WILL GO, make sure to CREATE that directory, the full and thumbs dir
put the images in the pubdir's full dir and run the script.

Using the CGI mode
------------------

With CGI mode you need to put your assets and images outside of the path and then rewrite e.g. like
<pre>
RewriteEngine on
RewriteCond %{REQUEST_URI} !assets/(.*)\.
RewriteCond %{REQUEST_URI} !full/(.*)\.
RewriteCond %{REQUEST_URI} !thumbs/(.*)\.
RewriteRule ^(.*) /cgi-bin/gallery.pl/$1 [QSA]
</pre>
