#!/usr/bin/python3

from pyvirtualdisplay import Display
from selenium import webdriver
import time
import http.server
import socketserver
from http import HTTPStatus
import atexit
from urllib.parse import urlparse

display = Display(visible=0, size=(1200, 800))
display.start()


def get_title(url):
    browser = webdriver.Firefox()
    browser.get(url)
    parsed_url = urlparse(url)
    # Special treatment needed for shittiest
    # websites on the planet.
    #
    # Twitter first
    if parsed_url.hostname.endswith("twitter.com"):
        title = browser.title
        tries = 0
        while tries < 6 and ":" not in title:
            tries = tries + 1
            time.sleep(1)
            title = browser.title
    else:
        title = browser.title
        
    browser.quit()
    return title


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(HTTPStatus.OK)
        self.end_headers()
        url = self.path
        url = url[1:]
        title = get_title(url)
        self.wfile.write(bytes(title, 'utf-8'))

httpd = socketserver.TCPServer(('', 9001), Handler)

def exit_handler():
    httpd.server_close()
    display.stop()

atexit.register(exit_handler)
httpd.serve_forever()
