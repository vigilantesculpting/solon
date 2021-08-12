#!/usr/bin/env python

import sys
import solon

import yaml
import os
import re

import pdb
import traceback

def readfile(path):
	with open(path, "r") as f:
		return f.read()

def separateheader(text):
	# If there is a YAML header the protocol is to separate it from the main body
	# content using a single "---" line.
	spec = r'^---\s*\n(.*)^---\s*\n(.*)^---\s*\n(.*)'
	# re needs to match newlines and be multi-line aware
	flags = re.DOTALL | re.M
	m = re.match(spec, text, flags)
	fileheader, filebody, expected = m.groups()
	return fileheader, filebody, expected

def main():
	try:
		solon.LOG = False

		print "*** Start Tests ***"
		for dirpath, dirnames, filenames in os.walk("tests"):
			for filename in sorted(filenames):

				test = os.path.splitext(filename)[0]
				path = os.path.join(dirpath, filename)

				print "[>>>>] Running test", test, path

				content = readfile(path)
				header, body, expected = separateheader(content)

				context = yaml.safe_load(header)
				if context is None:
					context = {}

				expectedexc = None
				if context['exception'] != 'nil':
					expectedexc = getattr(sys.modules["solon"], context['exception'])				

				s = solon.Solon(context)

				keepWhitespace = context.get("config/keepWhitespace", False)
				keepComments = context.get("config/keepComments", False)

				try:
					s.addtemplate(test, body)
					result = s.rendertemplate(test, keepWhitespace, keepComments)
					if expectedexc is not None:
						print "[FAIL] Expected exception [%s] did not trigger" % expectedexc
						return -1
					print result
					if result.strip() != expected.strip():
						print "[FAIL] results do not match expected:"
						print expected
						assert(result.strip() == expected.strip())
					print "[ OK ] results match expected results"
				except Exception as e:
					if expectedexc is None:
						# we caught an exception, but did not expect any
						print "[FAIL] No exception expected, caught exception [%s]\n\t" % e.__class__.__name__, e
						raise
					if not isinstance(e, expectedexc):
						# we caught an exception, not the expected one (and our expected exception is not in its base classes)
						print "[FAIL] Expected exception [%s], instead caught [%s]\n\t" % (context['exception'], e.__class__.__name__), e
						raise
					# we caught an exception, not the expected one (and our expected exception is not in its base classes)
					print "[ OK ] Caught expected exception [%s]/[%s]\n\t" % (e.__class__.__name__, expectedexc), e
				except:
					print "[FAIL] Unknown exception, terminating"
					raise

				#print "--- done"

		print "*** Done! ***"

	except:
		traceback.print_exc()
		pdb.post_mortem()

if __name__ == "__main__":
	sys.exit(main())
