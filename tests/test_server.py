import json
import threading
import unittest
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import urlopen

from app.server import ApplicationHandler


class ApplicationHandlerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), ApplicationHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = "http://127.0.0.1:%s" % cls.server.server_port

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def test_health_check(self):
        with urlopen("%s/health" % self.base_url) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(json.load(response), {"status": "ok"})

    def test_root_includes_service_and_version(self):
        with urlopen(self.base_url) as response:
            self.assertEqual(response.status, 200)
            result = json.load(response)
            self.assertEqual(result["service"], "personal-project")
            self.assertEqual(result["version"], "local")

    def test_unknown_path_returns_not_found(self):
        with self.assertRaises(HTTPError) as error:
            urlopen("%s/missing" % self.base_url)

        with error.exception as response:
            self.assertEqual(response.code, 404)
            self.assertEqual(json.load(response), {"error": "not found"})


if __name__ == "__main__":
    unittest.main()
