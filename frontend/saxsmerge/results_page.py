import saliweb.frontend
import os

def show_results_page(job):
    if os.path.exists(job.get_path('summary.txt')):
        return saliweb.frontend.render_results_template(
            "results_ok.html", job=job)
    else:
        return saliweb.frontend.render_results_template(
            "results_failed.html", job=job)
