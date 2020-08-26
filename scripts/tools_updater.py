#
#  PBRP Tools Updater Script
#  
#  Copyright (C) 2020-2021, Manjot Sidhu <manjot.techie@gmail.com>
#                           PitchBlack Recovery Project <pitchblackrecovery@gmail.com>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#

import os
import sys
import json
import re
import requests

tools_json = 'pb_tools.json'
tools_dir = 'PBRP/tools/'

args = sys.argv

if not len(args) == 2:
	raise Exception("Use proper arguments.\n\n Available Commands:\n > tools_updater.py update.")


def make_gh_link(repo):
	return 'https://github.com/' + repo


def make_gh_release_link(repo, asset_name, release_data, regex):
	asset = asset_name.format(tag = release_data['tag_name'])

	if regex:
		for asset_obj in release_data['assets']:
			if re.search(asset, asset_obj['browser_download_url']):
				print(asset_obj['browser_download_url'])
				return asset_obj['browser_download_url']

	return f'https://github.com/{repo}/releases/latest/download/{asset}'


def get_release_data(repo):
	return json.loads(requests.get(f'https://api.github.com/repos/{repo}/releases/latest').text)


def update_asset(zip_name, link):
	print(f"Downloading {zip_name}")
	r = requests.get(link, allow_redirects=True)
	os.remove(tools_dir + zip_name)
	open(tools_dir + zip_name, 'wb').write(r.content)
	print(f"Downloaded {zip_name}")


def update_json(new_content, zip_name, new_tag):
	for obj in new_content:
		if obj['zip_name'] == zip_name:
			obj['tag_name'] = new_tag
			break

	file = open(tools_json, "w", encoding="utf-8")
	file.write(json.dumps(new_content, indent = 4, sort_keys=True))
	file.close()


def read_json():
	file = open(tools_json, "r", encoding="utf-8")
	content = file.read()
	file.close()

	return json.loads(content)


def magic():
	print("PBRP Tools Updation Script v0.1\n---------------------------\n")
	
	if 'scripts' in os.getcwd():
		os.chdir("../")

	json = read_json()
	for obj in json:
		name = obj['name']
		gh_repo = obj['gh_repo']
		asset_name = obj['asset_name']
		zip_name = obj['zip_name']
		tag = obj['tag_name'] if 'tag_name' in obj else None
		release_data = get_release_data(obj['gh_repo'])
		latest_tag = release_data['tag_name']
		regex = True if 'regex' in obj else False

		if latest_tag != tag:
			print(f'Updating {name} from {tag} to {latest_tag}')
			update_asset(zip_name, make_gh_release_link(gh_repo, asset_name, release_data, regex))
			update_json(json, zip_name, latest_tag)
			print(f'Updated {name} Successfully')


magic()