import os
import sqlite3
import re

final_variations = {
  'a': re.compile(r'ā'),
  'u': re.compile(r'ū'),
  't': re.compile(r'ṭ'),
  'n': re.compile(r'[ñṇṅ]'),
  'i': re.compile(r'ī'),
  'd': re.compile(r'ḍ'),
  'l': re.compile(r'ḷ'),
  'm': re.compile(r'[ṁṃ]')
}

def cleanhtml(raw_html):
    re_html = re.compile('<[^>]*>')
    cleantext = re.sub(re_html, '', raw_html)
    return cleantext

def cleanWord(word):
    re_token = re.compile(r'[^a-zāīūṅñṭḍṇḷṃ]')
    clean_word = re.sub(re_token, '', word)
    return clean_word

def _toPlain(word):
    plain = word.lower().strip()
    for key, value in final_variations.items():
        plain = value.sub(key, plain)
    return plain

words = {}

dbfile = '../assets/database/tipitaka_pali.db'

print('building wordlist ...\nplease wait a moment ...')

conn = sqlite3.connect(dbfile)
cursor = conn.cursor()

cursor.execute('DROP TABLE IF EXISTS words')
cursor.execute('CREATE TABLE words (word TEXT, plain TEXT, frequency INTEGER)')
cursor.execute('SELECT rowid, content FROM pages')
rows = cursor.fetchall()

for row in rows:
    rowid = row[0]
    content = row[1]
    content = cleanhtml(content)
    wordlist = content.split()

    for idx, word in enumerate(wordlist):
        word = cleanWord(word)
        if len(word) > 0:
            plain_word = _toPlain(word)
            if word in words:
                words[word]['frequency'] += 1
            else:
                words[word] = {'plain': plain_word, 'frequency': 1}

for key, value in words.items():
    cursor.execute(f"INSERT INTO words (word, plain, frequency) VALUES ('{key}', '{value['plain']}', {value['frequency']})")

conn.commit()
conn.close()

print('successfully created word list table')
