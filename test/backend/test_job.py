import unittest
import saxsmerge
import saliweb.test
import saliweb.backend
import os


class JobTests(saliweb.test.TestCase):
    """Check custom Job class"""

    def test_init(self):
        """Test creation of Job object"""
        _ = self.make_test_job(saxsmerge.Job, 'RUNNING')

    def test_get_args(self):
        """Test get_args() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            with open('input.txt', 'w') as fh:
                fh.write('--foo  \n--bar\n')
            self.assertEqual(j.get_args(),
                             '--foo --bar --blimit_fitting=240 '
                             '--elimit_fitting=240 --blimit_hessian=80 '
                             '--elimit_hessian=80 -v -v -v')

    def test_run_ok(self):
        """Test successful run method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            with open('input.txt', 'w') as fh:
                fh.write('datafile=10\n--foo  \n--bar\n')
            with open('datafile', 'w') as fh:
                fh.write('\n')
            _ = j.run()

    def test_postprocess_files(self):
        """Test postprocess() method with files present"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            with open('data_merged.dat', 'w') as fh:
                fh.write('0.02   109.78   0.34   1 foo.dat\n')
            with open('mean_merged.dat', 'w') as fh:
                fh.write('0   277.40   4.13  264.11 --- --- 1\n')
                fh.write('0   213.47   3.37  264.04 --- --- 1\n')
            j.postprocess()
            os.unlink('data_merged_3col.dat')
            os.unlink('mean_merged_3col.dat')
            os.unlink('saxsmerge.zip')

    def test_postprocess_no_files(self):
        """Test postprocess() method with no files present"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            with open('saxsmerge.log', 'w') as fh:
                fh.write('garbage\n')
            j.postprocess()
            self.assertFalse(os.path.exists('data_merged_3col.dat'))
            self.assertFalse(os.path.exists('mean_merged_3col.dat'))
            os.unlink('saxsmerge.zip')

    def test_plot_log_scale(self):
        """Test plot_log_scale() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_log_scale('log_scale.plot', 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertTrue("set log y" in p)
        self.assertTrue('p "data_merged.dat" every 5 u 1:2 w p' in p)

    def test_plot_log_scale_colored(self):
        """Test plot_log_scale_colored() method"""
        for full, col in ((False, 4), (True, 7)):
            j = self.make_test_job(saxsmerge.Job, 'RUNNING')
            p = j.plot_log_scale_colored('log_scale.plot', 5, full=full)
            self.assertTrue("set terminal canvas solid" in p)
            self.assertTrue("set log y" in p)
            self.assertTrue('p "data_merged.dat" every 5 u 1:2:(1+\\$%d)' % col
                            in p)

    def test_plot_lin_scale(self):
        """Test plot_lin_scale() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_lin_scale('lin_scale.plot', 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertFalse("set log y" in p)
        self.assertTrue('p "data_merged.dat" every 5 u 1:2 w p' in p)

    def test_plot_lin_scale_colored(self):
        """Test plot_lin_scale_colored() method"""
        for full, col in ((False, 4), (True, 7)):
            j = self.make_test_job(saxsmerge.Job, 'RUNNING')
            p = j.plot_lin_scale_colored('lin_scale.plot', 5, full=full)
            self.assertTrue("set terminal canvas solid" in p)
            self.assertFalse("set log y" in p)
            self.assertTrue('p "data_merged.dat" every 5 u 1:2:(1+\\$%d)' % col
                            in p)

    def test_plot_guinier(self):
        """Test plot_guinier() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_guinier('guinier.plot', 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertTrue("set log y" in p)
        self.assertTrue('p "data_merged.dat" every 5 u (\\$1**2):2' in p)

    def test_plot_kratky(self):
        """Test plot_guinier() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_kratky('kratky.plot', 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertFalse("set log y" in p)
        self.assertIn('p "data_merged.dat" every 5 u 1:(\\$1**2*\\$2) w', p)

    def test_plot_inputs_log_scale(self):
        """Test plot_inputs_log_scale() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_inputs_log_scale('log_scale.plot', ['foo', 'bar'], 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertTrue("set log y" in p)
        self.assertTrue('p "data_foo" every 5 u 1:(\\$4==1?1*\\$2:1/0)'
                        in p)
        self.assertTrue('"data_bar" every 5 u 1:(\\$4==1?10*\\$2:1/0)'
                        in p)

    def test_plot_inputs_lin_scale(self):
        """Test plot_inputs_lin_scale() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_inputs_lin_scale('lin_scale.plot', ['foo', 'bar'], 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertFalse("set log y" in p)
        self.assertTrue('p "data_foo" every 5 u 1:(\\$4==1?0+\\$2:1/0)'
                        in p)
        self.assertTrue('"data_bar" every 5 u 1:(\\$4==1?30+\\$2:1/0)'
                        in p)

    def test_plot_inputs_guinier(self):
        """Test plot_inputs_guinier() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        p = j.plot_inputs_guinier('guinier.plot', ['foo', 'bar'], 5)
        self.assertTrue("set terminal canvas solid" in p)
        self.assertTrue("set log y" in p)
        self.assertTrue('p "data_foo" every 5 u (\\$1**2):(\\$4==1?1*\\$2:1/0)'
                        in p)
        self.assertTrue('"data_bar" every 5 u (\\$1**2):(\\$4==1?10*\\$2:1/0)'
                        in p)

    def test_plot_inputs_kratky(self):
        """Test plot_inputs_kratky() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            p = j.plot_inputs_kratky('kratky.plot', ['foo', 'bar'], 5)
            self.assertTrue("set terminal canvas solid" in p)
            self.assertFalse("set log y" in p)
            with open('is_nm', 'w'):
                pass
            p = j.plot_inputs_kratky('kratky.plot', ['foo', 'bar'], 5)
            self.assertTrue("set terminal canvas solid" in p)
            self.assertFalse("set log y" in p)

    def test_estimate_subsampling(self):
        """Test estimate_subsampling() method"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        fname = os.path.join(j.directory, 'test.txt')
        for lines, subsamp in ((1, 1), (499, 1), (500, 2)):
            with open(fname, 'w') as fh:
                fh.write('\n' * lines)
            self.assertEqual(j.estimate_subsampling(fname), subsamp)

    def make_input_txt(self, contents):
        with open('input.txt', 'w') as fh:
            fh.write('testfile=100\n' + contents)
        with open('testfile', 'w') as fh:
            fh.write('\n')

    def test_gen_gnuplots_no_opts(self):
        """Test gen_gnuplots() method with no options"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            self.make_input_txt('')
            script = j.gen_gnuplots()
            self.assertEqual(script, '')

    def test_gen_gnuplots_hasmerge(self):
        """Test gen_gnuplots() method with merging"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            self.make_input_txt('--stop=merging\n--outlevel=sparse\n')
            script = j.gen_gnuplots()
            self.assertTrue('fontscale 1 name "mergeplots_4"' in script)

    def test_gen_gnuplots_hasmerge_longtable(self):
        """Test gen_gnuplots() method with merging and long table"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            self.make_input_txt('--stop=merging\n')
            script = j.gen_gnuplots()
            self.assertTrue('fontscale 1 name "mergeplots_4"' in script)
            self.assertTrue('fontscale 1 name "mergeinplots_2"' in script)

    def test_gen_gnuplots_hasinputs(self):
        """Test gen_gnuplots() method with input plots"""
        j = self.make_test_job(saxsmerge.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            self.make_input_txt('test2file=200\n--allfiles\n')
            script = j.gen_gnuplots()
            self.assertTrue('p "data_testfile" every 1' in script)
            self.assertTrue('"data_test2file" every 1' in script)


if __name__ == '__main__':
    unittest.main()
