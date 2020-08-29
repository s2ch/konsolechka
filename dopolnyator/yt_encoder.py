"""Byte pair encoding utilities"""
import os
import youtokentome as yttm
import hashlib
from transformers.tokenization_utils import PreTrainedTokenizer
import shutil
import regex as re
from os.path import samefile

NEW_LINE = '<|n|>'

class YTEncoder(PreTrainedTokenizer):
    def_name = 'encoder.model'
    def __init__(self, filename, *inputs, **kwargs):
        super().__init__(*inputs, **kwargs)

        if os.path.isdir(filename): filename = os.path.join(filename, self.def_name)

        self.bpe = yttm.BPE(filename)
        self.hash = hashlib.sha512(open(filename, 'rb').read()).hexdigest()[:10]
        self.filename = filename

    def encode(self, text):
        if text and text[0] != ' ': text = ' ' + text
        text = re.sub(r'(?=[^ ])([\W])([\w])',r'\g<1> \g<2>',text)
        text = text.replace('\n', f' {NEW_LINE} ')

        return self.bpe.encode([text], output_type=yttm.OutputType.ID)[0]


    def decode(self, tokens): # I hate regexps
        if not isinstance(tokens,list):
            tokens = tokens.tolist()
        result = self.bpe.decode(tokens)[0]
        result = re.sub(r'( )?(<\|n\|>)( )?', r'\n', result)
        result = re.sub(r'([\n(]) (\w)',r'\g<1>\g<2>', result)
        result = re.sub(r'(\W)([«"''\n(]|^) (\w)',r'\g<1>\g<2>\g<3>', result)
        result = re.sub(r'(\w)- (\w)',r'\g<1>-\g<2>', result)
        return result

    def encode_list(self, text_list):
        result_list = []
        for text in text_list:
          if text and text[0] != ' ': text = ' ' + text
          text = re.sub(r'(?=[^ ])([\W])([\w])',r'\g<1> \g<2>',text)
          text = text.replace('\n', f' {NEW_LINE} ')
          result_list +=self.bpe.encode([text], output_type=yttm.OutputType.ID)[0]
          

        return result_list
        
    def encode_full(self, text):
        if text and text[0] != ' ': text = ' ' + text
        text = re.sub(r'(?=[^ ])([\W])([\w])',r'\g<1> \g<2>',text)
        text = text.replace('\n', f' {NEW_LINE} ')

        return self.bpe.encode([text], output_type=yttm.OutputType.ID)



    def vocab(self):
        return self.bpe.vocab()
        
    def tokenize(self, text, **kwargs):
        return self.encode(text)

    @classmethod
    def from_pretrained(cls, *inputs, **kwargs):
        return cls(*inputs, **kwargs)

    def add_special_tokens_single_sentence(self, token_ids):
        return token_ids

    def save_pretrained(self, save_directory):
        src = self.filename
        dst = os.path.join(save_directory, self.def_name)
        if src != dst:
            shutil.copyfile(src, dst)
