package saxsmerge;
use base qw(saliweb::frontend);
use strict;

# Add our own JavaScript and CSS to the page header
sub get_start_html_parameters {
  my ($self, $style) = @_;
  my %param = $self->SUPER::get_start_html_parameters($style);
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => 'html/jquery-1.8.1.min.js' };
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => 'html/saxsmerge.js' };
  #push @{$param{-style}->{'-src'}}, 'html/saxsmerge.css';
  return %param;
}



sub _display_content {
  my ($self, $content) = @_;
  print $content;
}

sub _display_web_page {
  my ($self, $content) = @_;
  # Call all prefix and suffix methods before printing anything, in case one
  # of them raises an error
  my $prefix = $self->start_html() . "<div id='container'>" . $self->get_header();
  my $suffix = $self->get_footer() . "</div>\n" . $self->end_html;
  my $navigation = $self->get_navigation_lab();
  print $prefix;
  print $navigation;
  $self->_display_content($content);
  print $suffix;
}

sub get_help_page {
  my ($self, $display_type) = @_;
  my $file;
  if ($display_type eq "contact") {
    $file = "contact.txt";
  } elsif ($display_type eq "news") {
    $file = "news.txt";
  } elsif ($display_type eq "about") {
    $file = "about.txt";
  } elsif ($display_type eq "FAQ") {
    $file = "FAQ.txt";
  } elsif ($display_type eq "links") {
    $file = "links.txt";
  } elsif ($display_type eq "download") {
    $file = "download.txt";
  } else {
    $file = "help.txt";
  }
  return $self->google_tracker() . $self->get_text_file($file);
}

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

sub get_navigation_lab {
  return "<div id=\"navigation_lab\">
      &bull;&nbsp; <a href=\"http://modbase.compbio.ucsf.edu/saxsmerge/help.cgi?type=about\">About SAXS Merge</a>&nbsp;
      &bull;&nbsp; <a href=\"http://salilab.org/saxsmerge\">Web Server</a>&nbsp;
      &bull;&nbsp; <a href=\"http://modbase.compbio.ucsf.edu/saxsmerge/help.cgi?type=help\">Help</a>&nbsp;
      &bull;&nbsp; <a href=\"http://modbase.compbio.ucsf.edu/saxsmerge/help.cgi?type=FAQ\">FAQ</a>&nbsp;
      &bull;&nbsp; <a href=\"http://modbase.compbio.ucsf.edu/saxsmerge/help.cgi?type=download\">Download</a>&nbsp;
      &bull;&nbsp; <a href=\"http://salilab.org/foxs\">FoXS</a>&nbsp;
      &bull;&nbsp; <a href=\"http://www.pasteur.fr\">Institut Pasteur</a>&nbsp;
      &bull;&nbsp; <a href=\"http://salilab.org\">Sali Lab</a>&nbsp;
      &bull;&nbsp; <a href=\"http://salilab.org/imp\">IMP</a>&nbsp;
      &bull;&nbsp; <a href=\"http://modbase.compbio.ucsf.edu/saxsmerge/help.cgi?type=links\">Links</a>&nbsp;</div>\n";
}


sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "SAXS Merge Home"),
        $q->a({-href=>$self->queue_url}, "SAXS Merge Current queue"),
        $q->a({-href=>$self->help_url}, "SAXS Merge Help"),
        $q->a({-href=>$self->contact_url}, "SAXS Merge Contact")
        ];
}

sub get_project_menu {
  # no menu
  return "";
}

sub get_header {
  return "<div id='header1'>
  <table> <tbody> <tr> <td halign='left'>
  <table><tr><td><img src=\"http://salilab.org/saxsmerge/logo.png\" align = 'right' height = '80'></td></tr>
         <tr><td><h1>SAXS Merge</h1> </td></tr></table>
      </td> <td halign='right'><img src=\"http://salilab.org/saxsmerge/logo2.gif\" height = '80'></td></tr>
  </tbody>
  </table></div>\n";
}


sub get_footer {
  return "<hr size='2' width=\"80%\"><div id='address'>
<p> <p>Contact: <script>escramble(\"yannick.spill\",\"pasteur.fr\")</script><br></div>\n";
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
sub check_required_email {
    my ($email) = @_;
    if($email !~ m/^[\w\.-]+@[\w-]+\.[\w-]+((\.[\w-]+)*)?$/ ) {
	throw saliweb::frontend::InputValidationError("Please provide a valid return email address");
    }
}


sub get_input_form {
  my $self = shift;
  my $q = $self->cgi;

  my $form = $q->h4("Required inputs");
  $form .= $q->table(
                $q->Tr( $q->td("Email (Required)"),
                        $q->td($q->textfield({-name=>"jobemail",
                                              -value=>$self->email,
                                              -size=>"25"}))
                       ),
                $q->Tr($q->td("Number of times each profile has been recorded")
                       ,$q->td($q->textfield({name=>'recordings',value=>10,
                                              maxlength=>3,size=>"1"}))
                      ),
                $q->tbody({id=>'profiles'}, 
                  $q->Tr( $q->td("upload SAXS profile "),
                        $q->td($q->filefield({-name=>'uploaded_file'}))
                       )),
                  $q->Tr($q->td($q->button(-value=>'Add more profiles',
                                       -onClick=>"add_profile()"))),
                  $q->Tr( $q->td($q->input({-type=>"submit", -value=>"Submit"})),
                        $q->td($q->input({-type=>"reset",
                                          -value=>"Reset to defaults"}))
                       )
                   );

  $form .= $q->h4("Advanced options");
  $form .= $self->get_advanced_options();
  	    
  $form .= $q->h4("Expert options");
  $form .= $self->get_expert_options();
  	    
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

  return $self->google_tracker() . "$input_form\n";

}

sub get_submit_page {
    my $self = shift;
    my $q = $self->cgi;

    my $email = $q->param('jobemail');

    check_required_email($email);

    #create job directory time_stamp
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    my $time_stamp = $sec."_".$min."_".$hour."_".$mday."_".$mon."_".$year;
    my $job = $self->make_job($time_stamp, $self->email);
    my $jobdir = $job->directory;

    my $data_file_name = $jobdir . "/input.txt";
    open(DATAFILE, "> $data_file_name")
      or throw saliweb::frontend::InternalError("Cannot open $data_file_name: $!");

    #handle input profiles
    my $records = $q->param("recordings");
    my @uplfiles = $q->upload("uploaded_file");
    my $upl_num = 0;
    foreach my $upl (@uplfiles) {      
	if (defined $upl) {
	    if(length $upl > 40) { 
		throw saliweb::frontend::InputValidationError(
                        "Please limit the file name length to a maximum of 40 characters");
	    }
        my $buffer;
        my $fullpath = $job->directory . "/" . $upl;
        open(OUTFILE, '>', $fullpath)
	    or throw saliweb::frontend::InternalError("Cannot open $fullpath: $!");
        while (<$upl>) {
	    print OUTFILE $_;
        }
        close OUTFILE;
	print DATAFILE "$upl=$records\n";
        #system("echo $upl >>$list");

        $upl_num++;
	}
    }
    if ($upl_num == 0) {throw saliweb::frontend::InputValidationError(
                        "Please input at least one file!");}

    use Scalar::Util qw/looks_like_number/;

    #advanced options
    #general
    if ($q->param("gen_header")) {print DATAFILE "--header\n";}
    if ($q->param("gen_input")) {print DATAFILE "--allfiles\n";}
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
    my $lambdamin = $q->param("gen_lambdamin");
    if ( not (looks_like_number($lambdamin) and $lambdamin>0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: general: lambda minimum is invalid positive float");
    }
    print DATAFILE "--lambdamin=$lambdamin\n";
    if ($q->param("gen_postpone")) {print DATAFILE "--postpone_cleanup\n";}
    #cleanup
    my $qcut = $q->param("clean_cut");
    if ( not (looks_like_number($qcut) and $qcut>0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: cleanup: q cutoff is invalid positive float");
    }
    print DATAFILE "--acutoff=$qcut\n";
    #fitting
    if ($q->param("fit_avg")) {print DATAFILE "--baverage\n";}
    my $dstart = $q->param("fit_d");
    if ( not (looks_like_number($dstart) and $dstart>=0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: fitting: d initial value is invalid positive float");
    }
    print DATAFILE "--bd=$dstart\n";
    my $sstart = $q->param("fit_s");
    if ( not (looks_like_number($sstart) and $sstart>=0.0))
    { 
        throw saliweb::frontend::InputValidationError(
            "Expert: fitting: s initial value is invalid positive float");
    }
    print DATAFILE "--bs=$sstart\n";
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

    $job->submit($email);

    my $line = $job->results_url . " " . $email;
    #`echo $line >> ../submit.log`;

    # Inform the user of the job name and results URL
    my $retval = $q->p("Your job has been submitted with job ID ".$job->name);
    #$retval .= $q->p("Results will be found at <a href=\""
    #                    . $job->results_url . "\">this link</a>.");
    $retval .= $q->p("You will receive an e-mail with results link "
                     ."once the job has finished");
    $retval .= $self->google_tracker();
    return $retval;
}

sub get_results_page {
  my ($self, $job) = @_;
  my $q = $self->cgi;

  my $return = $self->google_tracker();
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
  $return .= $q->h1("Results");
  $return .= $q->h2("Output files");
  $return .= $q->table(
              $q->Tr($q->td(
            [$q->a({-href=>$job->get_results_file_url('data_merged.dat')},
                     "Merged data"),
             $q->a({-href=>$job->get_results_file_url('mean_merged.dat')},
                     "Merged mean"),
             $q->a({-href=>$job->get_results_file_url('summary.txt')},
                     "Summary file")
            ])));

  $return .= setupCanvas();
  if (-f 'mergeplots.js')
  {
      #merge stats
      #$return .= $self->get_merge_stats($job->get_results_file_url('summary.txt'));
      #gnuplots
      my $mergeplotsrc=$job->get_results_file_url('mergeplots.js');
      $return .= $self->get_merge_plots($mergeplotsrc);
  }

  if (-f 'mergeinplots.js')
  {
      my $mergeplotsrc=$job->get_results_file_url('mergeinplots.js');
      $return .= $self->get_merge_color_plots($mergeplotsrc);
  }
  return $return;
}

sub get_merge_stats {
    my ($self, $sumname) = @_;
    my $q = $self->cgi;
    #parse summary.txt file's merge section
    open(FILE, $sumname);
    while (<FILE>) { last if ( /^Merge file$/ );}
    my $return = $q->h2("Merge statistics");
    $return .= $q->table();
    return $return;
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
                'Output data files for parsed input files as well'
                ,$q->checkbox(-label=>"",
                            -name=>"gen_input")
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
                'Type I error'
                ,$q->textfield({name=>'clean_alpha',value=>1e-4,
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

    return $self->make_dropdown("advanced", "Show/Hide", 0, $return);
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
                'Lower bound for lambda in steps 2 and 5'
                ,$q->textfield({name=>'gen_lambdamin',
                        value=>0.005, size=>"5"})
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
                'Start discarding curve after qcut='
                ,$q->textfield({name=>'clean_cut',value=>0.1,
                               size=>"5"})
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
            ,$q->td([
                'Initial value for d',
                ,$q->textfield({name=>'fit_d',value=>4.0,
                               size=>"5"})
                ])
            ,$q->td([
                'Initial value for s',
                ,$q->textfield({name=>'fit_s',value=>0.0,
                               size=>"5"})
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

    return $self->make_dropdown("expert", "Show/Hide", 0, $return);
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

sub get_merge_plots()
{
  my $self = shift;
  my $mergeplotsrc=shift;
  my $q = $self->cgi;

  my $return = $q->h2("Merge Plots");

  $return .= $q->script({-src=>$mergeplotsrc},"");
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
             $q->input({type=>'button', id=>'minus'.$num, value=>'reset',
                        onclick=>'gnuplot.unzoom();'}),
             $q->checkbox(-id=>"data".$num, -label=>"data", -checked=>1,
                            -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_1');"),
             $q->checkbox(-id=>"derr".$num, -label=>"data error", -checked=>1,
                            -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_2');"),
             $q->checkbox(-id=>"mean".$num, -label=>"mean", -checked=>1,
                            -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_3');"),
             $q->checkbox(-id=>"SD".$num, -label=>"SD", -checked=>1,
                          -onclick=>"gnuplot.toggle_plot('mergeplots_"."$num"."_plot_4');
                                     gnuplot.toggle_plot('mergeplots_"."$num"."_plot_5');")
           ])));
    $return .=
    $q->script("window.addEventListener('load', mergeplots_$num, false);");
    return $return;
}


sub get_merge_color_plots()
{
  my $self = shift;
  my $mergeplotsrc=shift;
  my $q = $self->cgi;

  my $return = $q->h2("Input colored Merge Plots");

  $return .= $q->script({-src=>$mergeplotsrc},"");
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
             $q->input({type=>'button', id=>'minus'.$num, value=>'reset',
                        onclick=>'gnuplot.unzoom();'}))));
    $return .=
    $q->script("window.addEventListener('load', mergeinplots_$num, false);");
    return $return;
}

sub google_tracker() {
return "<script type='text/javascript'>

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
  })();

</script>"
}

1;
