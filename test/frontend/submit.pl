#!/usr/bin/perl -w

# A file handle object that behaves similarly to those returned by CGI's
# upload() method
package TestFh;
use Fcntl;
use overload
    '""' => \&asString;

$FH='fh00000';

sub DESTROY {
    my $self = shift;
    close $self;
}

sub asString {
    my $self = shift;
    # get rid of package name
    (my $i = $$self) =~ s/^\*(\w+::fh\d{5})+//;
    $i =~ s/%(..)/ chr(hex($1)) /eg;
    return $i;
}

sub new {
    my ($pack, $name, $reported_name) = @_;
    if (not defined $reported_name) {
        $reported_name = $name;
    }
    my $fv = ++$FH . $reported_name;
    my $ref = \*{"TestFh::$fv"};
    sysopen($ref, $name, Fcntl::O_RDWR(), 0600) || die "could not open: $!";
    return bless $ref, $pack;
}

package main;

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp;

BEGIN {
    use_ok('saxsmerge');
}

my $t = new saliweb::Test('saxsmerge');

sub make_default_submit_parameters {
    my ($cgi) = @_;
    $cgi->param('recordings', '3');
    $cgi->param('gen_unit', 'Angstrom');
    $cgi->param('gen_output', 'normal');
    $cgi->param('gen_stop', 'merging');
    $cgi->param('fit_param', 'Full');
    $cgi->param('res_model', 'normal');
    $cgi->param('class_alpha', '0.05');
    $cgi->param('merge_param', 'Full');
    $cgi->param('gen_npoints_val', '200');
    $cgi->param('clean_cut', '0.1');
    $cgi->param('res_ref', 'last');
    $cgi->param('res_npoints', '200');
    $cgi->param('merge_extrapol', '0');
}

# Check job submission

# Check basic get_submit_page usage
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    make_default_submit_parameters($cgi);

    ok(open(FH, "> test.profile"), "Open test.profile");
    ok(close(FH), "Close test.profile");
    $cgi->param('uploaded_file', (TestFh->new('test.profile')));

    my $ret = $self->get_submit_page();
    like($ret, qr/Your job has been submitted.*Results will be found/ms,
         "submit page HTML");

    ok(open(FH, "incoming/input.txt"), "Open input.txt");
    my $contents;
    {
        local $/ = undef;
        $contents = <FH>
    }
    ok(close(FH), "Close input.txt");
    like($contents, qr/test\.profile=3.*\-\-outlevel=normal/ms,
         "submit page output file");

    chdir('/') # Allow the temporary directory to be deleted
}
