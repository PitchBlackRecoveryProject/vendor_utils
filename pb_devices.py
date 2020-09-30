#!/usr/bin/python3
#
# Python script for PBRP's Official Devices.
#
# Copyright (C) 2018, PitchBlack Recovery Project <pitchblackrecovery@gmail.com>
#

import sys, json, urllib.request, shutil, os

url = 'https://raw.githubusercontent.com/PitchBlackRecoveryProject/vendor_utils/pb/pb_devices.json'
arguments = sys.argv
json_file = "/tmp/pb_devices.json"

def invalid_arguments():
	raise Exception("PB_DEVICES.PY: Use proper arguments.\n\n Available Commands:\n > pb_devices.py verify <vendor> <codename>.")

def print_all_official():
	response = urllib.request.urlopen(url)
	data = json.loads(response.read().decode('utf-8'))
	ven = data.keys()
	cod = ""
	for i in ven:
		cod = json.loads(json.dumps(data[i])).keys()
		for j in cod:
			print(j)
	return 0

def verify_device(vendor, codename, maintainer = 0):
	with open(json_file, 'r') as f:
		data = json.load(f)

	ven = data.keys()
	found = 1
	i = ''
	if vendor != "all":
		for i in ven:
			if i.casefold() == vendor.casefold():
				found = 0
				break
		if found != 0:
			return 1
		found = 1
		ven = i

		cod = data[ven]

		for i in cod:
			if i.casefold() == codename.casefold():
				found = 0
				break
		if found != 0:
			return 1
		found = 1

		cod = i
		if codename.casefold() == cod.casefold():
			found = 0
	else:
		cod = ""
		for i in ven:
			cod = json.loads(json.dumps(data[i])).keys()
			for j in cod:
				if j.casefold() == codename.casefold():
					found = 0
					break
			if found == 0:
				cod = j
				break

	if found == 0 and maintainer != 0:
		print(data[ven][cod]["maintainer"]);

	return found


if len(arguments) == 2 and arguments[1] == 'print_all':
	exit(print_all_official())
elif len(arguments) < 4:
	invalid_arguments()

cmd = arguments[1]

if len(arguments) != 5 or cmd != 'verify':
	print("PB_DEVICES: Detected Codename: ", arguments[3])
	print("PB_DEVICES: Detected Vendor: ", arguments[2])
if cmd == 'verify' and len(arguments) == 4:
	exit(verify_device(arguments[2], arguments[3]))
elif cmd == 'verify' and len(arguments) == 5:
	exit(verify_device(arguments[2], arguments[3], arguments[4]))
else:
	invalid_arguments()
