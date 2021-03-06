from flask import jsonify
from HTMLParser import HTMLParser
import opml
import re
from bs4 import BeautifulSoup, Comment
from .core import logger
from .models import *
import xxhash


def make_error(message, error_code=0, status_code=500):
    response = jsonify(error={'message': message, 'code': error_code})
    response.status_code = status_code
    return response


class HTMLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.fed = []

    def handle_data(self, d):
        self.fed.append(d)

    def get_data(self):
        return ''.join(self.fed)


def strip_html_tags(html):
    s = HTMLStripper()
    s.feed(html)
    return s.get_data()


def import_opml(user_id, path):
    _opml = opml.parse(path)

    uncategorized = None
    for outline in _opml:
        if hasattr(outline, 'xmlUrl'):
            if uncategorized is None:  # does not defined yet
                uncategorized = Category.query.filter_by(user_id=user_id, name="Uncategorized").first()
                if uncategorized is None:  # not found
                    uncategorized = Category(user_id, "Uncategorized", order_id=9999)
                    uncategorized.save()

            feed = Feed(outline.xmlUrl)
            feed.save()

            user_feed = UserFeed(user_id, uncategorized.id, feed.id, outline.text)
            user_feed.save()

        else:
            category = Category.query.filter_by(user_id=user_id, name=outline.text).first()
            if category is None:
                category = Category(user_id, outline.text)
                category.save()

            for child in outline:
                if hasattr(child, 'xmlUrl'):
                    hash = xxhash.xxh64()
                    feed = Feed.query.filter_by(feed_url_hash=hash).first()
                    if feed is None:
                        feed = Feed(child.xmlUrl)
                        feed.save()

                    user_feed = UserFeed(user_id=user_id, category_id=category.id, feed_id=feed.id, feed_name=child.text)
                    user_feed.save()
                else:
                    logger.warn("Nested category is not supported yet, ignored!")


def html_sanitizer(html):
    """ Sanitize HTML filter, borrowed from http://djangosnippets.org/snippets/205/"""

    rjs = r'[\s]*(&#x.{1,7})?'.join(list('javascript:'))
    rvb = r'[\s]*(&#x.{1,7})?'.join(list('vbscript:'))
    re_scripts = re.compile('(%s)|(%s)' % (rjs, rvb), re.IGNORECASE)

    valid_tags = ['a', 'br', 'b', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'img', 'li', 'ol',
                  'p', 'strong', 'table', 'tr', 'td', 'th', 'u', 'ul', 'thead', 'tbody', 'tfoot',
                  'em', 'dd', 'dt', 'dl', 'span', 'div', 'del', 'add', 'i', 'hr', 'pre', 'blockquote',
                  'address', 'code', 'caption', 'abbr', 'acronym', 'cite', 'dfn', 'q', 'ins', 'sup', 'sub',
                  'samp', 'tt', 'small', 'big', 'video', 'audio', 'canvas']
    valid_attrs = ['href', 'src', 'width', 'height']

    soup = BeautifulSoup(html)
    for comment in soup.findAll(text=lambda text: isinstance(text, Comment)):
        comment.extract()
    for tag in soup.findAll(True):
        if tag.name not in valid_tags:
            tag.hidden = True
        attrs = tag.attrs
        tag.attrs = {}
        for attr in attrs:
            if attr in valid_attrs:
                val = re_scripts.sub('', attrs[attr])  # Remove scripts (vbs & js)
                tag.attrs[attr] = val
    return soup.renderContents().decode('utf8')
