#! /bin/env python3
import argparse
import sys
import time

parser = argparse.ArgumentParser(description='join nextclade and pangolin tables')
debugmode = parser.add_mutually_exclusive_group()
debugmode.add_argument('-v', '--verbose', action='store_true')
debugmode.add_argument('-q', '--quiet', action='store_true')
parser.add_argument('--version', action='version', version='0.0.1')
parser.add_argument('-n', '--nextclade', help='path to nextclade file')
parser.add_argument('-p', '--pangolin', help='path to pangolin file')
parser.add_argument('-o', '--output', help='path to output file')

if __name__ == '__main__':
    args = parser.parse_args()

pango_file=args.pangolin
next_file=args.nextclade
final_file=args.output

def dict_pangolin(pango_file):
    dict_pango={}
    first=True
    with open(pango_file, "r") as file :
        for element in file :
            if first : #add header to the dictionary
                header_pango=element.replace(",","\t")
                header_pango=header_pango.replace("\n","")
                dict_pango["header"]=header_pango
                first=False
            else : #add results to the dictionary
                pango=element.replace(",","\t")
                pango_split=pango.split("\t")
                dict_pango[pango_split[0]]=pango.replace("\n","")
    return dict_pango

def dict_nextclade(next_file):
    dict_next={}
    first=True
    with open(next_file, "r") as file :
        for element in file :
            if first : #add header to the dictionary
                dict_next["header"]=element.replace("\n","")
                first=False
            else : #add results to the dictionary
                next_split=element.split("\t")
                dict_next[next_split[0]]=element.replace("\n","")
    return dict_next

def file_fusion(dict_next, dict_pango, final_file):
    i=0
    with open(final_file, "w") as output_file:
        for key in dict_next.keys():
            if key in dict_pango:
                output_file.write(dict_next[key]+ '\t' + dict_pango[key]+"\n")
                i+=1
    print(i)

a=dict_nextclade(next_file)
b=dict_pangolin(pango_file)
file_fusion(a,b,final_file)
