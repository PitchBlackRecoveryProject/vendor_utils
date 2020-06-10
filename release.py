#!/usr/bin/python3

import sys, json, shutil, os

release_file = 'pb.releases'
backup_file = 'pb.releases.bk'
arguments = sys.argv

if len(arguments) != 3:
	raise Exception("RELEASE.PY: Use proper arguments. Ex: release.py <codename> <build_date_time>")

codename = arguments[1]
build_date_time = arguments[2]
shutil.copyfile(release_file, backup_file)

with open(backup_file, 'r') as f:
  data = json.load(f)

data[codename] = build_date_time
  
with open(release_file, 'w') as f:
  json.dump(data, f, indent=4)

os.remove(backup_file)
print("RELEASE.PY: Success! ", codename, " ", build_date_time)