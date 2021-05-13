import unittest
import saliweb.test
import os

# Import the saxsmerge frontend with mocks
saxsmerge = saliweb.test.import_mocked_frontend("saxsmerge", __file__,
                                                '../../frontend')


class Tests(saliweb.test.TestCase):
    """Check submit page"""

    def test_submit_page(self):
        """Test submit page"""
        with saliweb.test.temporary_directory() as t:
            incoming = os.path.join(t, 'incoming')
            os.mkdir(incoming)
            saxsmerge.app.config['DIRECTORIES_INCOMING'] = incoming
            c = saxsmerge.app.test_client()
            rv = c.post('/job')
            self.assertEqual(rv.status_code, 400)  # no recordings
            self.assertIn(
                b'number of times each profile has been recorded must '
                b'be at least 2!', rv.data)


if __name__ == '__main__':
    unittest.main()
