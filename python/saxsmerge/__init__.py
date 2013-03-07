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

    def run(self):
        args = self.get_args()
        script="""
date
hostname

IMPPY="/netapp/sali/saxsmerge/imp/cmake-fast/tools/setup_evironment.sh"
SMERGE="/netapp/sali/saxsmerge/imp/src/applications/saxs_merge/saxs_merge.py"

#. /netapp/sali/yannick/.bashrc
#export PATH="/netapp/sali/yannick/bin:$PATH"
#export LD_LIBRARY_PATH="/netapp/sali/yannick/lib:$LD_LIBRARY_PATH"
#export CPPFLAGS="/netapp/sali/yannick/include:$CPPFLAGS"

$IMPPY $SMERGE %s

date
""" % args
        r = self.runnercls(script)
        r.set_sge_options('-l arch=linux-x64')
        return r

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)

