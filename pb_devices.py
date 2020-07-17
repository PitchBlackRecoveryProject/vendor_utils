#!/usr/bin/python3

#
# Python script for PBRP's Official Devices.
# Copyright PitchBlackRecoveryProject <pitchblackrecovery@gmail.com>
#

import sys, json, urllib.request, shutil, os

url = 'https://raw.githubusercontent.com/PitchBlackRecoveryProject/vendor_pb/pb/pb_devices.json'
local_file = 'pb_devices.json'
backup_file = 'pb_devices.json.bk'
arguments = sys.argv

def invalid_arguments():
	raise Exception("PB_DEVICES.PY: Use proper arguments.\n\n Available Commands:\n > pb_devices.py verify <vendor> <codename>.\n > pb_devices.py release <vendor> <codename> <build-date-time>")

def release_error(error_message):
	raise Exception("PB_DEVICES.PY: ", error_message)


def verify_device(vendor, codename, maintainer = 0):
	response = urllib.request.urlopen(url)

	data = json.loads(response.read().decode('utf-8'))
	ven = data.keys()
	found = 1
	if vendor != "all":
		for i in ven:
			if i.casefold() == vendor.casefold():
				ven = i
				break
		if not ven:
			found = 1

		cod = data[ven]

		for i in cod:
			if i.casefold() == codename.casefold():
				cod = i
				break
		if not cod or isinstance(cod, str) is False:
			found = 1

		if codename.casefold() == cod.casefold():
			found = 0
	else:
		cod = ""
		for i in ven:
			cod = json.loads(json.dumps(data[i])).keys()

			for j in cod:
				if j.casefold() == codename.casefold():
					cod = j
					break
			if not cod:
				found = 1

			if codename.casefold() == j.casefold():
				found = 0
	if found == 0 and maintainer != 0:
		print(data[ven][cod]["maintainer"]);

	return found

def release(vendor, codename, build_date_time):
	shutil.copyfile(local_file, backup_file)

	with open(backup_file, 'r') as f:
	  data = json.load(f)

	ven = data.keys()
	for i in ven:
		if i.casefold() == vendor.casefold():
			ven = i
			break
	if not ven:
		return 1

	cod = data[ven]

	for i in cod:
		if i.casefold() == codename.casefold():
			cod = i
			break
	if not cod or isinstance(cod, str) is False:
		return 1

	if codename.casefold() == cod.casefold():
		data[ven][cod]['latest_release'] = build_date_time
	else:
  		release_error('Device not Official')

	with open(local_file, 'w') as f:
	  json.dump(data, f, indent=2)

	os.remove(backup_file)
	print("PB_DEVICES.PY: Release Success! ", codename, " ", build_date_time)

if len(arguments) < 4:
	invalid_arguments()

cmd = arguments[1]
if len(arguments) != 5 or cmd != 'verify':
	print("PB_DEVICES: Detected Codename: ", arguments[3])
	print("PB_DEVICES: Detected Vendor: ", arguments[2])

if cmd == 'verify' and len(arguments) == 4:
	exit(verify_device(arguments[2], arguments[3]))

elif cmd == 'verify' and len(arguments) == 5:
	exit(verify_device(arguments[2], arguments[3], arguments[4]))

elif cmd == 'release':
	if len(arguments) < 5:
		invalid_arguments()

	release(arguments[2], arguments[3], arguments[4])
else:
	invalid_arguments()
