import unittest
import saliweb.test
import re

# Import the saxsmerge frontend with mocks
saxsmerge = saliweb.test.import_mocked_frontend("saxsmerge", __file__,
                                                '../../frontend')


class Tests(saliweb.test.TestCase):
    """Check results page"""

    def test_results_file(self):
        """Test download of results files"""
        with saliweb.test.make_frontend_job('testjob') as j:
            j.make_file('saxsmerge.log')
            c = saxsmerge.app.test_client()
            rv = c.get('/job/testjob/saxsmerge.log?passwd=%s' % j.passwd)
            self.assertEqual(rv.status_code, 200)

    def test_ok_job(self):
        """Test display of OK job"""
        with saliweb.test.make_frontend_job('testjob2') as j:
            j.make_file("summary.txt")
            c = saxsmerge.app.test_client()
            for endpoint in ('job', 'results.cgi'):
                rv = c.get('/%s/testjob2?passwd=%s' % (endpoint, j.passwd))
                r = re.compile(
                        b'Job.*testjob.*has completed.*output\\.pdb.*'
                        b'Download output PDB', re.MULTILINE | re.DOTALL)
                self.assertRegex(rv.data, r)

    def test_failed_job(self):
        """Test display of failed job"""
        with saliweb.test.make_frontend_job('testjob3') as j:
            c = saxsmerge.app.test_client()
            rv = c.get('/job/testjob3?passwd=%s' % j.passwd)
            r = re.compile(
                b'No output file was produced.*'
                b'Please inspect the log file.*'
                b'saxsmerge\.log.*View SAXS Merge log file',
                re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)


if __name__ == '__main__':
    unittest.main()
