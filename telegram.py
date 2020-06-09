from argparse import ArgumentParser

from requests import post
from os import environ
import json

def arg_parse():
    global token, chat, message, mode, preview, caption, silent, photo, gif, video, note, audio, voice, file, send, out, sticker, button, a
    switches = ArgumentParser()
    group = switches.add_mutually_exclusive_group(required=True)
    group.add_argument("-M", "--message", help="Text message")
    group.add_argument("-P", "--photo", help="Photo path")
    group.add_argument("-G", "--gif", help="GIF Photo path")
    group.add_argument("-V", "--video", help="Video path")
    group.add_argument("-N", "--note", help="Video Note path")
    group.add_argument("-A", "--audio", help="Audio path")
    group.add_argument("-O", "--voice", help="Voice path")
    group.add_argument("-F", "--file", help="File path")
    group.add_argument("-S", "--sticker", help="Sticker id")
    switches.add_argument("-D", "--button", help="Text parse as a Inline button")
    switches.add_argument("-c", "--chat", required=True, help="Chat to use as recipient")
    switches.add_argument("-m", "--mode", help="Text parse mode - HTML/Markdown", default="Markdown")
    switches.add_argument("-p", "--preview", help="Disable URL preview - yes/no", default="yes")
    switches.add_argument("-s", "--silent", help="Disable Notification Sound - yes/no", default="no")
    switches.add_argument("-d", "--output", help="Disable Script output - yes/no", default="yes")
    switches.add_argument("-C", "--caption", help="Media/Document caption")

    args = vars(switches.parse_args())
    token = environ['BOT_API']
    chat = args["chat"]
    message = args["message"]
    photo = args["photo"]
    gif = args["gif"]
    video = args["video"]
    note = args["note"]
    audio = args["audio"]
    voice = args["voice"]
    file = args["file"]
    mode = args["mode"]
    preview = args["preview"]
    silent = args["silent"]
    out = args["output"]
    caption = args["caption"]
    sticker = args["sticker"]
    button = args["button"]
    if button is not None:
        button = button.split('|')
        a = {"inline_keyboard": [[{"text":button[0], "url": button[1]}]]}

    if message is not None:
        send = "text"
    elif photo is not None:
        send = "photo"
    elif gif is not None:
        send = "gif"
    elif video is not None:
        send = "video"
    elif note is not None:
        send = "note"
    elif audio is not None:
        send = "audio"
    elif voice is not None:
        send = "voice"
    elif file is not None:
        send = "file"
    elif sticker is not None:
        send = "sticker"

def send_message():
    global r, status, response
    if send == "text":
       if button is not None:
            params = {
                ('chat_id', chat),
                ('text', message.replace(r'\n', '\n')),
                ('parse_mode', mode),
                ('disable_notification', silent),
                ('reply_markup', json.dumps(a))
            }
            url = "https://api.telegram.org/bot" + token + "/sendMessage"
            r = post(url, params=params)
       else:
            params = {
                ('chat_id', chat),
                ('text', message.replace(r'\n', '\n')),
                ('parse_mode', mode),
                ('disable_notification', silent),
            }
            url = "https://api.telegram.org/bot" + token + "/sendMessage"
            r = post(url, params=params)
    elif send == "photo":
        files = {
            'chat_id': (None, chat),
            'caption': (None, caption),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'photo': (photo, open(photo, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendPhoto"
        r = post(url, files=files)
    elif send == "gif":
        files = {
            'chat_id': (None, chat),
            'caption': (None, caption),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'animation': (gif, open(gif, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendAnimation"
        r = post(url, files=files)
    elif send == "video":
        files = {
            'chat_id': (None, chat),
            'caption': (None, caption),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'video': (video, open(video, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendVideo"
        r = post(url, files=files)
    elif send == "note":
        files = {
            'chat_id': (None, chat),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'video_note': (note, open(note, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendVideoNote"
        r = post(url, files=files)
    elif send == "audio":
        files = {
            'chat_id': (None, chat),
            'caption': (None, caption),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'audio': (audio, open(audio, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendAudio"
        r = post(url, files=files)
    elif send == "voice":
        files = {
            'chat_id': (None, chat),
            'caption': (None, caption),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'voice': (voice, open(voice, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendVoice"
        r = post(url, files=files)
    elif send == "file":
        files = {
            'chat_id': (None, chat),
            'caption': (None, caption),
            'parse_mode': (None, mode),
            'disable_notification': (None, silent),
            'document': (file, open(file, 'rb')),
        }
        url = "https://api.telegram.org/bot" + token + "/sendDocument"
        r = post(url, files=files)
    elif send == "sticker":
        params = (
            ('chat_id', chat),
            ('parse_mode', mode),
            ('sticker', sticker),
        )
        url = "https://api.telegram.org/bot" + token + "/sendSticker"
        r = post(url, params=params)
    else:
        print("Error!")
    status = r.status_code
    response = r.reason


def req_status():
    if out == 'yes':
        if status == 200:
            print("Message sent")
        elif status == 400:
            print("Bad recipient / Wrong text format")
        elif status == 401:
            print("Wrong / Unauthorized token")
        else:
            print("Unknown error")
        print("Response: " + response)


arg_parse()
send_message()
req_status()
