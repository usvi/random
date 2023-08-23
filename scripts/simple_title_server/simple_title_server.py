#!/usr/bin/python3

#
# sudo apt-get install python3-pyvirtualdisplay
# sudo apt-get install python3-selenium
# sudo apt-get install firefox-geckodriver
#
# python3 simple_title_server.py
# wget http://172.16.8.205:9001/https://twitter.com/Yrtithepreaa/status/1357623427176235008
# wget http://172.16.8.205:9001/https://x.com/martinmbauer/status/1694246157851967829

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
    if parsed_url.hostname.endswith("twitter.com") or parsed_url.hostname.endswith("x.com"):
        title = browser.title
        tries = 0
        while tries < 6 and len(title) < 16:
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
        #self.wfile.write(bytes('<!DOCTYPE HTML><html lang="en"><head><title>' + title +
        #                       '</title></head><body>' + title + '</body></html>', 'utf-8'))
        self.wfile.write(bytes(title, 'utf-8'))
        print('Served ' + self.path)

httpd = socketserver.TCPServer(('', 9001), Handler)

def exit_handler():
    httpd.server_close()
    display.stop()

atexit.register(exit_handler)
httpd.serve_forever()
