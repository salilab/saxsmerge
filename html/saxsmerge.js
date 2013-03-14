function add_profile() {
  
  var row = '<tr>' +
            '<td> upload SAXS profile </td>' +
            '<td><input type="file" name="uploaded_file"  /></td>' +
            '</tr>'
  $(row).appendTo("#profiles");
}

function gen_output_context(sel)
{
    var text;
    switch (sel.options[sel.selectedIndex].text)
    {
      case 'sparse':
        text="only output q,I,err columns"
        break;
      case 'normal':
        text="output q,I,err,eorigin,eoriname,eextrapol columns"
        break;
      case 'full':
        text="output all flags"
        break;
    }
    document.getElementById('gen_output_text').innerHTML=text;
}

function fit_param_context(sel)
{
    var text;
    switch (sel.options[sel.selectedIndex].text)
    {
      case 'Flat':
        text="only optimize offset A"
        break;
      case 'Simple':
        text="Optimize A, G and Rg"
        break;
      case 'Generalized':
        text="Optimize A, G, Rg and d"
        break;
      case 'Full':
        text="Optimize A, G, Rg, d and s"
        break;
    }
    document.getElementById('fit_param_text').innerHTML=text;
}

function merge_param_context(sel)
{
    var text;
    switch (sel.options[sel.selectedIndex].text)
    {
      case 'Flat':
        text="only optimize offset A"
        break;
      case 'Simple':
        text="Optimize A, G and Rg"
        break;
      case 'Generalized':
        text="Optimize A, G, Rg and d"
        break;
      case 'Full':
        text="Optimize A, G, Rg, d and s"
        break;
    }
    document.getElementById('merge_param_text').innerHTML=text;
}

function google_tracker()
{
  document.getElementById('outfiles').innerHTML="google tracker";
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-39277378-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type =
    'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl'
      : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(ga, s);
  })();
}

