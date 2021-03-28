#!/usr/bin/env python

import argparse
import sys
import os
import re
from time import sleep
from hashlib import md5
from subprocess import run
from PIL import Image
from youtube_dl import YoutubeDL
import pytesseract
import requests

def extract_text_from_lofi_video(youtube_url, threshold=221):
    # build unique filename in case we have multiple instances running
    unique_filename = md5(youtube_url.encode()).hexdigest()

    # get the underlying googlevideo streaming url
    with YoutubeDL({"quiet": True, "nocheckcertificate": True}) as ydl:
        info = ydl.extract_info(youtube_url, download=False)
        ytdl_url = info.get("url")

    # run ffmpeg against the stream to extract a frame from the video
    run([
        "ffmpeg",
        "-i",
        f"{ytdl_url}",
        "-vframes",
        "1",
        "-q:v",
        "2",
        f"{unique_filename}.jpeg"
    ], capture_output=True)

    # convert the image to grayscale
    im = Image.open(f"{unique_filename}.jpeg").convert('LA')

    # crop the image to 90% of its width and 7% of it's height
    # text has historically been across the top of the video
    width, height = im.size
    width = int(width * 0.9)
    height = int(height * 0.07)
    left = 0
    upper = 0
    right = left + width
    lower = upper + height
    im_crop = im.crop((left, upper, right, lower))
    if os.path.exists(f"{unique_filename}.jpeg"):
        os.remove(f"{unique_filename}.jpeg")

    # step through every x,y pixel coordinate in the image and if the
    # grayscale value is below our threshold, force it to full black
    # this is based on the assumption that the text is almost pure white
    # so we're attempting to black out the rest to make the text pop for ocr
    for x in range(width):
        for y in range(height):
            coord = x, y
            gray, alpha = im_crop.getpixel(coord)
            if gray < threshold:
                im_crop.putpixel(coord, (0, 255))

    # finally ocr the cropped and color-manipulated image and return the detected text
    return pytesseract.image_to_string(im_crop).rstrip()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extract text from Lofi Girl live streams')
    parser.add_argument('youtube_url', type=str, help='The live stream YouTube URL')
    parser.add_argument('mount_point', type=str, help='The live stream mount point')
    args = parser.parse_args()

    old_extracted_text = ''
    while True:
        # get song title from stream
        extracted_text = extract_text_from_lofi_video(youtube_url=args.youtube_url)
        if old_extracted_text != extracted_text:
            old_extracted_text = extracted_text

            # read values out of icecast config to post new title to metadata endpoint
            with open('/etc/icecast2/icecast.xml', 'r') as f:
                conf = f.read()
            m = re.search(r'<admin\-password>(?P<admin_pass>.*)</admin', conf)
            m = re.search(r'<port>(?P<ice_port>.*)</port', conf)

            # send new title to icecast admin metadata endpoint
            requests.get(f"http://admin:{m['admin_password']}@localhost:{m['ice_port']}/admin/metadata?mount=/{args.mount_point}&mode=updinfo&song={extracted_text}")
            print(f"Updated song title to '{extracted_text}'")
        sleep(1)