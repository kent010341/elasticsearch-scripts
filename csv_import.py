import sys
import os
import json
import tkinter as tk
from tkinter import filedialog, simpledialog
import requests
import pandas as pd

ES_HOST = '127.0.0.1'
ES_PORT = '9200'

def tk_ask(func, params={}):
    root = tk.Tk()
    root.withdraw()
    r = func(**params)

    if r == '':
        raise ValueError('Canceled.')

    return r

def ask_csv_path():
    return tk_ask(filedialog.askopenfilename)

def ask_string(title, default):
    params = {'title': title, 'initialvalue': default, 'prompt': ''}
    return tk_ask(simpledialog.askstring, params)

def ask_index_name(csv_path):
    base = os.path.basename(csv_path)
    index_name = 'index_' + (os.path.splitext(base)[0]).lower()

    index_name = ask_string('Index name', index_name)

    return index_name

def ask_host():
    return ask_string('Host', ES_HOST + ':' + ES_PORT)

def prepare_body(csv_path):
    df = pd.read_csv(csv_path, dtype=str)

    body = ''
    for _, row in df.iterrows():
        body += '{"create": {}}\n' + \
        json.dumps(row.to_dict()) + '\n'

    return body

def send_request(host, body, index_name):
    headers = {'Content-Type': 'application/x-ndjson'}
    resp = requests.post('http://{}/{}/_bulk'.format(host, index_name), 
        headers=headers, data=body)
    try:
        resp.raise_for_status()
    except requests.exceptions.HTTPError as e:
        print(resp.text)
        print(e)
    print(resp.text)

def main():
    csv_path = ask_csv_path()
    index_name = ask_index_name(csv_path)
    host = ask_host()

    body = prepare_body(csv_path)
    send_request(host, body, index_name)

if __name__ == '__main__':
    main()
