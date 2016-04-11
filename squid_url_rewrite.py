#!/usr/bin/python3

import re
import sys
import urllib.parse

LINE_RE = re.compile(r'(\S+ )?(\S+)://(\S+)( .*)?')

for line in sys.stdin:
    try:
        match = LINE_RE.match(line)

        channel = match.group(1) or ''
        url = '{}://{}'.format(match.group(2), match.group(3))
        parsed_url = urllib.parse.urlparse(url)
        scheme = parsed_url.scheme
        netloc = parsed_url.netloc
        fragment = parsed_url.fragment
        path = parsed_url.path
        params = parsed_url.params
        query = parsed_url.query

        if netloc == 'akamai.bintray.com':
            print("Rewriting URL %s" % url, file=sys.stderr)
            query_dict = urllib.parse.parse_qs(query)
            if '__gda__' in query_dict:
                del query_dict['__gda__']
            query = urllib.parse.urlencode(query_dict)
        else:
            # Nothing to do.
            print('ERR')
            continue

        new_parsed_url = urllib.parse.ParseResult(
            scheme=scheme,
            netloc=netloc,
            fragment=fragment,
            path=path,
            params=params,
            query=query,
        )
        new_url = urllib.parse.urlunparse(new_parsed_url)

        print("{}OK {}".format(channel, new_url))

    except Exception as e:
        print("Failed to rewrite URL %s" % line, file=sys.stderr)
        print(e, file=sys.stderr)
        print('ERR')
        continue
