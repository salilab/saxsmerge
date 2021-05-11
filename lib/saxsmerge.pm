package saxsmerge;
use saliweb::frontend;
use strict;
our @ISA = "saliweb::frontend";

use Scalar::Util qw/looks_like_number/;

# Add our own JavaScript and CSS to the page header
sub get_start_html_parameters {
  my ($self, $style) = @_;
  my %param = $self->SUPER::get_start_html_parameters($style);
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => '/jquery/latest/jquery.min.js' };
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => '//modbase.compbio.ucsf.edu/saxsmerge/html/saxsmerge.js' };
  push @{$param{-script}}, {-language => 'JavaScript',
                            -code => $self->google_tracker()};
  #push @{$param{-style}->{'-src'}}, 'html/saxsmerge.css';
  #push @{$param{-style}->{'-src'}}, 'html/saxsmerge.css';
  return %param;
}

sub get_download_page {
  my ($self) = @_;
  return "<div id=\"fullpart\">".$self->get_text_file("download.txt")."</div>";
}

sub new {
    return saliweb::frontend::new(@_, "##CONFIG##");
}

sub get_lab_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    my $links = $self->SUPER::get_lab_navigation_links();
    push @$links, $q->a({-href=>'http://www.pasteur.fr'}, 'Institut Pasteur');
    return $links;
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "SAXS Merge Home"),
        $q->a({-href=>$self->queue_url}, "Queue"),
        $q->a({-href=>$self->help_url}, "Help"),
        $q->a({-href=>$self->faq_url}, "FAQ"),
        $q->a({-href=>$self->download_url}, "Download"),
        $q->a({-href=>"https://modbase.compbio.ucsf.edu/saxsmerge/results.cgi/53_31_12_11_4_121?passwd=MnVGDrwrjR"}, "Example output")
        ];
}

sub get_project_menu {
  # no menu
  return "";
}

sub get_header_page_title {
  return "<table> <tbody> <tr> <td halign='left'>
  <table><tr><td>
  <a href=\"https://salilab.org/saxsmerge\">
  <img src=\"//salilab.org/saxsmerge/html/img/saxsmerge_logo.png\" align = 'left' height = '80'
  alt='SAXS Merge'></a></td></tr>
         <tr><td><h1>An automated statistical method to merge SAXS profiles from different concentrations and exposure times</h1> </td></tr></table>
         </table>
      </td> </tr>
  </tbody>
  </table>\n";
}

sub get_footer {
  return "<hr size='2' width=\"80%\"><div id='address'>
<p> <p>Contact: <script>escramble(\"saxsmerge\",\"salilab.org\")</script><br></div>
<p>Note: this server is in beta, results might be bad!
<p>If you use this server, please cite<br>
Spill, Y. G., Kim, S. J., Schneidman-Duhovny, D., Russel, D.,
Webb, B., Sali, A. &amp; Nilges, M. (2014). <i>J. Synchrotron Rad.</i>
<b>21</b>, 203&ndash;208.\n";
}

sub make_dropdown {
    my ($self, $id, $title, $initially_visible, $text) = @_;
    my $style = "";
    if (!$initially_visible) {
      $style = " style=\"display:none\"";
    }
    return "<div class=\"dropdown_container\">\n" .
           "<a onclick=\"\$('#${id}').slideToggle('fast')\" " .
           "href=\"#\">$title</a>\n" .
           "<div class=\"dropdown\" id=\"${id}\"$style>\n" .
           $text . "\n</div></div>\n";
}

sub get_input_form {
  my $self = shift;
  my $q = $self->cgi;

  my $form = $q->h4("Required inputs");
  $form .= $self->get_required_inputs();

  #$form .= $q->h4("Advanced options");
  $form .=  $self->make_dropdown("advanced", 
              $q->h4("Advanced options"), 0,
              $self->get_advanced_options());
  	    
  #$form .= $q->h4("Expert options");
  $form .=  $self->make_dropdown("expert",
              $q->h4("Expert options"), 0,
              $self->get_expert_options());
  	    
  return #$q->h2({-align=>"center"}, "SAXS Merge ...") .
  $q->start_form({-name=>"saxsmerge_form", -method=>"post",
                  -action=>$self->submit_url}) .
  $form .
  $q->end_form;
}

sub get_index_page {
  my $self = shift;
  my $q = $self->cgi;

  my $input_form = get_input_form($self, $q);

  return "<div id=\"fullpart\">$input_form</div>\n";

}

sub get_submit_page {
    my $self = shift;
    my $q = $self->cgi;

    my $email = $q->param('jobemail') || undef;

    check_optional_email($email);

    #create job directory time_stamp
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    my $time_stamp = $sec."_".$min."_".$hour."_".$mday."_".$mon."_".$year;
    my $job = $self->make_job($time_stamp);
    my $jobdir = $job->directory;

    my $data_file_name = $jobdir . "/input.txt";
    open(DATAFILE, "> $data_file_name")
      or throw saliweb::frontend::InternalError("Cannot open $data_file_name: $!");

    #handle input profiles
    my $records = $q->param("recordings");
    if (not (looks_like_number($records) and $records >1))
    {
        throw saliweb::frontend::InputValidationError(
            "The number of times each profile has been recorded must be at least 2!");
    }
    my @uplfiles = $q->upload("uploaded_file");
    my $upl_num = 0;
    foreach my $upl (@uplfiles) {      
	if (defined $upl) {
	    if(length $upl > 40) { 
		throw saliweb::frontend::InputValidationError(
                        "Please limit the file name length to a maximum of 40 characters");
	    }
            if($upl =~ /(zip|tar|gz|bz2|rar)$/){
		throw saliweb::frontend::InputValidationError(
                        "Please provide plain text files with three columns (q,I,err)");
            }
            my $buffer;
            my $filename = sanitize_filename($upl);
            # Make sure it doesn't contain = either since that will confuse
            # parsing of the datafile
            $filename =~ s/=//g;
            my $fullpath = $job->directory . "/" . $filename;
            open(OUTFILE, '>', $fullpath)
                or throw saliweb::frontend::InternalError("Cannot open $fullpath: $!");
            while (<$upl>) {
                print OUTFILE $_;
            }
            close OUTFILE;
            print DATAFILE "$filename=$records\n";
            #system("echo $upl >>$list");

            $upl_num++;
	}
    }
    if ($upl_num == 0) {throw saliweb::frontend::InputValidationError(
                        "Please input at least one file!");}

    #advanced options
    #general
    if ($q->param("gen_auto")) {print DATAFILE "--auto\n";}
    if ($q->param("gen_header")) {print DATAFILE "--header\n";}
    if ($q->param("gen_noisy")) {print DATAFILE "--remove_noisy\n";}
    if ($q->param("gen_redundant")) {print DATAFILE "--remove_redundant\n";}
    if ($q->param("gen_input")) {print DATAFILE "--allfiles\n";}
    my $mult=1;
    if ($q->param("gen_unit") =~ /Nanometer/) {
        $mult=10;
        my $unitfile = $jobdir."/is_nm";
        open(UNITFILE, "> $unitfile")
            or throw saliweb::frontend::InternalError("Cannot open $unitfile: $!");
        print UNITFILE "nm";
        close(UNITFILE);
    }
    print DATAFILE "--outlevel=".$q->param("gen_output")."\n";
    print DATAFILE "--stop=".$q->param("gen_stop")."\n";

    #cleanup
    if (looks_like_number($q->param("clean_alpha")))
        { print DATAFILE "--aalpha=".$q->param("clean_alpha")."\n"; }

    #fitting
    print DATAFILE "--bmean=".$q->param("fit_param")."\n";
    if (not $q->param("fit_comp")) {print DATAFILE "--bnocomp\n";}
    if ($q->param("fit_bars")) {print DATAFILE "--berror\n";}

    #rescaling
    print DATAFILE "--cmodel=".$q->param("res_model")."\n";

    #classification
    if (looks_like_number($q->param("class_alpha")))
    { 
        print DATAFILE "--dalpha=".$q->param("class_alpha")."\n";
    } else {
        throw saliweb::frontend::InputValidationError(
            "Advanced: classification: alpha is invalid number");
    }


    #merging
    print DATAFILE "--emean=".$q->param("merge_param")."\n";
    if (not $q->param("merge_comp"))
        {print DATAFILE "--enocomp\n";}
    if ($q->param("merge_bars")) {print DATAFILE "--eerror\n";}
    if ($q->param("merge_noextrapol"))
        {print DATAFILE "--enoextrapolate\n";}


    #expert options
    #general
    if ($q->param("gen_npoints_input"))
    {
        print DATAFILE "--npoints=-1\n";
    } else {
        my $qnum = $q->param("gen_npoints_val");
        if (not (looks_like_number($qnum) and $qnum >0))
        {
            throw saliweb::frontend::InputValidationError(
                "Expert: general: q values not a positive number");
        }
        print DATAFILE "--npoints=$qnum\n";
    }
    if ($q->param("gen_postpone")) {print DATAFILE "--postpone_cleanup\n";}
    #cleanup
    my $qcut = $q->param("clean_cut");
    if ( not (looks_like_number($qcut) and $qcut>0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: cleanup: q cutoff is invalid positive float");
    }
    $qcut = $qcut*$mult;
    print DATAFILE "--acutoff=$qcut\n";
    #fitting
    if ($q->param("fit_avg")) {print DATAFILE "--baverage\n";}
    #rescaling
    print DATAFILE "--creference=".$q->param("res_ref")."\n";
    my $ngamma = $q->param("res_npoints");
    if ( not (looks_like_number($ngamma) and $ngamma>0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: rescaling: number of gamma points must be >0");
    }
    print DATAFILE "--cnpoints=$ngamma\n";
    #merging
    if ($q->param("merge_avg")) {print DATAFILE "--eaverage\n";}
    my $nextrapol = $q->param("merge_extrapol");
    if ( not (looks_like_number($nextrapol) and $nextrapol>=0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: merging: percentage must be positive");
    }
    print DATAFILE "--eextrapolate=$nextrapol\n";

    close(DATAFILE);

    if (defined $email) {
        $job->submit($email);
    } else {
        $job->submit();
    }

    # Inform the user of the job name and results URL
    my $retval = $q->p("Your job has been submitted with job ID ".$job->name);
    $retval .= $q->p("Results will be found at <a href=\""
                        . $job->results_url . "\">this link</a>.");
    if ($email) {
        $retval .= $q->p("You will be notified at $email when job results " .
                         "are available.");
    }
    return $retval;
}

sub get_results_page {
  my ($self, $job) = @_;
  my $q = $self->cgi;

  my $return = "";
  my $jobname = $job->name;
  my $joburl = $job->results_url;
  my $passwd = $q->param('passwd');

  if (not(-f 'summary.txt')) {
    $return .= $q->p("No output file was produced. Please inspect the log file 
to determine the problem.");
    $return .= $q->p("<a href=\"" . 
	$job->get_results_file_url('saxsmerge.log') .  
	"\">View SAXS Merge log file</a>.");
    return $return;
  }

  #output files
  $return .= $q->h4("Output Files");
  $return .= "<table><tr>";
  if (-f 'data_merged.dat'){
      $return .= $q->td($q->a({-href=>$job->get_results_file_url('data_merged.dat')},
                     "Merged data"));
      $return .= $q->td($q->a({-href=>$job->get_results_file_url('data_merged_3col.dat')},
                     "Merged data (standardized)"));
  }
  if (-f 'mean_merged.dat'){
      $return .= $q->td($q->a({-href=>$job->get_results_file_url('mean_merged.dat')},
                     "Merged mean"));
      $return .= $q->td($q->a({-href=>$job->get_results_file_url('mean_merged_3col.dat')},
                     "Merged mean (standardized)"));
  }
  $return .= $q->td($q->a({-href=>$job->get_results_file_url('summary.txt')},
                     "Summary file"));
  $return .= $q->td($q->a({-href=>$job->get_results_file_url('saxsmerge.zip')},
                     "All files"));
  $return .= "</tr></table>\n";

  #merge stats
  $return .=  $self->make_dropdown("mergestatsdd",
              $q->h4("Merge Statistics"), 0,
              $self->get_merge_stats('summary.txt'));

  $return .= setupCanvas();
  if (-f 'mergeplots.js')
  {
      #gnuplots
      my $mergeplotsrc=$job->get_results_file_url('mergeplots.js');
      $return .=  $self->make_dropdown("mergeplotsdd",
                  $q->h4("Merge Plots"), 1,
                  $self->get_merge_plots($mergeplotsrc));
  }

  if (-f 'mergeinplots.js')
  {
      my $mergeplotsrc=$job->get_results_file_url('mergeinplots.js');
      $return .=  $self->make_dropdown("mergeinplotsdd",
                  $q->h4("Input Colored Merge Plots"), 0,
                  $self->get_merge_color_plots($mergeplotsrc));
  }
  
  if (-f 'inputplots.js')
  {
      my $inplotsrc=$job->get_results_file_url('inputplots.js');
      $return .=  $self->make_dropdown("inputplotsdd",
                  $q->h4("Input Plots"), 0,
                  $self->get_input_plots($inplotsrc));
  }
  return $return;
}

sub get_merge_stats {
    my ($self, $sumname) = @_;
    my $q = $self->cgi;
    #parse summary.txt file's merge section
    open(FILE, $sumname) or die;
    while (<FILE>) { last if ( /^Merge file/ );}
    my $return = "<table border='1'>\n";
    my @particles= ("A","G","Rg","d","s","sigma","tau","lambda");
    $return .= "<tr>\n" .
        $q->th(["order","filename","num points (%)",
            "mean function"]);
    foreach (@particles){
        $return .= $q->th($_);
    }
    while (<FILE>) { last if /Number of points:/; }
    /Number of points: (\d+)/;
    my $nmergepoints = $1;
    <FILE>; #drop next line
    #get input filenames
    my @mergefiles;
    my @mergefpoints;
    while (<FILE>) {
        last if /Gaussian Process parameters/;
        /(\d+) points from profile \d+ \((.+)\)/;
        push(@mergefpoints, $1);
        push(@mergefiles, $2);
    }
    #get merge mean parameters
    <FILE> =~ /mean function : (\w+)/;
    my $mergemean = $1;
    my %mergevals;
    my %mergeerrs;
    while (<FILE>){
        last if /Calculated Values/;
        /(\w+) : (.+) \+- (.+)$/;
        my $key = $1;
        my $val = $2;
        my $err = $3;
        if ($key =~ /sigma2/){
            $key="sigma";
            $val=sqrt($val);
            if ($err !~ /nan/){
                $err = sqrt($err);
            }
        }
        $mergevals{$key} = $val;
        $mergeerrs{$key} = $err;
    }
    #print merge mean parameters
    $return .= "<tr>\n";
    foreach ("merge","*_merged.dat", $nmergepoints. " (100%)", $mergemean){
        $return .= "<td><b>" . $_ . "</b></td>\n";
    }
    foreach (@particles){
        $return .= "<td><b>";
        if (defined($mergevals{$_})){
            my $val = $mergevals{$_};
            my $err = $mergeerrs{$_};
            $return .= sprintf("%.3f", $val);
            if ($err !~ /nan/ and $err < $val/10.){
                $return .= " +-&nbsp;" . sprintf("%.3f", $err);
            }
        }
        $return .= "</b></td>\n";
    }
    $return .= "</tr>\n";

    #get input mean parameters
    my $filenum=0;
    while (<FILE>){
        $filenum++;
        #skip to next input
        while (<FILE>) {last if /mean function :/;}
        /mean function : (\w+)/;
        my $inpmean = $1;
        my %inpvals;
        my %inperrs;
        while (<FILE>){
            last if /Calculated Values/;
            /(\w+) : (.+) \+- (.+)$/;
            my $key = $1;
            my $val = $2;
            my $err = $3;
            if ($key =~ /sigma2/){
                $key="sigma";
                $val=sqrt($val);
                if ($err !~ /nan/){
                    $err = sqrt($err);
                }
            }
            $inpvals{$key} = $val;
            $inperrs{$key} = $err;
        }
        last if not (<FILE>);
        #print inp mean parameters
        $return .= "<tr>\n";
        $return .= $q->td([$filenum,$mergefiles[$filenum-1],
            $mergefpoints[$filenum-1] . " ("
                    . sprintf("%.1f",100*$mergefpoints[$filenum-1]/$nmergepoints)
                    . "%)", $inpmean]);
        foreach (@particles){
            $return .= "<td>";
            if (defined($inpvals{$_})){
                my $val = $inpvals{$_};
                my $err = $inperrs{$_};
                $return .= sprintf("%.3f", $val);
                if ($err !~ /nan/ and $err < $val/10.){
                    $return .= " +-&nbsp;" . sprintf("%.3f", $err);
                }
            }
            $return .= "</td>\n";
        }
        $return .= "</tr>\n";
    }

    $return .= "\n</table>\n";
    return $return;
}

sub get_required_inputs {
      my $self = shift;
      my $q = $self->cgi;
      return $q->table(
                $q->Tr( $q->td("Email (optional)"),
                        $q->td($q->textfield({-name=>"jobemail",
                                              -value=>$self->email,
                                              -size=>"25"}))
                       ),
                $q->Tr($q->td("Number of times each profile has been recorded")
                       ,$q->td($q->textfield({name=>'recordings',value=>10,
                                              maxlength=>3,size=>"1"}))
                      ),
                $q->tbody({id=>'profiles'}, 
                  $q->Tr( $q->td("Upload SAXS profile "),
                        $q->td($q->filefield({-name=>'uploaded_file'})),
                        $q->td($q->a({-href=>'html/example/example_input.zip'},
                                'Example input'))
                       )),
                  $q->Tr($q->td($q->button(-value=>'Add more profiles',
                                       -onClick=>"add_profile()"))),
                  $q->Tr( $q->td([
                      'Automatically determine profile order'
                      ,$q->checkbox(-label=>"", -checked=>1,
                                  -name=>"gen_auto")
                      ])),
                  $q->Tr( $q->td([
                      'Output data for parsed input files as well'
                      ,$q->checkbox(-label=>"",
                                  -name=>"gen_input")
                      ])),
                  $q->Tr( $q->td([
                        'Momentum transfer values are per'
                      ,$q->radio_group('gen_unit', ['Angstrom','Nanometer'],
                                      'Angstrom','false')
                      ])),
                  $q->Tr( $q->td($q->input({-type=>"submit", -value=>"Submit"})),
                        $q->td($q->input({-type=>"reset",
                                          -value=>"Reset to defaults"}))
                       )
                   );
}

sub get_advanced_options {
    my $self = shift;
    my $q = $self->cgi;
    my $return = $q->table(
        $q->tbody($q->Tr([
            $q->th("General")
            ,$q->td([
                'First line of output files is a header'
                ,$q->checkbox(-name=>"gen_header",
                              -label=>"")
                ])
            ,$q->td([
                'Remove points with too large error bars'
                ,$q->checkbox(-name=>"gen_noisy", -checked=>1,
                              -label=>"")
                ])
            ,$q->td([
                'Remove high noise data if it is redundant'
                ,$q->checkbox(-name=>"gen_redundant", -checked=>1,
                              -label=>"")
                ])
            ,$q->td([
                'Output level'
                ,$q->popup_menu(-name=>"gen_output",
                                -Values=>['sparse','normal','full'],
                                -default=>'normal',
                                -onChange=>"gen_output_context(this);"),
                ,$q->p({id=>"gen_output_text"})
                ])
            ,$q->td([
                'Stop after step'
                ,$q->popup_menu(-name=>"gen_stop",
                                -Values=>['cleanup','fitting','rescaling','classification','merging'],
                                -default=>'merging'),
                ])
            ]))
        #cleanup
        ,$q->tbody($q->Tr([
            $q->th("Cleanup (Step 1)")
            ,$q->td([
                'Type I error (before Bonferroni correction)'
                ,$q->textfield({name=>'clean_alpha',value=>0.05,
                               size=>"5"})
                ])
            ]))
        #fitting
        ,$q->tbody($q->Tr([
            $q->th("Fitting (Step 2)")
            ,$q->td([
                'Parameter set'
                ,$q->popup_menu(-name=>"fit_param",
                                -Values=>['Flat','Simple','Generalized','Full'],
                                -default=>'Full',
                                -onChange=>"fit_param_context(this);"),
                ,$q->p({id=>"fit_param_text"})
                ])
            ,$q->td([
                'Model comparison'
                ,$q->checkbox(-label=>"",
                            -checked=>1,
                            -name=>"fit_comp")
                ])
            ,$q->td([
                'Always compute error bars'
                ,$q->checkbox(-label=>"",
                            -name=>"fit_bars")
                ])
            ]))
        #rescaling
        ,$q->tbody($q->Tr([
            $q->th("Rescaling (Step 3)")
            ,$q->td([
                'Model'
                ,$q->popup_menu(-name=>"res_model",
                                -Values=>['normal','normal-offset','lognormal'],
                                -default=>'normal'),
                ])
            ]))
        #classification
        ,$q->tbody($q->Tr([
            $q->th("Classification (Step 4)")
            ,$q->td([
                'Type I error'
                ,$q->textfield({name=>'class_alpha',value=>0.05,
                               size=>"5"})
                ])
            ]))
        #merging
        ,$q->tbody($q->Tr([
            $q->th("Merging (Step 5)")
            ,$q->td([
                'Parameter set'
                ,$q->popup_menu(-name=>"merge_param",
                                -Values=>['Flat','Simple','Generalized','Full'],
                                -default=>'Full',
                                -onChange=>"merge_param_context(this);"),
                ,$q->p({id=>"merge_param_text"})
                ])
            ,$q->td([
                'Model comparison'
                ,$q->checkbox(-label=>"",
                            -checked=>1,
                            -name=>"merge_comp")
                ])
            ,$q->td([
                'Always compute error bars'
                ,$q->checkbox(-label=>"",
                            -name=>"merge_bars")
                ])
            ,$q->td([
                "Don't extrapolate at all, even at low angle"
                ,$q->checkbox(-label=>"",
                            -name=>"merge_noextrapol")
                ])
            ]))
        );

    return $return;
}

sub get_expert_options {
    my $self = shift;
    my $q = $self->cgi;
    my $return = $q->table(
        $q->tbody($q->Tr([
            $q->th("General")
            ,$q->td([
                'Take q values from first input file',
                ,$q->checkbox(-label=>"",
                            -name=>"gen_npoints_input",
-onchange=>"document.getElementById('gen_npoints_val').disabled=this.checked;")
                ])
            ,$q->td([
                'Number of evenly spaced q values to return for the mean',
                ,$q->textfield({name=>'gen_npoints_val', id=>'gen_npoints_val',
                        value=>200, size=>"5"})
                ])
            ,$q->td([
                'Cleanup step comes after rescaling step'
                ,$q->checkbox(-label=>"",
                            -name=>"gen_postpone")
                ])
            ]))
        #cleanup
        ,$q->tbody($q->Tr([
            $q->th("Cleanup (Step 1)")
            ,$q->td([
                'Start discarding curve after qcut= (per Angstrom)'
                ,$q->textfield({name=>'clean_cut',value=>0.1,
                               size=>"5", id=>"clean_cut"})
                ])
            ]))
        #fitting
        ,$q->tbody($q->Tr([
            $q->th("Fitting (Step 2)")
            ,$q->td([
                'Average over parameters instead of taking most probable set'
                ,$q->checkbox(-label=>"",
                            -name=>"fit_avg")
                ])
            ]))
        #Rescaling
        ,$q->tbody($q->Tr([
            $q->th("Rescaling (Step 3)")
            ,$q->td([
                'Which input curve to rescale the others to'
                ,$q->popup_menu(-name=>"res_ref",
                                -Values=>['first','last'],
                                -default=>'last')
                ])
            ,$q->td([
                'Number of points to use to compute gamma'
                ,$q->textfield({name=>'res_npoints',value=>200,
                               size=>"5"})
                ])
            ]))
        #Merging
        ,$q->tbody($q->Tr([
            $q->th("Merging (Step 5)")
            ,$q->td([
                'Average over parameters instead of taking most probable set'
                ,$q->checkbox(-label=>"",
                            -name=>"merge_avg")
                ])
            ,$q->td([
                "Extrapolate NUM percent outside of the curve's bounds"
                ,$q->textfield({name=>'merge_extrapol',value=>0,
                               size=>"5"})
                ])
            ]))
    );

    return $return;
}

sub setupCanvas {
return "<script src=\"/foxs/gnuplot_js/canvastext.js\"></script>
<script src=\"/foxs/gnuplot_js/gnuplot_common.js\"></script>
<script src=\"/foxs/gnuplot_js/gnuplot_dashedlines.js\"></script>
<script src=\"/foxs/gnuplot_js/gnuplot_mouse.js\"></script>
<script type=\"text/javascript\">
var canvas, ctx;
gnuplot.grid_lines = true;
gnuplot.zoomed = false;
gnuplot.active_plot_name = \"gnuplot_canvas\";
gnuplot.active_plot = gnuplot.dummyplot;
gnuplot.dummyplot = function() {};
function gnuplot_canvas( plot ) { gnuplot.active_plot(); };
</script>\n";
}

sub get_merge_plots {
  my $self = shift;
  my $mergeplotsrc=shift;
  my $q = $self->cgi;

  my $return = $q->script({-src=>$mergeplotsrc},"");
  #. "<table align='center'><tr><td><div  id=\"wrapper\">

  $return .= $q->table(
      $q->Tr({align=>'LEFT', valign=>'TOP'},
          [$q->th(["Log scale", "Linear scale"]),
          $q->td([drawCanvasMerge($q,1), drawCanvasMerge($q,2)]),
          $q->th(["Guinier plot", "Kratky plot"]),
          $q->td([drawCanvasMerge($q,3), drawCanvasMerge($q,4)])]
  )
  );

  return $return;
}

sub drawCanvasMerge {
    my $q = shift;
    my $num = shift;
    my $return="";
    #canvas
    $return .= "
        <canvas id='mergeplots_$num' width=400 height=350 tabindex='0' oncontextmenu='return false;'>
            <div class='box'><h2>Your browser does not support the HTML 5 canvas element</h2></div>
        </canvas>";
    #buttons
    $return .= $q->table($q->Tr($q->td(
           [
             $q->input({type=>'button', id=>'minus_m_'.$num, value=>'reset',
                        onclick=>'gnuplot.unzoom();'}),
             $q->checkbox(-id=>"data_m_".$num, -label=>"data", -checked=>1,
                          -name=>"data_m_".$num,
                          -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_1');"),
             $q->checkbox(-id=>"derr_m_".$num, -label=>"data error", -checked=>1,
                          -name=>"derr_m_".$num,
                          -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_2');"),
             $q->checkbox(-id=>"mean_m_".$num, -label=>"mean", -checked=>1,
                          -name=>"mean_m_".$num,
                          -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_3');"),
             $q->checkbox(-id=>"SD_m_".$num, -label=>"SD", -checked=>1,
                          -name=>"SD_m_".$num,
                          -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_4');
                                     gnuplot.toggle_plot('mergeplots_"."$num"."_plot_5');")
           ])));
    $return .=
    $q->script("window.addEventListener('load', mergeplots_$num, false);");
    return $return;
}


sub get_input_plots {
  my $self = shift;
  my $inputsplotsrc=shift;
  my $q = $self->cgi;

  my $return = $q->script({-src=>$inputsplotsrc},"");
  #. "<table align='center'><tr><td><div  id=\"wrapper\">

  $return .= $q->table(
      $q->Tr({align=>'LEFT', valign=>'TOP'},
          [$q->th(["Log scale", "Linear scale"]),
          $q->td([drawCanvasInputs($q,1), drawCanvasInputs($q,2)]),
          $q->th(["Guinier plot", "Kratky plot"]),
          $q->td([drawCanvasInputs($q,3), drawCanvasInputs($q,4)])]
  )
  );

  return $return;
}

sub drawCanvasInputs {
    my $q = shift;
    my $num = shift;
    my $return="";
    #canvas
    $return .= "
        <canvas id='inputplots_$num' width=400 height=350 tabindex='0' oncontextmenu='return false;'>
            <div class='box'><h2>Your browser does not support the HTML 5 canvas element</h2></div>
        </canvas>";
    #buttons
    $return .= $q->table($q->Tr($q->td(
           [
             $q->input({type=>'button', id=>'minus_i_'.$num, value=>'reset',
                        onclick=>'gnuplot.unzoom();'})])));
    $return .= "\n<table>\n";
    $return .= $q->Tr($q->td(["input file","data","error","mean","SD"]));
    open(FILE, 'input.txt');
    my $nfiles=0;
    while(<FILE>) {
        $nfiles++; 
        /(.+)=\d+/;
        $return .= $q->Tr($q->td(
             [$1,
             $q->checkbox(-id=>"data".$nfiles."_".$num, -label=>"", -checked=>1,
                          -name=>"data".$nfiles."_".$num,
                          -onclick=>"gnuplot.toggle_plot('inputplots_"."$num"."_plot_".(5*$nfiles-4)."');"),
             $q->checkbox(-id=>"derr".$nfiles."_".$num, -label=>"", -checked=>1,
                          -name=>"derr".$nfiles."_".$num,
                          -onclick=>"gnuplot.toggle_plot('inputplots_"."$num"."_plot_".(5*$nfiles-3)."');"),
             $q->checkbox(-id=>"mean".$nfiles."_".$num, -label=>"", -checked=>1,
                          -name=>"mean".$nfiles."_".$num,
                          -onclick=>"gnuplot.toggle_plot('inputplots_"."$num"."_plot_".(5*$nfiles-2)."');"),
             $q->checkbox(-id=>"SD".$nfiles."_".$num, -label=>"", -checked=>1,
                          -name=>"SD".$nfiles."_".$num,
                          -onclick=>"gnuplot.toggle_plot('inputplots_"."$num"."_plot_".(5*$nfiles-1)."');
                                       gnuplot.toggle_plot('inputplots_"."$num"."_plot_".(5*$nfiles)."');")
            ]));
        last if (/^--.+/);
    }
    $return .= "\n</table>\n";
    $return .= $q->script("window.addEventListener('load', inputplots_$num, false);");
    return $return;
}


sub get_merge_color_plots()
{
  my $self = shift;
  my $mergeplotsrc=shift;
  my $q = $self->cgi;

  my $return = $q->script({-src=>$mergeplotsrc},"");
  #. "<table align='center'><tr><td><div  id=\"wrapper\">

  $return .= $q->table(
      $q->Tr({align=>'LEFT', valign=>'TOP'},
          [$q->th(["Log scale", "Linear scale"]),
          $q->td([drawCanvasMergeColor($q,1), drawCanvasMergeColor($q,2)])]
  )
  );

  return $return;
}

sub drawCanvasMergeColor {
    my $q = shift;
    my $num = shift;
    my $return="";
    #canvas
    $return .= "
        <canvas id='mergeinplots_$num' width=400 height=350 tabindex='0' oncontextmenu='return false;'>
            <div class='box'><h2>Your browser does not support the HTML 5 canvas element</h2></div>
        </canvas>";
    #buttons
    $return .= $q->table($q->Tr($q->td(
             $q->input({type=>'button', id=>'minus_mi_'.$num, value=>'reset',
                        onclick=>'gnuplot.unzoom();'}))));
    $return .=
    $q->script("window.addEventListener('load', mergeinplots_$num, false);");
    return $return;
}

sub google_tracker() {
return "
  var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-39277378-1']);
      _gaq.push(['_trackPageview']);

(function() {
var ga = document.createElement('script'); ga.type =
'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ?
        'https://ssl' : 'http://www') +
    '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(ga, s);
  })(); ";
}

1;
