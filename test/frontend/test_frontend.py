import unittest
import saliweb.test

# Import the saxsmerge frontend with mocks
saxsmerge = saliweb.test.import_mocked_frontend("saxsmerge", __file__,
                                                '../../frontend')


class Tests(saliweb.test.TestCase):

    def test_index(self):
        """Test index page"""
        c = saxsmerge.app.test_client()
        rv = c.get('/')
        self.assertIn(b'An automated statistical method',
                      rv.data)
        self.assertIn(b'Start discarding curve after qcut', rv.data)

    def test_faq(self):
        """Test FAQ page"""
        c = saxsmerge.app.test_client()
        rv = c.get('/faq')
        self.assertIn(b'How are the profiles rescaled', rv.data)

    def test_help(self):
        """Test help page"""
        c = saxsmerge.app.test_client()
        rv = c.get('/help')
        self.assertIn(b'Output data for parsed input files', rv.data)

    def test_download(self):
        """Test download page"""
        c = saxsmerge.app.test_client()
        rv = c.get('/download')
        self.assertIn(b'SAXS Merge can be downloaded', rv.data)

    def test_queue(self):
        """Test queue page"""
        c = saxsmerge.app.test_client()
        rv = c.get('/job')
        self.assertIn(b'No pending or running jobs', rv.data)


if __name__ == '__main__':
    unittest.main()
