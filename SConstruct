import saliweb.build

vars = Variables('config.py')
env = saliweb.build.Environment(vars, ['conf/live.conf'], service_module='saxsmerge')
Help(vars.GenerateHelpText(env))

env.InstallAdminTools()

Export('env')
SConscript('backend/saxsmerge/SConscript')
SConscript('frontend/saxsmerge/SConscript')
SConscript('test/SConscript')
SConscript('html/SConscript')
