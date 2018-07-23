#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';

BEGIN {
    use_ok('saxsmerge');
}

my $t = new saliweb::Test('saxsmerge');

# Test get_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_navigation_links();
    isa_ok($links, 'ARRAY', 'navigation links');
    like($links->[0], qr#<a href="http://modbase/top/">SAXS Merge Home</a>#,
         'Index link');
    like($links->[1],
         qr#<a href="http://modbase/top/queue.cgi">Queue</a>#,
         'Queue link');
}

# Test get_lab_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_lab_navigation_links();
    isa_ok($links, 'ARRAY', 'navigation links');
    like($links->[-1], qr#<a href="http://www.pasteur.fr">Institut Pasteur</a>#,
         'Pasteur link');
}
