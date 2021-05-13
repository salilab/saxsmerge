import unittest
import saliweb.test
import re

# Import the saxsmerge frontend with mocks
saxsmerge = saliweb.test.import_mocked_frontend("saxsmerge", __file__,
                                                '../../frontend')


def get_summary_file():
    return """Merge file
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
"""


class Tests(saliweb.test.TestCase):
    """Check results page"""

    def test_results_file(self):
        """Test download of results files"""
        with saliweb.test.make_frontend_job('testjob') as j:
            j.make_file('saxsmerge.log')
            c = saxsmerge.app.test_client()
            rv = c.get('/job/testjob/saxsmerge.log?passwd=%s' % j.passwd)
            self.assertEqual(rv.status_code, 200)

    def test_ok_job_minimal(self):
        """Test display of OK job, minimal outputs"""
        with saliweb.test.make_frontend_job('testjob2') as j:
            j.make_file("summary.txt")
            c = saxsmerge.app.test_client()
            for endpoint in ('job', 'results.cgi'):
                rv = c.get('/%s/testjob2?passwd=%s' % (endpoint, j.passwd))
                r = re.compile(
                    b'Output Files.*Summary file.*All files.*Merge Statistics'
                    b'.*order.*filename.*num points.*mean function.*A'
                    b'.*G.*Rg.*d.*s.*sigma.*tau.*lambda',
                    re.MULTILINE | re.DOTALL)
                self.assertRegex(rv.data, r)

    def test_failed_job(self):
        """Test display of failed job"""
        with saliweb.test.make_frontend_job('testjob3') as j:
            c = saxsmerge.app.test_client()
            rv = c.get('/job/testjob3?passwd=%s' % j.passwd)
            r = re.compile(
                b'No output file was produced.*'
                b'Please inspect the log file.*'
                rb'saxsmerge\.log.*View SAXS Merge log file',
                re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)

    def test_ok_job(self):
        """Test display of OK job"""
        with saliweb.test.make_frontend_job('testjob4') as j:
            j.make_file("summary.txt", contents=get_summary_file())
            c = saxsmerge.app.test_client()
            rv = c.get('/job/testjob4?passwd=%s' % j.passwd)
            r = re.compile(
                b'Output Files.*'
                b'Summary file.*'
                b'Merge Statistics.*'
                b'mean function.*A.*G.*Rg.*sigma.*lambda.*'
                rb'180713_MBP-IVB_1mg\.dat',
                re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)

    def test_ok_job_plots(self):
        """Test display of OK job with plots"""
        with saliweb.test.make_frontend_job('testjob5') as j:
            j.make_file("summary.txt", contents=get_summary_file())
            j.make_file('input.txt',
                        "SubtrB1-A11b.dat=10\nSubtrB2-A11b.dat=10\n--auto\n")
            for fname in ("mergeplots.js", "mergeinplots.js", "inputplots.js"):
                j.make_file(fname, "")
            c = saxsmerge.app.test_client()
            rv = c.get('/job/testjob5?passwd=%s' % j.passwd)
            r = re.compile(
                b'Output Files.*'
                b'Summary file.*'
                b'Merge Statistics.*'
                b'mean function.*A.*G.*Rg.*sigma.*lambda.*'
                rb'180713_MBP-IVB_1mg\.dat.*'
                rb'<h4>Merge Plots<\/h4>.*'
                rb'<h4>Input Colored Merge Plots<\/h4>.*'
                rb'<h4>Input Plots<\/h4>',
                re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)


if __name__ == '__main__':
    unittest.main()
