#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('saxsmerge');
    use_ok('saliweb::frontend');
}

my $t = new saliweb::Test('saxsmerge');

sub get_summary_file() {
  return "Merge file
  General
   Filename: merged.dat
   Number of points: 816
   Data range: 0.01713 0.33480
   447 points from profile 0 (180713_MBP-IVB_1mg.dat)
   13 points from profile 1 (180713_MBP-IVB_2.5mg.dat)
   356 points from profile 2 (180713_MBP-IVB_5mg.dat)
  Gaussian Process parameters
   mean function : Full
   G : 23.548439 +- 0.610082
   Rg : 25.133688 +- 0.976429
   d : 1.313590 +- 11.304685
   s : 0.360370 +- 79.795855
   A : -4.938232 +- 0.217562
   sigma2 : 21.339089 +- 0.151586
   tau : 9.507107 +- -nan
   lambda : 0.041534 +- 232.081966
  Calculated Values
   Q1 : 0.044627
   Q1.Rg : 1.121638
   I(0) : inf

Input file 0
   mean function : Simple
   G : 13.989880 +- 1.351631
   Rg : 45.703773 +- 0.861011
   A : 1.857049 +- 1.503380
   sigma2 : 18.321082 +- 0.344843
   tau : 1.066421 +- 3.944389
   lambda : 0.047426 +- 128.533419
   Calculated Values
    Q1 : 0.159873
    Q1.Rg : 7.306783
    I(0) : 107.007365
";
}

# Check results page

# Check failed job
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    my $ret = $frontend->get_results_page($job);
    like($ret, '/No output file was produced/', 'job no output');

    chdir("/");
}

# Check OK job
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(open(FH, ">summary.txt"));
    print FH get_summary_file();
    ok(close(FH));

    my $ret = $frontend->get_results_page($job);
    like($ret, '/Output Files.*' .
               'Summary file.*' .
               'Merge Statistics.*' .
               'mean function.*A.*G.*Rg.*sigma.*lambda.*' .
               '180713_MBP-IVB_1mg\.dat/ms', 'results page, ok');

    chdir("/");
}

# Check OK job with plots
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(open(FH, ">summary.txt"));
    print FH get_summary_file();
    ok(close(FH));

    ok(open(FH, ">input.txt"));
    print FH "SubtrB1-A11b.dat=10
SubtrB2-A11b.dat=10
--auto
";
    ok(close(FH));

    foreach my $plot ("mergeplots.js", "mergeinplots.js", "inputplots.js") {
      ok(open(FH, ">$plot"));
      print FH "";
      ok(close(FH));
    }

    my $ret = $frontend->get_results_page($job);
    like($ret, '/Output Files.*' .
               'Summary file.*' .
               'Merge Statistics.*' .
               'mean function.*A.*G.*Rg.*sigma.*lambda.*' .
               '180713_MBP-IVB_1mg\.dat.*' .
               '<h4>Merge Plots<\/h4>.*' .
               '<h4>Input Colored Merge Plots<\/h4>.*' .
               '<h4>Input Plots<\/h4>/ms', 'results page, ok with plots');

    chdir("/");
}
