import unittest
import saliweb.test
import tempfile
import os
import re
import io
from werkzeug.datastructures import FileStorage


# Import the saxsmerge frontend with mocks
saxsmerge = saliweb.test.import_mocked_frontend("saxsmerge", __file__,
                                                '../../frontend')


def _mock_profile_fh():
    """Get a handle to a minimal profile file"""
    return io.BytesIO(b"1.0 2.0 3.0")


def get_default_submit_parameters():
    return {'recordings': '3', 'gen_unit': 'Angstrom',
            'gen_output': 'normal', 'gen_stop': 'merging',
            'fit_param': 'Full', 'res_model': 'normal',
            'class_alpha': '0.05', 'merge_param': 'Full',
            'gen_npoints_val': '200', 'clean_cut': '0.1',
            'res_ref': 'last', 'res_npoints': '200',
            'merge_extrapol': '0'}


class Tests(saliweb.test.TestCase):
    """Check submit page"""

    def test_submit_page(self):
        """Test submit page"""
        with tempfile.TemporaryDirectory() as t:
            incoming = os.path.join(t, 'incoming')
            os.mkdir(incoming)
            saxsmerge.app.config['DIRECTORIES_INCOMING'] = incoming
            c = saxsmerge.app.test_client()
            rv = c.post('/job')
            self.assertEqual(rv.status_code, 400)  # no recordings
            self.assertIn(
                b'number of times each profile has been recorded must '
                b'be at least 2!', rv.data)

            data = get_default_submit_parameters()
            profile = os.path.join(t, 'test.profile')
            with open(profile, 'w') as fh:
                print("1.0 2.0 3.0", file=fh)

            # Successful submission (no email)
            data['uploaded_file'] = open(profile, 'rb')
            rv = c.post('/job', data=data, follow_redirects=True)
            self.assertEqual(rv.status_code, 503)
            r = re.compile(b'Your job .* has been submitted.*'
                           b'results will be found',
                           re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)

    def _check_submit(self, data, profile='default'):
        with tempfile.TemporaryDirectory() as t:
            incoming = os.path.join(t, 'incoming')
            os.mkdir(incoming)
            saxsmerge.app.config['DIRECTORIES_INCOMING'] = incoming
            c = saxsmerge.app.test_client()

            if profile == 'default':
                profile = os.path.join(t, 'test.profile')
                with open(profile, 'w') as fh:
                    print("1.0 2.0 3.0", file=fh)
                profile = open(profile, 'rb')
            data['uploaded_file'] = profile
            return c.post('/job', data=data, follow_redirects=True)

    def test_submit_bool_option(self):
        """Test submit page with some normally-off bools turned on"""
        data = get_default_submit_parameters()
        data['fit_bars'] = 'on'
        data['merge_bars'] = 'on'
        data['fit_comp'] = 'on'
        rv = self._check_submit(data)
        self.assertEqual(rv.status_code, 503)

    def test_submit_bad_float(self):
        """Test submit page with bad float option"""
        data = get_default_submit_parameters()
        data['class_alpha'] = 'not-a-float'
        rv = self._check_submit(data)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'Advanced: classification: alpha is invalid number',
                      rv.data)

    def test_submit_bad_choice(self):
        """Test submit page with bad choice option"""
        data = get_default_submit_parameters()
        data['gen_output'] = 'bad-level'
        rv = self._check_submit(data)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'gen_output must be one of', rv.data)

    def test_submit_nanometer(self):
        """Test submit page with units in nanometers"""
        data = get_default_submit_parameters()
        data['gen_unit'] = 'Nanometer'
        rv = self._check_submit(data)
        self.assertEqual(rv.status_code, 503)

    def test_submit_q_first_input(self):
        """Test submit page with q values taken from first input"""
        data = get_default_submit_parameters()
        data['gen_npoints_input'] = 'on'
        rv = self._check_submit(data)
        self.assertEqual(rv.status_code, 503)

    def test_submit_bad_q(self):
        """Test submit page with bad q values"""
        for val in ('not-an-int', '0', '-20'):
            data = get_default_submit_parameters()
            data['gen_npoints_val'] = val
            rv = self._check_submit(data)
            self.assertEqual(rv.status_code, 400)
            self.assertIn(b'q values not a positive number', rv.data)

    def test_submit_bad_qcut(self):
        """Test submit page with bad q cutoff values"""
        for val in ('not-a-float', '0.', '-20.'):
            data = get_default_submit_parameters()
            data['clean_cut'] = val
            rv = self._check_submit(data)
            self.assertEqual(rv.status_code, 400)
            self.assertIn(b'q cutoff is invalid positive float', rv.data)

    def test_submit_bad_ngamma(self):
        """Test submit page with bad number of gamma points"""
        for val in ('not-an-int', '0', '-20'):
            data = get_default_submit_parameters()
            data['res_npoints'] = val
            rv = self._check_submit(data)
            self.assertEqual(rv.status_code, 400)
            self.assertIn(b'number of gamma points must be &gt;0', rv.data)

    def test_submit_bad_extrapol(self):
        """Test submit page with bad merge_extrapol"""
        for val in ('not-an-int', '-20'):
            data = get_default_submit_parameters()
            data['merge_extrapol'] = val
            rv = self._check_submit(data)
            self.assertEqual(rv.status_code, 400)
            self.assertIn(b'percentage must be positive integer', rv.data)

    def test_submit_no_profile(self):
        """Test submit page with no profiles"""
        data = get_default_submit_parameters()
        rv = self._check_submit(data, profile=None)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'Please input at least one file!', rv.data)

    def test_submit_long_profile(self):
        """Test submit page with too-long profile name"""
        data = get_default_submit_parameters()
        fh = FileStorage(stream=_mock_profile_fh(), filename='x' * 80)
        rv = self._check_submit(data, profile=fh)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'limit the file name length to a maximum '
                      b'of 40 characters', rv.data)

    def test_submit_zip_profile(self):
        """Test submit page with zipped profile"""
        data = get_default_submit_parameters()
        fh = FileStorage(stream=_mock_profile_fh(), filename='foo.gz')
        rv = self._check_submit(data, profile=fh)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'Please provide plain text files', rv.data)

    def test_submit_gif_profile(self):
        """Test submit page with gif instead of profile"""
        data = get_default_submit_parameters()
        fh = FileStorage(stream=_mock_profile_fh(), filename='foo.gif')
        rv = self._check_submit(data, profile=fh)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'Please provide plain text files', rv.data)

    def test_submit_empty_profile(self):
        """Test submit page with empty profile file"""
        data = get_default_submit_parameters()
        fh = FileStorage(stream=None, filename='foo.txt')
        rv = self._check_submit(data, profile=fh)
        self.assertEqual(rv.status_code, 400)
        self.assertIn(b'You have uploaded an empty profile: foo.txt', rv.data)


if __name__ == '__main__':
    unittest.main()
