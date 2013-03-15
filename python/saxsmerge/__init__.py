import os
import saliweb.backend

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner

    def get_protection_args(self):
        args = ['--blimit_fitting=80', '--elimit_fitting=80',
                 '--blimit_hessian=80', '--elimit_hessian=80']
        return ' '.join(args)

    def get_input_args(self):
        args = [l.rstrip() for l in open('input.txt')]
        return ' '.join(args)

    def get_args(self):
        return self.get_input_args() + ' ' + self.get_protection_args()

    def complete(self):
        os.chmod(".", 0775)

    def run(self):
        args = self.get_args()
        post = self.gen_gnuplots()
        script="""
date
hostname

IMPPY="/netapp/sali/saxsmerge/imp/cmake-fast/setup_environment.sh"
SMERGE="/netapp/sali/saxsmerge/imp/src/applications/saxs_merge/saxs_merge.py"

#. /netapp/sali/yannick/.bashrc
#export PATH="/netapp/sali/yannick/bin:$PATH"
#export LD_LIBRARY_PATH="/netapp/sali/yannick/lib:$LD_LIBRARY_PATH"
#export CPPFLAGS="/netapp/sali/yannick/include:$CPPFLAGS"

$IMPPY $SMERGE %s

cat <<EOF > Cpgnuplot
%s
EOF
/netapp/sali/yannick/bin/gnuplot Cpgnuplot

zip -9 saxsmerge.zip data_* mean_* summary.txt

date
""" % (args,post)
        r = self.runnercls(script)
        r.set_sge_options('-l arch=linux-x64')
        return r
    
    def plot_log_scale(self,outfile):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data log-scale"\n'
        script += 'set log y\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'p "%s" u 1:2 w p lt 1 t "data", ' % datafile
        script += '"%s" u 1:2:3 w yerr lt 1 t "data", ' % datafile
        script += '"%s" u 1:2 w l lt 2 t "mean", ' % meanfile
        script += '"%s" u 1:(\$2+\$3) w l lt 3 t "+- SD", ' % meanfile
        script += '"%s" u 1:(\$2-\$3) w l lt 3 not\n' % meanfile
        return script

    def plot_lin_scale(self,outfile):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data linear scale"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "I(q)"\n'
        script += 'p "%s" u 1:2 w p lt 1 t "data", ' % datafile
        script += '"%s" u 1:2:3 w yerr lt 1 t "data", ' % datafile
        script += '"%s" u 1:2 w l lt 2 t "mean", ' % meanfile
        script += '"%s" u 1:(\$2+\$3) w l lt 3 t "+- SD", ' % meanfile
        script += '"%s" u 1:(\$2-\$3) w l lt 3 not\n' % meanfile
        return script

    def plot_guinier(self,outfile):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data Guinier plot"\n'
        script += 'set xlabel "q^2"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'set log y\n'
        script += 'p "%s" u (\$1**2):2 w p lt 1 t "data", ' % datafile
        script += '"%s" u (\$1**2):2:3 w yerr lt 1 t "data", ' % datafile
        script += '"%s" u (\$1**2):2 w l lt 2 t "mean", ' % meanfile
        script += '"%s" u (\$1**2):(\$2+\$3) w l lt 3 t "+- SD", ' % meanfile
        script += '"%s" u (\$1**2):(\$2-\$3) w l lt 3 not\n' % meanfile
        return script

    def plot_kratky(self,outfile):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data Kratky plot"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "q^2 I(q)"\n'
        script += 'p "%s" u 1:(\$1**2*\$2) w p lt 1 t "data", ' % datafile
        script += '"%s" u 1:(\$1**2*\$2):(\$1**2*\$3) w yerr lt 1 t "data", ' % datafile
        script += '"%s" u 1:(\$1**2*\$2) w l lt 2 t "mean", ' % meanfile
        script += '"%s" u 1:(\$1**2*(\$2+\$3)) w l lt 3 t "+- SD", ' % meanfile
        script += '"%s" u 1:(\$1**2*(\$2-\$3)) w l lt 3 not\n' % meanfile
        return script

    def plot_log_scale_colored(self,outfile):
        datafile = "data_merged.dat"
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data colored by inputs"\n'
        script += 'set log y\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'p "%s" u 1:2:(1+\$4) w p lc var t "data"\n' % datafile
        return script

    def plot_lin_scale_colored(self,outfile):
        datafile = "data_merged.dat"
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data colored by inputs"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "I(q)"\n'
        script += 'p "%s" u 1:2:(1+\$4) w p lc var t "data"\n' % datafile
        return script
    
    def plot_inputs_log_scale(self,outfile,infiles):
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files log-scale"\n'
        script += 'set log y\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'p '
        for i,fn in enumerate(infiles):
            datafile='data_'+fn
            meanfile='mean_'+fn
            if i>0:
                script += ',\\\n  '
            script += '"%s" u 1:(\$4==1?%d*\$2:1/0):(%d*\$3) w yerr lt %d t "%s", '\
                        % (datafile,10**i,10**i,i+1,fn)
            script += '"%s" u 1:(\$5==1?%d*\$2:1/0) w l lt %d not, ' \
                        % (meanfile,10**i,i+2)
            script += '"%s" u 1:(\$5==1?%d*(\$2+\$3):1/0) w l lt %d not, ' \
                        % (meanfile,10**i,i+3)
            script += '"%s" u 1:(\$5==1?%d*(\$2-\$3):1/0) w l lt %d not' \
                        % (meanfile,10**i,i+3)
        script += '\n'
        return script

    def plot_inputs_lin_scale(self,outfile,infiles):
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files log-scale"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'p '
        for i,fn in enumerate(infiles):
            datafile='data_'+fn
            meanfile='mean_'+fn
            if i>0:
                script += ',\\\n  '
            script += '"%s" u 1:(\$4==1?%d+\$2:1/0):3 w yerr lt %d t "%s", '\
                        % (datafile,i*30,i+1,fn)
            script += '"%s" u 1:(\$5==1?%d+\$2:1/0) w l lt %d not, ' \
                        % (meanfile,i*30,i+2)
            script += '"%s" u 1:(\$5==1?%d+(\$2+\$3):1/0) w l lt %d not, ' \
                        % (meanfile,i*30,i+3)
            script += '"%s" u 1:(\$5==1?%d+(\$2-\$3):1/0) w l lt %d not' \
                        % (meanfile,i*30,i+3)
        script += '\n'
        return script

    def plot_inputs_guinier(self,outfile,infiles):
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files Guinier plot"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'set log y\n'
        script += 'p '
        for i,fn in enumerate(infiles):
            datafile='data_'+fn
            meanfile='mean_'+fn
            if i>0:
                script += ',\\\n  '
            script += '"%s" u (\$1**2):(\$4==1?%d*\$2:1/0):(%d*\$3) w yerr lt %d t "%s", '\
                        % (datafile,10**i,10**i,i+1,fn)
            script += '"%s" u (\$1**2):(\$5==1?%d*\$2:1/0) w l lt %d not, ' \
                        % (meanfile,10**i,i+2)
            script += '"%s" u (\$1**2):(\$5==1?%d*(\$2+\$3):1/0) w l lt %d not, ' \
                        % (meanfile,10**i,i+3)
            script += '"%s" u (\$1**2):(\$5==1?%d*(\$2-\$3):1/0) w l lt %d not' \
                        % (meanfile,10**i,i+3)
        script += '\n'
        return script


    def plot_inputs_kratky(self,outfile,infiles):
        script="reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files Kratky plot"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "q^2 I(q)"\n'
        script += 'p '
        for i,fn in enumerate(infiles):
            datafile='data_'+fn
            meanfile='mean_'+fn
            if i>0:
                script += ',\\\n  '
            script += '"%s" u 1:(\$4==1?%f+\$2*\$1**2:1/0):(\$1**2*\$3) w yerr lt %d t "%s", '\
                        % (datafile,0.1*i,i+1,fn)
            script += '"%s" u 1:(\$5==1?%f+\$2*\$1**2:1/0) w l lt %d not, ' \
                        % (meanfile,0.1*i,i+2)
            script += '"%s" u 1:(\$5==1?%f+\$1**2*(\$2+\$3):1/0) w l lt %d not, ' \
                        % (meanfile,0.1*i,i+3)
            script += '"%s" u 1:(\$5==1?%f+\$1**2*(\$2-\$3):1/0) w l lt %d not' \
                        % (meanfile,0.1*i,i+3)
        script += '\n'
        return script

    def gen_gnuplots(self):
        script=""
        infile = open('input.txt').readlines()
        hasmerge = '--stop=merging\n' in infile
        haslongtable = not ('--outlevel=sparse\n' in infile)
        hasinputs = '--allfiles\n' in infile
        #merge-related plots
        if hasmerge:
            outfile = "mergeplots"
            script += 'set output "%s.js"\n' % outfile
            script += self.plot_log_scale(outfile+'_1')
            script += self.plot_lin_scale(outfile+'_2')
            script += self.plot_guinier(outfile+'_3')
            script += self.plot_kratky(outfile+'_4')
        #merge/input related plots
        if hasmerge and haslongtable:
            outfile = "mergeinplots"
            script += 'set output "%s.js"\n' % outfile
            script += self.plot_log_scale_colored(outfile+'_1')
            script += self.plot_lin_scale_colored(outfile+'_2')
        if hasinputs:
            infiles=[i[:i.rfind('=')] for i in infile if not i.startswith('--')]
            outfile = "inputplots"
            script += 'set output "%s.js"\n' % outfile
            script += self.plot_inputs_log_scale(outfile+'_1', infiles)
            script += self.plot_inputs_lin_scale(outfile+'_2',infiles)
            script += self.plot_inputs_guinier(outfile+'_3',infiles)
            script += self.plot_inputs_kratky(outfile+'_4',infiles)
        return script

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)


