import unittest
import saliweb.test
import os
import re

# Import the saxsmerge frontend with mocks
saxsmerge = saliweb.test.import_mocked_frontend("saxsmerge", __file__,
                                                '../../frontend')


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

            data = get_default_submit_parameters()
            profile = os.path.join(t, 'test.profile')
            with open(profile, 'w'):
                pass

            # Successful submission (no email)
            data['uploaded_file'] = open(profile, 'rb')
            rv = c.post('/job', data=data)
            self.assertEqual(rv.status_code, 200)
            r = re.compile(b'Your job .* has been submitted.*'
                           b'Results will be found',
                           re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)


if __name__ == '__main__':
    unittest.main()
