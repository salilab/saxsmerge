from flask import render_template, request, send_from_directory
import saliweb.frontend
from saliweb.frontend import get_completed_job
from . import submit_page, results_page

parameters = []
app = saliweb.frontend.make_application(__name__, parameters)


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/help')
def help():
    return render_template('help.html')


@app.route('/faq')
def faq():
    return render_template('faq.html')


@app.route('/download')
def download():
    return render_template('download.html')


@app.route('/job', methods=['GET', 'POST'])
def job():
    if request.method == 'GET':
        return saliweb.frontend.render_queue_page()
    else:
        return submit_page.handle_new_job()


@app.route('/results.cgi/<name>')  # compatibility with old perl-CGI scripts
@app.route('/job/<name>')
def results(name):
    job = get_completed_job(name, request.args.get('passwd'),
                            still_running_template='running.html')
    return results_page.show_results_page(job)


@app.route('/job/<name>/<path:fp>')
def results_file(name, fp):
    job = get_completed_job(name, request.args.get('passwd'))
    # Profiles (.dat) should display in the browser by default
    mimetype = 'text/plain' if fp.endswith('.dat') else None
    return send_from_directory(job.directory, fp, mimetype=mimetype)
