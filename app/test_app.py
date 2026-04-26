import unittest
import os
import sqlite3
import tempfile
from app import app, init_db, DB_PATH

class AppTestCase(unittest.TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['WTF_CSRF_ENABLED'] = False
        self.client = app.test_client()

        # Override DB_PATH for tests
        global DB_PATH
        self.db_fd, self.temp_db = tempfile.mkstemp()
        import app as app_module
        app_module.DB_PATH = self.temp_db
        app_module.NGINX_TEMPLATE = '/tmp/nginx.conf.template'
        app_module.NGINX_CONF = '/tmp/nginx.conf'

        with open('/tmp/nginx.conf.template', 'w') as f:
            f.write("# PUSH_DIRECTIVES")

        init_db()

    def tearDown(self):
        os.close(self.db_fd)
        os.unlink(self.temp_db)

    def test_health(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)

    def test_login_page(self):
        response = self.client.get('/login')
        self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    unittest.main()
