import unittest
import saxsmerge
import saliweb.test
import saliweb.backend
import os

class JobTests(saliweb.test.TestCase):
    """Check custom Job class"""

    def test_init(self):
        """Test creation of Job object"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')

if __name__ == '__main__':
    unittest.main()
