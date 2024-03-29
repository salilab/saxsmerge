from __future__ import division
import os
import math
import saliweb.backend
import subprocess


# Exceptions
class LogError(Exception):
    pass


class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.WyntonSGERunner

    def get_protection_args(self):
        args = ['--blimit_fitting=240', '--elimit_fitting=240',
                '--blimit_hessian=80', '--elimit_hessian=80',
                '-v -v -v']
        return ' '.join(args)

    def get_input_args(self):
        with open('input.txt') as fh:
            args = [line.rstrip() for line in fh]
        return ' '.join(args)

    def get_args(self):
        return self.get_input_args() + ' ' + self.get_protection_args()

    def standardize(self, infile, outfile):
        with open(infile) as fh:
            data = [i.split()[:3] for i in fh.readlines()]
        with open(outfile, 'w') as fl:
            n = 0
            ntot = len(data)
            while n < ntot:
                i = 0
                chunk = []
                while n+i < ntot and data[n][0] == data[n+i][0]:
                    chunk.append(data[n+i])
                    i += 1
                n += i
                if len(chunk) == 1:
                    outline = tuple(chunk[0])
                else:
                    qval = chunk[0][0]
                    Is = [float(k[1]) for k in chunk]
                    ss = [float(k[2]) for k in chunk]
                    s2mean = len(ss)/sum([1/k**2 for k in ss])
                    Imean = s2mean/len(ss)*sum([k/l**2
                                               for (k, l) in zip(Is, ss)])
                    outline = (qval, '%-15.14G' % Imean,
                               '%-15.14G' % math.sqrt(s2mean))
                fl.write(' '.join(outline))
                fl.write('\n')

    def check_log_errors(self):
        """Check log file for common errors"""
        with open('saxsmerge.log') as fh:
            if 'ImportError' in fh.read():
                raise LogError("Error reported in saxsmerge.log")

    def postprocess(self):
        self.check_log_errors()
        if os.path.isfile('data_merged.dat'):
            self.standardize('data_merged.dat', 'data_merged_3col.dat')
        if os.path.isfile('mean_merged.dat'):
            self.standardize('mean_merged.dat', 'mean_merged_3col.dat')
        subprocess.check_call(
             'zip -q -9 saxsmerge.zip data_* mean_* summary.txt saxsmerge.log',
             shell=True)

    def run(self):
        args = self.get_args()
        post = self.gen_gnuplots()
        script = """
date
hostname
module load Sali
module load gnuplot imp-fast python3/scipy

saxs_merge %s

cat <<EOF > Cpgnuplot
%s
EOF
gnuplot Cpgnuplot

date
""" % (args, post)
        r = self.runnercls(script)
        r.set_sge_options('-l arch=lx-amd64 -j y -o saxsmerge.log')
        r.set_sge_name(self.name)
        return r

    def plot_log_scale(self, outfile, subs):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data log-scale"\n'
        script += 'set log y\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += ('p "%s" every %d u 1:2 w p lt 1 t "data", '
                   % (datafile, subs))
        script += ('"%s" every %d u 1:2:3 w yerr lt 1 t "data", '
                   % (datafile, subs))
        script += '"%s" every %d u 1:2 w l lt 2 t "mean", ' % (meanfile, subs)
        script += ('"%s" every %d u 1:(\\$2+\\$3) w l lt 3 t "+- SD", '
                   % (meanfile, subs))
        script += ('"%s" every %d u 1:(\\$2-\\$3) w l lt 3 not\n'
                   % (meanfile, subs))
        return script

    def plot_lin_scale(self, outfile, subs):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data linear scale"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "I(q)"\n'
        script += ('p "%s" every %d u 1:2 w p lt 1 t "data", '
                   % (datafile, subs))
        script += ('"%s" every %d u 1:2:3 w yerr lt 1 t "data", '
                   % (datafile, subs))
        script += ('"%s" every %d u 1:2 w l lt 2 t "mean", '
                   % (meanfile, subs))
        script += ('"%s" every %d u 1:(\\$2+\\$3) w l lt 3 t "+- SD", '
                   % (meanfile, subs))
        script += ('"%s" every %d u 1:(\\$2-\\$3) w l lt 3 not\n'
                   % (meanfile, subs))
        return script

    def plot_guinier(self, outfile, subs):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data Guinier plot"\n'
        script += 'set xlabel "q^2"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'set log y\n'
        script += ('p "%s" every %d u (\\$1**2):2 w p lt 1 t "data", '
                   % (datafile, subs))
        script += ('"%s" every %d u (\\$1**2):2:3 w yerr lt 1 t "data", '
                   % (datafile, subs))
        script += ('"%s" every %d u (\\$1**2):2 w l lt 2 t "mean", '
                   % (meanfile, subs))
        script += ('"%s" every %d u (\\$1**2):(\\$2+\\$3) '
                   'w l lt 3 t "+- SD", ' % (meanfile, subs))
        script += ('"%s" every %d u (\\$1**2):(\\$2-\\$3) w l lt 3 not\n'
                   % (meanfile, subs))
        return script

    def plot_kratky(self, outfile, subs):
        datafile = "data_merged.dat"
        meanfile = "mean_merged.dat"
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data Kratky plot"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "q^2 I(q)"\n'
        script += ('p "%s" every %d u 1:(\\$1**2*\\$2) w p lt 1 t "data", '
                   % (datafile, subs))
        script += ('"%s" every %d u 1:(\\$1**2*\\$2):(\\$1**2*\\$3) '
                   'w yerr lt 1 t "data", ' % (datafile, subs))
        script += ('"%s" every %d u 1:(\\$1**2*\\$2) w l lt 2 t "mean", '
                   % (meanfile, subs))
        script += ('"%s" every %d u 1:(\\$1**2*(\\$2+\\$3)) '
                   'w l lt 3 t "+- SD", ' % (meanfile, subs))
        script += ('"%s" every %d u 1:(\\$1**2*(\\$2-\\$3)) '
                   'w l lt 3 not\n' % (meanfile, subs))
        return script

    def plot_log_scale_colored(self, outfile, subs, full=False):
        datafile = "data_merged.dat"
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data colored by inputs"\n'
        script += 'set log y\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        if full:
            script += ('p "%s" every %d u 1:2:(1+\\$7) w p lc var not\n'
                       % (datafile, subs))
        else:
            script += ('p "%s" every %d u 1:2:(1+\\$4) w p lc var not\n'
                       % (datafile, subs))
        return script

    def plot_lin_scale_colored(self, outfile, subs, full=False):
        datafile = "data_merged.dat"
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "merged data colored by inputs"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "I(q)"\n'
        if full:
            script += ('p "%s" every %d u 1:2:(1+\\$7) w p lc var not\n'
                       % (datafile, subs))
        else:
            script += ('p "%s" every %d u 1:2:(1+\\$4) w p lc var not\n'
                       % (datafile, subs))
        return script

    def plot_inputs_log_scale(self, outfile, infiles, subs):
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files log-scale"\n'
        script += 'set log y\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'p '
        for i, fn in enumerate(infiles):
            datafile = 'data_'+fn
            meanfile = 'mean_'+fn
            if i > 0:
                script += ',\\\n  '
            script += ('"%s" every %d u 1:(\\$4==1?%d*\\$2:1/0) '
                       'w p lt %d t "%s", '
                       % (datafile, subs, 10**i, i+1, fn))
            script += ('"%s" every %d u 1:(\\$4==1?%d*\\$2:1/0):(%d*\\$3) '
                       'w yerr lt %d not, '
                       % (datafile, subs, 10**i, 10**i, i+1))
            script += ('"%s" every %d u 1:(\\$5==1?%d*\\$2:1/0) '
                       'w l lt %d not, '
                       % (meanfile, subs, 10**i, i+2))
            script += ('"%s" every %d u 1:(\\$5==1?%d*(\\$2+\\$3):1/0) '
                       'w l lt %d not, '
                       % (meanfile, subs, 10**i, i+3))
            script += ('"%s" every %d u 1:(\\$5==1?%d*(\\$2-\\$3):1/0) '
                       'w l lt %d not'
                       % (meanfile, subs, 10**i, i+3))
        script += '\n'
        return script

    def plot_inputs_lin_scale(self, outfile, infiles, subs):
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files linear scale"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "I(q)"\n'
        script += 'p '
        for i, fn in enumerate(infiles):
            datafile = 'data_'+fn
            meanfile = 'mean_'+fn
            if i > 0:
                script += ',\\\n  '
            script += ('"%s" every %d u 1:(\\$4==1?%d+\\$2:1/0) '
                       'w p lt %d t "%s", '
                       % (datafile, subs, i*30, i+1, fn))
            script += ('"%s" every %d u 1:(\\$4==1?%d+\\$2:1/0):3 '
                       'w yerr lt %d not, '
                       % (datafile, subs, i*30, i+1))
            script += ('"%s" every %d u 1:(\\$5==1?%d+\\$2:1/0) '
                       'w l lt %d not, '
                       % (meanfile, subs, i*30, i+2))
            script += ('"%s" every %d u 1:(\\$5==1?%d+(\\$2+\\$3):1/0) '
                       'w l lt %d not, '
                       % (meanfile, subs, i*30, i+3))
            script += ('"%s" every %d u 1:(\\$5==1?%d+(\\$2-\\$3):1/0) '
                       'w l lt %d not'
                       % (meanfile, subs, i*30, i+3))
        script += '\n'
        return script

    def plot_inputs_guinier(self, outfile, infiles, subs):
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files Guinier plot"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "log I(q)"\n'
        script += 'set log y\n'
        script += 'p '
        for i, fn in enumerate(infiles):
            datafile = 'data_'+fn
            meanfile = 'mean_'+fn
            if i > 0:
                script += ',\\\n  '
            script += ('"%s" every %d u (\\$1**2):(\\$4==1?%d*\\$2:1/0) '
                       'w p lt %d t "%s", '
                       % (datafile, subs, 10**i, i+1, fn))
            script += ('"%s" every %d '
                       'u (\\$1**2):(\\$4==1?%d*\\$2:1/0):(%d*\\$3) '
                       'w yerr lt %d not, '
                       % (datafile, subs, 10**i, 10**i, i+1))
            script += ('"%s" every %d u (\\$1**2):(\\$5==1?%d*\\$2:1/0) '
                       'w l lt %d not, '
                       % (meanfile, subs, 10**i, i+2))
            script += ('"%s" every %d '
                       'u (\\$1**2):(\\$5==1?%d*(\\$2+\\$3):1/0) '
                       'w l lt %d not, ' % (meanfile, subs, 10**i, i+3))
            script += ('"%s" every %d '
                       'u (\\$1**2):(\\$5==1?%d*(\\$2-\\$3):1/0) '
                       'w l lt %d not' % (meanfile, subs, 10**i, i+3))
        script += '\n'
        return script

    def plot_inputs_kratky(self, outfile, infiles, subs):
        script = "reset\n"
        script += 'set terminal canvas solid butt size 400,350 fsize 10 '
        script += 'lw 1.5 fontscale 1 name "%s" jsdir "."\n' % outfile
        script += 'set title "input files Kratky plot"\n'
        script += 'set xlabel "q"\n'
        script += 'set ylabel "q^2 I(q)"\n'
        script += 'p '
        mult = 1
        if os.path.isfile('is_nm'):
            mult = 100
        for i, fn in enumerate(infiles):
            datafile = 'data_'+fn
            meanfile = 'mean_'+fn
            if i > 0:
                script += ',\\\n  '
            script += ('"%s" every %d u 1:(\\$4==1?%f+\\$2*\\$1**2:1/0) '
                       'w p lt %d t "%s", ' % (datafile, subs, mult*0.1*i,
                                               i+1, fn))
            script += ('"%s" every %d '
                       'u 1:(\\$4==1?%f+\\$2*\\$1**2:1/0):(\\$1**2*\\$3) '
                       'w yerr lt %d not, ' % (datafile, subs, mult*0.1*i,
                                               i+1))
            script += ('"%s" every %d '
                       'u 1:(\\$5==1?%f+\\$2*\\$1**2:1/0) '
                       'w l lt %d not, ' % (meanfile, subs, mult*0.1*i, i+2))
            script += ('"%s" every %d '
                       'u 1:(\\$5==1?%f+\\$1**2*(\\$2+\\$3):1/0) '
                       'w l lt %d not, ' % (meanfile, subs, mult*0.1*i, i+3))
            script += ('"%s" every %d '
                       'u 1:(\\$5==1?%f+\\$1**2*(\\$2-\\$3):1/0) '
                       'w l lt %d not' % (meanfile, subs, mult*0.1*i, i+3))
        script += '\n'
        return script

    def estimate_subsampling(self, fname):
        with open(fname) as fh:
            nlines = len(fh.readlines())
        return 1 + nlines//500

    def gen_gnuplots(self):
        script = ""
        with open('input.txt') as fh:
            infile = fh.readlines()
        hasmerge = '--stop=merging\n' in infile
        haslongtable = not ('--outlevel=sparse\n' in infile)
        hasfull = '--outlevel=full\n' in infile
        hasinputs = '--allfiles\n' in infile
        nsubs = self.estimate_subsampling(infile[0][:infile[0].rfind('=')])
        # merge-related plots
        if hasmerge:
            outfile = "mergeplots"
            script += 'set output "%s.js"\n' % outfile
            script += self.plot_log_scale(outfile+'_1', nsubs)
            script += self.plot_lin_scale(outfile+'_2', nsubs)
            script += self.plot_guinier(outfile+'_3', nsubs)
            script += self.plot_kratky(outfile+'_4', nsubs)
        # merge/input related plots
        if hasmerge and haslongtable:
            outfile = "mergeinplots"
            script += 'set output "%s.js"\n' % outfile
            script += self.plot_log_scale_colored(outfile+'_1', nsubs,
                                                  full=hasfull)
            script += self.plot_lin_scale_colored(outfile+'_2', nsubs,
                                                  full=hasfull)
        if hasinputs:
            infiles = [i[:i.rfind('=')]
                       for i in infile if not i.startswith('--')]
            outfile = "inputplots"
            script += 'set output "%s.js"\n' % outfile
            script += self.plot_inputs_log_scale(outfile+'_1', infiles, nsubs)
            script += self.plot_inputs_lin_scale(outfile+'_2', infiles, nsubs)
            script += self.plot_inputs_guinier(outfile+'_3', infiles, nsubs)
            script += self.plot_inputs_kratky(outfile+'_4', infiles, nsubs)
        return script


def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)
